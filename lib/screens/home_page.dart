import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';
import 'package:lamlayers/screens/canvas_preset_screen.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/screens/scrapbook_manager_screen.dart';
import 'package:lamlayers/screens/settings_screen.dart';
import 'package:lamlayers/utils/export_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Box<PosterProject> _projectBox;
  late Box<Scrapbook> _scrapbookBox;
  bool _isBoxReady = false;

  final List<String> _designQuotes = [
    "Design is intelligence made visible",
    "Creativity is contagious, pass it on",
    "Great design is invisible",
    "Design creates culture, culture shapes values",
    "Every great design begins with an even better story",
    "Design is where science and art break even",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _openProjectBox();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _getGreetingAnimation() {
    final hour = DateTime.now().hour;
    String assetPath;
    if (hour < 12) {
      assetPath = 'assets/icons/morning.json';
    } else if (hour < 17) {
      assetPath = 'assets/icons/afternoon.json';
    } else {
      assetPath = 'assets/icons/night.json';
    }

    return SizedBox(
      height: 20.h,
      width: 20.w,
      child: Lottie.asset(
        assetPath,
        repeat: true,
        reverse: false,
        animate: true,
        fit: BoxFit.contain,
      ),
    );
  }

  String _getRandomQuote() {
    return _designQuotes[DateTime.now().day % _designQuotes.length];
  }

  Future<void> _openProjectBox() async {
    _projectBox = await Hive.openBox<PosterProject>('posterProjects');
    _scrapbookBox = await Hive.openBox<Scrapbook>('scrapbooks');
    setState(() {
      _isBoxReady = true;
    });
  }

  Future<void> _createNewScrapbook() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name your Lambook',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'You can change this later in settings.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: 'e.g. Planner 1',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: const Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Create',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (name == null || name.isEmpty) return;

    // Create default cover and back cover pages at 1600x1200
    final double pageW = 1600;
    final double pageH = 1200;

    final cover = PosterProject(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Cover',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      canvasItems: [],
      settings: ProjectSettings(exportSettings: ExportSettings()),
      canvasWidth: pageW,
      canvasHeight: pageH,
    );
    final back = PosterProject(
      id: 'p_${DateTime.now().millisecondsSinceEpoch + 1}',
      name: 'Back Cover',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      canvasItems: [],
      settings: ProjectSettings(exportSettings: ExportSettings()),
      canvasWidth: pageW,
      canvasHeight: pageH,
    );

    await _projectBox.put(cover.id, cover);
    await _projectBox.put(back.id, back);

    final scrapbook = Scrapbook(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      pageProjectIds: [cover.id, back.id],
      pageWidth: pageW,
      pageHeight: pageH,
    );
    await _scrapbookBox.put(scrapbook.id, scrapbook);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScrapbookManagerScreen(scrapbookId: scrapbook.id),
      ),
    );
  }

  void _openScrapbookList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScrapbookManagerScreen()),
    );
  }

  Future<void> _createNewProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CanvasPresetScreen()),
    );
    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PosterMakerScreen(
            initialCanvasWidth: result.width,
            initialCanvasHeight: result.height,
            initialBackgroundImagePath: result.backgroundImagePath,
          ),
        ),
      );
    }
  }

  Future<void> _renameScrapbook(Scrapbook scrapbook) async {
    final controller = TextEditingController(text: scrapbook.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rename Scrapbook',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: const Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final updated = scrapbook.copyWith(name: newName);
      await _scrapbookBox.put(scrapbook.id, updated);
    }
  }

  Future<void> _deleteScrapbook(Scrapbook scrapbook) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: const Color(0xFFEF4444),
                  size: 24.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete Scrapbook?',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to delete "${scrapbook.name}"? All its pages will also be deleted.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      // Cascade delete: remove all page projects referenced by this scrapbook
      final List<String> pageIds = List<String>.from(scrapbook.pageProjectIds);
      for (final String pid in pageIds) {
        await _projectBox.delete(pid);
      }
      await _scrapbookBox.delete(scrapbook.id);
    }
  }

  Widget _scrapbookCard(Scrapbook scrapbook) {
    PosterProject? cover;
    if (scrapbook.pageProjectIds.isNotEmpty) {
      cover = _projectBox.get(scrapbook.pageProjectIds.first);
    }

    return Container(
      width: 220.w,
      margin: EdgeInsets.only(right: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScrapbookManagerScreen(scrapbookId: scrapbook.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                    child: _buildProjectPreviewImage(cover),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scrapbook.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              Icons.auto_stories,
                              size: 13.r,
                              color: const Color(0xFFEC4899),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${scrapbook.pageProjectIds.length} pages',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8.w,
            top: 8.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    _renameScrapbook(scrapbook);
                  } else if (value == 'delete') {
                    _deleteScrapbook(scrapbook);
                  }
                },
                icon: Icon(
                  Icons.more_horiz,
                  size: 20.r,
                  color: const Color(0xFF64748B),
                ),
                tooltip: 'More options',
                elevation: 6,
                color: Colors.white,
                shadowColor: Colors.black.withOpacity(0.08),
                surfaceTintColor: Colors.transparent,
                offset: Offset(0, 6.h),
                constraints: BoxConstraints(minWidth: 160.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    height: 40.h,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18.r,
                          color: const Color(0xFF64748B),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Rename',
                          style: GoogleFonts.inter(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete',
                    height: 40.h,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18.r,
                          color: const Color(0xFFEF4444),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProjectFromStorage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;

        if (!filePath.toLowerCase().endsWith('.lamlayers')) {
          _showErrorMessage(
            'Please select a .lamlayers file. Selected: ${filePath.split('/').last}',
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildLoadingDialog(),
        );

        try {
          final PosterProject? project = await ExportManager.loadProject(
            filePath,
          );

          if (!mounted) return;
          Navigator.of(context).pop();

          if (project != null) {
            await _projectBox.put(project.id, project);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PosterMakerScreen(projectId: project.id),
              ),
            );

            _showSuccessMessage('Project loaded successfully!');
          } else {
            _showErrorMessage(
              'Failed to load project. The file may be corrupted or incomplete.\n\nPossible causes:\n• File was not fully downloaded/transferred\n• File was created with an older version\n• File structure is invalid\n\nPlease try exporting the project again or contact support if the issue persists.',
            );
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.of(context).pop();
          _showErrorMessage('Error loading project: ${e.toString()}');
        }
      }
    } catch (e) {
      _showErrorMessage('Error selecting file: ${e.toString()}');
    }
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF6366F1),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Loading Project',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please wait a moment',
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: const Color(0xFF10B981),
                size: 16.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: const Color(0xFFEF4444),
                size: 16.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _renameProject(PosterProject project) async {
    final controller = TextEditingController(text: project.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rename Project',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: const Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final updated = project.copyWith(name: newName);
      await _projectBox.put(project.id, updated);
    }
  }

  Future<void> _deleteProject(PosterProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: const Color(0xFFEF4444),
                  size: 24.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete Project?',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _projectBox.delete(project.id);
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final d = dateTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  Widget _buildProjectPreviewImage(PosterProject? project) {
    final String? thumbnailPath = project?.thumbnailPath;
    final String? bgPath = project?.backgroundImagePath;

    final String? toShow = (thumbnailPath != null && thumbnailPath.isNotEmpty)
        ? thumbnailPath
        : (bgPath != null && bgPath.isNotEmpty ? bgPath : null);

    if (toShow == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.1),
              const Color(0xFF8B5CF6).withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 48.r,
            color: const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    final file = File(toShow);
    if (!file.existsSync()) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEF4444).withOpacity(0.1),
              const Color(0xFFF59E0B).withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40.r,
            color: const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return Image.file(
      file,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF8FAFC),
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 40.r,
              color: const Color(0xFF94A3B8),
            ),
          ),
        );
      },
    );
  }

  Widget _projectCard(PosterProject? project) {
    return Container(
      width: 220.w,
      margin: EdgeInsets.only(right: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PosterMakerScreen(projectId: project?.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                    child: _buildProjectPreviewImage(project),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project?.name ?? 'Unnamed Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 13.r,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _formatDate(project?.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8.w,
            top: 8.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (project == null) return;
                  if (value == 'rename') {
                    _renameProject(project);
                  } else if (value == 'delete') {
                    _deleteProject(project);
                  }
                },
                icon: Icon(
                  Icons.more_horiz,
                  size: 20.r,
                  color: const Color(0xFF64748B),
                ),
                tooltip: 'More options',
                elevation: 6,
                color: Colors.white,
                shadowColor: Colors.black.withOpacity(0.08),
                surfaceTintColor: Colors.transparent,
                offset: Offset(0, 6.h),
                constraints: BoxConstraints(minWidth: 160.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    height: 40.h,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18.r,
                          color: const Color(0xFF64748B),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Rename',
                          style: GoogleFonts.inter(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete',
                    height: 40.h,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18.r,
                          color: const Color(0xFFEF4444),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),

          // Motivational Quote Card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.06),
                  const Color(0xFF8B5CF6).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 18.w),
                Expanded(
                  child: Text(
                    _getRandomQuote(),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // Quick Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),

          SizedBox(height: 16.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Create New',
                    subtitle: 'Start fresh project',
                    icon: Icons.add_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    onTap: _createNewProject,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildActionCard(
                    title: 'Load Project',
                    subtitle: 'Open from storage',
                    icon: Icons.folder_open_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    onTap: _loadProjectFromStorage,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          // Recent Projects
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Projects',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          if (!_isBoxReady)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(48.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 28.w,
                      height: 28.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Loading projects...',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ValueListenableBuilder<Box<PosterProject>>(
              valueListenable: _projectBox.listenable(),
              builder: (context, box, _) {
                // Build a set of all project IDs that belong to any scrapbook (cover, back, or pages)
                final Set<String> scrapbookProjectIds = <String>{};
                for (int i = 0; i < _scrapbookBox.length; i++) {
                  final sb = _scrapbookBox.getAt(i);
                  if (sb != null) {
                    scrapbookProjectIds.addAll(sb.pageProjectIds);
                  }
                }

                // Collect poster-only projects (exclude projects that are scrapbook pages)
                final List<PosterProject?> posterOnly = [];
                for (int i = 0; i < box.length; i++) {
                  final p = box.getAt(i);
                  if (p != null && !scrapbookProjectIds.contains(p.id)) {
                    posterOnly.add(p);
                  }
                }

                if (posterOnly.isEmpty) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    padding: EdgeInsets.all(48.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.folder_outlined,
                              size: 48.r,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'No projects yet',
                            style: GoogleFonts.inter(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Create your first project to get started',
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

                return SizedBox(
                  height: 300.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: posterOnly.length,
                    itemBuilder: (context, index) {
                      final project = posterOnly[index];
                      return _projectCard(project);
                    },
                  ),
                );
              },
            ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32.r),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.95),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrapbookTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),

          // Quick Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Create New',
                    subtitle: 'Start scrapbook',
                    icon: Icons.add_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                    ),
                    onTap: _createNewScrapbook,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildActionCard(
                    title: 'Load Project',
                    subtitle: 'Open from storage',
                    icon: Icons.folder_open_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                    ),
                    onTap: _openScrapbookList,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          // Scrapbooks List
          if (!_isBoxReady)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(48.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 28.w,
                      height: 28.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFEC4899),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Loading scrapbooks...',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ValueListenableBuilder<Box<Scrapbook>>(
              valueListenable: _scrapbookBox.listenable(),
              builder: (context, box, _) {
                if (box.isEmpty) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    padding: EdgeInsets.all(48.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.collections_bookmark_rounded,
                              size: 48.r,
                              color: const Color(0xFFEC4899),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'No scrapbooks yet',
                            style: GoogleFonts.inter(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Create your first scrapbook to get started',
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

                return SizedBox(
                  height: 300.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final scrapbook = box.getAt(index)!;
                      return _scrapbookCard(scrapbook);
                    },
                  ),
                );
              },
            ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 90.h,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Row(
          children: [
            Container(
              height: 65.h,
              width: 65.w,

              child: ClipRRect(
                child: Image.asset('assets/icons/lamlayers_logo_home.png'),
                
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lamlayers',
                  style: GoogleFonts.inter(
                    fontSize: 25.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    _getGreetingAnimation(),
                    SizedBox(width: 6.w),
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF6366F1),
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    indicatorColor: const Color(0xFF6366F1),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding: EdgeInsets.symmetric(horizontal: 8.w),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Design'),
                      Tab(text: 'Lambook'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPosterTab(),
          _buildScrapbookTab(),
          const SettingsScreen(),
        ],
      ),
    );
  }
}
