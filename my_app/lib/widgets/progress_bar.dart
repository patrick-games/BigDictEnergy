import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double percentage;

  const ProgressBar({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(2)}% Complete',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
