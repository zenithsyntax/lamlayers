import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';
import 'package:lamlayers/screens/scrapbook_flip_book_view.dart';
import 'package:lamlayers/screens/scrapbook_template_screen.dart';
import 'package:lamlayers/utils/export_manager.dart';

class ScrapbookManagerScreen extends StatefulWidget {
  final String? scrapbookId;
  const ScrapbookManagerScreen({Key? key, this.scrapbookId}) : super(key: key);

  @override
  State<ScrapbookManagerScreen> createState() => _ScrapbookManagerScreenState();
}

class _ScrapbookManagerScreenState extends State<ScrapbookManagerScreen>
    with WidgetsBindingObserver {
  late Box<Scrapbook> _scrapbookBox;
  late Box<PosterProject> _projectBox;
  Scrapbook? _scrapbook;
  bool _isGridView = true;
  InterstitialAd? _interstitialAd;
  bool _isShowingAd = false;

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9698718721404755/8193728553'; // Production ID
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-9698718721404755/8193728553'; // Production ID
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrapbookBox = Hive.box<Scrapbook>('scrapbooks');
    _projectBox = Hive.box<PosterProject>('posterProjects');
    _load();
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
        _load();
        setState(() {});
      }
    }
  }

  void _loadInterstitial() {
    if (_interstitialAdUnitId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          print('Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          print('Failed to load interstitial ad: $error');
        },
      ),
    );
  }

  void _navigateToTemplateScreen() {
    print('Starting navigation to template screen');
    _showAdIfAvailable(
      onAfter: () {
        print('Ad callback triggered, navigating to template screen');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            print('Pushing ScrapbookTemplateScreen');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScrapbookTemplateScreen(
                  onTemplateSelected: _addPageFromTemplate,
                  requiredCanvasWidth: _scrapbook!.pageWidth,
                  requiredCanvasHeight: _scrapbook!.pageHeight,
                ),
              ),
            );
          } else {
            print('Widget not mounted, skipping navigation');
          }
        });
      },
    );

    // Fallback: If ad doesn't show within 5 seconds, navigate anyway
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isShowingAd) {
        print('Ad timeout, navigating anyway');
        _isShowingAd = false;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScrapbookTemplateScreen(
              onTemplateSelected: _addPageFromTemplate,
              requiredCanvasWidth: _scrapbook!.pageWidth,
              requiredCanvasHeight: _scrapbook!.pageHeight,
            ),
          ),
        );
      }
    });
  }

  Future<void> _showAdIfAvailable({VoidCallback? onAfter}) async {
    final ad = _interstitialAd;
    print('Ad available: ${ad != null}, Already showing: $_isShowingAd');

    if (ad == null || _isShowingAd) {
      // If no ad available or already showing, proceed immediately
      print('No ad available or already showing, proceeding without ad');
      if (onAfter != null) onAfter();
      return;
    }

    print('Showing interstitial ad...');
    _isShowingAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('Ad dismissed by user');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
        // Call the callback after ad is dismissed with a small delay
        if (onAfter != null) {
          print('Calling onAfter callback from ad dismissed');
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              print('Executing onAfter callback after ad dismissed');
              onAfter();
            } else {
              print('Widget not mounted, skipping callback');
            }
          });
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
        // Call the callback even if ad fails to show
        if (onAfter != null) {
          print('Calling onAfter callback from ad failed');
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              print('Executing onAfter callback after ad failed');
              onAfter();
            } else {
              print('Widget not mounted, skipping callback');
            }
          });
        }
      },
    );

    try {
      await ad.show();
      print('Ad show() called successfully');
    } catch (e) {
      print('Exception while showing ad: $e');
      // If ad fails to show, still call the callback
      _isShowingAd = false;
      if (onAfter != null) {
        print('Calling onAfter callback from exception');
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            print('Executing onAfter callback after exception');
            onAfter();
          } else {
            print('Widget not mounted, skipping callback');
          }
        });
      }
    }
  }

  void _load() {
    if (widget.scrapbookId != null) {
      _scrapbook = _scrapbookBox.get(widget.scrapbookId);
    } else if (_scrapbookBox.isNotEmpty) {
      _scrapbook = _scrapbookBox.getAt(0);
    }
  }

  Future<void> _refreshThumbnails() async {
    if (_scrapbook == null) return;

    print(
      'Refreshing thumbnails for ${_scrapbook!.pageProjectIds.length} pages...',
    );

    // Force refresh all project data from Hive
    for (String projectId in _scrapbook!.pageProjectIds) {
      final project = _projectBox.get(projectId);
      if (project != null) {
        print(
          'Checking project $projectId, thumbnail path: ${project.thumbnailPath}',
        );

        // Re-get the project to ensure we have the latest data
        _projectBox.put(projectId, project);

        // Check if thumbnail exists and is valid
        if (project.thumbnailPath != null &&
            project.thumbnailPath!.isNotEmpty) {
          final thumbnailFile = File(project.thumbnailPath!);
          if (thumbnailFile.existsSync()) {
            print('Thumbnail file exists: ${project.thumbnailPath}');
            // Clear image cache to force refresh
            PaintingBinding.instance.imageCache.evict(FileImage(thumbnailFile));
          } else {
            print(
              'Thumbnail file does not exist, clearing path: ${project.thumbnailPath}',
            );
            // Thumbnail file doesn't exist, clear the path
            project.thumbnailPath = null;
            _projectBox.put(projectId, project);
          }
        } else {
          print('No thumbnail path for project $projectId');
        }
      }
    }

    if (mounted) {
      setState(() {});
    }

    print('Thumbnail refresh completed');
  }

  Future<void> _addPage() async {
    if (_scrapbook == null) return;
    final page = PosterProject(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Page ${_scrapbook!.pageProjectIds.length - 1}',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      canvasItems: [],
      settings: ProjectSettings(exportSettings: ExportSettings()),
      canvasWidth: _scrapbook!.pageWidth,
      canvasHeight: _scrapbook!.pageHeight,
    );
    await _projectBox.put(page.id, page);
    final ids = List<String>.from(_scrapbook!.pageProjectIds);
    ids.insert(ids.length - 1, page.id);
    _scrapbook = _scrapbook!.copyWith(pageProjectIds: ids);
    await _scrapbookBox.put(_scrapbook!.id, _scrapbook!);
    setState(() {});
  }

  Future<void> _duplicatePage(int index) async {
    if (_scrapbook == null) return;

    final original = _projectBox.get(_scrapbook!.pageProjectIds[index]);
    if (original == null) return;
    final copy = original.copyWith(name: '${original.name} Copy');
    final newId = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final copied = PosterProject(
      id: newId,
      name: copy.name,
      description: copy.description,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      canvasItems: copy.canvasItems,
      settings: copy.settings,
      thumbnailPath: copy.thumbnailPath,
      tags: copy.tags,
      isFavorite: copy.isFavorite,
      canvasWidth: copy.canvasWidth,
      canvasHeight: copy.canvasHeight,
      canvasBackgroundColor: copy.canvasBackgroundColor,
      backgroundImagePath: copy.backgroundImagePath,
    );
    await _projectBox.put(newId, copied);
    final ids = List<String>.from(_scrapbook!.pageProjectIds);
    ids.insert(index + 1, newId);
    _scrapbook = _scrapbook!.copyWith(pageProjectIds: ids);
    await _scrapbookBox.put(_scrapbook!.id, _scrapbook!);
    setState(() {});
  }

  Future<void> _deletePage(int index) async {
    if (_scrapbook == null) return;

    // Ensure at least one page remains
    if (_scrapbook!.pageProjectIds.length <= 1) {
      _showErrorMessage(
        'Cannot delete the last page. At least one page must remain in the scrapbook.',
      );
      return;
    }

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
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: const Color(0xFFEF4444),
                  size: 32.r,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Delete Page?',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'This action cannot be undone',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final ids = List<String>.from(_scrapbook!.pageProjectIds);
      final removedId = ids.removeAt(index);
      // Delete the underlying page project as well
      await _projectBox.delete(removedId);
      _scrapbook = _scrapbook!.copyWith(pageProjectIds: ids);
      await _scrapbookBox.put(_scrapbook!.id, _scrapbook!);
      setState(() {});
    }
  }

  Future<void> _reorderPages(int oldIndex, int newIndex) async {
    if (_scrapbook == null) return;

    final ids = List<String>.from(_scrapbook!.pageProjectIds);
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);

    _scrapbook = _scrapbook!.copyWith(pageProjectIds: ids);
    await _scrapbookBox.put(_scrapbook!.id, _scrapbook!);
    setState(() {});
  }

  Future<void> _editPage(String projectId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosterMakerScreen(
          projectId: projectId,
          scrapbookId: widget.scrapbookId,
        ),
      ),
    );
    // Refresh the state when returning from poster maker
    if (mounted) {
      print('Returning from poster maker, refreshing scrapbook manager...');

      // Force reload scrapbook data to ensure fresh state
      _load();

      // Also refresh thumbnails to ensure they're up to date
      await _refreshThumbnails();

      // Add a small delay to ensure all updates are processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Force a rebuild to show updated images
      setState(() {});

      print('Scrapbook manager refreshed successfully');
    }
  }

  void _openFlipBookView() async {
    if (_scrapbook == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScrapbookFlipBookView(scrapbook: _scrapbook!),
      ),
    );
    // Refresh when returning from flip book view
    if (mounted) {
      await _refreshThumbnails();
    }
  }

  void _showLoadPageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Load Page',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Choose how you want to add a new page',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 24.h),
            _buildLoadOption(
              icon: Icons.dashboard_outlined,
              title: 'From Template',
              subtitle: 'Choose from scrapbook templates',
              onTap: () {
                Navigator.pop(context);
                _navigateToTemplateScreen();
              },
            ),
            SizedBox(height: 12.h),
            _buildLoadOption(
              icon: Icons.folder_outlined,
              title: 'From Storage',
              subtitle: 'Load a .lamlayers file from device',
              onTap: () {
                Navigator.pop(context);
                _loadPageFromStorage();
              },
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: const Color(0xFFEC4899), size: 24.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF94A3B8),
                size: 16.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPageFromTemplate(PosterProject templateProject) async {
    if (_scrapbook == null) return;

    // Validate canvas size matches scrapbook's canvas size
    if (templateProject.canvasWidth != _scrapbook!.pageWidth ||
        templateProject.canvasHeight != _scrapbook!.pageHeight) {
      _showErrorMessage(
        'Template does not match the scrapbook page size (${_scrapbook!.pageWidth.toInt()}x${_scrapbook!.pageHeight.toInt()}).',
      );
      return;
    }

    // Create a new page based on the template
    final page = PosterProject(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Page ${_scrapbook!.pageProjectIds.length - 1}',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      canvasItems: templateProject.canvasItems,
      settings: templateProject.settings,
      canvasWidth: _scrapbook!.pageWidth, // Use scrapbook's canvas size
      canvasHeight: _scrapbook!.pageHeight, // Use scrapbook's canvas size
      canvasBackgroundColor: templateProject.canvasBackgroundColor,
      backgroundImagePath: templateProject.backgroundImagePath,
    );

    await _projectBox.put(page.id, page);
    final ids = List<String>.from(_scrapbook!.pageProjectIds);
    ids.insert(ids.length - 1, page.id);
    _scrapbook = _scrapbook!.copyWith(pageProjectIds: ids);
    await _scrapbookBox.put(_scrapbook!.id, _scrapbook!);
    setState(() {});

    // Navigate to edit the new page
    _editPage(page.id);
  }

  Future<void> _loadPageFromStorage() async {
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
          builder: (context) => _buildLoadingDialog('Loading page...'),
        );

        try {
          final PosterProject? project = await ExportManager.loadProject(
            filePath,
          );

          if (!mounted) return;
          Navigator.of(context).pop();

          if (project != null) {
            // Validate canvas size matches scrapbook's canvas size
            if (project.canvasWidth != _scrapbook!.pageWidth ||
                project.canvasHeight != _scrapbook!.pageHeight) {
              _showErrorMessage(
                'Template does not match the scrapbook page size (${_scrapbook!.pageWidth.toInt()}x${_scrapbook!.pageHeight.toInt()}).',
              );
              return;
            }

            await _addPageFromTemplate(project);
            _showSuccessMessage('Page loaded successfully!');
          } else {
            _showErrorMessage(
              'Failed to load page. The file may be corrupted or incomplete.',
            );
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.of(context).pop();
          _showErrorMessage('Error loading page: ${e.toString()}');
        }
      }
    } catch (e) {
      _showErrorMessage('Error selecting file: ${e.toString()}');
    }
  }

  Widget _buildLoadingDialog(String message) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFEC4899),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
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
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  Widget _previewFor(String projectId) {
    return ValueListenableBuilder<Box<PosterProject>>(
      valueListenable: _projectBox.listenable(),
      builder: (context, box, child) {
        final project = box.get(projectId);
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
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: const Color(0xFF94A3B8),
                size: 48.r,
              ),
            ),
          );
        }

        // Try thumbnail first, then background image
        String? imagePath = project.thumbnailPath;
        if (imagePath == null ||
            imagePath.isEmpty ||
            !File(imagePath).existsSync()) {
          imagePath = project.backgroundImagePath;
        }

        if (imagePath == null ||
            imagePath.isEmpty ||
            !File(imagePath).existsSync()) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: const Color(0xFF94A3B8),
                size: 48.r,
              ),
            ),
          );
        }

        // Use a unique key to force image refresh when file changes
        return Image.file(
          File(imagePath),
          key: ValueKey(
            '${projectId}_${project.lastModified.millisecondsSinceEpoch}',
          ),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If image fails to load, show placeholder
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 48.r,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPageCard(String projectId, int index) {
    final pageNumber = 'Page ${index + 1}';

    return GestureDetector(
      onTap: () => _editPage(projectId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Preview
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    child: _previewFor(projectId),
                  ),
                  // Menu button - show for all pages now
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'duplicate') _duplicatePage(index);
                          if (v == 'delete') _deletePage(index);
                        },
                        icon: Icon(
                          Icons.more_horiz,
                          size: 18.r,
                          color: const Color(0xFF64748B),
                        ),
                        tooltip: 'More options',
                        elevation: 6,
                        color: Colors.white,
                        shadowColor: Colors.black.withOpacity(0.08),
                        surfaceTintColor: Colors.transparent,
                        offset: Offset(0, 6.h),
                        constraints: BoxConstraints(minWidth: 170.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'duplicate',
                            height: 40.h,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.content_copy,
                                  size: 18.r,
                                  color: const Color(0xFF64748B),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Duplicate',
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
            ),
            // Page number
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                pageNumber,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPageCard() {
    return GestureDetector(
      onTap: _addPage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFEC4899),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: const Color(0xFFEC4899),
                size: 32.r,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'New Page',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListPageItem(String projectId, int index) {
    final isCover = index == 0;
    final isBack = index == _scrapbook!.pageProjectIds.length - 1;
    final pageNumber = 'Page ${index + 1}';

    return Container(
      key: ValueKey(projectId),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editPage(projectId),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Drag handle - show for all pages now
                Container(
                  margin: EdgeInsets.only(right: 12.w),
                  child: Icon(
                    Icons.drag_handle,
                    color: const Color(0xFF94A3B8),
                    size: 20.r,
                  ),
                ),
                // Page preview
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: _previewFor(projectId),
                  ),
                ),
                SizedBox(width: 16.w),
                // Page info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageNumber,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isCover
                            ? 'Front cover of your scrapbook'
                            : isBack
                            ? 'Back cover of your scrapbook'
                            : 'Page content',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu button - show for all pages now
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'duplicate') _duplicatePage(index);
                      if (v == 'delete') _deletePage(index);
                    },
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18.r,
                      color: const Color(0xFF64748B),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.content_copy,
                              size: 18.r,
                              color: const Color(0xFF64748B),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Duplicate',
                              style: GoogleFonts.inter(fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPageListItem() {
    return Container(
      key: const ValueKey('new_page_item'),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFEC4899),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addPage,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.add,
                    color: const Color(0xFFEC4899),
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Page',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Create a new page for your scrapbook',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_scrapbook == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Scrapbooks',
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
                  Icons.collections_bookmark_rounded,
                  size: 64.r,
                  color: const Color(0xFFEC4899),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'No scrapbook yet',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
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

    final ids = _scrapbook!.pageProjectIds;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _scrapbook!.name,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu_book_rounded, color: const Color(0xFF64748B)),
            onPressed: () => _openFlipBookView(),
            tooltip: 'View as Flip Book',
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: const Color(0xFF64748B),
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.upload_rounded,
                color: Colors.white,
                size: 20.r,
              ),
            ),
            onPressed: _showLoadPageOptions,
            tooltip: 'Load Page',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: _isGridView
            ? GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 1,
                ),
                itemCount: ids.length + 1,
                itemBuilder: (context, index) {
                  if (index == ids.length) {
                    return _buildNewPageCard();
                  }
                  return _buildPageCard(ids[index], index);
                },
              )
            : ReorderableListView.builder(
                padding: EdgeInsets.zero,
                itemCount: ids.length + 1,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  if (oldIndex == ids.length || newIndex == ids.length) {
                    return; // Don't reorder the "Add New Page" item
                  }
                  _reorderPages(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  if (index == ids.length) {
                    return _buildNewPageListItem();
                  }
                  return _buildListPageItem(ids[index], index);
                },
              ),
      ),
    );
  }
}
