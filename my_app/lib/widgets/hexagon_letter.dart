import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;

class HexagonLetter extends StatelessWidget {
  final String letter;
  final double size;

  const HexagonLetter({
    super.key,
    required this.letter,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: HexagonPainter(),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double width = size.width;
    final double height = size.height;
    final double radius = width / 2;

    path.moveTo(width / 2, 0);
    for (int i = 1; i <= 6; i++) {
      double angle = i * 60 * pi / 180;
      path.lineTo(
        width / 2 + radius * cos(angle),
        height / 2 + radius * sin(angle),
      );
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
