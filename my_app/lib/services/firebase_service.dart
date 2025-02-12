import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the single game document
  DocumentReference get _gameRef =>
      _firestore.collection('games').doc('current');

  // Reference to completed words collection
  CollectionReference get _wordsRef => _firestore.collection('completedWords');

  // Stream of game state
  Stream<DocumentSnapshot> getGameStateStream() {
    return _gameRef.snapshots();
  }

  // Stream of completed words
  Stream<QuerySnapshot> getCompletedWordsStream() {
    return _wordsRef.orderBy('timestamp', descending: true).snapshots();
  }

  // Initialize or get current game state
  Future<void> initializeGameState() async {
    try {
      print("Initializing game state...");

      final gameDoc = await _gameRef.get();
      print("Game document exists: ${gameDoc.exists}");

      if (!gameDoc.exists) {
        print("Creating new game state...");
        await _gameRef.set({
          'currentLetters': [],
          'timeRemaining': 60,
          'wordsFoundThisMinute': 0,
          'totalWordsFound': 0,
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
    await _gameRef.update({
      'currentLetters': letters,
      'timeRemaining': 60,
      'wordsFoundThisMinute': 0,
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

  // Get time since last update
  Future<int> getElapsedTime() async {
    try {
      DocumentSnapshot gameDoc = await _gameRef.get();
      if (!gameDoc.exists) return 0;

      Timestamp? lastUpdated = gameDoc.get('lastUpdated');
      if (lastUpdated == null) return 0;

      return DateTime.now().difference(lastUpdated.toDate()).inSeconds;
    } catch (e) {
      print('Error getting elapsed time: $e');
      return 0;
    }
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

    await _gameRef.update(data);
  }

  // Get current game state
  Future<Map<String, dynamic>> getCurrentGameState() async {
    try {
      DocumentSnapshot gameDoc = await _gameRef.get();
      print("Retrieved game state: ${gameDoc.data()}");
      if (!gameDoc.exists) {
        print("No game state found, initializing...");
        await initializeGameState();
        return {
          'currentLetters': [],
          'timeRemaining': 60,
          'wordsFoundThisMinute': 0,
          'totalWordsFound': 0,
        };
      }
      return gameDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting game state: $e');
      rethrow;
    }
  }

  Future<void> submitWord(String word) async {
    try {
      final batch = _firestore.batch();

      // Add to completed words collection
      batch.set(_wordsRef.doc(), {
        'word': word.toUpperCase(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update counters in game state
      batch.update(_gameRef, {
        'wordsFoundThisMinute': FieldValue.increment(1),
        'totalWordsFound': FieldValue.increment(1),
      });

      // Commit both operations atomically
      await batch.commit();
      print("Word added to Firestore: $word");
    } catch (e) {
      print("Error adding word: $e");
      rethrow;
    }
  }

  Future<void> resetGame() async {
    try {
      // Delete all words
      final wordsSnapshot = await _wordsRef.get();
      final batch = _firestore.batch();
      for (var doc in wordsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Reset game state
      batch.update(_gameRef, {
        'wordsFoundThisMinute': 0,
        'totalWordsFound': 0,
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
    final doc = await _gameRef.get();
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
}
