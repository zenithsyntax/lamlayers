import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';
import 'package:lamlayers/screens/canvas_preset_screen.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MyDesignsScreen extends StatefulWidget {
  const MyDesignsScreen({Key? key}) : super(key: key);

  @override
  State<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends State<MyDesignsScreen> {
  late Box<PosterProject> _projectBox;
  bool _isBoxReady = false;

  @override
  void initState() {
    super.initState();
    _openProjectBox();
  }

  Future<void> _openProjectBox() async {
    _projectBox = await Hive.openBox<PosterProject>('posterProjects');
    setState(() {
      _isBoxReady = true;
    });
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

  Widget _actionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32.r),
              SizedBox(height: 8.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameProject(PosterProject project) async {
    final controller = TextEditingController(text: project.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Project', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
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
      builder: (ctx) => AlertDialog(
        title: Text('Delete Project', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete "${project.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _projectBox.delete(project.id);
    }
  }

  Widget _projectCard(PosterProject? project) {
    return Container(
      width: 160.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.w),
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
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                    child: _buildProjectPreviewImage(project),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project?.name ?? 'Unnamed Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        project?.description ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4.w,
            top: 4.h,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (project == null) return;
                if (value == 'rename') {
                  _renameProject(project);
                } else if (value == 'delete') {
                  _deleteProject(project);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename', style: GoogleFonts.poppins()),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(String title, Color color, {double? height}) {
    return Container(
      height: height != null ? height.h : null,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectPreviewImage(PosterProject? project) {
    final String? thumbnailPath = project?.thumbnailPath;
    final String? bgPath = project?.backgroundImagePath;

    final String? toShow = (thumbnailPath != null && thumbnailPath.isNotEmpty)
        ? thumbnailPath
        : (bgPath != null && bgPath.isNotEmpty ? bgPath : null);

    if (toShow == null) {
      return Center(
        child: Icon(
          Icons.image_outlined,
          size: 48.r,
          color: const Color(0xFFBDBDBD),
        ),
      );
    }

    final file = File(toShow);
    if (!file.existsSync()) {
      return Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40.r,
          color: const Color(0xFFBDBDBD),
        ),
      );
    }

    return Image.file(
      file,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 40.r,
            color: const Color(0xFFBDBDBD),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'My Designs',
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

            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  _actionButton(
                    title: 'Create New',
                    icon: Icons.add_circle_outline,
                    onTap: _createNewProject,
                    color: const Color(0xFF42A5F5),
                  ),
                  SizedBox(width: 12.w),
                  _actionButton(
                    title: 'Load from Storage',
                    icon: Icons.folder_open,
                    onTap: () {},
                    color: const Color(0xFF66BB6A),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Recent Projects Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'My Recent Projects',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            if (!_isBoxReady)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1.w,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Loading projects...',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: const Color(0xFF666666),
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
                  if (box.isEmpty) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(32.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1.w,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 48.r,
                              color: const Color(0xFFBDBDBD),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No projects yet',
                              style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Create a new project to get started!',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 220.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: box.length,
                      itemBuilder: (context, index) {
                        final project = box.getAt(index);
                        return _projectCard(project);
                      },
                    ),
                  );
                },
              ),

            SizedBox(height: 32.h),

            // Templates Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'Templates',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              itemBuilder: (context, index) {
                final List<double> heights = [
                  180,
                  220,
                  160,
                  240,
                  200,
                  150,
                  210,
                  170,
                ];
                final List<Map<String, dynamic>> items = [
                  {'title': 'Template 1', 'color': const Color(0xFF42A5F5)},
                  {'title': 'Template 2', 'color': const Color(0xFF5C6BC0)},
                  {'title': 'Template 3', 'color': const Color(0xFF7E57C2)},
                  {'title': 'Template 4', 'color': const Color(0xFF26C6DA)},
                  {'title': 'Template 5', 'color': const Color(0xFF66BB6A)},
                  {'title': 'Template 6', 'color': const Color(0xFFFF7043)},
                  {'title': 'Template 7', 'color': const Color(0xFFAB47BC)},
                  {'title': 'Template 8', 'color': const Color(0xFF26A69A)},
                ];
                final item = items[index % items.length];
                return _templateCard(
                  item['title'] as String,
                  item['color'] as Color,
                  height: heights[index % heights.length],
                );
              },
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
