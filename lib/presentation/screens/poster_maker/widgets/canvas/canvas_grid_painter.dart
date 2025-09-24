import 'package:flutter/material.dart';

class CanvasGridPainter extends CustomPainter {
  final bool showGrid;
  final double gridSize;

  CanvasGridPainter({required this.showGrid, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;

    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is CanvasGridPainter &&
        (oldDelegate.showGrid != showGrid || oldDelegate.gridSize != gridSize);
  }
}


