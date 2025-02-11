import 'package:flutter/material.dart';
import 'package:my_app/models/game_state.dart';

class GameDisplay extends StatefulWidget {
  final Stream<GameState> gameState;
  final Function(String) onSubmitWord;
  final VoidCallback onResetGame;

  const GameDisplay({
    Key? key,
    required this.gameState,
    required this.onSubmitWord,
    required this.onResetGame,
  }) : super(key: key);

  @override
  _GameDisplayState createState() => _GameDisplayState();
}

class _GameDisplayState extends State<GameDisplay> {
  final TextEditingController _wordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameState>(
      stream: widget.gameState,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final state = snapshot.data!;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Global progress at top
                Text(
                    '${state.totalWordsFound} / ${state.dictionarySize} words (${state.completionPercentage.toStringAsFixed(4)}%)'),
                const SizedBox(height: 20),

                // Timer
                Text('Time: ${state.timeRemaining}'),
                const SizedBox(height: 20),

                // Letters display with hexagonal shape
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: state.currentLetters.map((letter) {
                    bool isVowel = 'AEIOU'.contains(letter);
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isVowel ? Colors.amber : Colors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Word input
                TextField(
                  controller: _wordController,
                  decoration: const InputDecoration(
                    labelText: 'Enter word',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (word) {
                    widget.onSubmitWord(word);
                    _wordController.clear();
                  },
                ),
                const SizedBox(height: 20),

                // Words found counters
                Text('Words found this round: ${state.wordsFoundThisMinute}'),
                Text(
                    'Total words you found this session: ${state.sessionWordsFound}'),
                const SizedBox(height: 20),

                // List of found words (only from current round)
                Expanded(
                  child: ListView(
                    children: state.completedWords
                        .map((wordEntry) => ListTile(
                              title: Text(wordEntry.word),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }
}
