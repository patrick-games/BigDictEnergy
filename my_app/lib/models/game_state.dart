class GameState {
  final List<String> currentLetters;
  final int timeRemaining;
  final int totalWordsFound;
  final List<WordEntry> completedWords;
  final double completionPercentage;
  final int dictionarySize;

  GameState({
    required this.currentLetters,
    required this.timeRemaining,
    required this.totalWordsFound,
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
