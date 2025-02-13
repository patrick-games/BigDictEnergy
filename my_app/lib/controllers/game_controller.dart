import 'dart:async';
import '../services/word_service.dart';
import '../services/firebase_service.dart';
import '../models/game_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

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

  void _handleGameStateUpdate(DocumentSnapshot snapshot) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    // Get server-based time
    Timestamp roundStartTime = data['roundStartTime'];
    int elapsedSeconds =
        DateTime.now().difference(roundStartTime.toDate()).inSeconds;
    _timeRemaining = math.max(0, 60 - elapsedSeconds);

    // Update letters if round is over
    if (_timeRemaining <= 0) {
      currentLetters = List<String>.from(data['currentLetters']);
      wordsFoundThisMinute = 0;
      _currentRoundWords.clear();
    } else {
      currentLetters = List<String>.from(data['currentLetters']);
      wordsFoundThisMinute = data['wordsFoundThisMinute'] ?? 0;
    }

    _updateGameState();
  }

  void _handleCompletedWordsUpdate(QuerySnapshot snapshot) {
    try {
      List<WordEntry> currentWords = [];
      DateTime now = DateTime.now();
      DateTime roundStartTime =
          now.subtract(Duration(seconds: 60 - _timeRemaining));

      // Create a set to prevent duplicates
      Set<String> processedWords = {};

      // Track current round words
      for (var doc in snapshot.docs) {
        String word = doc.get('word');
        DateTime timestamp = doc.get('timestamp').toDate();

        // Only add words from current round and not already processed
        if (timestamp.isAfter(roundStartTime) &&
            !processedWords.contains(word)) {
          currentWords.add(WordEntry(word.toUpperCase(), timestamp));
          processedWords.add(word);
          print("Added word to current round: $word");
        }
      }

      // Update words found this minute count
      wordsFoundThisMinute = currentWords.length;

      // Update total words found (all time) - this is the total in Firestore
      totalWordsFound =
          snapshot.size; // Use size instead of current round length

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
      try {
        // Get time from server
        int serverTimeRemaining =
            await firebaseService.calculateTimeRemaining();

        if (serverTimeRemaining <= 0) {
          // Cancel current timer immediately
          timer.cancel();

          try {
            // Generate new letters
            List<String> newLetters = wordService.generateLetters();

            // Update Firebase atomically with new state
            await firebaseService.startNewRound(
              letters: newLetters,
              duration: 60,
            );

            // Update local state
            currentLetters = newLetters;
            _timeRemaining = 60;
            wordsFoundThisMinute = 0;
            _currentRoundWords.clear();

            // Start new timer
            _startTimer();
          } catch (e) {
            print("Error starting new round: $e");
          }
        } else {
          _timeRemaining = serverTimeRemaining;
          _updateGameState();
        }
      } catch (e) {
        print("Error in timer: $e");
      }
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
    String upperWord = word.toUpperCase();

    // First check if word was already found this round
    if (_currentRoundWords.contains(upperWord)) {
      print("Word already found this round: $word");
      return Future.error('Word already found this round');
    }

    // Then check if word was found in any previous round
    bool wasFoundPreviously =
        await firebaseService.wasWordFoundBefore(upperWord);
    if (wasFoundPreviously) {
      print("Word was found in a previous round: $word");
      return Future.error('Word was found in a previous round');
    }

    // Check if it's a valid dictionary word first
    if (!wordService.isValidDictionaryWord(upperWord)) {
      return Future.error('Not a valid word');
    }

    // Then check if it can be made with current letters
    if (wordService.canBeFormedFromLetters(upperWord, currentLetters)) {
      try {
        // Optimistically add to local state for immediate feedback
        _currentRoundWords.add(upperWord);
        _sessionWordsFound++;
        wordsFoundThisMinute = _currentRoundWords.length;
        _updateGameState();

        // Then update Firebase in the background
        firebaseService.submitWord(upperWord).catchError((e) {
          // If Firebase update fails, rollback local state
          _currentRoundWords.remove(upperWord);
          _sessionWordsFound--;
          wordsFoundThisMinute = _currentRoundWords.length;
          _updateGameState();
          print("Error submitting word: $e");
          return Future.error('Failed to submit word');
        });

        print("Word submitted successfully: $word");
      } catch (e) {
        print("Error submitting word: $e");
        return Future.error('Failed to submit word');
      }
    } else {
      return Future.error('Word cannot be made with current letters');
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
