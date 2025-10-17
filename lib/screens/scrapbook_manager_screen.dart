import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';
import 'package:lamlayers/screens/scrapbook_flip_book_view.dart';

class ScrapbookManagerScreen extends StatefulWidget {
  final String? scrapbookId;
  const ScrapbookManagerScreen({Key? key, this.scrapbookId}) : super(key: key);

  @override
  State<ScrapbookManagerScreen> createState() => _ScrapbookManagerScreenState();
}

class _ScrapbookManagerScreenState extends State<ScrapbookManagerScreen> {
  late Box<Scrapbook> _scrapbookBox;
  late Box<PosterProject> _projectBox;
  Scrapbook? _scrapbook;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _scrapbookBox = Hive.box<Scrapbook>('scrapbooks');
    _projectBox = Hive.box<PosterProject>('posterProjects');
    _load();
  }

  void _load() {
    if (widget.scrapbookId != null) {
      _scrapbook = _scrapbookBox.get(widget.scrapbookId);
    } else if (_scrapbookBox.isNotEmpty) {
      _scrapbook = _scrapbookBox.getAt(0);
    }
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
    if (index == 0 || index == _scrapbook!.pageProjectIds.length - 1) return;
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
    if (index == 0 || index == _scrapbook!.pageProjectIds.length - 1) return;

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

    // Don't allow reordering cover (index 0) and back (last index) pages
    if (oldIndex == 0 || oldIndex == _scrapbook!.pageProjectIds.length - 1)
      return;
    if (newIndex == 0 || newIndex == _scrapbook!.pageProjectIds.length - 1)
      return;

    final ids = List<String>.from(_scrapbook!.pageProjectIds);
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);

    _scrapbook = _scrapbook!.copyWith(pageProjectIds: ids);
    await _scrapbookBox.put(_scrapbook!.id, _scrapbook!);
    setState(() {});
  }

  void _editPage(String projectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosterMakerScreen(projectId: projectId),
      ),
    );
  }

  void _openFlipBookView() {
    if (_scrapbook == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScrapbookFlipBookView(scrapbook: _scrapbook!),
      ),
    );
  }

  Widget _previewFor(String projectId) {
    final project = _projectBox.get(projectId);
    final thumb = project?.thumbnailPath ?? project?.backgroundImagePath;
    if (thumb == null || !File(thumb).existsSync()) {
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
    return Image.file(File(thumb), fit: BoxFit.cover);
  }

  Widget _buildPageCard(String projectId, int index) {
    final isCover = index == 0;
    final isBack = index == _scrapbook!.pageProjectIds.length - 1;
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
                  // Menu button
                  if (!isCover && !isBack)
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
    final isDraggable = !isCover && !isBack;

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
                // Drag handle
                if (isDraggable)
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
                // Menu button
                if (isDraggable)
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
              child: Icon(Icons.add, color: Colors.white, size: 20.r),
            ),
            onPressed: _addPage,
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
