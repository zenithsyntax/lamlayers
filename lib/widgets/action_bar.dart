import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool hasItems;
  final VoidCallback onShowLayers;
  final VoidCallback onExport;
  final VoidCallback? onBack;
  final bool isAutoSaving;

  const ActionBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.hasItems,
    required this.onShowLayers,
    required this.onExport,
    this.onBack,
    this.isAutoSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Back button
          if (onBack != null) ...[
            _buildBackButton(context),
            SizedBox(width: 12.w),
          ],
          // Undo button
          _buildActionButton(
            context,
            Icons.undo_rounded,
            canUndo,
            onUndo,
            'Undo',
            iconColor: const Color(0xFF6366F1),
          ),
          SizedBox(width: 12.w),
          // Redo button
          _buildActionButton(
            context,
            Icons.redo_rounded,
            canRedo,
            onRedo,
            'Redo',
            iconColor: const Color(0xFF6366F1),
          ),
          SizedBox(width: 12.w),
          // Layers button
          _buildActionButton(
            context,
            Icons.layers_rounded,
            hasItems,
            onShowLayers,
            'Layers',
            iconColor: const Color(0xFF8B5CF6),
          ),
          SizedBox(width: 12.w),
          // Export button or Auto-save progress indicator
          isAutoSaving
              ? _buildAutoSaveIndicator(context)
              : _buildExportButton(
                  context,
                  'Export',
                  Icons.file_download_rounded,
                  onExport,
                ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
    String tooltip, {
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 42.w,
          height: 42.h,
          decoration: BoxDecoration(
            color: enabled
                ? (iconColor ?? const Color(0xFF6366F1)).withOpacity(0.1)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16.r),
            border: enabled
                ? Border.all(
                    color: (iconColor ?? const Color(0xFF6366F1)).withOpacity(
                      0.2,
                    ),
                    width: 1.5,
                  )
                : null,
          ),
          child: Icon(
            icon,
            color: enabled
                ? (iconColor ?? const Color(0xFF6366F1))
                : const Color(0xFF94A3B8),
            size: 20.r,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Tooltip(
      message: 'Back',
      child: GestureDetector(
        onTap: onBack,
        child: Container(
          width: 42.w,
          height: 42.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF64748B),
            size: 20.r,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSaveIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.w,
            height: 12.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF10B981),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Saving...',
            style: GoogleFonts.inter(
              color: const Color(0xFF10B981),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
