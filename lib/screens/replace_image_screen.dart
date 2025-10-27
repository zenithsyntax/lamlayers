import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Professional screen for replacing and adjusting images with clean black & white design.
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

class _ReplaceImageScreenState extends State<ReplaceImageScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  final ScreenshotController _screenshotController = ScreenshotController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  String? _currentImagePath;
  BoxFit _selectedFit = BoxFit.cover;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _previousScale = 1.0;
  bool _isCapturing = false;
  bool _isProcessing = false;
  bool _hasTransparency = false;

  bool get _hasChanges => _scale != 1.0 || _offset != Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.currentImagePath;

    // Check initial image for transparency
    if (_currentImagePath != null) {
      _checkImageTransparency(_currentImagePath!).then((hasTransparency) {
        if (mounted) {
          setState(() {
            _hasTransparency = hasTransparency;
          });
        }
      });
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
        // Check if image has transparency
        final bool hasAlpha = await _checkImageTransparency(picked.path);

        setState(() {
          _currentImagePath = picked.path;
          _hasTransparency = hasAlpha;
        });
        widget.onImageSelected(picked.path);
        _resetTransformations();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to pick image', isError: true);
      }
    }
  }

  Future<bool> _checkImageTransparency(String imagePath) async {
    try {
      // Simple check: if file is PNG, assume it might have transparency
      // More thorough checks would require pixel-level analysis
      final String lowerPath = imagePath.toLowerCase();
      if (!lowerPath.endsWith('.png')) {
        return false;
      }

      final File imageFile = File(imagePath);
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(bytes);

      // If decoded image has 4 channels (RGBA), it supports transparency
      // For simplicity, we'll return true for PNG files
      // The actual transparency will be preserved during capture if present
      return decodedImage != null;
    } catch (e) {
      return false;
    }
  }

  void _resetTransformations() {
    setState(() {
      _offset = Offset.zero;
      _scale = 1.0;
      _previousScale = 1.0;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _captureAndCropImage() async {
    setState(() => _isCapturing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return null;

      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes == null) {
        _showSnackBar('Failed to capture image', isError: true);
        return null;
      }

      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        _showSnackBar('Failed to process image', isError: true);
        return null;
      }

      final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final int croppedWidth = (widget.imageWidth * devicePixelRatio).toInt();
      final int croppedHeight = (widget.imageHeight * devicePixelRatio).toInt();

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
        croppedImage = img.copyResize(
          originalImage,
          width: croppedWidth,
          height: croppedHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'cropped_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${tempDir.path}/$fileName';

      final File file = File(filePath);
      // Encode PNG with transparency support if source has alpha channel
      final Uint8List pngBytes = img.encodePng(
        croppedImage,
        level: 9, // Maximum compression
        filter: img.PngFilter.none,
      );
      await file.writeAsBytes(pngBytes);

      return filePath;
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to process image', isError: true);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _handleDone() async {
    if (!mounted || _isProcessing) return;

    final hasImage =
        _currentImagePath != null && File(_currentImagePath!).existsSync();

    if (hasImage) {
      setState(() => _isProcessing = true);

      final String? croppedPath = await _captureAndCropImage();

      if (mounted) {
        setState(() => _isProcessing = false);

        if (croppedPath != null) {
          Navigator.pop(context, croppedPath);
        } else {
          Navigator.pop(context);
        }
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
      backgroundColor: Colors.black,
      appBar: _buildAppBar(hasImage),
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildImageContainer(hasImage),
                            SizedBox(height: 32.h),
                            if (hasImage) ...[
                              _buildActionButtons(),
                              SizedBox(height: 24.h),
                              _buildZoomIndicator(),
                            ] else
                              _buildEmptyStateCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool hasImage) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Adjust Image',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        if (hasImage)
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: _hasChanges ? Colors.white : Colors.grey,
              size: 24.sp,
            ),
            onPressed: _hasChanges ? _resetTransformations : null,
            tooltip: 'Reset',
          ),
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Center(child: _buildDoneButton()),
        ),
      ],
    );
  }

  Widget _buildDoneButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _handleDone,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      child: Text(
        'Done',
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
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
              : Border.all(
                  color: hasImage ? Colors.white : Colors.grey.shade800,
                  width: 2,
                ),
          // Use transparent background if image has transparency, otherwise use grey
          color: _hasTransparency && hasImage
              ? Colors.transparent
              : Colors.grey.shade900,
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
      child: Container(
        // Use transparent background if image has transparency
        color: _hasTransparency ? Colors.transparent : Colors.grey.shade900,
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
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          color: Colors.grey.shade900,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 40.sp,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Add Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tap to select from gallery',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.photo_library_rounded,
            label: 'Replace',
            onTap: _pickImage,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22.sp),
                SizedBox(width: 10.w),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    final percentage = ((_scale - 0.5) / 2.5 * 100).round();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.zoom_in_rounded, color: Colors.grey.shade400, size: 18.sp),
          SizedBox(width: 12.w),
          Text(
            'Pinch to zoom • Drag to reposition',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_scale != 1.0) ...[
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: Colors.grey.shade600,
            size: 32.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'Select an image to get started',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade800, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48.w,
                height: 48.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Processing Image...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
