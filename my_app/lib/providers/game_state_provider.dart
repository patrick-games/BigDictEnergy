import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:html' if (dart.library.html) 'dart:html' as html;
import '../models/game_state.dart';
import '../services/firebase_service.dart';
import '../services/word_service.dart';

part 'game_state_provider.g.dart';

@riverpod
class GameStateNotifier extends _$GameStateNotifier
    with WidgetsBindingObserver {
  late FirebaseService _firebaseService;
  late WordService _wordService;
  bool _isInitialized = false;
  Timer? _localTimer;
  Timer? _syncTimer;
  DateTime? _roundStartTime;

  @override
  GameState build() {
    // Initialize services
    _firebaseService = FirebaseService();
    _wordService = WordService();

    // Register observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Add visibility change listener for web
    if (kIsWeb) {
      html.window.onVisibilityChange.listen((_) {
        if (html.document.visibilityState == 'hidden') {
          _handleAppBackground();
        } else if (html.document.visibilityState == 'visible') {
          _handleAppForeground();
        }
      });

      // Handle page refresh/unload
      html.window.onBeforeUnload.listen((event) {
        _handleAppBackground();
      });
    }

    // Initialize with default state
    return _createInitialState();
  }

  GameState _createInitialState() {
    return GameState(
      currentLetters: [],
      timeRemaining: 60,
      wordsFoundThisMinute: 0,
      totalWordsFound: 0,
      sessionWordsFound: 0,
      completedWords: [],
      completionPercentage: 0,
      dictionarySize: 0,
    );
  }

  void _handleAppBackground() {
    _localTimer?.cancel();
    _syncTimer?.cancel();
    _isInitialized = false;
    state = _createInitialState();
  }

  void _handleAppForeground() {
    if (_isInitialized) {
      initialize(); // Re-initialize the game
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _handleAppBackground();
        break;
      case AppLifecycleState.resumed:
        _handleAppForeground();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _updateGameState(GameState Function(GameState) update) {
    state = update(state);
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_roundStartTime != null) {
        final elapsedSeconds =
            DateTime.now().difference(_roundStartTime!).inSeconds;
        final timeRemaining = (60 - (elapsedSeconds % 60)).clamp(0, 60);

        _updateGameState(
            (state) => state.copyWith(timeRemaining: timeRemaining));

        if (timeRemaining <= 0) {
          _updateGameState((state) => state.copyWith(
                wordsFoundThisMinute: 0,
                completedWords: [],
              ));
          _startNewRound();
        }
      }
    });
  }

  Future<void> _syncWithFirebase() async {
    try {
      final snapshot = await _firebaseService.getCurrentGameState();
      final data = snapshot.data() as Map<String, dynamic>;

      if (data != null) {
        final serverLetters = List<String>.from(data['currentLetters'] ?? []);
        if (state.currentLetters != serverLetters) {
          _updateGameState((state) => state.copyWith(
                currentLetters: serverLetters,
                wordsFoundThisMinute: data['wordsFoundThisMinute'] ?? 0,
                totalWordsFound: data['totalWordsFound'] ?? 0,
              ));
        }
      }
    } catch (e) {
      print("Error syncing with Firebase: $e");
    }
  }

  Future<void> _startNewRound() async {
    try {
      final newLetters = _wordService.generateLetters();
      _roundStartTime = DateTime.now();

      _updateGameState((state) => state.copyWith(
            currentLetters: newLetters,
            timeRemaining: 60,
            wordsFoundThisMinute: 0,
            completedWords: [],
          ));

      await _firebaseService.startNewRound(newLetters);
    } catch (e) {
      print("Error starting new round: $e");
    }
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await _wordService.initializeWords();
        await _firebaseService.initializeGameState();

        // Get initial state from Firebase
        final gameDoc = await _firebaseService.gameRef.get();
        if (gameDoc.exists) {
          final data = gameDoc.data() as Map<String, dynamic>;
          _roundStartTime = (data['roundStartTime'] as Timestamp).toDate();

          final now = DateTime.now();
          final elapsedSeconds = now.difference(_roundStartTime!).inSeconds;
          final timeRemaining = (60 - (elapsedSeconds % 60)).clamp(0, 60);

          ref.notifyListeners();

          // Start timers after initial state is set
          _startLocalTimer();
          _syncWithFirebase();
        }

        _isInitialized = true;
      } catch (e) {
        print("Error initializing game: $e");
        rethrow;
      }
    }
  }

  void _setupFirestoreListeners() {
    // Listen to completed words only
    _firebaseService.getCompletedWordsStream().listen(
      (snapshot) {
        _handleCompletedWordsUpdate(snapshot);
      },
      onError: (error) {
        print("Completed words stream error: $error");
        Future.delayed(const Duration(seconds: 2), _setupFirestoreListeners);
      },
    );
  }

  void _handleCompletedWordsUpdate(QuerySnapshot snapshot) {
    try {
      final now = DateTime.now();
      final roundStartTime = _roundStartTime ?? now;

      final currentWords = snapshot.docs
          .where((doc) => (doc.get('timestamp') as Timestamp)
              .toDate()
              .isAfter(roundStartTime))
          .map((doc) => WordEntry(
                doc.get('word') as String,
                (doc.get('timestamp') as Timestamp).toDate(),
              ))
          .toList();

      ref.notifyListeners();
    } catch (e) {
      print("Error handling completed words update: $e");
    }
  }

  Future<void> submitWord(String word) async {
    final upperWord = word.toUpperCase();

    // Validate word
    if (!_wordService.isValidDictionaryWord(upperWord)) {
      throw 'Not a valid word';
    }

    if (!_wordService.canBeFormedFromLetters(upperWord, state.currentLetters)) {
      throw 'Word cannot be made with current letters';
    }

    // Check if word was already found
    if (state.completedWords.any((w) => w.word == upperWord)) {
      throw 'Word already found this round';
    }

    try {
      // Submit to Firebase first
      await _firebaseService.submitWord(upperWord);

      // Then update local state
      final newWord = WordEntry(upperWord, DateTime.now());
      ref.notifyListeners();
    } catch (e) {
      print("Error submitting word: $e");
      throw 'Failed to submit word';
    }
  }

  Future<void> resetGame() async {
    try {
      await _firebaseService.resetGame();
      ref.notifyListeners();
      await _startNewRound();
    } catch (e) {
      print("Error resetting game: $e");
      rethrow;
    }
  }
}
