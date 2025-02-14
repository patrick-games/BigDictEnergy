import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class FirebaseService {
  FirebaseFirestore? _firestore;
  DocumentSnapshot? _cachedGameState;
  DateTime? _lastGameStateFetch;

  FirebaseService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print("Error initializing Firestore: $e");
    }
  }

  // Reference to the single game document
  DocumentReference get gameRef {
    if (_firestore == null) {
      throw Exception('Firestore not initialized');
    }
    return _firestore!.collection('games').doc('current');
  }

  // Reference to completed words collection
  CollectionReference get _wordsRef {
    if (_firestore == null) {
      throw Exception('Firestore not initialized');
    }
    return _firestore!.collection('completedWords');
  }

  // Stream of game state with caching
  Stream<DocumentSnapshot> getGameStateStream() {
    return gameRef.snapshots();
  }

  // Stream of completed words
  Stream<QuerySnapshot> getCompletedWordsStream() {
    return _wordsRef.orderBy('timestamp', descending: true).snapshots();
  }

  // Get current game state with caching
  Future<Map<String, dynamic>> getCurrentGameState() async {
    // If we have a cached state and it's less than 1 second old, use it
    if (_cachedGameState != null && _lastGameStateFetch != null) {
      final age = DateTime.now().difference(_lastGameStateFetch!);
      if (age.inSeconds < 1) {
        return _cachedGameState!.data() as Map<String, dynamic>;
      }
    }

    final snapshot = await gameRef.get();
    _cachedGameState = snapshot;
    _lastGameStateFetch = DateTime.now();

    if (!snapshot.exists) {
      return {};
    }
    return snapshot.data() as Map<String, dynamic>;
  }

  // Initialize or get current game state
  Future<void> initializeGameState() async {
    try {
      print("Initializing game state...");

      final gameDoc = await gameRef.get();
      _cachedGameState = gameDoc;
      _lastGameStateFetch = DateTime.now();

      print("Game document exists: ${gameDoc.exists}");

      if (!gameDoc.exists) {
        print("Creating new game state...");
        await gameRef.set({
          'currentLetters': [],
          'timeRemaining': 60,
          'roundStartTime': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      print("Game state initialized successfully");
    } catch (e) {
      print('Error initializing game state: $e');
      rethrow;
    }
  }

  // Update current letters
  Future<void> updateCurrentLetters(List<String> letters) async {
    await gameRef.update({
      'currentLetters': letters,
      'timeRemaining': 60,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Add a found word
  Future<void> addFoundWord(String word) async {
    try {
      // Add to completed words collection
      await _wordsRef.add({
        'word': word.toUpperCase(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Word added to Firestore: $word");
    } catch (e) {
      print("Error adding word: $e");
      rethrow;
    }
  }

  // Calculate elapsed time since round start
  Future<int> getElapsedTime() async {
    final snapshot = await gameRef.get();
    if (!snapshot.exists) {
      return 0;
    }

    final data = snapshot.data() as Map<String, dynamic>;
    final roundStartTime = (data['roundStartTime'] as Timestamp?)?.toDate();

    if (roundStartTime == null) {
      return 0;
    }

    return DateTime.now().difference(roundStartTime).inSeconds;
  }

  // Update game state with time
  Future<void> updateGameState(
    int timeRemaining,
    List<String> currentLetters, {
    DateTime? roundStartTime,
  }) async {
    Map<String, dynamic> data = {
      'timeRemaining': timeRemaining,
      'currentLetters': currentLetters,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (roundStartTime != null) {
      data['roundStartTime'] = Timestamp.fromDate(roundStartTime);
    }

    await gameRef.update(data);
  }

  Future<void> submitWord(String word) async {
    final timestamp = FieldValue.serverTimestamp();

    // Use a transaction to ensure word is counted even at last moment
    await _firestore!.runTransaction((transaction) async {
      final gameDoc = await transaction.get(gameRef);
      final gameData = gameDoc.data() as Map<String, dynamic>;

      // Only accept word if time remaining
      if (gameData['timeRemaining'] > 0) {
        await transaction.update(gameRef, {});

        await _wordsRef.add({
          'word': word,
          'timestamp': timestamp,
        });
      }
    });
  }

  Future<void> resetGame() async {
    try {
      // Delete all words
      final wordsSnapshot = await _wordsRef.get();
      final batch = _firestore!.batch();
      for (var doc in wordsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Reset game state
      batch.update(gameRef, {
        'timeRemaining': 60,
      });

      await batch.commit();
      print("Game reset successful");
    } catch (e) {
      print("Error resetting game: $e");
      rethrow;
    }
  }

  Future<DateTime?> getRoundStartTime() async {
    final doc = await gameRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['roundStartTime'] != null) {
        return (data['roundStartTime'] as Timestamp).toDate();
      }
    }
    return null;
  }

  Future<bool> wasWordFoundBefore(String word) async {
    final snapshot =
        await _wordsRef.where('word', isEqualTo: word).limit(1).get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> startNewRound({
    required List<String> letters,
    required int duration,
  }) async {
    await _firestore!.runTransaction((transaction) async {
      final gameDoc = await transaction.get(gameRef);

      // Update game state atomically
      transaction.set(gameRef, {
        'currentLetters': letters,
        'timeRemaining': duration,
        'roundStartTime': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // Add this method to calculate time based on server timestamp
  Future<int> calculateTimeRemaining() async {
    try {
      DocumentSnapshot gameDoc = await gameRef.get();
      if (!gameDoc.exists) return 60;

      Timestamp roundStartTime = gameDoc.get('roundStartTime');
      int elapsedSeconds =
          DateTime.now().difference(roundStartTime.toDate()).inSeconds;

      return math.max(0, 60 - elapsedSeconds);
    } catch (e) {
      print('Error calculating time: $e');
      return 60;
    }
  }
}
