import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TextBrushPage extends StatefulWidget {
  const TextBrushPage({Key? key}) : super(key: key);

  @override
  State<TextBrushPage> createState() => _TextBrushPageState();
}

class _TextBrushPageState extends State<TextBrushPage> {
  final List<Offset> _points = [];
  final ValueNotifier<List<Offset>> _pointsNotifier = ValueNotifier([]);

  String _brushText = "LOVE";
  Color _brushColor = Colors.purple;
  double _fontSize = 24;
  double _spacing = 40;

  @override
  void dispose() {
    _pointsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smooth Text Brush 🎨"),
        backgroundColor: _brushColor,
        actions: [
          IconButton(
            tooltip: 'Pick color',
            icon: const Icon(Icons.color_lens),
            onPressed: _openColorPicker,
          ),
          IconButton(
            tooltip: 'Clear canvas',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _points.clear();
              _pointsNotifier.value = List.from(_points);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Text Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Enter Brush Text or Emoji",
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                _brushText = value.isNotEmpty ? value : "LOVE";
                _pointsNotifier.value = List.from(_points);
              },
            ),
          ),
          // Size Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text("Size"),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 8,
                    max: 96,
                    divisions: 88,
                    label: _fontSize.round().toString(),
                    onChanged: (double v) {
                      _fontSize = v;
                      _pointsNotifier.value = List.from(_points);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Spacing Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text("Spacing"),
                Expanded(
                  child: Slider(
                    value: _spacing,
                    min: 4,
                    max: 200,
                    divisions: 98,
                    label: _spacing.round().toString(),
                    onChanged: (double v) {
                      _spacing = v;
                      _pointsNotifier.value = List.from(_points);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Drawing Area
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                _points.add(details.localPosition);
                _pointsNotifier.value = List.from(_points);
              },
              onPanUpdate: (details) {
                _points.add(details.localPosition);
                _pointsNotifier.value = List.from(_points);
              },
              onPanEnd: (details) {
                // Don’t add Offset.zero
                _pointsNotifier.value = List.from(_points);
              },

              child: ValueListenableBuilder<List<Offset>>(
                valueListenable: _pointsNotifier,
                builder: (context, points, child) {
                  return CustomPaint(
                    painter: SmoothTextBrushPainter(
                      points: points,
                      text: _brushText,
                      color: _brushColor,
                      fontSize: _fontSize,
                      spacing: _spacing,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openColorPicker() {
    Color tempColor = _brushColor;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Pick Brush Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _brushColor,
            onColorChanged: (Color c) => tempColor = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _brushColor = tempColor;
              _pointsNotifier.value = List.from(_points);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class SmoothTextBrushPainter extends CustomPainter {
  SmoothTextBrushPainter({
    required this.points,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.spacing,
  });

  final List<Offset> points;
  final String text;
  final Color color;
  final double fontSize;
  final double spacing;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || text.isEmpty) return;

    // Smooth path
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }

    final pathMetrics = path.computeMetrics();
    double distance = 0;

    for (final metric in pathMetrics) {
      int charIndex = 0;

      while (distance < metric.length) {
        final char = text[charIndex % text.length]; // loop over chars

        // Measure character
        final tp = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final tangent = metric.getTangentForOffset(distance);
        if (tangent == null) break;

        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.rotate(tangent.angle);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();

        // Advance distance
        distance += tp.width + spacing;
        charIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SmoothTextBrushPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.text != text ||
        oldDelegate.color != color ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.spacing != spacing;
  }
}
