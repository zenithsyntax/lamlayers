import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';
import 'package:lamlayers/screens/canvas_preset_screen.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:file_picker/file_picker.dart';

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

  Future<void> _loadProjectFromStorage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final selectedPath = result?.files.single.path;
    if (selectedPath == null) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PosterMakerScreen(initialBackgroundImagePath: selectedPath),
      ),
    );
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
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
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: _buildProjectPreviewImage(project),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project?.name ?? 'Unnamed Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project?.description ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
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
            right: 4,
            top: 4,
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

  Widget _templateCard(String title, Color color) {
    return Container(
      width: 160,
      height: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
          size: 48,
          color: const Color(0xFFBDBDBD),
        ),
      );
    }

    final file = File(toShow);
    if (!file.existsSync()) {
      return Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
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
            size: 40,
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
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE0E0E0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _actionButton(
                    title: 'Create New',
                    icon: Icons.add_circle_outline,
                    onTap: _createNewProject,
                    color: const Color(0xFF42A5F5),
                  ),
                  const SizedBox(width: 12),
                  _actionButton(
                    title: 'Load from Storage',
                    icon: Icons.folder_open,
                    onTap: _loadProjectFromStorage,
                    color: const Color(0xFF66BB6A),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recent Projects Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'My Recent Projects',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (!_isBoxReady)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading projects...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
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
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 48,
                              color: const Color(0xFFBDBDBD),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No projects yet',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new project to get started!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: box.length,
                      itemBuilder: (context, index) {
                        final project = box.getAt(index);
                        return _projectCard(project);
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // Templates Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Templates',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _templateCard('Template 1', const Color(0xFF42A5F5)),
                  _templateCard('Template 2', const Color(0xFF5C6BC0)),
                  _templateCard('Template 3', const Color(0xFF7E57C2)),
                  _templateCard('Template 4', const Color(0xFF26C6DA)),
                  _templateCard('Template 5', const Color(0xFF66BB6A)),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
