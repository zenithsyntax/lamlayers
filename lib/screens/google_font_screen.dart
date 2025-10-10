import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../models/font_favorites.dart';

class GoogleFontsPage extends StatefulWidget {
  final Function(String)? onFontSelected;

  const GoogleFontsPage({super.key, this.onFontSelected});

  @override
  State<GoogleFontsPage> createState() => _GoogleFontsPageState();
}

class _GoogleFontsPageState extends State<GoogleFontsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _apiKey = 'AIzaSyBaTQhgkhm6TVOroOQtE6HEw1d2Gpv5SXY';

  // Professional Color Scheme
  static const Color _primaryIndigo = Color(0xFF6366F1);
  static const Color _primaryPurple = Color(0xFF8B5CF6);
  static const Color _surfaceGray = Color(0xFFF1F5F9);
  static const Color _cardBackground = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _dividerColor = Color(0xFFE2E8F0);
  static const Color _borderColor = Color(0xFFCBD5E1);

  List<GoogleFont> _allFonts = [];
  List<GoogleFont> _filteredFonts = [];
  List<GoogleFont> _likedFonts = [];

  int _currentPage = 0;
  final int _fontsPerPage = 12;
  bool _isLoading = false;
  bool _showLikedList = false;

  @override
  void initState() {
    super.initState();
    _fetchGoogleFonts();
    _searchController.addListener(_filterFonts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchGoogleFonts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/webfonts/v1/webfonts?key=$_apiKey&sort=popularity',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fonts = (data['items'] as List)
            .map((font) => GoogleFont.fromJson(font))
            .toList();

        setState(() {
          _allFonts = fonts;
          _filteredFonts = fonts;
          _isLoading = false;
        });
      } else {
        _loadSampleFonts();
      }
    } catch (e) {
      _loadSampleFonts();
    }
  }

  void _loadSampleFonts() {
    final sampleFonts = [
      GoogleFont(
        family: 'Roboto',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Open Sans',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Lato',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Montserrat',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Poppins',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Source Sans Pro',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Raleway',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'PT Sans',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Nunito',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Ubuntu',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Inter',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Work Sans',
        variants: ['regular', 'bold'],
        category: 'sans-serif',
      ),
      GoogleFont(
        family: 'Playfair Display',
        variants: ['regular', 'bold'],
        category: 'serif',
      ),
      GoogleFont(
        family: 'Merriweather',
        variants: ['regular', 'bold'],
        category: 'serif',
      ),
      GoogleFont(
        family: 'Lora',
        variants: ['regular', 'bold'],
        category: 'serif',
      ),
      GoogleFont(
        family: 'Crimson Text',
        variants: ['regular', 'bold'],
        category: 'serif',
      ),
      GoogleFont(
        family: 'Dancing Script',
        variants: ['regular', 'bold'],
        category: 'handwriting',
      ),
      GoogleFont(
        family: 'Pacifico',
        variants: ['regular'],
        category: 'handwriting',
      ),
      GoogleFont(family: 'Lobster', variants: ['regular'], category: 'display'),
      GoogleFont(
        family: 'Great Vibes',
        variants: ['regular'],
        category: 'handwriting',
      ),
    ];

    setState(() {
      _allFonts = sampleFonts;
      _filteredFonts = sampleFonts;
      _isLoading = false;
    });
  }

  void _filterFonts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFonts = _allFonts;
      } else {
        _filteredFonts = _allFonts
            .where((font) => font.family.toLowerCase().contains(query))
            .toList();
      }
      _currentPage = 0;
    });
    // Scroll to top when search results change
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleLikeFont(GoogleFont font) {
    setState(() {
      final isLiked = FontFavorites.instance.isLiked(font.family);
      if (isLiked) {
        FontFavorites.instance.remove(font.family);
        _likedFonts.remove(font);
      } else {
        FontFavorites.instance.add(font.family);
        if (!_likedFonts.contains(font)) {
          _likedFonts.add(font);
        }
      }
    });
  }

  List<GoogleFont> _getCurrentPageFonts() {
    final fontsToShow = _showLikedList ? _likedFonts : _filteredFonts;
    final startIndex = _currentPage * _fontsPerPage;
    final endIndex = (startIndex + _fontsPerPage).clamp(0, fontsToShow.length);
    return fontsToShow.sublist(startIndex, endIndex);
  }

  int _getTotalPages() {
    final fontsToShow = _showLikedList ? _likedFonts : _filteredFonts;
    return (fontsToShow.length / _fontsPerPage).ceil();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    // Scroll to top when page changes
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  TextStyle? _getGoogleFontStyle(String fontFamily, double fontSize) {
    try {
      String fontName = fontFamily.replaceAll(' ', '');

      switch (fontName.toLowerCase()) {
        case 'roboto':
          return GoogleFonts.roboto(fontSize: fontSize);
        case 'opensans':
          return GoogleFonts.openSans(fontSize: fontSize);
        case 'lato':
          return GoogleFonts.lato(fontSize: fontSize);
        case 'montserrat':
          return GoogleFonts.montserrat(fontSize: fontSize);
        case 'poppins':
          return GoogleFonts.poppins(fontSize: fontSize);
        case 'raleway':
          return GoogleFonts.raleway(fontSize: fontSize);
        case 'ptsans':
          return GoogleFonts.ptSans(fontSize: fontSize);
        case 'nunito':
          return GoogleFonts.nunito(fontSize: fontSize);
        case 'ubuntu':
          return GoogleFonts.ubuntu(fontSize: fontSize);
        case 'inter':
          return GoogleFonts.inter(fontSize: fontSize);
        case 'worksans':
          return GoogleFonts.workSans(fontSize: fontSize);
        case 'playfairdisplay':
          return GoogleFonts.playfairDisplay(fontSize: fontSize);
        case 'merriweather':
          return GoogleFonts.merriweather(fontSize: fontSize);
        case 'lora':
          return GoogleFonts.lora(fontSize: fontSize);
        case 'crimsontext':
          return GoogleFonts.crimsonText(fontSize: fontSize);
        case 'dancingscript':
          return GoogleFonts.dancingScript(fontSize: fontSize);
        case 'pacifico':
          return GoogleFonts.pacifico(fontSize: fontSize);
        case 'lobster':
          return GoogleFonts.lobster(fontSize: fontSize);
        case 'greatvibes':
          return GoogleFonts.greatVibes(fontSize: fontSize);
        default:
          return GoogleFonts.getFont(fontFamily, fontSize: fontSize);
      }
    } catch (e) {
      return null;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'serif':
        return const Color(0xFF8B5CF6);
      case 'sans-serif':
        return _primaryIndigo;
      case 'handwriting':
        return const Color(0xFFEC4899);
      case 'display':
        return const Color(0xFF10B981);
      case 'monospace':
        return const Color(0xFFF59E0B);
      default:
        return _textSecondary;
    }
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
              'Google Fonts',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Choose your perfect typography',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Search Bar
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
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                        hintText: 'Search fonts...',
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
                                onPressed: () => _searchController.clear(),
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
                        _currentPage = 0;
                        if (_showLikedList) {
                          final likedFamilies =
                              FontFavorites.instance.likedFamilies;
                          _likedFonts = _allFonts
                              .where((f) => likedFamilies.contains(f.family))
                              .toList();
                        }
                      });
                      // Scroll to top when switching between all fonts and liked fonts
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
                            color: _showLikedList
                                ? Colors.white
                                : _textSecondary,
                            size: 18.r,
                          ),
                          if (_showLikedList && _likedFonts.isNotEmpty) ...[
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
                                '${_likedFonts.length}',
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

            // Content Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: _primaryIndigo,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Loading fonts...',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Fetching the latest Google Fonts',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _getCurrentPageFonts().isEmpty
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
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(
                              _showLikedList
                                  ? Icons.favorite_border_rounded
                                  : Icons.search_off_rounded,
                              size: 32.r,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            _showLikedList
                                ? 'No liked fonts yet'
                                : 'No fonts found',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _showLikedList
                                ? 'Start liking fonts to see them here'
                                : 'Try adjusting your search terms',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.w),
                      itemCount: _getCurrentPageFonts().length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final font = _getCurrentPageFonts()[index];
                        final isLiked = FontFavorites.instance.isLiked(
                          font.family,
                        );
                        final googleFontStyle = _getGoogleFontStyle(
                          font.family,
                          18.sp,
                        );

                        return GestureDetector(
                          onTap: () {
                            widget.onFontSelected?.call(font.family);
                            Navigator.pop(
                              context,
                              font.family,
                            ); // Pass the selected font family back
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _cardBackground,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isLiked
                                    ? _primaryIndigo.withOpacity(0.3)
                                    : _dividerColor,
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
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              font.family,
                                              style: GoogleFonts.inter(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: _textPrimary,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getCategoryColor(
                                                  font.category,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                font.category,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.sp,
                                                  color: _getCategoryColor(
                                                    font.category,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Compact Like Button
                                      GestureDetector(
                                        onTap: () => _toggleLikeFont(font),
                                        child: Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            color: isLiked
                                                ? _primaryIndigo.withOpacity(
                                                    0.1,
                                                  )
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          child: Icon(
                                            isLiked
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: isLiked
                                                ? _primaryIndigo
                                                : _textSecondary,
                                            size: 20.w,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 16.h),

                                  // Font Preview
                                  Text(
                                    'The quick brown fox jumps over the lazy dog',
                                    style:
                                        googleFontStyle?.copyWith(
                                          fontSize: 18.sp,
                                          color: _textPrimary,
                                          height: 1.3,
                                        ) ??
                                        GoogleFonts.inter(
                                          fontSize: 18.sp,
                                          color: _textPrimary,
                                          height: 1.3,
                                        ),
                                  ),

                                  SizedBox(height: 8.h),

                                  // Numbers Preview
                                  Text(
                                    '1234567890 !@#\$%^&*()',
                                    style:
                                        googleFontStyle?.copyWith(
                                          fontSize: 14.sp,
                                          color: _textSecondary,
                                        ) ??
                                        GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          color: _textSecondary,
                                        ),
                                  ),

                                  SizedBox(height: 12.h),

                                  // Variants Info
                                  Text(
                                    '${font.variants.length} variants',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Compact Pagination
            if (_getTotalPages() > 1)
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                color: Colors.white,
                child: Row(
                  children: [
                    // Previous Button
                    Expanded(
                      child: Container(
                        height: 44.h,
                        child: ElevatedButton.icon(
                          onPressed: _currentPage > 0
                              ? () => _goToPage(_currentPage - 1)
                              : null,
                          icon: Icon(Icons.chevron_left_rounded, size: 18.w),
                          label: Text(
                            'Previous',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPage > 0
                                ? _primaryIndigo
                                : _dividerColor,
                            foregroundColor: _currentPage > 0
                                ? Colors.white
                                : _textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
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
                        color: _surfaceGray,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Text(
                        '${_currentPage + 1} of ${_getTotalPages()}',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _primaryIndigo,
                        ),
                      ),
                    ),

                    SizedBox(width: 16.w),

                    // Next Button
                    Expanded(
                      child: Container(
                        height: 44.h,
                        child: ElevatedButton.icon(
                          onPressed: _currentPage < _getTotalPages() - 1
                              ? () => _goToPage(_currentPage + 1)
                              : null,
                          label: Text(
                            'Next',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          icon: Icon(Icons.chevron_right_rounded, size: 18.w),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPage < _getTotalPages() - 1
                                ? _primaryIndigo
                                : _dividerColor,
                            foregroundColor: _currentPage < _getTotalPages() - 1
                                ? Colors.white
                                : _textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GoogleFont {
  final String family;
  final List<String> variants;
  final String category;

  GoogleFont({
    required this.family,
    required this.variants,
    required this.category,
  });

  factory GoogleFont.fromJson(Map<String, dynamic> json) {
    return GoogleFont(
      family: json['family'] ?? '',
      variants: List<String>.from(json['variants'] ?? []),
      category: json['category'] ?? 'sans-serif',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoogleFont &&
          runtimeType == other.runtimeType &&
          family == other.family;

  @override
  int get hashCode => family.hashCode;
}
