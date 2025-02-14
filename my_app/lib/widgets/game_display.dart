import 'package:flutter/material.dart';
import 'package:my_app/models/game_state.dart';
import 'package:my_app/widgets/tappable_word_input.dart';
import 'package:my_app/widgets/app_drawer.dart';

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
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<TappableWordInputState> _tappableInputKey =
      GlobalKey<TappableWordInputState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _handleWordSubmit(String word) {
    widget.onSubmitWord(word).then((_) {
      _wordController.clear();
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Word found: $word'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      String message;
      if (error.toString().contains('already found this round')) {
        message = 'This word has already been found this round';
      } else if (error.toString().contains('found in a previous round')) {
        message = 'This word was found in a previous round';
      } else if (error.toString().contains('cannot be made')) {
        message = 'Word cannot be made with current letters';
      } else {
        message = 'Invalid word';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );

      _wordController.clear();
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameState>(
      stream: widget.gameState,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                children: const [
                  Text(
                    'Big Dict Energy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Together, lets find every word in the dictionary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
            drawer: const AppDrawer(),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skeleton UI for progress
                  Container(
                    width: double.infinity,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Skeleton UI for timer
                  Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Skeleton UI for honeycomb grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 15,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Skeleton UI for word input
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final state = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: const [
                Text(
                  'Big Dict Energy',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Together, lets find every word in the dictionary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          drawer: const AppDrawer(),
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Move all the fixed content into a Column
                    Column(
                      children: [
                        // Global progress
                        Text(
                            '${state.totalWordsFound} / ${state.dictionarySize} words (${state.completionPercentage.toStringAsFixed(4)}%)'),
                        const SizedBox(height: 20),

                        // Timer
                        Text(
                          'Time: ${state.timeRemaining}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: state.timeRemaining <= 5
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Letters display
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: state.currentLetters.map((letter) {
                                bool isVowel = 'AEIOU'.contains(letter);
                                return GestureDetector(
                                  onTap: () {
                                    if (constraints.maxWidth < 600) {
                                      _tappableInputKey.currentState
                                          ?.addLetter(letter);
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isVowel
                                          ? Colors.amber
                                          : Colors.lightBlue,
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
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Word input
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Use tappable input for screens narrower than 600px
                            if (constraints.maxWidth < 600) {
                              return Column(
                                children: [
                                  const SizedBox(height: 20),
                                  TappableWordInput(
                                    letters: state.currentLetters,
                                    onSubmitWord: _handleWordSubmit,
                                    key: _tappableInputKey,
                                    label: 'Enter word',
                                  ),
                                ],
                              );
                            } else {
                              // Original text field for wider screens
                              return Column(
                                children: [
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _wordController,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Enter word',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: _handleWordSubmit,
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                    // Words found section with fixed height
                    Container(
                      height: 300, // Fixed height for the words list
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Words Found This Round',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
