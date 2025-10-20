import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

// Cloudfair Sticker Model
class CloudfairSticker {
  final int stickerId;
  final String stickerUrl;

  CloudfairSticker({required this.stickerId, required this.stickerUrl});

  // Getter for backward compatibility
  String get id => stickerId.toString();
  String get imageUrl => stickerUrl;

  factory CloudfairSticker.fromJson(Map<String, dynamic> json) {
    return CloudfairSticker(
      stickerId: json['sticker_id'] ?? 0,
      stickerUrl: json['sticker_url'] ?? '',
    );
  }
}

// Cloudfair API Response Model
class CloudfairResponse {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<CloudfairSticker> results;

  CloudfairResponse({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.results,
  });

  factory CloudfairResponse.fromJson(Map<String, dynamic> json) {
    return CloudfairResponse(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      results:
          (json['results'] as List?)
              ?.map((item) => CloudfairSticker.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// In-memory favorites manager
class ImageFavorites {
  static final ImageFavorites _instance = ImageFavorites._internal();
  factory ImageFavorites() => _instance;
  ImageFavorites._internal();

  static ImageFavorites get instance => _instance;

  final Set<int> _likedImageIds = <int>{};
  final Set<String> _likedStickerIds = <String>{};

  bool isLiked(int imageId) => _likedImageIds.contains(imageId);
  bool isStickerLiked(String stickerId) => _likedStickerIds.contains(stickerId);

  void add(int imageId) => _likedImageIds.add(imageId);
  void addSticker(String stickerId) => _likedStickerIds.add(stickerId);

  void remove(int imageId) => _likedImageIds.remove(imageId);
  void removeSticker(String stickerId) => _likedStickerIds.remove(stickerId);

  Set<int> get likedImageIds => Set.unmodifiable(_likedImageIds);
  Set<String> get likedStickerIds => Set.unmodifiable(_likedStickerIds);
}

class PixabayImagesPage extends StatefulWidget {
  const PixabayImagesPage({super.key});

  @override
  State<PixabayImagesPage> createState() => _PixabayImagesPageState();
}

class _PixabayImagesPageState extends State<PixabayImagesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _apiKey = '52459319-dd5d01b2bb7f2a492c8302f54';
  final String _cloudfairApiUrl =
      'https://autumn-heart-6d34.zenithsyntax.workers.dev/stickers';

  // Professional Color Scheme - matching Settings and Fonts page
  static const Color _primaryPink = Color(0xFFEC4899);
  static const Color _surfaceGray = Color(0xFFF1F5F9);
  static const Color _cardBackground = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _dividerColor = Color(0xFFE2E8F0);

  // Pixabay data
  List<PixabayImage> _allImages = [];
  List<PixabayImage> _filteredImages = [];
  List<PixabayImage> _likedImages = [];
  int _currentPage = 1;
  final int _imagesPerPage = 20;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _showLikedList = false;
  String _currentSearchQuery = '';

  // Cloudfair stickers data
  List<CloudfairSticker> _allStickers = [];
  List<CloudfairSticker> _likedStickers = [];
  int _currentStickerPage = 1;
  final int _stickersPerPage = 20;
  int _totalStickerPages = 1;
  bool _isLoadingStickers = false;
  bool _showLikedStickers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchImages();
    _fetchStickers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text != _currentSearchQuery) {
      _currentSearchQuery = _searchController.text;
      _currentPage = 1;
      _fetchImages();
    }
  }

  Future<void> _fetchImages() async {
    if (_showLikedList) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String searchQuery = _currentSearchQuery.isEmpty
          ? 'nature'
          : _currentSearchQuery;

      final response = await http.get(
        Uri.parse(
          'https://pixabay.com/api/?key=$_apiKey'
          '&q=${Uri.encodeComponent(searchQuery)}'
          '&image_type=photo'
          '&orientation=all'
          '&min_width=640'
          '&min_height=480'
          '&per_page=$_imagesPerPage'
          '&page=$_currentPage'
          '&safesearch=true',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final images = (data['hits'] as List)
            .map((image) => PixabayImage.fromJson(image))
            .toList();

        setState(() {
          _allImages = images;
          _filteredImages = images;
          _totalPages = (data['totalHits'] / _imagesPerPage).ceil();
          _isLoading = false;
        });
      } else {
        _loadSampleImages();
      }
    } catch (e) {
      _loadSampleImages();
    }

    // Scroll to top when new images load
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _loadSampleImages() {
    final sampleImages = List.generate(
      12,
      (index) => PixabayImage(
        id: index + 1,
        webformatURL: 'https://picsum.photos/640/480?random=$index',
        previewURL: 'https://picsum.photos/150/150?random=$index',
        tags: 'nature, landscape, mountain',
        user: 'photographer${index + 1}',
        views: 1250 + (index * 100),
        downloads: 450 + (index * 50),
        likes: 89 + (index * 10),
      ),
    );

    setState(() {
      _allImages = sampleImages;
      _filteredImages = sampleImages;
      _totalPages = 5;
      _isLoading = false;
    });
  }

  Future<void> _fetchStickers() async {
    if (_showLikedStickers) return;

    setState(() {
      _isLoadingStickers = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$_cloudfairApiUrl?page=$_currentStickerPage&limit=$_stickersPerPage',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cloudfairResponse = CloudfairResponse.fromJson(data);

        setState(() {
          _allStickers = cloudfairResponse.results;
          _totalStickerPages = cloudfairResponse.totalPages;
          _isLoadingStickers = false;
        });
      } else {
        _loadSampleStickers();
      }
    } catch (e) {
      _loadSampleStickers();
    }
  }

  void _loadSampleStickers() {
    final sampleStickers = List.generate(
      8,
      (index) => CloudfairSticker(
        stickerId: index + 1,
        stickerUrl: 'https://picsum.photos/300/300?random=${index + 100}',
      ),
    );

    setState(() {
      _allStickers = sampleStickers;
      _totalStickerPages = 3;
      _isLoadingStickers = false;
    });
  }

  void _toggleLikeImage(PixabayImage image) {
    setState(() {
      final isLiked = ImageFavorites.instance.isLiked(image.id);
      if (isLiked) {
        ImageFavorites.instance.remove(image.id);
        _likedImages.removeWhere((img) => img.id == image.id);
      } else {
        ImageFavorites.instance.add(image.id);
        if (!_likedImages.any((img) => img.id == image.id)) {
          _likedImages.add(image);
        }
      }
    });
  }

  void _toggleLikeSticker(CloudfairSticker sticker) {
    setState(() {
      final isLiked = ImageFavorites.instance.isStickerLiked(sticker.id);
      if (isLiked) {
        ImageFavorites.instance.removeSticker(sticker.id);
        _likedStickers.removeWhere((s) => s.id == sticker.id);
      } else {
        ImageFavorites.instance.addSticker(sticker.id);
        if (!_likedStickers.any((s) => s.id == sticker.id)) {
          _likedStickers.add(sticker);
        }
      }
    });
  }

  List<PixabayImage> _getCurrentPageImages() {
    return _showLikedList ? _likedImages : _filteredImages;
  }

  List<CloudfairSticker> _getCurrentPageStickers() {
    return _showLikedStickers ? _likedStickers : _allStickers;
  }

  void _goToStickerPage(int page) {
    if (page < 1 || page > _totalStickerPages || page == _currentStickerPage)
      return;
    setState(() {
      _currentStickerPage = page;
    });
    _fetchStickers();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    setState(() {
      _currentPage = page;
    });
    _fetchImages();
  }

  void _addImageToCanvas(PixabayImage image) {
    Navigator.pop(context, image);
  }

  void _addStickerToCanvas(CloudfairSticker sticker) {
    Navigator.pop(context, sticker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 70.h,
        leading: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _surfaceGray,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _textPrimary,
              size: 20.r,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Images & Stickers',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Discover beautiful images and stickers',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primaryPink,
          indicatorWeight: 3,
          labelColor: _textPrimary,
          unselectedLabelColor: _textSecondary,
          labelStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Stickers'),
            Tab(text: 'Pixabay'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [_buildStickersTab(), _buildPixabayTab()],
        ),
      ),
    );
  }

  Widget _buildStickersTab() {
    return Column(
      children: [
        // Search Bar for Stickers
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: _dividerColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search stickers...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8.h,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: _textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showLikedStickers = !_showLikedStickers;
                    if (_showLikedStickers) {
                      final likedIds = ImageFavorites.instance.likedStickerIds;
                      _likedStickers = _allStickers
                          .where((sticker) => likedIds.contains(sticker.id))
                          .toList();
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: _showLikedStickers
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                          )
                        : null,
                    color: _showLikedStickers ? null : _surfaceGray,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _showLikedStickers
                          ? Colors.transparent
                          : _dividerColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: _showLikedStickers
                            ? Colors.white
                            : _textSecondary,
                        size: 18.r,
                      ),
                      if (_showLikedStickers && _likedStickers.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${_likedStickers.length}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Stickers Content
        Expanded(
          child: _isLoadingStickers && _allStickers.isEmpty
              ? _buildStickersShimmerGrid()
              : _getCurrentPageStickers().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          _showLikedStickers
                              ? Icons.favorite_border_rounded
                              : Icons.emoji_emotions_rounded,
                          size: 32.r,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        _showLikedStickers
                            ? 'No liked stickers yet'
                            : 'No stickers found',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _showLikedStickers
                            ? 'Start liking stickers to see them here'
                            : 'Try refreshing or check your connection',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  padding: EdgeInsets.all(16.w),
                  itemCount: _getCurrentPageStickers().length,
                  itemBuilder: (context, index) {
                    final sticker = _getCurrentPageStickers()[index];
                    final isLiked = ImageFavorites.instance.isStickerLiked(
                      sticker.id,
                    );

                    return GestureDetector(
                      onTap: () => _addStickerToCanvas(sticker),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _cardBackground,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isLiked
                                ? _primaryPink.withOpacity(0.3)
                                : _dividerColor,
                            width: isLiked ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15.r),
                              child: CachedNetworkImage(
                                imageUrl: sticker.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildImageShimmer(),
                                errorWidget: (context, url, error) => Container(
                                  height: 200.h,
                                  color: _surfaceGray,
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    size: 40.w,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ),

                            // Like Button
                            Positioned(
                              top: 8.h,
                              right: 8.w,
                              child: GestureDetector(
                                onTap: () => _toggleLikeSticker(sticker),
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
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
                                  child: Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isLiked
                                        ? _primaryPink
                                        : _textSecondary,
                                    size: 18.w,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Stickers Pagination
        if (!_showLikedStickers && _totalStickerPages > 1)
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous Button
                Expanded(
                  child: Container(
                    height: 44.h,
                    child: ElevatedButton.icon(
                      onPressed: _currentStickerPage > 1
                          ? () => _goToStickerPage(_currentStickerPage - 1)
                          : null,
                      icon: Icon(Icons.chevron_left_rounded, size: 18.w),
                      label: Text(
                        'Previous',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStickerPage > 1
                            ? _primaryPink
                            : _dividerColor,
                        foregroundColor: _currentStickerPage > 1
                            ? Colors.white
                            : _textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Page Indicator
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPink.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$_currentStickerPage of $_totalStickerPages',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Next Button
                Expanded(
                  child: Container(
                    height: 44.h,
                    child: ElevatedButton.icon(
                      onPressed: _currentStickerPage < _totalStickerPages
                          ? () => _goToStickerPage(_currentStickerPage + 1)
                          : null,
                      label: Text(
                        'Next',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(Icons.chevron_right_rounded, size: 18.w),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentStickerPage < _totalStickerPages
                            ? _primaryPink
                            : _dividerColor,
                        foregroundColor:
                            _currentStickerPage < _totalStickerPages
                            ? Colors.white
                            : _textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPixabayTab() {
    return Column(
      children: [
        // Search Bar for Pixabay
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: _dividerColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search images...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 18.r,
                              color: _textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _currentSearchQuery = '';
                              _currentPage = 1;
                              _fetchImages();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8.h,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: _textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showLikedList = !_showLikedList;
                    if (_showLikedList) {
                      final likedIds = ImageFavorites.instance.likedImageIds;
                      _likedImages = _allImages
                          .where((img) => likedIds.contains(img.id))
                          .toList();
                    }
                  });
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: _showLikedList
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                          )
                        : null,
                    color: _showLikedList ? null : _surfaceGray,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _showLikedList
                          ? Colors.transparent
                          : _dividerColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: _showLikedList ? Colors.white : _textSecondary,
                        size: 18.r,
                      ),
                      if (_showLikedList && _likedImages.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${_likedImages.length}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Pixabay Content
        Expanded(
          child: _isLoading && _allImages.isEmpty
              ? _buildShimmerGrid()
              : _getCurrentPageImages().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          _showLikedList
                              ? Icons.favorite_border_rounded
                              : Icons.image_search_rounded,
                          size: 32.r,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        _showLikedList
                            ? 'No liked images yet'
                            : 'No images found',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _showLikedList
                            ? 'Start liking images to see them here'
                            : 'Try adjusting your search terms',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : MasonryGridView.count(
                  controller: _scrollController,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  padding: EdgeInsets.all(16.w),
                  itemCount: _getCurrentPageImages().length,
                  itemBuilder: (context, index) {
                    final image = _getCurrentPageImages()[index];
                    final isLiked = ImageFavorites.instance.isLiked(image.id);

                    return GestureDetector(
                      onTap: () => _addImageToCanvas(image),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _cardBackground,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isLiked
                                ? _primaryPink.withOpacity(0.3)
                                : _dividerColor,
                            width: isLiked ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15.r),
                              child: CachedNetworkImage(
                                imageUrl: image.webformatURL,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildImageShimmer(),
                                errorWidget: (context, url, error) => Container(
                                  height: 200.h,
                                  color: _surfaceGray,
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    size: 40.w,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ),

                            // Like Button
                            Positioned(
                              top: 8.h,
                              right: 8.w,
                              child: GestureDetector(
                                onTap: () => _toggleLikeImage(image),
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
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
                                  child: Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isLiked
                                        ? _primaryPink
                                        : _textSecondary,
                                    size: 18.w,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Pixabay Pagination
        if (!_showLikedList && _totalPages > 1)
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous Button
                Expanded(
                  child: Container(
                    height: 44.h,
                    child: ElevatedButton.icon(
                      onPressed: _currentPage > 1
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                      icon: Icon(Icons.chevron_left_rounded, size: 18.w),
                      label: Text(
                        'Previous',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage > 1
                            ? _primaryPink
                            : _dividerColor,
                        foregroundColor: _currentPage > 1
                            ? Colors.white
                            : _textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Page Indicator
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPink.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$_currentPage of $_totalPages',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Next Button
                Expanded(
                  child: Container(
                    height: 44.h,
                    child: ElevatedButton.icon(
                      onPressed: _currentPage < _totalPages
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                      label: Text(
                        'Next',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(Icons.chevron_right_rounded, size: 18.w),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage < _totalPages
                            ? _primaryPink
                            : _dividerColor,
                        foregroundColor: _currentPage < _totalPages
                            ? Colors.white
                            : _textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      padding: EdgeInsets.all(16.w),
      itemCount: 6, // Show 6 shimmer items
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildStickersShimmerGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      padding: EdgeInsets.all(16.w),
      itemCount: 8, // Show 8 shimmer items for stickers
      itemBuilder: (context, index) {
        return _buildStickerShimmerCard();
      },
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: _surfaceGray,
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: _surfaceGray,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerShimmerCard() {
    return Shimmer.fromColors(
      baseColor: _surfaceGray,
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _dividerColor, width: 1),
        ),
        child: Stack(
          children: [
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: _surfaceGray,
                borderRadius: BorderRadius.circular(15.r),
              ),
            ),
            // Shimmer for sticker info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60.h,
                decoration: BoxDecoration(
                  color: _surfaceGray,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15.r),
                    bottomRight: Radius.circular(15.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: _surfaceGray,
      highlightColor: Colors.white,
      child: Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: _surfaceGray,
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
    );
  }
}

// Models
class PixabayImage {
  final int id;
  final String webformatURL;
  final String previewURL;
  final String tags;
  final String user;
  final int views;
  final int downloads;
  final int likes;

  PixabayImage({
    required this.id,
    required this.webformatURL,
    required this.previewURL,
    required this.tags,
    required this.user,
    required this.views,
    required this.downloads,
    required this.likes,
  });

  factory PixabayImage.fromJson(Map<String, dynamic> json) {
    return PixabayImage(
      id: json['id'] ?? 0,
      webformatURL: json['webformatURL'] ?? '',
      previewURL: json['previewURL'] ?? '',
      tags: json['tags'] ?? '',
      user: json['user'] ?? 'Unknown',
      views: json['views'] ?? 0,
      downloads: json['downloads'] ?? 0,
      likes: json['likes'] ?? 0,
    );
  }
}
