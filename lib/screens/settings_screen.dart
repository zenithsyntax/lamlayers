import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'hive_model.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<UserPreferences> _userPreferencesBox;
  late UserPreferences userPreferences;
  late UserPreferences originalPreferences;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    _userPreferencesBox = Hive.box<UserPreferences>('userPreferences');
    userPreferences =
        _userPreferencesBox.get('user_prefs_id') ?? UserPreferences();
    // Store original preferences for comparison
    originalPreferences = UserPreferences(
      autoSave: userPreferences.autoSave,
      autoSaveInterval: userPreferences.autoSaveInterval,
      showGrid: userPreferences.showGrid,
      snapToGrid: userPreferences.snapToGrid,
      defaultExportFormat: userPreferences.defaultExportFormat,
      defaultExportQuality: userPreferences.defaultExportQuality,
      enableHapticFeedback: userPreferences.enableHapticFeedback,
      language: userPreferences.language,
      darkMode: userPreferences.darkMode,
      recentColors: userPreferences.recentColors,
      recentFonts: userPreferences.recentFonts,
    );
  }

  void _updatePreferences() {
    _userPreferencesBox.put('user_prefs_id', userPreferences);
    _checkForChanges();
  }

  void _checkForChanges() {
    setState(() {
      hasChanges =
          userPreferences.autoSave != originalPreferences.autoSave ||
          userPreferences.autoSaveInterval !=
              originalPreferences.autoSaveInterval ||
          userPreferences.showGrid != originalPreferences.showGrid ||
          userPreferences.snapToGrid != originalPreferences.snapToGrid ||
          userPreferences.defaultExportFormat !=
              originalPreferences.defaultExportFormat ||
          userPreferences.defaultExportQuality !=
              originalPreferences.defaultExportQuality ||
          userPreferences.enableHapticFeedback !=
              originalPreferences.enableHapticFeedback ||
          userPreferences.darkMode != originalPreferences.darkMode;
    });
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restart_alt_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Reset Settings?',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'This will restore all settings to their default values. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
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
                      onPressed: () {
                        setState(() {
                          userPreferences = UserPreferences();
                          _updatePreferences();
                          originalPreferences = UserPreferences();
                          hasChanges = false;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Settings reset to defaults',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Reset',
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
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: const Color(0xFFEF4444),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                '⚠️ Clear All Data?',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'This will permanently delete ALL your projects, scrapbooks, and settings from the app. This action CANNOT be undone!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
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
                      onPressed: () async {
                        Navigator.pop(context);
                        await _performClearAllData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Delete All',
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
  }

  Future<void> _performClearAllData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: const Color(0xFFEC4899)),
                SizedBox(height: 16.h),
                Text(
                  'Clearing data...',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Clear all Hive boxes
      await Hive.box<PosterProject>('posterProjects').clear();
      await Hive.box<Scrapbook>('scrapbooks').clear();
      await Hive.box<UserPreferences>('userPreferences').clear();

      // Try to clear font favorites box if it exists
      try {
        if (Hive.isBoxOpen('fontFavoritesBox')) {
          await Hive.box('fontFavoritesBox').clear();
        }
      } catch (e) {
        // Ignore if box doesn't exist
      }

      // Reset current preferences
      setState(() {
        userPreferences = UserPreferences();
        originalPreferences = UserPreferences();
        hasChanges = false;
      });
      _userPreferencesBox.put('user_prefs_id', userPreferences);

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All data cleared successfully',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error clearing data: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Auto-Save Settings Card
          _buildSettingsCard(
            icon: Icons.save_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBgColor: const Color(0xFFF5F3FF),
            title: 'Auto-Save',
            children: [
              _buildSwitchTile(
                title: 'Enable Auto-Save',
                subtitle: 'Automatically save your work',
                value: userPreferences.autoSave,
                onChanged: (value) {
                  setState(() {
                    userPreferences.autoSave = value;
                    _updatePreferences();
                  });
                },
              ),
              if (userPreferences.autoSave) ...[
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Save Interval',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF8B5CF6),
                          inactiveTrackColor: const Color(0xFFE9D5FF),
                          thumbColor: const Color(0xFF8B5CF6),
                          overlayColor: const Color(
                            0xFF8B5CF6,
                          ).withOpacity(0.1),
                          trackHeight: 4.h,
                        ),
                        child: Slider(
                          value: userPreferences.autoSaveInterval.toDouble(),
                          min: 5,
                          max: 300,
                          divisions: 19,
                          label: '${userPreferences.autoSaveInterval}s',
                          onChanged: (value) {
                            setState(() {
                              userPreferences.autoSaveInterval = value.round();
                              _updatePreferences();
                            });
                          },
                        ),
                      ),
                      Text(
                        'Current: ${userPreferences.autoSaveInterval} seconds',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ],
          ),

          SizedBox(height: 16.h),

          // Export Settings Card
          _buildSettingsCard(
            icon: Icons.file_download_rounded,
            iconColor: const Color(0xFFEC4899),
            iconBgColor: const Color(0xFFFCE7F3),
            title: 'Export',
            children: [
              _buildSelectTile(
                title: 'Default Format',
                value: _getFormatName(userPreferences.defaultExportFormat),
                onTap: _showFormatDialog,
              ),
              Divider(height: 1.h, color: const Color(0xFFE2E8F0)),
              _buildSelectTile(
                title: 'Default Quality',
                value: _getQualityName(userPreferences.defaultExportQuality),
                onTap: _showQualityDialog,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Reset Settings Button (only show if there are changes)
          if (hasChanges) ...[
            _buildActionButton(
              icon: Icons.restart_alt_rounded,
              label: 'Reset Settings',
              subtitle: 'Restore default settings',
              color: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFEF3C7),
              onTap: _resetSettings,
            ),
            SizedBox(height: 16.h),
          ],

          // About App Button
          _buildActionButton(
            icon: Icons.info_rounded,
            label: 'About App',
            subtitle: 'Version & app information',
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),

          SizedBox(height: 16.h),

          // Privacy Policy Button
          _buildActionButton(
            icon: Icons.privacy_tip_rounded,
            label: 'Privacy Policy',
            subtitle: 'How we handle your data',
            color: const Color(0xFF06B6D4),
            bgColor: const Color(0xFFCFFAFE),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),

          SizedBox(height: 16.h),

          // Clear Data Button
          _buildActionButton(
            icon: Icons.delete_forever_rounded,
            label: 'Clear All Data',
            subtitle: 'Delete all projects and settings',
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
            onTap: _clearAllData,
          ),

          SizedBox(height: 32.h),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  'Made with ❤️ by Lamlayers Team',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
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
          ),
          Divider(height: 1.h, color: const Color(0xFFE2E8F0)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFEC4899),
            activeTrackColor: const Color(0xFFEC4899).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF94A3B8),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: bgColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF94A3B8),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.png:
        return 'PNG';
      default:
        return 'JPG';
    }
  }

  String _getQualityName(ExportQuality quality) {
    switch (quality) {
      case ExportQuality.low:
        return 'Low';
      case ExportQuality.medium:
        return 'Medium';
      case ExportQuality.high:
        return 'High';
    }
  }

  void _showFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Format',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 16.h),
              ...ExportFormat.values.map((format) {
                return RadioListTile<ExportFormat>(
                  title: Text(
                    _getFormatName(format),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: format,
                  groupValue: userPreferences.defaultExportFormat,
                  activeColor: const Color(0xFFEC4899),
                  onChanged: (value) {
                    setState(() {
                      userPreferences.defaultExportFormat = value!;
                      _updatePreferences();
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Quality',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 16.h),
              ...ExportQuality.values.map((quality) {
                return RadioListTile<ExportQuality>(
                  title: Text(
                    _getQualityName(quality),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: quality,
                  groupValue: userPreferences.defaultExportQuality,
                  activeColor: const Color(0xFFEC4899),
                  onChanged: (value) {
                    setState(() {
                      userPreferences.defaultExportQuality = value!;
                      _updatePreferences();
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
