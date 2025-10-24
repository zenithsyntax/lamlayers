import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamlayers/widgets/ad_interstitial.dart';
import 'package:lamlayers/screens/templates_screen.dart';

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
  late final InterstitialAdManager _templatesAd;
  String? _widthError;
  String? _heightError;

  @override
  void initState() {
    super.initState();
    // Production interstitial unit ID
    const String productionInterstitialId =
        'ca-app-pub-9698718721404755/8193728553';
    _templatesAd = InterstitialAdManager(adUnitId: productionInterstitialId);
    _templatesAd.load();

    // Add listeners for validation
    _w.addListener(_validateDimensions);
    _h.addListener(_validateDimensions);
  }

  @override
  void dispose() {
    _w.dispose();
    _h.dispose();
    _templatesAd.dispose();
    super.dispose();
  }

  void _validateDimensions() {
    setState(() {
      _widthError = null;
      _heightError = null;

      final width = double.tryParse(_w.text);
      final height = double.tryParse(_h.text);

      if (width != null) {
        if (width < 500) {
          _widthError = 'Width must be at least 500px';
        } else if (width > 5000) {
          _widthError = 'Width must be at most 5000px';
        }
      }

      if (height != null) {
        if (height < 500) {
          _heightError = 'Height must be at least 500px';
        } else if (height > 5000) {
          _heightError = 'Height must be at most 5000px';
        }
      }
    });
  }

  bool _isValidDimensions() {
    final width = double.tryParse(_w.text);
    final height = double.tryParse(_h.text);

    return width != null &&
        height != null &&
        width >= 500 &&
        width <= 5000 &&
        height >= 500 &&
        height <= 5000;
  }

  void _select(double w, double h) {
    Navigator.pop(
      context,
      CanvasSelectionResult(width: w, height: h, backgroundImagePath: _bgPath),
    );
  }

  void _openTemplatesWithAd() {
    _templatesAd.show(
      onClosed: () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TemplatesScreen()),
        );
      },
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
    required IconData icon,
  }) {
    final aspectRatio = width / height;

    return GestureDetector(
      onTap: () => _select(width, height),
      child: Container(
        width: 160.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 100.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.08),
                    const Color(0xFF8B5CF6).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: aspectRatio >= 1 ? 40.w : (40.w * aspectRatio),
                      height: aspectRatio <= 1 ? 40.w : (40.w / aspectRatio),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),

                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${width.toInt()} × ${height.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: Colors.white, size: 18.r),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Padding(
                padding: EdgeInsets.only(
                  right: index < children.length - 1 ? 16.w : 0,
                ),
                child: child,
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Canvas Size',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Select from presets or create custom',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        toolbarHeight: 80.h,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 20.r),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: TextButton.icon(
              onPressed: _openTemplatesWithAd,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: Text(
                'Templates',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            _categorySection('Instagram', Icons.camera_alt_rounded, [
              _presetCard(
                title: 'Profile Picture',
                width: 320,
                height: 320,
                icon: Icons.person_rounded,
              ),
              _presetCard(
                title: 'Square Post',
                width: 1080,
                height: 1080,
                icon: Icons.crop_square_rounded,
              ),
              _presetCard(
                title: 'Portrait Post',
                width: 1080,
                height: 1350,
                icon: Icons.crop_portrait_rounded,
              ),
              _presetCard(
                title: 'Landscape Post',
                width: 1080,
                height: 566,
                icon: Icons.crop_landscape_rounded,
              ),
              _presetCard(
                title: 'Story',
                width: 1080,
                height: 1920,
                icon: Icons.auto_stories_rounded,
              ),
            ]),

            _categorySection('WhatsApp', Icons.chat_bubble_rounded, [
              _presetCard(
                title: 'Profile Picture',
                width: 800,
                height: 800,
                icon: Icons.person_rounded,
              ),
              _presetCard(
                title: 'Status',
                width: 1080,
                height: 1920,
                icon: Icons.circle_rounded,
              ),
            ]),

            _categorySection('LinkedIn', Icons.business_center_rounded, [
              _presetCard(
                title: 'Profile Picture',
                width: 400,
                height: 400,
                icon: Icons.badge_rounded,
              ),
              _presetCard(
                title: 'Company Logo',
                width: 300,
                height: 300,
                icon: Icons.business_rounded,
              ),
            ]),

            _categorySection('General', Icons.apps_rounded, [
              _presetCard(
                title: 'App Icon',
                width: 1024,
                height: 1024,
                icon: Icons.phone_android_rounded,
              ),
              _presetCard(
                title: 'Web Logo',
                width: 512,
                height: 512,
                icon: Icons.language_rounded,
              ),
            ]),

            _categorySection('YouTube', Icons.play_circle_filled_rounded, [
              _presetCard(
                title: 'Channel Banner',
                width: 2560,
                height: 1440,
                icon: Icons.video_library_rounded,
              ),
              _presetCard(
                title: 'Profile Picture',
                width: 800,
                height: 800,
                icon: Icons.account_circle_rounded,
              ),
              _presetCard(
                title: 'Thumbnail',
                width: 1280,
                height: 720,
                icon: Icons.photo_size_select_actual_rounded,
              ),
            ]),

            _categorySection('Facebook', Icons.public_rounded, [
              _presetCard(
                title: 'Profile Picture',
                width: 400,
                height: 400,
                icon: Icons.person_rounded,
              ),
              _presetCard(
                title: 'Cover Photo',
                width: 820,
                height: 312,
                icon: Icons.panorama_rounded,
              ),
              _presetCard(
                title: 'Post Image',
                width: 1200,
                height: 630,
                icon: Icons.article_rounded,
              ),
              _presetCard(
                title: 'Story',
                width: 1080,
                height: 1920,
                icon: Icons.bolt_rounded,
              ),
            ]),

            _categorySection('TikTok', Icons.music_note_rounded, [
              _presetCard(
                title: 'Profile Picture',
                width: 200,
                height: 200,
                icon: Icons.person_rounded,
              ),
              _presetCard(
                title: 'Thumbnail',
                width: 1080,
                height: 1080,
                icon: Icons.videocam_rounded,
              ),
            ]),

            _categorySection('Pinterest', Icons.push_pin_rounded, [
              _presetCard(
                title: 'Pin',
                width: 1000,
                height: 1500,
                icon: Icons.collections_rounded,
              ),
              _presetCard(
                title: 'Profile Picture',
                width: 280,
                height: 280,
                icon: Icons.account_circle_rounded,
              ),
            ]),

            // Custom Size Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 18.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Custom Size',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Width',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  TextField(
                                    controller: _w,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '1080',
                                      hintStyle: GoogleFonts.inter(
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: _widthError != null
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: _widthError != null
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF6366F1),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                  ),
                                  if (_widthError != null) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      _widthError!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: const Color(0xFFEF4444),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Container(
                              padding: EdgeInsets.all(8.w),
                              child: Icon(
                                Icons.close_rounded,
                                color: const Color(0xFF94A3B8),
                                size: 20.r,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Height',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  TextField(
                                    controller: _h,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '1920',
                                      hintStyle: GoogleFonts.inter(
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: _heightError != null
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: _heightError != null
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF6366F1),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                  ),
                                  if (_heightError != null) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      _heightError!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: const Color(0xFFEF4444),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isValidDimensions()
                                ? () {
                                    final w = double.tryParse(_w.text);
                                    final h = double.tryParse(_h.text);
                                    if (w != null && h != null) {
                                      _select(w, h);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isValidDimensions()
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF94A3B8),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 18.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              elevation: 0,
                              shadowColor: _isValidDimensions()
                                  ? const Color(0xFF6366F1).withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, size: 22.r),
                                SizedBox(width: 8.w),
                                Text(
                                  'Create Canvas',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
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
