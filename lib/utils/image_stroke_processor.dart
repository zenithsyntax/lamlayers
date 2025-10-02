import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

class ImageStrokeProcessor {
  /// Applies a stroke effect using distance transform algorithm (like Photoshop)
  /// Based on the OpenCV distance transform approach from StackOverflow
  ///
  /// This method replicates the Python code:
  /// 1. Creates alpha mask from original image
  /// 2. Applies distance transform to find distances from edges
  /// 3. Creates stroke based on distance thresholds
  /// 4. Composites stroke under original image
  static Future<ui.Image> addStrokeToImage(
    ui.Image originalImage, {
    int strokeWidth = 10,
    ui.Color strokeColor = const ui.Color(0xFF000000), // Black by default
    int threshold = 0,
  }) async {
    // Get original image dimensions
    final int originalWidth = originalImage.width;
    final int originalHeight = originalImage.height;

    // Add padding like in Python code (stroke_size + 50)
    final int padding = strokeWidth + 50;
    final int expandedWidth = originalWidth + (padding * 2);
    final int expandedHeight = originalHeight + (padding * 2);

    // Convert original image to byte data
    final ByteData? originalByteData = await originalImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (originalByteData == null) {
      throw Exception('Failed to convert image to byte data');
    }

    final Uint8List originalPixels = originalByteData.buffer.asUint8List();

    // Step 1: Extract alpha channel and create padded version
    final List<List<int>> alpha = _extractAlphaWithPadding(
      originalPixels,
      originalWidth,
      originalHeight,
      padding,
    );

    // Step 2: Create binary mask (threshold alpha) - equivalent to cv2.threshold
    final List<List<int>> alphaMask = _createBinaryMask(alpha, threshold);

    // Step 3: Apply distance transform - equivalent to cv2.distanceTransform
    final List<List<double>> distanceMap = _distanceTransform(alphaMask);

    // Step 4: Create stroke mask using change_matrix function from Python
    final List<List<double>> strokeMask = _createStrokeMask(
      distanceMap,
      strokeWidth,
    );

    // Step 5: Create stroke image
    final Uint8List strokePixels = _createStrokeImage(
      strokeMask,
      expandedWidth,
      expandedHeight,
      strokeColor,
    );

    // Step 6: Create expanded original image with padding
    final Uint8List expandedOriginal = _createExpandedOriginal(
      originalPixels,
      originalWidth,
      originalHeight,
      expandedWidth,
      expandedHeight,
      padding,
    );

    // Step 7: Alpha composite stroke under original (like Python Image.alpha_composite)
    final Uint8List result = _alphaComposite(
      strokePixels,
      expandedOriginal,
      expandedWidth,
      expandedHeight,
    );

    // Create final image
    return await _createImageFromPixels(result, expandedWidth, expandedHeight);
  }

