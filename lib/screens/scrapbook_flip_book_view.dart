import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/scrap_book_page_turn/interactive_book.dart';
import 'package:lamlayers/utils/export_manager.dart';
import 'package:lamlayers/services/google_drive_share_service.dart';
import 'package:lamlayers/utils/share_config.dart';
import 'package:share_plus/share_plus.dart';

class ScrapbookFlipBookView extends StatefulWidget {
  final Scrapbook scrapbook;

  const ScrapbookFlipBookView({Key? key, required this.scrapbook})
    : super(key: key);

  @override
  State<ScrapbookFlipBookView> createState() => _ScrapbookFlipBookViewState();
}

class _ScrapbookFlipBookViewState extends State<ScrapbookFlipBookView>
    with WidgetsBindingObserver {
  late Box<PosterProject> _projectBox;
  late PageTurnController _pageController;
  // Track current page indices for navigation button state
  int _currentLeftPage = 0; // ignore: unused_field
  int _currentRightPage = 1; // ignore: unused_field

  // Customization state
  Color _scaffoldBgColor = const Color(0xFFF1F5F9);
  String? _scaffoldBgImagePath;

  Color _rightCoverColor = const Color(0xFFD7B89C);
  String? _rightCoverImagePath;

  Color _leftCoverColor = const Color.fromARGB(255, 192, 161, 134);
  String? _leftCoverImagePath;

  bool _showArrows = true;

  // Interstitial Ad state
  InterstitialAd? _interstitialAd;
  bool _isShowingAd = false;
  VoidCallback? _pendingActionAfterAd;

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9698718721404755/8193728553'; // Production ID
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-9698718721404755/8193728553'; // Production ID
    }
    return '';
  }

  void _loadInterstitial() {
    if (_interstitialAdUnitId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> _showAdIfAvailable({VoidCallback? onAfter}) async {
    final ad = _interstitialAd;
    if (ad == null || _isShowingAd) {
      if (onAfter != null) onAfter();
      return;
    }
    _isShowingAd = true;
    _pendingActionAfterAd = onAfter;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
        final action = _pendingActionAfterAd;
        _pendingActionAfterAd = null;
        if (action != null) action();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
        final action = _pendingActionAfterAd;
        _pendingActionAfterAd = null;
        if (action != null) action();
      },
    );
    await ad.show();
  }

  Future<bool> _ensureFileAccessPermission() async {
    // Request platform-appropriate permission for accessing media/files
    if (Platform.isAndroid) {
      // Android 13+ exposes READ_MEDIA_* permissions via Permission.photos/videos/audio
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) return true;

      // Fallback for older Android versions
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      // As a last resort for Android 11+ scoped storage exceptions
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) return true;

      if (photosStatus.isPermanentlyDenied ||
          storageStatus.isPermanentlyDenied ||
          manageStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }
    if (Platform.isIOS) {
      // iOS: request adding to Photos (export/share flow)
      final status = await Permission.photosAddOnly.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }
    return true;
  }

  Future<GoogleSignInAccount?> _ensureSignedInToGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: <String>['email', 'https://www.googleapis.com/auth/drive.file'],
    );
    GoogleSignInAccount? account = googleSignIn.currentUser;
    account ??= await googleSignIn.signInSilently();
    account ??= await googleSignIn.signIn();
    return account;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _projectBox = Hive.box<PosterProject>('posterProjects');
    _pageController = PageTurnController();
    // Initialize and load Google Mobile Ads interstitial
    MobileAds.instance.initialize();
    _loadInterstitial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app resumes to ensure latest state
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _openEditSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Customize Scrapbook',
                              style: GoogleFonts.inter(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF64748B),
                              iconSize: 24.r,
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1.h, thickness: 1),

                      // Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          children: [
                            // Background Section
                            _buildSectionHeader('Background'),
                            SizedBox(height: 12.h),
                            _buildOptionCardWithRemove(
                              icon: Icons.wallpaper_outlined,
                              title: 'Choose Image',
                              subtitle: 'Set a custom background image',
                              hasImage: _scaffoldBgImagePath != null,
                              onTap: () async {
                                final path = await _pickImage();
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                if (path != null) {
                                  setState(() {
                                    _scaffoldBgImagePath = path;
                                  });
                                }
                              },
                              onRemove: () {
                                setState(() {
                                  _scaffoldBgImagePath = null;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                            SizedBox(height: 8.h),
                            _buildOptionCard(
                              icon: Icons.palette_outlined,
                              title: 'Choose Color',
                              subtitle: 'Pick from palette or custom color',
                              trailing: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: _scaffoldBgColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onTap: () => _showColorOptions(
                                ctx,
                                'Background Color',
                                _scaffoldBgColor,
                                (color) {
                                  setState(() {
                                    _scaffoldBgColor = color;
                                    _scaffoldBgImagePath = null;
                                  });
                                },
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Left Cover Section
                            _buildSectionHeader('Left Cover'),
                            SizedBox(height: 12.h),
                            _buildOptionCardWithRemove(
                              icon: Icons.image_outlined,
                              title: 'Choose Image',
                              subtitle: 'Set left cover image',
                              hasImage: _leftCoverImagePath != null,
                              onTap: () async {
                                final path = await _pickImage();
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                if (path != null) {
                                  setState(() {
                                    _leftCoverImagePath = path;
                                  });
                                }
                              },
                              onRemove: () {
                                setState(() {
                                  _leftCoverImagePath = null;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                            SizedBox(height: 8.h),
                            _buildOptionCard(
                              icon: Icons.palette_outlined,
                              title: 'Choose Color',
                              subtitle: 'Pick from palette or custom color',
                              trailing: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: _leftCoverColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onTap: () => _showColorOptions(
                                ctx,
                                'Left Cover Color',
                                _leftCoverColor,
                                (color) {
                                  setState(() {
                                    _leftCoverColor = color;
                                    _leftCoverImagePath = null;
                                  });
                                },
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Right Cover Section
                            _buildSectionHeader('Right Cover'),
                            SizedBox(height: 12.h),
                            _buildOptionCardWithRemove(
                              icon: Icons.image_outlined,
                              title: 'Choose Image',
                              subtitle: 'Set right cover image',
                              hasImage: _rightCoverImagePath != null,
                              onTap: () async {
                                final path = await _pickImage();
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                if (path != null) {
                                  setState(() {
                                    _rightCoverImagePath = path;
                                  });
                                }
                              },
                              onRemove: () {
                                setState(() {
                                  _rightCoverImagePath = null;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                            SizedBox(height: 8.h),
                            _buildOptionCard(
                              icon: Icons.palette_outlined,
                              title: 'Choose Color',
                              subtitle: 'Pick from palette or custom color',
                              trailing: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: _rightCoverColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onTap: () => _showColorOptions(
                                ctx,
                                'Right Cover Color',
                                _rightCoverColor,
                                (color) {
                                  setState(() {
                                    _rightCoverColor = color;
                                    _rightCoverImagePath = null;
                                  });
                                },
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Navigation Section
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475569),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: const Color(0xFF3B82F6), size: 24.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 12.w),
                trailing,
              ] else
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 24.r,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCardWithRemove({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool hasImage,
    required VoidCallback onRemove,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                  topRight: hasImage ? Radius.zero : Radius.circular(12.r),
                  bottomRight: hasImage ? Radius.zero : Radius.circular(12.r),
                ),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF3B82F6),
                          size: 24.r,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!hasImage)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 24.r,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasImage)
              Container(width: 1, height: 60.h, color: const Color(0xFFE2E8F0)),
            if (hasImage)
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Icon(
                    Icons.delete_outline,
                    color: const Color(0xFFEF4444),
                    size: 24.r,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Compact, professional share option card used in the bottom sheet
  // Displays an icon with colored background, a title, a subtitle, and a chevron
  // to indicate interactivity.
  // ignore: unused_element
  Widget _ShareOptionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 22.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF94A3B8),
                size: 24.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorOptions(
    BuildContext parentContext,
    String title,
    Color initialColor,
    Function(Color) onColorSelected,
  ) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Divider(height: 1.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: const Color(0xFF3B82F6),
                    size: 24.r,
                  ),
                ),
                title: Text(
                  'Pick from palette',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(
                  'Choose from preset colors',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final color = await _selectColor(initial: initialColor);
                  if (!mounted) return;
                  Navigator.pop(parentContext);
                  if (color != null) {
                    onColorSelected(color);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.colorize_outlined,
                    color: const Color(0xFF8B5CF6),
                    size: 24.r,
                  ),
                ),
                title: Text(
                  'Custom color',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(
                  'Create your own color',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final color = await _selectCustomColor(initial: initialColor);
                  if (!mounted) return;
                  Navigator.pop(parentContext);
                  if (color != null) {
                    onColorSelected(color);
                  }
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    return file?.path;
  }

  Future<Color?> _selectColor({required Color initial}) async {
    return showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color temp = initial;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Pick from palette',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: temp,
              onColorChanged: (c) => temp = c,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(temp),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Select',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Color?> _selectCustomColor({required Color initial}) async {
    return showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color temp = initial;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Custom color',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: temp,
              onColorChanged: (c) => temp = c,
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(temp),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Select',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageContent(String projectId, int pageIndex) {
    try {
      final project = _projectBox.get(projectId);
      if (project == null) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 48.r,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Page ${pageIndex + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Try to get thumbnail or background image with better error handling
      String? imagePath = project.thumbnailPath;
      if (imagePath == null ||
          imagePath.isEmpty ||
          !File(imagePath).existsSync()) {
        imagePath = project.backgroundImagePath;
      }

      if (imagePath != null &&
          imagePath.isNotEmpty &&
          File(imagePath).existsSync()) {
        return Container(
          decoration: BoxDecoration(
            color: project.canvasBackgroundColor.toColor(),
          ),
          child: Stack(
            children: [
              // Background image with error handling and unique key for refresh
              Positioned.fill(
                child: Image.file(
                  File(imagePath),
                  key: ValueKey(
                    '${projectId}_${project.lastModified.millisecondsSinceEpoch}',
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // If image fails to load, show background color with placeholder
                    return Container(
                      decoration: BoxDecoration(
                        color: project.canvasBackgroundColor.toColor(),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: const Color(0xFF94A3B8),
                              size: 48.r,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Page ${pageIndex + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }

      // Fallback for pages without images
      return Container(
        decoration: BoxDecoration(
          color: project.canvasBackgroundColor.toColor(),
          gradient: project.canvasBackgroundColor.value == 0xFFFFFFFF
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                )
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                color: const Color(0xFF94A3B8),
                size: 48.r,
              ),
              SizedBox(height: 16.h),
              Text(
                project.name,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Error fallback
      print('Error building page content: $e');
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: const Color(0xFFEF4444),
                size: 48.r,
              ),
              SizedBox(height: 8.h),
              Text(
                'Error loading page ${pageIndex + 1}',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFFEF4444),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  void _onPageChanged(int leftPageIndex, int rightPageIndex) {
    setState(() {
      _currentLeftPage = leftPageIndex;
      _currentRightPage = rightPageIndex;
    });
  }

  void _goToPreviousPage() {
    if (_currentLeftPage > 0) {
      _pageController.previousPage();
    }
  }

  void _goToNextPage() {
    final pageIds = widget.scrapbook.pageProjectIds;
    if (_currentRightPage < pageIds.length - 1) {
      _pageController.nextPage();
    }
  }

  Widget _buildInteractiveBook() {
    final pageIds = widget.scrapbook.pageProjectIds;

    // Validate scrapbook dimensions to prevent division by zero
    if (widget.scrapbook.pageWidth <= 0 || widget.scrapbook.pageHeight <= 0) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: const Color(0xFFEF4444),
                size: 48.r,
              ),
              SizedBox(height: 16.h),
              Text(
                'Invalid scrapbook dimensions',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate aspect ratio safely with fallback
    double aspectRatio;
    try {
      if (widget.scrapbook.pageWidth > 0 && widget.scrapbook.pageHeight > 0) {
        aspectRatio =
            (widget.scrapbook.pageWidth * 2) / widget.scrapbook.pageHeight;
      } else {
        // Fallback to a reasonable aspect ratio for dual page view
        aspectRatio = 1.4; // Standard book aspect ratio
      }

      // Ensure aspect ratio is valid
      if (aspectRatio <= 0 || !aspectRatio.isFinite || aspectRatio.isNaN) {
        aspectRatio = 1.4;
      }
    } catch (e) {
      aspectRatio = 1.4; // Fallback aspect ratio
    }

    try {
      return InteractiveBook(
        pagesBoundaryIsEnabled: false,
        controller: _pageController,
        pageCount: pageIds.length,
        aspectRatio: aspectRatio,
        pageViewMode: PageViewMode.double,
        onPageChanged: _onPageChanged,
        settings: FlipSettings(
          flippingTime: 1200,
          startPageIndex: 0, usePortrait: false),

        builder: (context, pageIndex, constraints) {
          if (pageIndex >= pageIds.length) {
            return Container(
              color: Colors.white,
              child: Center(
                child: Text(
                  'End of Book',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }
          return _buildPageContent(pageIds[pageIndex], pageIndex);
        },
      );
    } catch (e) {
      // Log the error for debugging
      print('InteractiveBook Error: $e');
      // Fallback for any InteractiveBook errors
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                color: const Color(0xFF94A3B8),
                size: 48.r,
              ),
              SizedBox(height: 16.h),
              Text(
                'Unable to load flip book',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Please try again',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageIds = widget.scrapbook.pageProjectIds;

    // Debug information for release builds
    print('Scrapbook Debug Info:');
    print('- Name: ${widget.scrapbook.name}');
    print('- Page count: ${pageIds.length}');
    print('- Page width: ${widget.scrapbook.pageWidth}');
    print('- Page height: ${widget.scrapbook.pageHeight}');
    print('- Page IDs: $pageIds');

    if (pageIds.isEmpty) {
      return Scaffold(
        backgroundColor: _scaffoldBgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Flip Book View',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 64.r,
                  color: const Color(0xFFEC4899),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'No pages to display',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add some pages to your scrapbook first',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate aspect ratio based on scrapbook page dimensions
    // For dual page mode, we need to account for two pages side by side

    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            if (_scaffoldBgImagePath != null &&
                File(_scaffoldBgImagePath!).existsSync())
              Positioned.fill(
                child: Image.file(
                  File(_scaffoldBgImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF0F172A)),
                  onPressed: _openEditSheet,
                  tooltip: 'Edit view',
                ),
              ),
            ),
            // Share button (bottom-left at 8,8)
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  icon: const Icon(Icons.ios_share, color: Color(0xFF0F172A)),
                  tooltip: 'Share flip book',
                  onPressed: () async {
                    // Present actions: Share file (existing) or Share Link (new)
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) {
                        return SafeArea(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 12.w,
                              right: 12.w,
                              bottom: 12.h,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Handle
                                  Container(
                                    margin: EdgeInsets.only(top: 12.h),
                                    width: 40.w,
                                    height: 4.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  ),
                                  // Header
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Share scrapbook',
                                                style: GoogleFonts.inter(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                'Choose how you want to share your flip book',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: Color(0xFF64748B),
                                          ),
                                          onPressed: () => Navigator.pop(ctx),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1.h),
                                  Padding(
                                    padding: EdgeInsets.all(12.r),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Option: Share file
                                        _ShareOptionCard(
                                          icon:
                                              Icons.insert_drive_file_outlined,
                                          iconBg: const Color(0xFFEEF2FF),
                                          iconColor: const Color(0xFF6366F1),
                                          title: 'Share file (.lambook)',
                                          subtitle:
                                              'Export a portable scrapbook file',
                                          onTap: () async {
                                            Navigator.pop(ctx);
                                            await _showAdIfAvailable(
                                              onAfter: () async {
                                                final granted =
                                                    await _ensureFileAccessPermission();
                                                if (!granted) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Storage permission is required to share the file',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                final ids = widget
                                                    .scrapbook
                                                    .pageProjectIds;
                                                final List<PosterProject>
                                                pages = [];
                                                for (final id in ids) {
                                                  final p = _projectBox.get(id);
                                                  if (p != null) pages.add(p);
                                                }
                                                if (pages.isEmpty) return;
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) => const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                                try {
                                                  final String? path =
                                                      await ExportManager.exportScrapbookLambook(
                                                        scrapbook:
                                                            widget.scrapbook,
                                                        pages: pages,
                                                        scaffoldBgColor:
                                                            _scaffoldBgColor,
                                                        scaffoldBgImagePath:
                                                            _scaffoldBgImagePath,
                                                        leftCoverColor:
                                                            _leftCoverColor,
                                                        leftCoverImagePath:
                                                            _leftCoverImagePath,
                                                        rightCoverColor:
                                                            _rightCoverColor,
                                                        rightCoverImagePath:
                                                            _rightCoverImagePath,
                                                      );
                                                  if (path != null) {
                                                    await ExportManager.shareLambook(
                                                      path,
                                                    );
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Scrapbook exported and shared successfully!',
                                                          ),
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Failed to export scrapbook. Please try again.',
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  print(
                                                    'Error exporting scrapbook: $e',
                                                  );
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Export failed: ${e.toString()}',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    Navigator.of(
                                                      context,
                                                      rootNavigator: true,
                                                    ).pop();
                                                  }
                                                }
                                              },
                                            );
                                          },
                                        ),
                                        SizedBox(height: 10.h),
                                        // Option: Share link
                                        _ShareOptionCard(
                                          icon: Icons.link,
                                          iconBg: const Color(0xFFEFFCF5),
                                          iconColor: const Color(0xFF10B981),
                                          title: 'Share link',
                                          subtitle:
                                              'Upload to Drive and send a web link',
                                          onTap: () async {
                                            Navigator.pop(ctx);
                                            await _showAdIfAvailable(
                                              onAfter: () async {
                                                // Ensure Google account first (for Drive upload)
                                                final account =
                                                    await _ensureSignedInToGoogle();
                                                if (account == null) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Google sign-in is required to share a link',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                final ids = widget
                                                    .scrapbook
                                                    .pageProjectIds;
                                                final List<PosterProject>
                                                pages = [];
                                                for (final id in ids) {
                                                  final p = _projectBox.get(id);
                                                  if (p != null) pages.add(p);
                                                }
                                                if (pages.isEmpty) return;
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) => const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                                try {
                                                  // 1) Export .lambook locally
                                                  final String? path =
                                                      await ExportManager.exportScrapbookLambook(
                                                        scrapbook:
                                                            widget.scrapbook,
                                                        pages: pages,
                                                        scaffoldBgColor:
                                                            _scaffoldBgColor,
                                                        scaffoldBgImagePath:
                                                            _scaffoldBgImagePath,
                                                        leftCoverColor:
                                                            _leftCoverColor,
                                                        leftCoverImagePath:
                                                            _leftCoverImagePath,
                                                        rightCoverColor:
                                                            _rightCoverColor,
                                                        rightCoverImagePath:
                                                            _rightCoverImagePath,
                                                      );
                                                  if (path == null) return;

                                                  // 2) Upload to Google Drive and make public
                                                  final fileBytes = await File(
                                                    path,
                                                  ).readAsBytes();
                                                  final driveService =
                                                      GoogleDriveShareService();
                                                  final fileId = await driveService
                                                      .uploadAndMakePublic(
                                                        fileName:
                                                            widget
                                                                .scrapbook
                                                                .name
                                                                .endsWith(
                                                                  '.lambook',
                                                                )
                                                            ? widget
                                                                  .scrapbook
                                                                  .name
                                                            : '${widget.scrapbook.name}.lambook',
                                                        bytes: fileBytes,
                                                        mimeType:
                                                            'application/octet-stream',
                                                      );

                                                  // 3) Build web viewer URL
                                                  final viewerUrl =
                                                      'https://$firebaseWebDomain/?file='
                                                      'https://drive.google.com/uc?id=$fileId&export=download';

                                                  await Share.share(viewerUrl);
                                                } catch (_) {
                                                } finally {
                                                  if (mounted) {
                                                    Navigator.of(
                                                      context,
                                                      rootNavigator: true,
                                                    ).pop();
                                                  }
                                                }
                                              },
                                            );
                                          },
                                        ),
                                        SizedBox(height: 6.h),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Center(
              child: RotatedBox(
                quarterTurns: 1,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    children: [
                    
                      // 🟤 Background book cover (below)
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.height * 0.825,
                          height: MediaQuery.of(context).size.width * 0.76,

                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.height * 0.82,
                                  height:
                                      MediaQuery.of(context).size.width * 0.7,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(4, 4),
                                      ),
                                    ],
                                    color: _rightCoverImagePath == null
                                        ? _rightCoverColor
                                        : null,
                                    image:
                                        _rightCoverImagePath != null &&
                                            File(
                                              _rightCoverImagePath!,
                                            ).existsSync()
                                        ? DecorationImage(
                                            image: FileImage(
                                              File(_rightCoverImagePath!),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                ),
                              ),

                              Align(
                                alignment: AlignmentGeometry.centerLeft,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.height *
                                      0.815 /
                                      2,
                                  height:
                                      MediaQuery.of(context).size.width * 0.71,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16.r),
                                      topLeft: Radius.circular(16.r),
                                    ),
                                    color: _leftCoverImagePath == null
                                        ? _leftCoverColor
                                        : null,
                                    image:
                                        _leftCoverImagePath != null &&
                                            File(
                                              _leftCoverImagePath!,
                                            ).existsSync()
                                        ? DecorationImage(
                                            image: FileImage(
                                              File(_leftCoverImagePath!),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.height * 0.8,
                            height: MediaQuery.of(context).size.width * 0.9,
                            child: _buildInteractiveBook(),
                          ),
                        ),
                      ),

                      // Navigation buttons
                      if (_showArrows)
                        Positioned(
                          bottom: 20.h,
                          left: 20.w,
                          child: SizedBox(
                            child: Center(
                              child: IconButton(
                                onPressed: _currentLeftPage > 0
                                    ? _goToPreviousPage
                                    : null,
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: _currentLeftPage > 0
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                  size: 15.r,
                                ),
                                padding: EdgeInsets.all(8.w),
                                constraints: BoxConstraints(
                                  minWidth: 50.w,
                                  minHeight: 50.h,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (_showArrows)
                        Positioned(
                          bottom: 20.h,
                          right: 20.w,
                          child: SizedBox(
                            child: Center(
                              child: IconButton(
                                onPressed:
                                    _currentRightPage < pageIds.length - 1
                                    ? _goToNextPage
                                    : null,
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: _currentRightPage < pageIds.length - 1
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                  size: 15.r,
                                ),
                                padding: EdgeInsets.all(8.w),
                                constraints: BoxConstraints(
                                  minWidth: 50.w,
                                  minHeight: 50.h,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
