import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lamlayers/utils/image_stroke_processor.dart';

/// Example demonstrating how to use the ImageStrokeProcessor
/// This replicates the Python stroke method functionality in Flutter
class StrokeExample extends StatefulWidget {
  const StrokeExample({Key? key}) : super(key: key);

  @override
  State<StrokeExample> createState() => _StrokeExampleState();
}

class _StrokeExampleState extends State<StrokeExample> {
  ui.Image? originalImage;
  ui.Image? strokedImage;
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Stroke Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Image Stroke Effect Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This demonstrates the same stroke method as your Python code:\n'
              '• Loops through all pixels\n'
              '• For non-transparent pixels (alpha != 0)\n'
              '• Draws stroke in 8 directions\n'
              '• Repeats for stroke width (default: 30)',
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),

            // Display images side by side
            Expanded(
              child: Row(
                children: [
                  // Original image
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Original Image',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: originalImage != null
                                ? CustomPaint(
                                    painter: ImagePainter(originalImage!),
                                    size: Size.infinite,
                                  )
                                : const Center(child: Text('No image loaded')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Stroked image
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'With Stroke Effect',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: isProcessing
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : strokedImage != null
                                ? CustomPaint(
                                    painter: ImagePainter(strokedImage!),
                                    size: Size.infinite,
                                  )
                                : const Center(
                                    child: Text('Apply stroke to see result'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Control buttons
            Wrap(
              spacing: 16,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadSampleImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Load Sample Image'),
                ),
                ElevatedButton.icon(
                  onPressed: originalImage != null && !isProcessing
                      ? () => _applyStroke(strokeWidth: 10)
                      : null,
                  icon: const Icon(Icons.border_outer),
                  label: const Text('Thin Stroke (10px)'),
                ),
                ElevatedButton.icon(
                  onPressed: originalImage != null && !isProcessing
                      ? () => _applyStroke(strokeWidth: 30)
                      : null,
                  icon: const Icon(Icons.border_outer),
                  label: const Text('Medium Stroke (30px)'),
                ),
                ElevatedButton.icon(
                  onPressed: originalImage != null && !isProcessing
                      ? () => _applyStroke(strokeWidth: 50)
                      : null,
                  icon: const Icon(Icons.border_outer),
                  label: const Text('Thick Stroke (50px)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Load a sample image for demonstration
  Future<void> _loadSampleImage() async {
    // For this example, we'll create a simple test image
    // In a real app, you'd load from assets or file picker
    final ui.Image testImage = await _createTestImage();
    setState(() {
      originalImage = testImage;
      strokedImage = null;
    });
  }

  /// Apply stroke effect with specified width
  Future<void> _applyStroke({int strokeWidth = 30}) async {
    if (originalImage == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final ui.Image result = await ImageStrokeProcessor.addStrokeToImage(
        originalImage!,
        strokeWidth: strokeWidth,
        strokeColor: const ui.Color(0xFF000000), // Black stroke
      );

      setState(() {
        strokedImage = result;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error applying stroke: $e')));
    }
  }

  /// Create a test image with transparency for demonstration
  Future<ui.Image> _createTestImage() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    // Draw a simple shape with transparency
    final ui.Paint paint = ui.Paint()
      ..color = Colors.blue
      ..style = ui.PaintingStyle.fill;

    // Draw a circle
    canvas.drawCircle(const ui.Offset(100, 100), 50, paint);

    // Draw some text
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 24),
    );
    builder.pushStyle(ui.TextStyle(color: Colors.red));
    builder.addText('TEST');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 200));
    canvas.drawParagraph(paragraph, const ui.Offset(50, 170));

    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(200, 250);
  }
}

/// Custom painter to display ui.Image
class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final ui.Rect srcRect = ui.Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final ui.Rect dstRect = ui.Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, ui.Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
