import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'About',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          color: const Color(0xFF0F172A),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // App Logo & Name Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Image.asset(
                      'assets/icons/lamlayers_logo.png',
                      width: 80.w,
                      height: 80.w,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Lamlayers',
                    style: GoogleFonts.inter(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Create • Design • Share',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Description Card
            _buildInfoCard(
              icon: Icons.info_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFFF5F3FF),
              title: 'About Lamlayers',
              content:
                  'Lamlayers is a powerful and intuitive design tool that helps you create stunning posters, scrapbooks, and visual content. With our easy-to-use interface and professional features, you can bring your creative ideas to life.',
            ),

            SizedBox(height: 16.h),

            // Features Card
            _buildInfoCard(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFFEF3C7),
              title: 'Key Features',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem('✨ Professional poster maker'),
                  _buildFeatureItem('📚 Digital scrapbook creator'),
                  _buildFeatureItem('🎨 Advanced editing tools'),
                  _buildFeatureItem('💾 Auto-save functionality'),
                  _buildFeatureItem('📤 Export in multiple formats'),
                  _buildFeatureItem('🖼️ Custom templates & layouts'),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Team Card
            _buildInfoCard(
              icon: Icons.group_rounded,
              iconColor: const Color(0xFFEC4899),
              iconBgColor: const Color(0xFFFCE7F3),
              title: 'Our Team',
              content:
                  'Lamlayers is built with passion by a dedicated team of designers and developers who believe in empowering creativity through technology.',
            ),

            SizedBox(height: 16.h),

            // Contact Card
            _buildInfoCard(
              icon: Icons.mail_rounded,
              iconColor: const Color(0xFF06B6D4),
              iconBgColor: const Color(0xFFCFFAFE),
              title: 'Contact Us',
              content:
                  'Have questions or feedback? We\'d love to hear from you!\n\nEmail: support@lamlayers.com\nWebsite: www.lamlayers.com',
            ),

            SizedBox(height: 16.h),

            // Credits Card
            _buildInfoCard(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFEE2E2),
              title: 'Credits',
              content:
                  'Built with Flutter\nIcons by Material Design\nFonts by Google Fonts\n\nSpecial thanks to all our contributors and the open-source community.',
            ),

            SizedBox(height: 24.h),

            // Legal Links
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegalLink('Terms', () {
                    // Handle terms of service
                  }),
                  Container(
                    width: 1,
                    height: 20.h,
                    color: const Color(0xFFE2E8F0),
                  ),
                  _buildLegalLink('Privacy', () {
                    Navigator.pop(context);
                    // Privacy policy will be navigated from settings
                  }),
                  Container(
                    width: 1,
                    height: 20.h,
                    color: const Color(0xFFE2E8F0),
                  ),
                  _buildLegalLink('Licenses', () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Lamlayers',
                      applicationVersion: '1.0.0',
                      applicationIcon: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Image.asset(
                          'assets/icons/lamlayers_logo.png',
                          width: 48.w,
                          height: 48.w,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Copyright
            Text(
              '© 2025 Lamlayers. All rights reserved.',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? content,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (content != null)
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF475569),
                height: 1.6,
              ),
            ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          color: const Color(0xFF475569),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildLegalLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}
