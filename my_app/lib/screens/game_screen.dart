import 'package:flutter/material.dart';
import '../services/word_service.dart';
import 'dart:convert';
import 'dart:async';
import '../widgets/honeycomb_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  final WordService _wordService = WordService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> currentLetters = [];
  Timer? _timer;
  int _timeRemaining = 60;
  int wordsFoundThisMinute = 0;
  int totalWordsFound = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    String jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/word_list.json');
    Map<String, dynamic> wordMap =
        Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
    await _wordService.initializeWords(wordMap.keys.toList());
    _startGame();
  }

  void _startGame() {
    currentLetters = _wordService.generateLetters();
    _startTimer();
    setState(() {
      wordsFoundThisMinute = 0;
      _wordService.completedWords.clear();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          _startGame();
        }
      });
    });
  }

  void _handleSubmit() {
    String word = _controller.text.trim();
    if (word.isNotEmpty && _wordService.isValidWord(word, currentLetters)) {
      setState(() {
        wordsFoundThisMinute++;
        totalWordsFound++;
        _wordService.completedWords.add(word.toUpperCase());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Valid word: $word!'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (word.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid word'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _handleLetterTap(String letter) {
    _controller.text = _controller.text + letter;
    // Move cursor to end
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = (_wordService.completedWords.length /
            _wordService.dictionaryWords.length) *
        100;

    // Split letters into consonants and vowels
    List<String> consonants = currentLetters
        .where((letter) => !_wordService.vowels.contains(letter))
        .toList();
    List<String> vowels = currentLetters
        .where((letter) => _wordService.vowels.contains(letter))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Global Progress: ${_wordService.completedWords.length} / ${_wordService.dictionaryWords.length} words (${progressPercentage.toStringAsFixed(2)}%)',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Time: $_timeRemaining',
                style: const TextStyle(fontSize: 32),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Container(
                height: 150,
                child: HoneycombGrid(
                  consonants: consonants,
                  vowels: vowels,
                  onLetterTap: _handleLetterTap,
                ),
              ),
              const SizedBox(height: 80),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Enter word...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    child: const Text('Submit'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Words Found This Minute: $wordsFoundThisMinute',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              Text(
                'Total Words Found: $totalWordsFound',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    children: _wordService.completedWords
                        .where((word) => word.isNotEmpty)
                        .map((word) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                word,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
