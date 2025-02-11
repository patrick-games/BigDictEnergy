import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class WordService {
  final Set<String> dictionaryWords = {};
  final Set<String> completedWords = {};
  final List<String> _vowels = ['A', 'E', 'I', 'O', 'U'];

  List<String> get vowels => _vowels;

  Future<void> initializeWords() async {
    try {
      // Load dictionary from json
      String jsonString = await rootBundle.loadString('assets/word_list.json');
      Map<String, dynamic> jsonData = json.decode(jsonString);

      // Get the keys (words) from the JSON object
      dictionaryWords.addAll(jsonData.keys.map((w) => w.toUpperCase()));
      print("Dictionary loaded with ${dictionaryWords.length} words");
    } catch (e) {
      print("Error loading dictionary: $e");
      rethrow;
    }
  }

  List<String> generateLetters() {
    List<String> vowels = ['A', 'E', 'I', 'O', 'U'];
    List<String> consonants = [
      'B',
      'C',
      'D',
      'F',
      'G',
      'H',
      'J',
      'K',
      'L',
      'M',
      'N',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'V',
      'W',
      'X',
      'Y',
      'Z'
    ];

    // Shuffle separately
    vowels.shuffle();
    consonants.shuffle();

    // Take 4-5 vowels and fill rest with consonants
    int numVowels = Random().nextInt(2) + 4; // 4-5 vowels
    List<String> selectedLetters = [];

    // Add vowels first
    selectedLetters.addAll(vowels.take(numVowels));

    // Fill remaining spots with consonants
    selectedLetters.addAll(consonants.take(15 - numVowels));

    return selectedLetters;
  }

  bool isValidWord(String word, List<String> currentLetters) {
    word = word.toUpperCase();
    print("Checking word: $word");
    print("Available letters: $currentLetters");

    // First check if it's a valid dictionary word and hasn't been found before
    if (!dictionaryWords.contains(word)) {
      print("Word not in dictionary");
      return false;
    }
    if (completedWords.contains(word)) {
      print("Word already found");
      return false;
    }

    // Check if each letter in the word is available
    for (String letter in word.split('')) {
      if (!currentLetters.contains(letter)) {
        print("Letter $letter not available");
        return false;
      }
    }

    print("Word is valid!");
    return true;
  }

  int calculatePoints(String word) {
    return word.length * 10; // Simple scoring: 10 points per letter
  }
}
