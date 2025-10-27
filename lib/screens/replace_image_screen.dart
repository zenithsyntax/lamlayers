import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Screen for replacing and adjusting image within a fixed-size container.
/// Supports pinch-to-zoom, drag-to-move, and various fit modes.
class ReplaceImageScreen extends StatefulWidget {
  final String? currentImagePath;
  final double imageWidth;
  final double imageHeight;
  final Function(String newImagePath) onImageSelected;

  const ReplaceImageScreen({
    Key? key,
    this.currentImagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.onImageSelected,
  }) : super(key: key);

  @override
  State<ReplaceImageScreen> createState() => _ReplaceImageScreenState();
}

class _ReplaceImageScreenState extends State<ReplaceImageScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ScreenshotController _screenshotController = ScreenshotController();

  // Current image path (local state)
  String? _currentImagePath;

  // Image transformation state
  BoxFit _selectedFit = BoxFit.cover;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _previousScale = 1.0;

  bool get _hasChanges => _scale != 1.0 || _offset != Offset.zero;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.currentImagePath;
  }

  @override
  void didUpdateWidget(ReplaceImageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentImagePath != oldWidget.currentImagePath) {
      _currentImagePath = widget.currentImagePath;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (picked != null && mounted) {
        setState(() {
          _currentImagePath = picked.path;
        });
        widget.onImageSelected(picked.path);
        _resetTransformations(); // Reset transformations for new image
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to pick image. Please try again.');
      }
    }
  }

  void _resetTransformations() {
    setState(() {
      _offset = Offset.zero;
      _scale = 1.0;
      _previousScale = 1.0;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _captureAndCropImage() async {
    setState(() => _isCapturing = true);
    try {
      // Wait a frame to ensure the border is hidden
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return null;

      // Capture the screenshot
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes == null) {
        _showErrorSnackBar('Failed to capture image');
        return null;
      }

      // Load the image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        _showErrorSnackBar('Failed to process image');
        return null;
      }

      // Calculate the actual size of the container on screen
      final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final int croppedWidth = (widget.imageWidth * devicePixelRatio).toInt();
      final int croppedHeight = (widget.imageHeight * devicePixelRatio).toInt();

      // Crop the image to the container size (center crop)
      img.Image croppedImage;
      if (originalImage.width >= croppedWidth &&
          originalImage.height >= croppedHeight) {
        final int startX = (originalImage.width - croppedWidth) ~/ 2;
        final int startY = (originalImage.height - croppedHeight) ~/ 2;
        croppedImage = img.copyCrop(
          originalImage,
          x: startX,
          y: startY,
          width: croppedWidth,
          height: croppedHeight,
        );
      } else {
        // If the captured image is smaller, resize it to match the container size
        croppedImage = img.copyResize(
          originalImage,
          width: croppedWidth,
          height: croppedHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Save the cropped image
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'cropped_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${tempDir.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(img.encodePng(croppedImage));

      return filePath;
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to process image: $e');
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _handleDone() async {
    if (!mounted) return;

    final hasImage =
        _currentImagePath != null && File(_currentImagePath!).existsSync();

    if (hasImage) {
      // Always capture and crop the image to exact container size
      final String? croppedPath = await _captureAndCropImage();

      if (croppedPath != null && mounted) {
        // Return the cropped image path
        Navigator.pop(context, croppedPath);
      } else if (mounted) {
        // If cropping fails, just return the original
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        _currentImagePath != null && File(_currentImagePath!).existsSync();

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Replace Image',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (hasImage) ...[
            // Reset button
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _hasChanges ? _resetTransformations : null,
              tooltip: 'Reset transformations',
            ),
          ],
          // Done button
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Center(
              child: TextButton(
                onPressed: _handleDone,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageContainer(hasImage),
                SizedBox(height: 24.h),
                if (hasImage) ...[
                  _buildReplaceImageButton(),
                  SizedBox(height: 16.h),
                ],
                _buildInstructions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer(bool hasImage) {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: widget.imageWidth,
        height: widget.imageHeight,
        decoration: BoxDecoration(
          border: _isCapturing
              ? null
              : Border.all(color: Colors.white, width: 3),
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasImage) _buildImageWithGestures(),
            if (!hasImage) _buildAddImageButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithGestures() {
    return GestureDetector(
      onScaleStart: (details) {
        _previousScale = _scale;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_previousScale * details.scale).clamp(0.5, 3.0);
          _offset += details.focalPointDelta;
        });
      },
      onScaleEnd: (_) {
        _previousScale = 1.0;
      },
      child: ClipRect(
        child: Transform.translate(
          offset: _offset,
          child: Transform.scale(
            scale: _scale,
            child: Image.file(
              File(_currentImagePath!),
              fit: _selectedFit,
              width: widget.imageWidth,
              height: widget.imageHeight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickImage,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 36.sp,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Add Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Tap to browse gallery',
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplaceImageButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _pickImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
        ),
        icon: Icon(
          Icons.photo_library_outlined,
          color: const Color(0xFF6366F1),
          size: 20.sp,
        ),
        label: Text(
          'Replace Image',
          style: TextStyle(
            color: const Color(0xFF6366F1),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: Colors.white70, size: 16.sp),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              'Pinch to zoom • Drag to move',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
