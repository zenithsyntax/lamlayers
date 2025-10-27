import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamlayers/utils/export_manager.dart';
import 'package:lamlayers/scrap_book_page_turn/interactive_book.dart';
import 'package:lamlayers/widgets/canvas_renderer.dart';

class LambookReaderScreen extends StatefulWidget {
  final LambookData lambook;
  const LambookReaderScreen({Key? key, required this.lambook})
    : super(key: key);

  @override
  State<LambookReaderScreen> createState() => _LambookReaderScreenState();
}

class _LambookReaderScreenState extends State<LambookReaderScreen> {
  final PageTurnController _pageTurnController = PageTurnController();
  bool _isControllerReady = false;

  @override
  Widget build(BuildContext context) {
    final meta = widget.lambook.meta;
    final pages = widget.lambook.pages;

    return Scaffold(
      backgroundColor: meta.scaffoldBgColor,
      body: Stack(
        children: [
          if (meta.scaffoldBgImagePath != null &&
              File(meta.scaffoldBgImagePath!).existsSync())
            Positioned.fill(
              child: Image.file(
                File(meta.scaffoldBgImagePath!),
                fit: BoxFit.cover,
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

                    //background book cover
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
                                height: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(4, 4),
                                    ),
                                  ],
                                  color: meta.rightCoverImagePath == null
                                      ? meta.rightCoverColor
                                      : null,
                                  image:
                                      meta.rightCoverImagePath != null &&
                                          File(
                                            meta.rightCoverImagePath!,
                                          ).existsSync()
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(meta.rightCoverImagePath!),
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
                                  color: meta.leftCoverImagePath == null
                                      ? meta.leftCoverColor
                                      : null,
                                  image:
                                      meta.leftCoverImagePath != null &&
                                          File(
                                            meta.leftCoverImagePath!,
                                          ).existsSync()
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(meta.leftCoverImagePath!),
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
                      child: Container(
                        width: MediaQuery.of(context).size.height * 0.8,
                        height: MediaQuery.of(context).size.width * 0.9,
                        child: Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: InteractiveBook(
                              pagesBoundaryIsEnabled: false,
                              controller: _pageTurnController,
                              pageCount: pages.length,
                              aspectRatio:
                                  (meta.pageWidth * 2) / meta.pageHeight,
                              pageViewMode: PageViewMode.double,
                              onPageChanged: (index, __) {
                                setState(() {
                                  _isControllerReady = true;
                                });
                              },
                              settings: FlipSettings(
                                startPageIndex: 0,
                                usePortrait: false,
                                flippingTime: 1200,swipeDistance: 1200
                              ),
                              builder: (context, index, constraints) {
                                if (index >= pages.length) {
                                  print(
                                    'LambookReaderScreen: Index $index >= pages.length ${pages.length}',
                                  );
                                  return Container(color: Colors.white);
                                }
                                final project = pages[index];
                                final thumb =
                                    project.thumbnailPath ??
                                    project.backgroundImagePath;

                                print('=== LAMBOOK READER DEBUG ===');
                                print(
                                  'LambookReaderScreen: Page $index of ${pages.length}',
                                );
                                print(
                                  'LambookReaderScreen: Project name: ${project.name}',
                                );
                                print(
                                  'LambookReaderScreen: Project ID: ${project.id}',
                                );
                                print(
                                  'LambookReaderScreen: Canvas items count: ${project.canvasItems.length}',
                                );
                                print(
                                  'LambookReaderScreen: Canvas size: ${project.canvasWidth}x${project.canvasHeight}',
                                );
                                print(
                                  'LambookReaderScreen: thumbnailPath: ${project.thumbnailPath}',
                                );
                                print(
                                  'LambookReaderScreen: backgroundImagePath: ${project.backgroundImagePath}',
                                );
                                print(
                                  'LambookReaderScreen: thumb (final): $thumb',
                                );

                                if (thumb != null) {
                                  final file = File(thumb);
                                  print(
                                    'LambookReaderScreen: File exists check: ${file.existsSync()}',
                                  );
                                  if (file.existsSync()) {
                                    print(
                                      'LambookReaderScreen: File size: ${file.lengthSync()} bytes',
                                    );
                                  }
                                }
                                print('============================');

                                if (thumb != null && File(thumb).existsSync()) {
                                  print(
                                    'LambookReaderScreen: Page $index - File exists, displaying image',
                                  );
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: project.canvasBackgroundColor
                                          .toColor(),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.file(
                                            File(thumb),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  print(
                                                    'LambookReaderScreen: Page $index - Image load error: $error, falling back to canvas renderer',
                                                  );
                                                  return CanvasRenderer(
                                                    project: project,
                                                    width: constraints.maxWidth,
                                                    height:
                                                        constraints.maxHeight,
                                                  );
                                                },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  print(
                                    'LambookReaderScreen: Page $index - No valid image, using canvas renderer',
                                  );
                                  return CanvasRenderer(
                                    project: project,
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Left/Right page flip buttons overlay
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 50.w, bottom: 10.h),
                        child: _NavButton(
                          icon: Icons.arrow_back_ios_new,
                          onPressed:
                              (_isControllerReady &&
                                  _pageTurnController.hasPreviousPage)
                              ? () {
                                  _pageTurnController.previousPage();
                                }
                              : null,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 50.w, bottom: 10.h),
                        child: _NavButton(
                          icon: Icons.arrow_forward_ios,
                          onPressed:
                              (_isControllerReady &&
                                  _pageTurnController.hasNextPage)
                              ? () {
                                  _pageTurnController.nextPage();
                                }
                              : null,
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
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Icon(
              icon,
              color: const Color.fromARGB(97, 0, 0, 0),
              size: 18.w,
            ),
          ),
        ),
      ),
    );
  }
}