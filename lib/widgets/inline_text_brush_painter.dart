import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InlineSmoothTextBrushPainter extends CustomPainter {
  InlineSmoothTextBrushPainter({
    required this.points,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.spacing,
    this.fontFamily,
    this.isBold = false,
    this.angleOffsetRad = 0.0,
  });

  final List<Offset> points;
  final String text;
  final Color color;
  final double fontSize;
  final double spacing;
  final String? fontFamily;
  final bool isBold;
  final double angleOffsetRad;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || text.isEmpty) return;

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final Offset mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }

    final Iterable<ui.PathMetric> metrics = path.computeMetrics();
    for (final ui.PathMetric metric in metrics) {
      double distance = 0.0;
      int charIndex = 0;
      while (distance < metric.length) {
        final String char = text[charIndex % text.length];
        final TextStyle baseStyle = TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
        );
        final TextStyle effectiveStyle =
            fontFamily == null || fontFamily!.isEmpty
            ? baseStyle
            : GoogleFonts.getFont(fontFamily!, textStyle: baseStyle);
        final TextPainter tp = TextPainter(
          text: TextSpan(text: char, style: effectiveStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final ui.Tangent? tangent = metric.getTangentForOffset(distance);
        if (tangent == null) break;

        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.rotate(tangent.angle + angleOffsetRad);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();

        distance += tp.width + spacing;
        charIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant InlineSmoothTextBrushPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.text != text ||
        oldDelegate.color != color ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.spacing != spacing;
  }
}
