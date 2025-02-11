import 'package:flutter/material.dart';
import 'dart:math' as math;

class WordInput extends StatefulWidget {
  final Function(String) onSubmit;

  const WordInput({super.key, required this.onSubmit});

  @override
  WordInputState createState() => WordInputState();
}

class WordInputState extends State<WordInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitWord() {
    if (_controller.text.isNotEmpty) {
      widget.onSubmit(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter word...',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _submitWord(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _submitWord,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
