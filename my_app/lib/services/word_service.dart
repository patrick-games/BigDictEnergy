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

  bool canBeFormedFromLetters(String word, List<String> letters) {
    // Check if each letter in the word is in our available letters
    // Letters can be used multiple times
    for (var letter in word.split('')) {
      if (!letters.contains(letter)) {
        return false; // Letter not available at all
      }
    }
    return true;
  }

  bool isValidDictionaryWord(String word) {
    return dictionaryWords.contains(word.toUpperCase());
  }

  bool isValidWord(String word, List<String> letters) {
    return isValidDictionaryWord(word) && canBeFormedFromLetters(word, letters);
  }

  int calculatePoints(String word) {
    return word.length * 10; // Simple scoring: 10 points per letter
  }
}
