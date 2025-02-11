import 'dart:async';
import '../services/word_service.dart';
import '../services/firebase_service.dart';
import '../models/game_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GameController extends ChangeNotifier {
  final WordService wordService;
  final FirebaseService firebaseService;
  StreamSubscription? _gameSubscription;
  StreamSubscription? _wordsSubscription;
  List<String> currentLetters = [];
  Timer? _timer;
  int _timeRemaining = 60;
  int wordsFoundThisMinute = 0;
  int totalWordsFound = 0;
  bool _isInitialized = false;

  // Add session counter
  int _sessionWordsFound = 0;
  int get sessionWordsFound => _sessionWordsFound;

  final _gameStateController = StreamController<GameState>.broadcast();
  Stream<GameState> get gameState => _gameStateController.stream;

  // Keep track of current round words locally
  List<String> _currentRoundWords = [];

  GameController(this.wordService) : firebaseService = FirebaseService() {
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      print("Starting Firebase initialization...");
      await firebaseService.initializeGameState();
      print("Firebase initialized, getting game state...");

      // Get current game state
      Map<String, dynamic> gameState =
          await firebaseService.getCurrentGameState();
      print("Retrieved game state: $gameState");

      currentLetters = List<String>.from(gameState['currentLetters'] ?? []);
      wordsFoundThisMinute = gameState['wordsFoundThisMinute'] ?? 0;
      totalWordsFound = gameState['totalWordsFound'] ?? 0;
      print("State variables set");

      // Calculate remaining time
      int elapsedTime = await firebaseService.getElapsedTime();
      _timeRemaining = (gameState['timeRemaining'] ?? 60) - elapsedTime;
      print("Time remaining calculated: $_timeRemaining");

      if (_timeRemaining <= 0 || currentLetters.isEmpty) {
        print("Generating new letters...");
        await _generateNewLetters();
        _timeRemaining = 60;
      }

      print("Starting timer and updating state...");
      _startTimer();
      _updateGameState();

      // Listen to game state changes
      print("Setting up game state listener...");
      _gameSubscription = firebaseService.getGameStateStream().listen(
        (snapshot) {
          print("Game state update received");
          if (snapshot.exists) {
            _handleGameStateUpdate(snapshot);
          }
        },
        onError: (error) => print("Game state stream error: $error"),
      );

      // Listen to completed words
      print("Setting up completed words listener...");
      _wordsSubscription = firebaseService.getCompletedWordsStream().listen(
        (snapshot) {
          print("Completed words update received");
          _handleCompletedWordsUpdate(snapshot);
        },
        onError: (error) => print("Completed words stream error: $error"),
      );

      print("Firebase initialization complete");
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  void _handleGameStateUpdate(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    currentLetters = List<String>.from(data['currentLetters']);

    // Always update these values from Firebase
    wordsFoundThisMinute = data['wordsFoundThisMinute'] ?? 0;
    totalWordsFound = data['totalWordsFound'] ?? 0;

    // Only update time if it's from a newer state
    int newTime = data['timeRemaining'];
    if (newTime < _timeRemaining) {
      _timeRemaining = newTime;
    }

    // Use stored current round words
    _updateGameState();
  }

  void _handleCompletedWordsUpdate(QuerySnapshot snapshot) {
    try {
      List<WordEntry> currentWords = [];
      DateTime now = DateTime.now();
      DateTime roundStartTime =
          now.subtract(Duration(seconds: 60 - _timeRemaining));

      for (var doc in snapshot.docs) {
        String word = doc.get('word');
        DateTime timestamp = doc.get('timestamp').toDate();

        // Only add words from current round
        if (timestamp.isAfter(roundStartTime)) {
          currentWords.add(WordEntry(word.toUpperCase(), timestamp));
          print("Added word to current round: $word");
        }
      }

      // Update words found this minute count
      wordsFoundThisMinute = currentWords.length;

      // Update total words found (all time)
      totalWordsFound = snapshot.docs.length;

      // Sort by most recent first
      currentWords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Store current round words
      _currentRoundWords = currentWords.map((w) => w.word).toList();

      _updateGameState();
    } catch (e) {
      print("Error handling completed words update: $e");
    }
  }

  Future<void> startGame() async {
    if (!_isInitialized) {
      try {
        await wordService.initializeWords(); // Initialize dictionary from JSON
        _isInitialized = true;

        // Get existing state from Firebase
        Map<String, dynamic> gameState =
            await firebaseService.getCurrentGameState();

        // If we have existing letters and time remaining, use them
        if (gameState['currentLetters']?.isNotEmpty == true &&
            (gameState['timeRemaining'] ?? 0) > 0) {
          currentLetters = List<String>.from(gameState['currentLetters']);
          _timeRemaining = gameState['timeRemaining'];
          wordsFoundThisMinute = gameState['wordsFoundThisMinute'] ?? 0;
          totalWordsFound = gameState['totalWordsFound'] ?? 0;
        } else {
          // Generate new letters if no valid state exists
          await _generateNewLetters();
        }

        _startTimer();
        _updateGameState();
      } catch (e) {
        print("Error starting game: $e");
        rethrow;
      }
    }
  }

  Future<void> _generateNewLetters() async {
    try {
      currentLetters = wordService.generateLetters();
      wordsFoundThisMinute = 0;
      // Clear current round words
      _currentRoundWords = [];

      await firebaseService.updateCurrentLetters(currentLetters);
      print("Generated new letters: $currentLetters");
      _updateGameState();
    } catch (e) {
      print("Error generating new letters: $e");
      rethrow;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _timeRemaining--;
      if (_timeRemaining <= 0) {
        wordsFoundThisMinute = 0;
        await _generateNewLetters();
        _timeRemaining = 60;
      }
      await firebaseService.updateGameState(_timeRemaining, currentLetters);
      _updateGameState();
    });
  }

  void _updateGameState() {
    double completion =
        (totalWordsFound / wordService.dictionaryWords.length) * 100;

    _gameStateController.add(
      GameState(
        currentLetters: currentLetters,
        timeRemaining: _timeRemaining,
        wordsFoundThisMinute: wordsFoundThisMinute,
        totalWordsFound: totalWordsFound,
        sessionWordsFound: _sessionWordsFound,
        completedWords: _currentRoundWords
            .map((w) => WordEntry(w, DateTime.now()))
            .toList(),
        completionPercentage: completion,
        dictionarySize: wordService.dictionaryWords.length,
      ),
    );
  }

  Future<void> submitWord(String word) async {
    if (wordService.isValidWord(word, currentLetters)) {
      try {
        await firebaseService.submitWord(word);

        // Add to current round words
        _currentRoundWords.add(word.toUpperCase());
        _sessionWordsFound++;
        wordsFoundThisMinute = _currentRoundWords.length;

        _updateGameState();
        print("Word submitted successfully: $word");
      } catch (e) {
        print("Error submitting word: $e");
        return Future.error('Failed to submit word');
      }
    } else {
      return Future.error('Invalid word');
    }
  }

  Future<void> resetGame() async {
    try {
      await firebaseService.resetGame();
      _sessionWordsFound = 0;
      wordService.completedWords.clear();
      await _generateNewLetters();
      _timeRemaining = 60;
      _updateGameState();
    } catch (e) {
      print("Error resetting game: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _wordsSubscription?.cancel();
    _timer?.cancel();
    _gameStateController.close();
  }
}
