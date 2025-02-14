import 'package:flutter/material.dart';

class TappableWordInput extends StatefulWidget {
  final List<String> letters;
  final Function(String) onSubmitWord;
  final String label;

  const TappableWordInput({
    Key? key,
    required this.letters,
    required this.onSubmitWord,
    required this.label,
  }) : super(key: key);

  @override
  TappableWordInputState createState() => TappableWordInputState();
}

class TappableWordInputState extends State<TappableWordInput>
    with SingleTickerProviderStateMixin {
  String currentWord = '';
  late AnimationController _cursorController;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        setState(() {
          _showCursor = status == AnimationStatus.completed;
        });
        if (status == AnimationStatus.completed) {
          _cursorController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _cursorController.forward();
        }
      });
    _cursorController.forward();
  }

  void addLetter(String letter) {
    setState(() {
      currentWord += letter;
    });
  }

  void _handleDelete() {
    if (currentWord.isNotEmpty) {
      setState(() {
        currentWord = currentWord.substring(0, currentWord.length - 1);
      });
    }
  }

  void _handleSubmit() {
    if (currentWord.isNotEmpty) {
      widget.onSubmitWord(currentWord);
      setState(() {
        currentWord = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add the label
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
        // Word display area with cursor
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentWord,
                  style: const TextStyle(fontSize: 24),
                ),
                if (_showCursor)
                  const Text(
                    '|',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _handleDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(120, 40),
              ),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(120, 40),
              ),
              child: const Text('Enter'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }
}
