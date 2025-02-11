import 'dart:math';

class WordService {
  final Set<String> dictionaryWords = {};
  final Set<String> completedWords = {};
  final List<String> _vowels = ['A', 'E', 'I', 'O', 'U'];

  List<String> get vowels => _vowels;

  Future<void> initializeWords(List<String> words) {
    dictionaryWords.addAll(words.map((w) => w.toUpperCase()));
    return Future.value();
  }

  List<String> generateLetters() {
    List<String> letters = [_vowels[Random().nextInt(_vowels.length)]];
    List<String> alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')
      ..removeWhere((l) => letters.contains(l));

    // Random number between 5 and 14 (so total will be 6-15 letters)
    int additionalLetters = Random().nextInt(10) + 5;
    for (int i = 0; i < additionalLetters && alphabet.isNotEmpty; i++) {
      int index = Random().nextInt(alphabet.length);
      letters.add(alphabet[index]);
      alphabet.removeAt(index);
    }
    return letters;
  }

  bool isValidWord(String word, List<String> currentLetters) {
    word = word.toUpperCase();
    if (!dictionaryWords.contains(word)) return false;
    if (completedWords.contains(word)) return false;

    Map<String, int> letterCount = {};
    for (String letter in currentLetters) {
      letterCount[letter] = (letterCount[letter] ?? 0) + 1;
    }

    for (String letter in word.split('')) {
      if (!letterCount.containsKey(letter) || letterCount[letter]! < 1) {
        return false;
      }
      letterCount[letter] = letterCount[letter]! - 1;
    }
    return true;
  }

  int calculatePoints(String word) {
    return word.length * 10; // Simple scoring: 10 points per letter
  }
}
