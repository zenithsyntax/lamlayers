import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/template_models.dart';
import '../services/template_api_service.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  List<Template> templates = [];
  List<String> categories = [];
  String selectedCategory = 'All';
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    try {
      final categoriesList = await TemplateApiService.getCategories();
      setState(() {
        categories = categoriesList;
      });
    } catch (e) {
      // Handle error silently for categories
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
      final response = await TemplateApiService.getTemplates(
        page: currentPage,
        limit: 10,
        category: selectedCategory == 'All' ? null : selectedCategory,
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
      final response = await TemplateApiService.getTemplates(
        page: currentPage,
        limit: 10,
        category: selectedCategory == 'All' ? null : selectedCategory,
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

  void _onCategoryChanged(String category) {
    setState(() {
      selectedCategory = category;
    });
    _loadTemplates(refresh: true);
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) => _onCategoryChanged(category),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF3B82F6),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(Template template) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: CachedNetworkImage(
                imageUrl: template.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
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
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.category.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Template ${template.id}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              'No templates found',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try selecting a different category',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Templates',
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
      body: Column(
        children: [
          if (categories.isNotEmpty) _buildCategoryFilter(),
          Expanded(
            child: errorMessage != null
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
                          'Error loading templates',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () => _loadTemplates(refresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : isLoading && templates.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  )
                : _buildTemplatesGrid(),
          ),
        ],
      ),
    );
  }
}
