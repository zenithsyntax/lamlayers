import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/scrap_book_page_turn/interactive_book.dart';

class ScrapbookFlipBookView extends StatefulWidget {
  final Scrapbook scrapbook;

  const ScrapbookFlipBookView({Key? key, required this.scrapbook})
    : super(key: key);

  @override
  State<ScrapbookFlipBookView> createState() => _ScrapbookFlipBookViewState();
}

class _ScrapbookFlipBookViewState extends State<ScrapbookFlipBookView> {
  late Box<PosterProject> _projectBox;
  late PageTurnController _pageController;
  // Track current page indices for navigation button state
  int _currentLeftPage = 0; // ignore: unused_field
  int _currentRightPage = 1; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    _projectBox = Hive.box<PosterProject>('posterProjects');
    _pageController = PageTurnController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildPageContent(String projectId, int pageIndex) {
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
            ],
          ),
        ),
      );
    }

    // Try to get thumbnail or background image
    final thumb = project.thumbnailPath ?? project.backgroundImagePath;

    if (thumb != null && File(thumb).existsSync()) {
      return Container(
        decoration: BoxDecoration(
          color: project.canvasBackgroundColor.toColor(),
        ),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(child: Image.file(File(thumb), fit: BoxFit.cover)),
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

  @override
  Widget build(BuildContext context) {
    final pageIds = widget.scrapbook.pageProjectIds;
    if (pageIds.isEmpty) {
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
      backgroundColor: const Color(0xFFF1F5F9),

      body: SafeArea(
        child: Center(
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
                              width: MediaQuery.of(context).size.height * 0.82,
                              height: MediaQuery.of(context).size.width * 0.7,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD7B89C,
                                ), // light brown wood-like color
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(4, 4),
                                  ),
                                ],
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
                              height: MediaQuery.of(context).size.width * 0.71,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(
                                  255,
                                  192,
                                  161,
                                  134,
                                ), // light brown wood-like color
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16.r),
                                  topLeft: Radius.circular(16.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.height * 0.8,
                      height: MediaQuery.of(context).size.width * 0.9,
                      child: Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: InteractiveBook(
                            pagesBoundaryIsEnabled: false,

                            controller: _pageController,
                            pageCount: pageIds.length,
                            aspectRatio:
                                (widget.scrapbook.pageWidth * 2) /
                                widget.scrapbook.pageHeight,
                            pageViewMode: PageViewMode.double,
                            onPageChanged: _onPageChanged,
                            settings: FlipSettings(
                              startPageIndex: 0,
                              usePortrait: false,
                            ),
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
                              return _buildPageContent(
                                pageIds[pageIndex],
                                pageIndex,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Navigation buttons
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

                  Positioned(
                    bottom: 20.h,
                    right: 20.w,
                    child: SizedBox(
                      child: Center(
                        child: IconButton(
                          onPressed: _currentRightPage < pageIds.length - 1
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
      ),
    );
  }
}
