import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;

class ImageStrokeProcessorV2 {
  /// Applies stroke effect using distance transform method (like Photoshop)
  /// Based on the Python OpenCV implementation you provided
  static Future<ui.Image> addStrokeToImage(
    ui.Image originalImage, {
    int strokeSize = 10,
    ui.Color strokeColor = const ui.Color(0xFF000000),
    int threshold = 0,
  }) async {
    // Get original image dimensions
    final int originalWidth = originalImage.width;
    final int originalHeight = originalImage.height;

    // Convert original image to byte data
    final ByteData? originalByteData = await originalImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (originalByteData == null) {
      throw Exception('Failed to convert image to byte data');
    }

    final Uint8List originalPixels = originalByteData.buffer.asUint8List();

    // Add padding (like cv2.copyMakeBorder in Python)
    final int padding = strokeSize + 50;
    final int paddedWidth = originalWidth + (padding * 2);
    final int paddedHeight = originalHeight + (padding * 2);

    // Create padded image with border
    final Uint8List paddedPixels = Uint8List(paddedWidth * paddedHeight * 4);
    paddedPixels.fillRange(0, paddedPixels.length, 0); // Fill with transparent

    // Copy original image to center of padded image
    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        final int originalIndex = (y * originalWidth + x) * 4;
        final int paddedIndex =
            ((y + padding) * paddedWidth + (x + padding)) * 4;

        // Copy RGBA
        paddedPixels[paddedIndex] = originalPixels[originalIndex]; // R
        paddedPixels[paddedIndex + 1] = originalPixels[originalIndex + 1]; // G
        paddedPixels[paddedIndex + 2] = originalPixels[originalIndex + 2]; // B
        paddedPixels[paddedIndex + 3] = originalPixels[originalIndex + 3]; // A
      }
    }

    // Extract alpha channel and apply threshold
    final List<List<int>> alpha = List.generate(
      paddedHeight,
      (i) => List.generate(paddedWidth, (j) => 0),
    );

    for (int y = 0; y < paddedHeight; y++) {
      for (int x = 0; x < paddedWidth; x++) {
        final int index = (y * paddedWidth + x) * 4;
        final int alphaValue = paddedPixels[index + 3];

        // Apply threshold (like cv2.threshold in Python)
        alpha[y][x] = alphaValue > threshold ? 255 : 0;
      }
    }

    // Invert alpha for distance transform (255 - alpha_without_shadow)
    final List<List<int>> invertedAlpha = List.generate(
      paddedHeight,
      (i) => List.generate(paddedWidth, (j) => 255 - alpha[i][j]),
    );

    // Compute distance transform (simplified version of cv2.distanceTransform)
    final List<List<double>> distanceMap = _computeDistanceTransform(
      invertedAlpha,
    );

    // Apply stroke transformation (change_matrix function from Python)
    final List<List<double>> strokeMask = _changeMatrix(
      distanceMap,
      strokeSize,
    );

    // Create stroke layer
    final Uint8List strokePixels = Uint8List(paddedWidth * paddedHeight * 4);

    for (int y = 0; y < paddedHeight; y++) {
      for (int x = 0; x < paddedWidth; x++) {
        final int index = (y * paddedWidth + x) * 4;
        final double strokeAlpha = strokeMask[y][x];

        if (strokeAlpha > 0) {
          strokePixels[index] = strokeColor.red; // R
          strokePixels[index + 1] = strokeColor.green; // G
          strokePixels[index + 2] = strokeColor.blue; // B
          strokePixels[index + 3] = (strokeAlpha * 255).round().clamp(
            0,
            255,
          ); // A
        } else {
          strokePixels[index] = 0;
          strokePixels[index + 1] = 0;
          strokePixels[index + 2] = 0;
          strokePixels[index + 3] = 0;
        }
      }
    }

    // Alpha composite stroke with original image (like Image.alpha_composite in Python)
    final Uint8List resultPixels = _alphaComposite(
      strokePixels,
      paddedPixels,
      paddedWidth,
      paddedHeight,
    );

    // Create final image
    return await _createImageFromPixels(
      resultPixels,
      paddedWidth,
      paddedHeight,
    );
  }

  /// Simplified distance transform implementation
  /// This approximates cv2.distanceTransform(alpha_without_shadow, cv2.DIST_L2, cv2.DIST_MASK_3)
  static List<List<double>> _computeDistanceTransform(
    List<List<int>> binaryImage,
  ) {
    final int height = binaryImage.length;
    final int width = binaryImage[0].length;

    final List<List<double>> distances = List.generate(
      height,
      (i) => List.generate(width, (j) => double.infinity),
    );

    // Initialize distances for foreground pixels (where binaryImage[y][x] == 0)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (binaryImage[y][x] == 0) {
          distances[y][x] = 0.0;
        }
      }
    }

    // Forward pass
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        if (binaryImage[y][x] != 0) {
          double minDist = distances[y][x];

          // Check 8-connected neighbors
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dy == 0 && dx == 0) continue;

              final double neighborDist = distances[y + dy][x + dx];
              final double euclideanDist = math.sqrt(dx * dx + dy * dy);
              final double totalDist = neighborDist + euclideanDist;

              if (totalDist < minDist) {
                minDist = totalDist;
              }
            }
          }

          distances[y][x] = minDist;
        }
      }
    }

    // Backward pass
    for (int y = height - 2; y > 0; y--) {
      for (int x = width - 2; x > 0; x--) {
        if (binaryImage[y][x] != 0) {
          double minDist = distances[y][x];

          // Check 8-connected neighbors
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dy == 0 && dx == 0) continue;

              final double neighborDist = distances[y + dy][x + dx];
              final double euclideanDist = math.sqrt(dx * dx + dy * dy);
              final double totalDist = neighborDist + euclideanDist;

              if (totalDist < minDist) {
                minDist = totalDist;
              }
            }
          }

          distances[y][x] = minDist;
        }
      }
    }

    return distances;
  }

  /// Implements the change_matrix function from Python
  static List<List<double>> _changeMatrix(
    List<List<double>> inputMat,
    int strokeSize,
  ) {
    final int height = inputMat.length;
    final int width = inputMat[0].length;
    final double strokeSizeDouble = (strokeSize - 1).toDouble();
    final double checkSize = strokeSize.toDouble();

    final List<List<double>> mat = List.generate(
      height,
      (i) => List.generate(width, (j) => 1.0),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double dist = inputMat[y][x];

        if (dist > checkSize) {
          mat[y][x] = 0.0;
        } else if (dist > strokeSizeDouble && dist <= checkSize) {
          // Border case: gradual fade
          mat[y][x] = 1.0 - (dist - strokeSizeDouble);
        }
        // else: mat[y][x] remains 1.0 (inside stroke area)
      }
    }

    return mat;
  }

  /// Alpha composite two RGBA images (like Image.alpha_composite in Python)
  static Uint8List _alphaComposite(
    Uint8List bottom,
    Uint8List top,
    int width,
    int height,
  ) {
    final Uint8List result = Uint8List(width * height * 4);

    for (int i = 0; i < width * height; i++) {
      final int index = i * 4;

      // Get bottom layer (stroke)
      final double bottomR = bottom[index] / 255.0;
      final double bottomG = bottom[index + 1] / 255.0;
      final double bottomB = bottom[index + 2] / 255.0;
      final double bottomA = bottom[index + 3] / 255.0;

      // Get top layer (original image)
      final double topR = top[index] / 255.0;
      final double topG = top[index + 1] / 255.0;
      final double topB = top[index + 2] / 255.0;
      final double topA = top[index + 3] / 255.0;

      // Alpha compositing formula
      final double outA = topA + bottomA * (1.0 - topA);

      double outR, outG, outB;
      if (outA == 0) {
        outR = outG = outB = 0;
      } else {
        outR = (topR * topA + bottomR * bottomA * (1.0 - topA)) / outA;
        outG = (topG * topA + bottomG * bottomA * (1.0 - topA)) / outA;
        outB = (topB * topA + bottomB * bottomA * (1.0 - topA)) / outA;
      }

      // Store result
      result[index] = (outR * 255).round().clamp(0, 255);
      result[index + 1] = (outG * 255).round().clamp(0, 255);
      result[index + 2] = (outB * 255).round().clamp(0, 255);
      result[index + 3] = (outA * 255).round().clamp(0, 255);
    }

    return result;
  }

  /// Creates a ui.Image from RGBA pixel array
  static Future<ui.Image> _createImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  /// Convenience method to apply stroke to image from bytes
  static Future<ui.Image> addStrokeToImageFromBytes(
    Uint8List imageBytes, {
    int strokeSize = 10,
    ui.Color strokeColor = const ui.Color(0xFF000000),
    int threshold = 0,
  }) async {
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    return addStrokeToImage(
      originalImage,
      strokeSize: strokeSize,
      strokeColor: strokeColor,
      threshold: threshold,
    );
  }

  /// Convert ui.Image back to bytes for saving or further processing
  static Future<Uint8List> imageToBytes(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}
