import 'package:flutter/material.dart';
import '../services/word_service.dart';
import 'dart:convert';
import 'dart:async';
import '../widgets/honeycomb_grid.dart';
import '../controllers/game_controller.dart';
import '../models/game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final WordService _wordService = WordService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late GameController gameController;
  bool isInitialized = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      print("Initializing game controller...");
      gameController = GameController(WordService());
      await gameController.startGame();
      print("Game controller initialized");
      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      print("Error initializing game: $e");
      setState(() {
        error = e.toString();
      });
    }
  }

  void _handleSubmit() async {
    String word = _controller.text.trim().toUpperCase();
    if (word.isNotEmpty) {
      try {
        await gameController.submitWord(word);
        _controller.clear();
        _focusNode.requestFocus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid word'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
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
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      );
    }

    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading game state...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<GameState>(
          stream: gameController.gameState,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading game state...'),
                  ],
                ),
              );
            }

            GameState gameState = snapshot.data!;
            double progressPercentage = (gameState.completionPercentage);

            // Split letters into consonants and vowels
            List<String> consonants = gameState.currentLetters
                .where((letter) => !_wordService.vowels.contains(letter))
                .toList();
            List<String> vowels = gameState.currentLetters
                .where((letter) => _wordService.vowels.contains(letter))
                .toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Global Progress: ${_wordService.completedWords.length} / ${_wordService.dictionaryWords.length} words (${progressPercentage.toStringAsFixed(4)}%)',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Time: ${gameState.timeRemaining}',
                    style: const TextStyle(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
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
                    'Words Found This Minute: ${gameState.wordsFoundThisMinute}',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Total Words Found: ${gameState.totalWordsFound}',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
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
            );
          },
        ),
      ),
    );
  }
}
