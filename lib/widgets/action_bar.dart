import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Back button
          if (onBack != null) ...[
            _buildBackButton(context),
            SizedBox(width: 8.w),
          ],
          // Undo button
          _buildActionButton(
            context,
            Icons.undo_rounded,
            canUndo,
            onUndo,
            'Undo',
            iconColor: Colors.amber[600],
          ),
          SizedBox(width: 8.w),
          // Redo button
          _buildActionButton(
            context,
            Icons.redo_rounded,
            canRedo,
            onRedo,
            'Redo',
            iconColor: Colors.amber[600],
          ),
          SizedBox(width: 8.w),
          // Layers button
          _buildActionButton(
            context,
            Icons.layers_rounded,
            hasItems,
            onShowLayers,
            'Layers',
            iconColor: Colors.green[600],
          ),
          SizedBox(width: 8.w),
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
          width: 48.w,
          height: 48.h,
          child: Icon(
            icon,
            color: enabled ? (iconColor ?? Colors.grey[700]) : Colors.grey[400],
            size: 24.sp,
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
          width: 48.w,
          height: 48.h,
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.brown[700],
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSaveIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.green[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10.w,
            height: 10.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'saving...',
            style: TextStyle(
              color: Colors.green[600],
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
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
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.amber[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.amber[600], size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
