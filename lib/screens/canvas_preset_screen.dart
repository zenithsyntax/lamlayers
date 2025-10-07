import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CanvasSelectionResult {
  final double width;
  final double height;
  final String? backgroundImagePath;

  CanvasSelectionResult({
    required this.width,
    required this.height,
    this.backgroundImagePath,
  });
}

class CanvasPresetScreen extends StatefulWidget {
  const CanvasPresetScreen({super.key});

  @override
  State<CanvasPresetScreen> createState() => _CanvasPresetScreenState();
}

class _CanvasPresetScreenState extends State<CanvasPresetScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _w = TextEditingController(text: '1080');
  final TextEditingController _h = TextEditingController(text: '1920');
  String? _bgPath;

  @override
  void dispose() {
    _w.dispose();
    _h.dispose();
    super.dispose();
  }

  void _select(double w, double h) {
    Navigator.pop(
      context,
      CanvasSelectionResult(width: w, height: h, backgroundImagePath: _bgPath),
    );
  }

  Future<void> _pickBackground() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _bgPath = file.path);
    }
  }

  Widget _presetCard({
    required String title,
    required double width,
    required double height,
    required Color color,
  }) {
    final aspectRatio = width / height;
    final ratio = '${width.toInt()}:${height.toInt()}';

    return GestureDetector(
      onTap: () => _select(width, height),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Container(
                width: aspectRatio >= 1 ? 60.w : (60.w * aspectRatio),
                height: aspectRatio <= 1 ? 60.w : (60.w / aspectRatio),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${width.toInt()} x ${height.toInt()}',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: const Color(0xFF666666),
            ),
          ),
          Text(
            ratio,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Wrap(spacing: 16.w, runSpacing: 16.h, children: children),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'Select Canvas Size',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFE0E0E0), height: 1.h),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            _categorySection('General', [
              _presetCard(
                title: 'App Icon',
                width: 1024,
                height: 1024,
                color: const Color(0xFF4FC3F7),
              ),
              _presetCard(
                title: 'Web Logo',
                width: 512,
                height: 512,
                color: const Color(0xFF7E57C2),
              ),
            ]),

            _categorySection('YouTube', [
              _presetCard(
                title: 'Channel Banner',
                width: 2560,
                height: 1440,
                color: const Color(0xFFFF5252),
              ),
              _presetCard(
                title: 'Profile Picture',
                width: 800,
                height: 800,
                color: const Color(0xFFEC407A),
              ),
              _presetCard(
                title: 'Thumbnail',
                width: 1280,
                height: 720,
                color: const Color(0xFFFF7043),
              ),
            ]),

            _categorySection('Instagram', [
              _presetCard(
                title: 'Profile Picture',
                width: 320,
                height: 320,
                color: const Color(0xFFE91E63),
              ),
              _presetCard(
                title: 'Square Post',
                width: 1080,
                height: 1080,
                color: const Color(0xFFAB47BC),
              ),
              _presetCard(
                title: 'Portrait Post',
                width: 1080,
                height: 1350,
                color: const Color(0xFF7E57C2),
              ),
              _presetCard(
                title: 'Landscape Post',
                width: 1080,
                height: 566,
                color: const Color(0xFF5C6BC0),
              ),
              _presetCard(
                title: 'Story',
                width: 1080,
                height: 1920,
                color: const Color(0xFF42A5F5),
              ),
            ]),

            _categorySection('Facebook', [
              _presetCard(
                title: 'Profile Picture',
                width: 400,
                height: 400,
                color: const Color(0xFF29B6F6),
              ),
              _presetCard(
                title: 'Cover Photo',
                width: 820,
                height: 312,
                color: const Color(0xFF26C6DA),
              ),
              _presetCard(
                title: 'Post Image',
                width: 1200,
                height: 630,
                color: const Color(0xFF26A69A),
              ),
              _presetCard(
                title: 'Story',
                width: 1080,
                height: 1920,
                color: const Color(0xFF66BB6A),
              ),
            ]),

            _categorySection('LinkedIn', [
              _presetCard(
                title: 'Profile Picture',
                width: 400,
                height: 400,
                color: const Color(0xFF9CCC65),
              ),
              _presetCard(
                title: 'Cover Banner',
                width: 1584,
                height: 396,
                color: const Color(0xFFD4E157),
              ),
              _presetCard(
                title: 'Company Logo',
                width: 300,
                height: 300,
                color: const Color(0xFFFFEE58),
              ),
              _presetCard(
                title: 'Company Cover',
                width: 1128,
                height: 191,
                color: const Color(0xFFFFCA28),
              ),
            ]),

            _categorySection('X (Twitter)', [
              _presetCard(
                title: 'Profile Picture',
                width: 400,
                height: 400,
                color: const Color(0xFFFFB74D),
              ),
              _presetCard(
                title: 'Header Banner',
                width: 1500,
                height: 500,
                color: const Color(0xFFFF8A65),
              ),
              _presetCard(
                title: 'Post Image',
                width: 1200,
                height: 675,
                color: const Color(0xFFA1887F),
              ),
            ]),

            _categorySection('TikTok', [
              _presetCard(
                title: 'Profile Picture',
                width: 200,
                height: 200,
                color: const Color(0xFF26C6DA),
              ),
              _presetCard(
                title: 'Thumbnail',
                width: 1080,
                height: 1080,
                color: const Color(0xFF29B6F6),
              ),
            ]),

            _categorySection('Pinterest', [
              _presetCard(
                title: 'Pin',
                width: 1000,
                height: 1500,
                color: const Color(0xFFE91E63),
              ),
              _presetCard(
                title: 'Profile Picture',
                width: 280,
                height: 280,
                color: const Color(0xFFAB47BC),
              ),
            ]),

            _categorySection('WhatsApp', [
              _presetCard(
                title: 'Profile Picture',
                width: 800,
                height: 800,
                color: const Color(0xFF66BB6A),
              ),
              _presetCard(
                title: 'Status',
                width: 1080,
                height: 1920,
                color: const Color(0xFF9CCC65),
              ),
            ]),

            // Custom Size Section
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.w),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Size',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _w,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: const Color(0xFF1A1A1A),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Width',
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF666666),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: const Color(0xFFE0E0E0),
                                width: 1.w,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: const Color(0xFFE0E0E0),
                                width: 1.w,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: const Color(0xFF42A5F5),
                                width: 2.w,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: _h,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: const Color(0xFF1A1A1A),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Height',
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF666666),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: const Color(0xFFE0E0E0),
                                width: 1.w,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: const Color(0xFFE0E0E0),
                                width: 1.w,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: const Color(0xFF42A5F5),
                                width: 2.w,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final w = double.tryParse(_w.text);
                        final h = double.tryParse(_h.text);
                        if (w != null && h != null && w > 0 && h > 0) {
                          _select(w, h);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Create Canvas',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _pickBackground,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        side: BorderSide(
                          color: const Color(0xFF42A5F5),
                          width: 2.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        _bgPath == null
                            ? 'Pick Background'
                            : 'Background Selected ✓',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF42A5F5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