  /// Extract alpha channel with padding (equivalent to cv2.copyMakeBorder)
  static List<List<int>> _extractAlphaWithPadding(
    Uint8List pixels,
    int width,
    int height,
    int padding,
  ) {
    final List<List<int>> alpha = List.generate(
      height + padding * 2,
      (i) => List.filled(width + padding * 2, 0),
    );

    // Copy alpha values to padded array
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = (y * width + x) * 4;
        alpha[y + padding][x + padding] =
            pixels[pixelIndex + 3]; // Alpha channel
      }
    }

    return alpha;
  }

  /// Create binary mask (equivalent to cv2.threshold)
  static List<List<int>> _createBinaryMask(
    List<List<int>> alpha,
    int threshold,
  ) {
    final int height = alpha.length;
    final int width = alpha[0].length;
    final List<List<int>> mask = List.generate(
      height,
      (i) => List.filled(width, 0),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Threshold and invert (255 - alpha_without_shadow in Python)
        if (alpha[y][x] <= threshold) {
          mask[y][x] = 255; // Background (where we want stroke)
        } else {
          mask[y][x] = 0; // Foreground (original image)
        }
      }
    }

    return mask;
  }

  /// Distance transform (simplified version of cv2.distanceTransform)
  static List<List<double>> _distanceTransform(List<List<int>> binaryMask) {
    final int height = binaryMask.length;
    final int width = binaryMask[0].length;
    final List<List<double>> distances = List.generate(
      height,
      (i) => List.filled(width, double.infinity),
    );

    // Initialize distances for foreground pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (binaryMask[y][x] == 0) {
          // Foreground pixel
          distances[y][x] = 0.0;
        }
      }
    }

    // Forward pass
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        if (distances[y][x] != 0) {
          double minDist = distances[y][x];

          // Check 8-connected neighbors
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dy == 0 && dx == 0) continue;

              final double neighborDist = distances[y + dy][x + dx];
              final double edgeCost = (dx == 0 || dy == 0) ? 1.0 : math.sqrt(2);
              minDist = math.min(minDist, neighborDist + edgeCost);
            }
          }

          distances[y][x] = minDist;
        }
      }
    }

    // Backward pass
    for (int y = height - 2; y > 0; y--) {
      for (int x = width - 2; x > 0; x--) {
        if (distances[y][x] != 0) {
          double minDist = distances[y][x];

          // Check 8-connected neighbors
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dy == 0 && dx == 0) continue;

              final double neighborDist = distances[y + dy][x + dx];
              final double edgeCost = (dx == 0 || dy == 0) ? 1.0 : math.sqrt(2);
              minDist = math.min(minDist, neighborDist + edgeCost);
            }
          }

          distances[y][x] = minDist;
        }
      }
    }

    return distances;
  }

  /// Create stroke mask using change_matrix function from Python
  static List<List<double>> _createStrokeMask(
    List<List<double>> distanceMap,
    int strokeSize,
  ) {
    final int height = distanceMap.length;
    final int width = distanceMap[0].length;
    final List<List<double>> strokeMask = List.generate(
      height,
      (i) => List.filled(width, 0.0),
    );

    final double strokeSizeFloat = strokeSize - 1.0;
    final double checkSize = strokeSize.toDouble();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double dist = distanceMap[y][x];

        if (dist > checkSize) {
          strokeMask[y][x] = 0.0; // No stroke
        } else if (dist > strokeSizeFloat && dist <= checkSize) {
          // Border area with smooth falloff
          strokeMask[y][x] = 1.0 - (dist - strokeSizeFloat);
        } else {
          strokeMask[y][x] = 1.0; // Full stroke
        }
      }
    }

    return strokeMask;
  }

  /// Create stroke image from stroke mask
  static Uint8List _createStrokeImage(
    List<List<double>> strokeMask,
    int width,
    int height,
    ui.Color strokeColor,
  ) {
    final Uint8List strokePixels = Uint8List(width * height * 4);

    final int r = strokeColor.red;
    final int g = strokeColor.green;
    final int b = strokeColor.blue;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = (y * width + x) * 4;
        final double alpha = strokeMask[y][x];
        final int alphaInt = (alpha * 255).round().clamp(0, 255);

        strokePixels[pixelIndex] = r; // R
        strokePixels[pixelIndex + 1] = g; // G
        strokePixels[pixelIndex + 2] = b; // B
        strokePixels[pixelIndex + 3] = alphaInt; // A
      }
    }

    return strokePixels;
  }

  /// Create expanded original image with padding
  static Uint8List _createExpandedOriginal(
    Uint8List originalPixels,
    int originalWidth,
    int originalHeight,
    int expandedWidth,
    int expandedHeight,
    int padding,
  ) {
    final Uint8List expandedPixels = Uint8List(
      expandedWidth * expandedHeight * 4,
    );

    // Fill with transparent pixels
    expandedPixels.fillRange(0, expandedPixels.length, 0);

    // Copy original image to center
    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        final int originalIndex = (y * originalWidth + x) * 4;
        final int expandedIndex =
            ((y + padding) * expandedWidth + (x + padding)) * 4;

        expandedPixels[expandedIndex] = originalPixels[originalIndex]; // R
        expandedPixels[expandedIndex + 1] =
            originalPixels[originalIndex + 1]; // G
        expandedPixels[expandedIndex + 2] =
            originalPixels[originalIndex + 2]; // B
        expandedPixels[expandedIndex + 3] =
            originalPixels[originalIndex + 3]; // A
      }
    }

    return expandedPixels;
  }

  /// Alpha composite two images (equivalent to Image.alpha_composite in Python)
  static Uint8List _alphaComposite(
    Uint8List bottom,
    Uint8List top,
    int width,
    int height,
  ) {
    final Uint8List result = Uint8List(width * height * 4);

    for (int i = 0; i < width * height; i++) {
      final int pixelIndex = i * 4;

      final double topA = top[pixelIndex + 3] / 255.0;
      final double bottomA = bottom[pixelIndex + 3] / 255.0;

      final double outA = topA + bottomA * (1.0 - topA);

      if (outA > 0) {
        final double topR = top[pixelIndex] / 255.0;
        final double topG = top[pixelIndex + 1] / 255.0;
        final double topB = top[pixelIndex + 2] / 255.0;

        final double bottomR = bottom[pixelIndex] / 255.0;
        final double bottomG = bottom[pixelIndex + 1] / 255.0;
        final double bottomB = bottom[pixelIndex + 2] / 255.0;

        final double outR =
            (topR * topA + bottomR * bottomA * (1.0 - topA)) / outA;
        final double outG =
            (topG * topA + bottomG * bottomA * (1.0 - topA)) / outA;
        final double outB =
            (topB * topA + bottomB * bottomA * (1.0 - topA)) / outA;

        result[pixelIndex] = (outR * 255).round().clamp(0, 255);
        result[pixelIndex + 1] = (outG * 255).round().clamp(0, 255);
        result[pixelIndex + 2] = (outB * 255).round().clamp(0, 255);
        result[pixelIndex + 3] = (outA * 255).round().clamp(0, 255);
      } else {
        result[pixelIndex] = 0;
        result[pixelIndex + 1] = 0;
        result[pixelIndex + 2] = 0;
        result[pixelIndex + 3] = 0;
      }
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

  /// Convenience method to apply stroke to an image from bytes
  static Future<ui.Image> addStrokeToImageFromBytes(
    Uint8List imageBytes, {
    int strokeWidth = 10,
    ui.Color strokeColor = const ui.Color(0xFF000000),
    int threshold = 0,
  }) async {
    // Load image from bytes
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    return addStrokeToImage(
      originalImage,
      strokeWidth: strokeWidth,
      strokeColor: strokeColor,
      threshold: threshold,
    );
  }

  /// Convenience method to apply stroke to an image file
  static Future<ui.Image> addStrokeToImageFile(
    File imageFile, {
    int strokeWidth = 10,
    ui.Color strokeColor = const ui.Color(0xFF000000),
    int threshold = 0,
  }) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    return addStrokeToImageFromBytes(
      imageBytes,
      strokeWidth: strokeWidth,
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
