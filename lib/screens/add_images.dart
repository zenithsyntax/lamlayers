import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

// In-memory favorites manager
class ImageFavorites {
  static final ImageFavorites _instance = ImageFavorites._internal();
  factory ImageFavorites() => _instance;
  ImageFavorites._internal();
  
  static ImageFavorites get instance => _instance;
  
  final Set<int> _likedImageIds = <int>{};
  
  bool isLiked(int imageId) => _likedImageIds.contains(imageId);
  
  void add(int imageId) => _likedImageIds.add(imageId);
  
  void remove(int imageId) => _likedImageIds.remove(imageId);
  
  Set<int> get likedImageIds => Set.unmodifiable(_likedImageIds);
}

class PixabayImagesPage extends StatefulWidget {
  const PixabayImagesPage({super.key});

  @override
  State<PixabayImagesPage> createState() => _PixabayImagesPageState();
}

class _PixabayImagesPageState extends State<PixabayImagesPage> {
  final TextEditingController _searchController = TextEditingController();
  final String _apiKey = '52459319-dd5d01b2bb7f2a492c8302f54'; 
  
  // Modern Color Scheme
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFF3B82F6);
  static const Color _accentBlue = Color(0xFF1D4ED8);
  static const Color _surfaceGray = Color(0xFFF8FAFC);
  static const Color _cardBackground = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _dividerColor = Color(0xFFE2E8F0);
  static const Color _borderColor = Color(0xFFCBD5E1);
  
  List<PixabayImage> _allImages = [];
  List<PixabayImage> _filteredImages = [];
  List<PixabayImage> _likedImages = [];
  
  int _currentPage = 1;
  final int _imagesPerPage = 20;
  bool _isLoading = false;
  bool _showLikedList = false;
  bool _showLikedImagesScroll = false; // New flag for the side-scrolling liked images
  String _selectedCategory = 'all';
  String _currentSearchQuery = '';
  
  final List<ImageCategory> _categories = [
    ImageCategory('all', 'All', Icons.apps_rounded),
    ImageCategory('nature', 'Nature', Icons.landscape_rounded),
    ImageCategory('people', 'People', Icons.people_rounded),
    ImageCategory('animals', 'Animals', Icons.pets_rounded),
    ImageCategory('food', 'Food', Icons.restaurant_rounded),
    ImageCategory('travel', 'Travel', Icons.flight_rounded),
    ImageCategory('business', 'Business', Icons.business_rounded),
    ImageCategory('technology', 'Tech', Icons.computer_rounded),
    ImageCategory('sports', 'Sports', Icons.sports_rounded),
    ImageCategory('music', 'Music', Icons.music_note_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      String searchQuery = _currentSearchQuery.isEmpty ? 'nature' : _currentSearchQuery;
      String categoryQuery = _selectedCategory == 'all' ? searchQuery : _selectedCategory;
      
      final response = await http.get(
        Uri.parse(
          'https://pixabay.com/api/?key=$_apiKey'
          '&q=${Uri.encodeComponent(categoryQuery)}'
          '&image_type=photo'
          '&orientation=all'
          '&category=${_selectedCategory == 'all' ? '' : _selectedCategory}'
          '&min_width=640'
          '&min_height=480'
          '&per_page=$_imagesPerPage'
          '&page=$_currentPage'
          '&safesearch=true'
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final images = (data['hits'] as List)
            .map((image) => PixabayImage.fromJson(image))
            .toList();
        
        setState(() {
          if (_currentPage == 1) {
            _allImages = images;
            _filteredImages = images;
          } else {
            _allImages.addAll(images);
            _filteredImages.addAll(images);
          }
          _isLoading = false;
        });
      } else {
        _loadSampleImages();
      }
    } catch (e) {
      _loadSampleImages();
    }
  }

  void _loadSampleImages() {
    final sampleImages = [
      PixabayImage(
        id: 1,
        webformatURL: 'https://picsum.photos/640/480?random=1',
        previewURL: 'https://picsum.photos/150/150?random=1',
        tags: 'nature, landscape, mountain',
        user: 'photographer1',
        views: 1250,
        downloads: 450,
        likes: 89,
      ),
      PixabayImage(
        id: 2,
        webformatURL: 'https://picsum.photos/640/480?random=2',
        previewURL: 'https://picsum.photos/150/150?random=2',
        tags: 'city, architecture, building',
        user: 'photographer2',
        views: 2100,
        downloads: 680,
        likes: 156,
      ),
      // Add more sample images...
    ];
    
    setState(() {
      _allImages = sampleImages;
      _filteredImages = sampleImages;
      _isLoading = false;
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

  void _selectCategory(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
        _currentPage = 1;
        _allImages.clear();
        _filteredImages.clear();
      });
      _fetchImages();
    }
  }

  List<PixabayImage> _getCurrentPageImages() {
    return _showLikedList ? _likedImages : _filteredImages;
  }

  void _loadMoreImages() {
    if (!_isLoading && !_showLikedList) {
      _currentPage++;
      _fetchImages();
    }
  }

  void _addImageToCanvas(PixabayImage image) {
    Navigator.pop(context, image);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return const Color(0xFF059669);
      case 'people':
        return const Color(0xFFDC2626);
      case 'animals':
        return const Color(0xFF7C2D12);
      case 'food':
        return const Color(0xFFEA580C);
      case 'travel':
        return const Color(0xFF0284C7);
      case 'business':
        return const Color(0xFF4338CA);
      case 'technology':
        return const Color(0xFF7C3AED);
      case 'sports':
        return const Color(0xFF16A34A);
      case 'music':
        return const Color(0xFFDB2777);
      default:
        return _primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceGray,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _surfaceGray,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search images...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: _textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _textSecondary,
                            size: 20.w,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    size: 18.w,
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
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Favorites Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: _showLikedList ? _primaryBlue : _surfaceGray,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _showLikedList ? _primaryBlue : _borderColor,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showLikedList = !_showLikedList;
                          if (_showLikedList) {
                            final likedIds = ImageFavorites.instance.likedImageIds;
                            _likedImages = _allImages.where((img) => likedIds.contains(img.id)).toList();
                          }
                        });
                      },
                      icon: Icon(
                        Icons.favorite_rounded,
                        color: _showLikedList ? Colors.white : _textSecondary,
                        size: 20.w,
                      ),
                    ),
                  ),
                  
                  // Toggle for Liked Images Scroll
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      color: _showLikedImagesScroll ? _primaryBlue : _surfaceGray,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _showLikedImagesScroll ? _primaryBlue : _borderColor,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showLikedImagesScroll = !_showLikedImagesScroll;
                          if (_showLikedImagesScroll) {
                            final likedIds = ImageFavorites.instance.likedImageIds;
                            _likedImages = _allImages.where((img) => likedIds.contains(img.id)).toList();
                          }
                        });
                      },
                      icon: Icon(
                        Icons.slideshow_rounded, // or a suitable icon
                        color: _showLikedImagesScroll ? Colors.white : _textSecondary,
                        size: 20.w,
                      ),
                    ),
                  ),
                  
                  if (_showLikedList && _likedImages.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${_likedImages.length}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Liked Images Horizontal Scroll
            if (_showLikedImagesScroll && _likedImages.isNotEmpty)
              Container(
                height: 100.h, // Height for the horizontal scroll list
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _likedImages.length,
                  itemBuilder: (context, index) {
                    final image = _likedImages[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                              imageUrl: image.previewURL, // Use previewURL for smaller images
                              width: 60.w,
                              height: 60.h,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60.w,
                                height: 60.h,
                                color: _surfaceGray,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _primaryBlue,
                                    strokeWidth: 1.5,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60.w,
                                height: 60.h,
                                color: _surfaceGray,
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 24.w,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          GestureDetector(
                            onTap: () => _addImageToCanvas(image),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: _primaryBlue,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Add',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            // Category Filter
            if (!_showLikedList)
              Container(
                height: 50.h,
                color: Colors.white,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category.key;
                    
                    return GestureDetector(
                      onTap: () => _selectCategory(category.key),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSelected ? _getCategoryColor(category.key) : _surfaceGray,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected ? _getCategoryColor(category.key) : _borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 16.w,
                              color: isSelected ? Colors.white : _textSecondary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              category.name,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Content Area
            Expanded(
              child: _isLoading && _allImages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: _primaryBlue,
                            strokeWidth: 2.5,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Loading images...',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _getCurrentPageImages().isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24.w),
                                decoration: BoxDecoration(
                                  color: _surfaceGray,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _dividerColor),
                                ),
                                child: Icon(
                                  _showLikedList ? Icons.favorite_border_rounded : Icons.image_search_rounded,
                                  size: 40.w,
                                  color: _textSecondary,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                _showLikedList ? 'No liked images yet' : 'No images found',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
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
                      : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (!_showLikedList && 
                                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                                !_isLoading) {
                              _loadMoreImages();
                            }
                            return false;
                          },
                          child: GridView.builder(
                            padding: EdgeInsets.all(16.w),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12.w,
                              mainAxisSpacing: 12.h,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _getCurrentPageImages().length + (_isLoading ? 2 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _getCurrentPageImages().length) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _cardBackground,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(color: _dividerColor),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: _primaryBlue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              
                              final image = _getCurrentPageImages()[index];
                              final isLiked = ImageFavorites.instance.isLiked(image.id);
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: _cardBackground,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isLiked ? _primaryBlue.withOpacity(0.3) : _dividerColor,
                                    width: isLiked ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(15.r),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: image.webformatURL,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: _surfaceGray,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    color: _primaryBlue,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
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
                                                  color: Colors.white.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(8.r),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                  color: isLiked ? Colors.red : _textSecondary,
                                                  size: 18.w,
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          Positioned(
                                            bottom: 8.h,
                                            right: 8.w,
                                            child: GestureDetector(
                                              onTap: () => _addImageToCanvas(image),
                                              child: Container(
                                                padding: EdgeInsets.all(8.w),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(8.r),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.add_a_photo_rounded,
                                                  color: _primaryBlue,
                                                  size: 18.w,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Image Info
                                    Padding(
                                      padding: EdgeInsets.all(12.w),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'by ${image.user}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              color: _textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          SizedBox(height: 4.h),
                                          
                                          Text(
                                            image.tags,
                                            style: GoogleFonts.inter(
                                              fontSize: 10.sp,
                                              color: _textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          SizedBox(height: 6.h),
                                          
                                          Row(
                                            children: [
                                              Icon(Icons.visibility_rounded, size: 12.w, color: _textSecondary),
                                              SizedBox(width: 2.w),
                                              Text(
                                                '${image.views}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.sp,
                                                  color: _textSecondary,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Icon(Icons.download_rounded, size: 12.w, color: _textSecondary),
                                              SizedBox(width: 2.w),
                                              Text(
                                                '${image.downloads}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.sp,
                                                  color: _textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PixabayImage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ImageCategory {
  final String key;
  final String name;
  final IconData icon;

  const ImageCategory(this.key, this.name, this.icon);
}