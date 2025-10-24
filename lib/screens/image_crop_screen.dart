import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? originalFilePath;
  final String? originalImageUrl;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    this.originalFilePath,
    this.originalImageUrl,
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop Image'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _cropImage,
            child: Text(
              'Crop',
              style: TextStyle(
                color: _isProcessing ? Colors.grey : Colors.blue,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing image...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width - 32.w,
                        height: MediaQuery.of(context).size.height * 0.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Tap "Crop" to open the crop tool',
                    style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _cropImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Save image bytes to temporary file for cropping
      final Directory tempDir = await getTemporaryDirectory();
      final String tempFilePath =
          '${tempDir.path}/temp_crop_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final File tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(widget.imageBytes);

      // Configure crop settings with simplified approach
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: tempFilePath,
        compressFormat:
            ImageCompressFormat.png, // Always use PNG to preserve quality
        compressQuality: 100, // Maximum quality
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white.withOpacity(0.5),
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            statusBarColor: Colors.black,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            hidesNavigationBar: false,
          ),
        ],
      );

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (croppedFile != null) {
        // Read the cropped image bytes
        final Uint8List croppedBytes = await croppedFile.readAsBytes();

        // Return the cropped image bytes
        if (mounted) {
          Navigator.pop(context, croppedBytes);
        }
      } else {
        // User cancelled cropping
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Crop error: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to crop image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
