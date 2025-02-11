import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;

class HoneycombGrid extends StatelessWidget {
  final List<String> consonants;
  final List<String> vowels;
  final Function(String) onLetterTap;

  const HoneycombGrid({
    super.key,
    required this.consonants,
    required this.vowels,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    List<String> allLetters = [...vowels, ...consonants];
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth;
        double cellSize =
            maxWidth / 12; // Changed from 8 to 12 for even smaller cells

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: cellSize * 0.15, // Increased spacing slightly
            runSpacing: cellSize * 0.2, // Increased row spacing
            children: allLetters.map((letter) {
              return HoneycombCell(
                letter: letter,
                size: cellSize,
                isVowel: vowels.contains(letter),
                onTap: () => onLetterTap(letter),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class HoneycombCell extends StatelessWidget {
  final String letter;
  final double size;
  final bool isVowel;
  final VoidCallback onTap;

  const HoneycombCell({
    super.key,
    required this.letter,
    required this.size,
    required this.isVowel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size * 0.866, // Height of a regular hexagon
        child: CustomPaint(
          painter: HexagonPainter(
            color: isVowel ? Colors.amber.shade200 : Colors.blue.shade100,
            borderColor: isVowel ? Colors.amber.shade400 : Colors.blue.shade300,
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  HexagonPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double radius = width / 2;

    // Start at the rightmost point
    path.moveTo(centerX + radius, centerY);

    // Draw the hexagon
    for (int i = 1; i <= 6; i++) {
      double angle = i * pi / 3;
      path.lineTo(
        centerX + radius * cos(angle),
        centerY + radius * sin(angle),
      );
    }
    path.close();

    // Draw fill and border
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(HexagonPainter oldDelegate) =>
      color != oldDelegate.color || borderColor != oldDelegate.borderColor;
}
