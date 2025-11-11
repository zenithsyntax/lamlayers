import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Privacy Policy',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.privacy_tip_rounded,
                      color: Colors.white,
                      size: 48.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Your Privacy Matters',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Last updated: November 11, 2025',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Introduction
            _buildSection(
              icon: Icons.description_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFFF5F3FF),
              title: 'Introduction',
              content:
                  'Welcome to Lamlayers! We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we handle your information when you use our app.',
            ),

            SizedBox(height: 16.h),

            // Data Collection
            _buildSection(
              icon: Icons.storage_rounded,
              iconColor: const Color(0xFF06B6D4),
              iconBgColor: const Color(0xFFCFFAFE),
              title: 'Data We Collect',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lamlayers stores data locally on your device:',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildBulletPoint('Your design projects and lambooks'),
                  _buildBulletPoint('App settings and preferences'),
                  _buildBulletPoint('Images and media you add to projects'),
                  _buildBulletPoint('Font favorites and recent colors'),
                  SizedBox(height: 12.h),
                  Text(
                    'All data is stored locally using Hive database. We do not collect or transmit your personal information to external servers.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Data Usage
            _buildSection(
              icon: Icons.security_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFD1FAE5),
              title: 'How We Use Your Data',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'To save and manage your creative projects',
                  ),
                  _buildBulletPoint(
                    'To remember your app preferences and settings',
                  ),
                  _buildBulletPoint('To provide auto-save functionality'),
                  _buildBulletPoint('To enhance your creative experience'),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Your data never leaves your device',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Data Sharing
            _buildSection(
              icon: Icons.share_rounded,
              iconColor: const Color(0xFFEC4899),
              iconBgColor: const Color(0xFFFCE7F3),
              title: 'Data Sharing',
              content:
                  'We do NOT share, sell, or transmit your data to third parties. All your projects, images, and settings remain private and stored only on your device. When you export images or share lambooks, you have complete control over where and how you share them.',
            ),

            SizedBox(height: 16.h),

            // Third-Party Services
            _buildSection(
              icon: Icons.extension_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFFEF3C7),
              title: 'Third-Party Services',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lamlayers may use the following third-party services:',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildServiceItem(
                    'Google Fonts',
                    'For providing beautiful typography',
                  ),
                  _buildServiceItem(
                    'Google Mobile Ads',
                    'For displaying ads (if applicable)',
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'These services may have their own privacy policies. We recommend reviewing them separately.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Data Security
            _buildSection(
              icon: Icons.lock_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFFF5F3FF),
              title: 'Data Security',
              content:
                  'We implement appropriate security measures to protect your data. All information is stored locally using encrypted Hive database. However, please note that no method of electronic storage is 100% secure.',
            ),

            SizedBox(height: 16.h),

            // Your Rights
            _buildSection(
              icon: Icons.admin_panel_settings_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFEE2E2),
              title: 'Your Rights',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You have complete control over your data:',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildBulletPoint(
                    'Access all your projects and data anytime',
                  ),
                  _buildBulletPoint('Modify or delete your projects'),
                  _buildBulletPoint('Export images as JPG or PNG'),
                  _buildBulletPoint('Share lambooks with others'),
                  _buildBulletPoint('Clear all app data from Settings'),
                  _buildBulletPoint('Uninstall the app to remove all data'),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Children's Privacy
            _buildSection(
              icon: Icons.child_care_rounded,
              iconColor: const Color(0xFF06B6D4),
              iconBgColor: const Color(0xFFCFFAFE),
              title: 'Children\'s Privacy',
              content:
                  'Lamlayers does not knowingly collect personal information from children under 13. The app is designed to store data locally without requiring personal information.',
            ),

            SizedBox(height: 16.h),

            // Changes to Policy
            _buildSection(
              icon: Icons.update_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFFEF3C7),
              title: 'Changes to This Policy',
              content:
                  'We may update this privacy policy from time to time. Any changes will be reflected with an updated "Last updated" date at the top of this policy. We encourage you to review this policy periodically.',
            ),

            SizedBox(height: 16.h),

            // Contact
            _buildSection(
              icon: Icons.contact_support_rounded,
              iconColor: const Color(0xFFEC4899),
              iconBgColor: const Color(0xFFFCE7F3),
              title: 'Contact Us',
              content:
                  'If you have any questions or concerns about this privacy policy or how we handle your data, please contact us at:\n\nEmail: zenithsyntax@gmail.com',
            ),

            SizedBox(height: 32.h),

            // Summary Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF06B6D4).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: const Color(0xFF10B981),
                    size: 40.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Privacy First',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your creativity is yours. Your data stays on your device. Always.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF8B5CF6),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String name, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
