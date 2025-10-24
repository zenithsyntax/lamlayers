import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/template_models.dart';
import '../services/template_api_service.dart';
import '../screens/hive_model.dart';
import '../utils/export_manager.dart';

class ScrapbookTemplateScreen extends StatefulWidget {
  final Function(PosterProject) onTemplateSelected;
  final double requiredCanvasWidth;
  final double requiredCanvasHeight;

  const ScrapbookTemplateScreen({
    Key? key,
    required this.onTemplateSelected,
    this.requiredCanvasWidth = 1080,
    this.requiredCanvasHeight = 1920,
  }) : super(key: key);

  @override
  State<ScrapbookTemplateScreen> createState() =>
      _ScrapbookTemplateScreenState();
}

class _ScrapbookTemplateScreenState extends State<ScrapbookTemplateScreen> {
  List<Template> templates = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && currentPage < totalPages) {
        _loadMoreTemplates();
      }
    }
  }

  Future<void> _loadTemplates({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        templates.clear();
        errorMessage = null;
      });
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await TemplateApiService.getScrapbookTemplates(
        page: currentPage,
        limit: 10,
      );

      setState(() {
        if (refresh) {
          templates = response.results;
        } else {
          templates.addAll(response.results);
        }
        totalPages = response.totalPages;
        isLoading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreTemplates() async {
    if (isLoadingMore || currentPage >= totalPages) return;

    setState(() {
      isLoadingMore = true;
      currentPage++;
    });

    try {
      final response = await TemplateApiService.getScrapbookTemplates(
        page: currentPage,
        limit: 10,
      );

      setState(() {
        templates.addAll(response.results);
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        currentPage--; // Revert page increment on error
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadTemplate(Template template) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog('Downloading template...'),
    );

    try {
      // Download template file
      final String filePath = await TemplateApiService.downloadTemplate(
        template.templateFile,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Show loading dialog for parsing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLoadingDialog('Loading template...'),
      );

      // Load the project using ExportManager
      final PosterProject? project = await ExportManager.loadProject(filePath);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (project != null) {
        // Validate canvas size matches required scrapbook canvas size
        if (project.canvasWidth != widget.requiredCanvasWidth ||
            project.canvasHeight != widget.requiredCanvasHeight) {
          _showErrorMessage(
            'Template does not match the required page size (${widget.requiredCanvasWidth.toInt()}x${widget.requiredCanvasHeight.toInt()}).',
          );
          return;
        }

        // Call the callback with the loaded project
        widget.onTemplateSelected(project);

        // Navigate back to scrapbook manager
        Navigator.pop(context);

        _showSuccessMessage('Template loaded successfully!');
      } else {
        _showErrorMessage(
          'Failed to load template. The file may be corrupted or incomplete.\n\nPossible causes:\n• Template file was not fully downloaded\n• Template was created with an older version\n• Template structure is invalid\n\nPlease try again or contact support if the issue persists.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorMessage('Error loading template: ${e.toString()}');
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

  Widget _buildTemplateCard(Template template) {
    return GestureDetector(
      onTap: () => _loadTemplate(template),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: CachedNetworkImage(
          imageUrl: template.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFFF1F5F9),
            child: const Icon(
              Icons.image_not_supported,
              color: Color(0xFF94A3B8),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    if (templates.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: 64.w,
              color: const Color(0xFF94A3B8),
            ),
            SizedBox(height: 16.h),
            Text(
              'No lambook templates found',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try refreshing the page',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      itemCount: templates.length + (isLoadingMore ? 1 : 0),
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemBuilder: (context, index) {
        if (index == templates.length) {
          return Container(
            height: 50.h,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
          );
        }

        final template = templates[index];
        return _buildTemplateCard(template);
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Lambook Templates',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTemplates(refresh: true),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
        ),
      ),
      body: isLoading && templates.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            )
          : errorMessage != null && templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.w,
                    color: const Color(0xFFEF4444),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Failed to load templates',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => _loadTemplates(refresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _buildTemplatesGrid(),
    );
  }
}
