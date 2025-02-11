class GameState {
  final List<String> currentLetters;
  final int timeRemaining;
  final int wordsFoundThisMinute;
  final int totalWordsFound;
  final int sessionWordsFound;
  final List<WordEntry> completedWords;
  final double completionPercentage;
  final int dictionarySize;

  GameState({
    required this.currentLetters,
    required this.timeRemaining,
    required this.wordsFoundThisMinute,
    required this.totalWordsFound,
    required this.sessionWordsFound,
    required this.completedWords,
    required this.completionPercentage,
    required this.dictionarySize,
  });
}

class WordEntry {
  final String word;
  final DateTime timestamp;

  const WordEntry(this.word, this.timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordEntry &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          timestamp == other.timestamp;

  @override
  int get hashCode => word.hashCode ^ timestamp.hashCode;
}
