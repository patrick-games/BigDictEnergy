import 'package:flutter/material.dart';
import 'hexagon_letter.dart';

class LetterGrid extends StatelessWidget {
  final List<String> letters;

  const LetterGrid({super.key, this.letters = const []});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: maxSize * 0.02,
            runSpacing: maxSize * 0.02,
            children: letters
                .map((letter) => HexagonLetter(
                      letter: letter,
                      size: maxSize / (letters.length > 12 ? 8 : 6),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
