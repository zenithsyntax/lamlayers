import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

enum ExportFormat { jpg, png }

enum ExportClarity { high, medium, low }

enum ExportType { image, project }

class ExportOptions {
  final ExportFormat format;
  final ExportClarity clarity;
  final ExportType type;

  ExportOptions({
    required this.format,
    required this.clarity,
    required this.type,
  });
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({Key? key}) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.png;
  ExportClarity _selectedClarity = ExportClarity.high;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.file_download_rounded,
                  color: Colors.amber[600],
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Export Options',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Export Format Section
            Text(
              'Export Format',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    ExportFormat.png,
                    'PNG',
                    Icons.image_outlined,
                    Colors.blue[600]!,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildFormatOption(
                    ExportFormat.jpg,
                    'JPG',
                    Icons.image_outlined,
                    Colors.green[600]!,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Clarity Section
            Text(
              'Clarity',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildClarityOption(
                    ExportClarity.high,
                    'High',
                    Colors.red[600]!,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildClarityOption(
                    ExportClarity.medium,
                    'Medium',
                    Colors.orange[600]!,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildClarityOption(
                    ExportClarity.low,
                    'Low',
                    Colors.green[600]!,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Export Image',
                    Icons.image_rounded,
                    Colors.blue[600]!,
                    ExportType.image,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton(
                    'Download Project',
                    Icons.download_rounded,
                    Colors.purple[600]!,
                    ExportType.project,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    ExportFormat format,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClarityOption(
    ExportClarity clarity,
    String label,
    Color color,
  ) {
    final isSelected = _selectedClarity == clarity;
    return GestureDetector(
      onTap: () => setState(() => _selectedClarity = clarity),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    ExportType type,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(ExportOptions(
          format: _selectedFormat,
          clarity: _selectedClarity,
          type: type,
        ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
