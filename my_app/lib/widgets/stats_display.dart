import 'package:flutter/material.dart';

class StatsDisplay extends StatelessWidget {
  final int wordsFoundThisMinute;
  final int totalWordsFound;

  const StatsDisplay({
    super.key,
    required this.wordsFoundThisMinute,
    required this.totalWordsFound,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('This Minute'),
              Text(
                '$wordsFoundThisMinute',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            children: [
              const Text('Total Words'),
              Text(
                '$totalWordsFound',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
