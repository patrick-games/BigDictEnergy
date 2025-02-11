import 'dart:async';
import '../services/word_service.dart';
import '../models/game_state.dart';

class GameController {
  final WordService wordService;
  List<String> currentLetters = [];
  Timer? _timer;
  int _timeRemaining = 60;
  int wordsFoundThisMinute = 0;
  int totalWordsFound = 0;
  bool _isInitialized = false;

  final _gameStateController = StreamController<GameState>.broadcast();
  Stream<GameState> get gameState => _gameStateController.stream;

  GameController(this.wordService);

  Future<void> startGame() async {
    if (!_isInitialized) {
      _isInitialized = true;
      _generateNewLetters();
      _startTimer();
      _updateGameState();
    }
  }

  void _generateNewLetters() {
    currentLetters = wordService.generateLetters();
    print("Generated letters: $currentLetters");
    _updateGameState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;
      if (_timeRemaining <= 0) {
        wordsFoundThisMinute = 0;
        _generateNewLetters();
        _timeRemaining = 60;
      }
      _updateGameState();
    });
  }

  void _updateGameState() {
    double completion = (wordService.completedWords.length /
            wordService.dictionaryWords.length) *
        100;

    print(
        "Updating game state: ${currentLetters.length} letters, $completion% complete");

    _gameStateController.add(GameState(
      currentLetters: currentLetters,
      timeRemaining: _timeRemaining,
      wordsFoundThisMinute: wordsFoundThisMinute,
      totalWordsFound: totalWordsFound,
      completionPercentage: completion,
    ));
  }

  void dispose() {
    _timer?.cancel();
    _gameStateController.close();
  }
}
