class GameState {
  final List<String> currentLetters;
  final int timeRemaining;
  final int wordsFoundThisMinute;
  final int totalWordsFound;
  final double completionPercentage;

  GameState({
    required this.currentLetters,
    required this.timeRemaining,
    required this.wordsFoundThisMinute,
    required this.totalWordsFound,
    required this.completionPercentage,
  });
}
