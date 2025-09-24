import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActionBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool snapToGrid;
  final ValueChanged<bool> onToggleGrid;
  final bool hasItems;
  final VoidCallback onShowLayers;
  final VoidCallback onExport;

  const ActionBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.snapToGrid,
    required this.onToggleGrid,
    required this.hasItems,
    required this.onShowLayers,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(context, Icons.undo_rounded, canUndo, onUndo, 'Undo'),
          SizedBox(width: 7.w),
          _buildActionButton(context, Icons.redo_rounded, canRedo, onRedo, 'Redo'),
          SizedBox(width: 7.w),
          _buildActionButton(context, Icons.grid_on_rounded, true, () => onToggleGrid(!snapToGrid), snapToGrid ? 'Grid On' : 'Grid Off', isActive: snapToGrid),
        SizedBox(width: 7.w),
          _buildActionButton(context, Icons.layers_rounded, hasItems, onShowLayers, 'Layers'),
          SizedBox(width: 12.w),
          _buildGradientButton(context, 'Export', Icons.file_download_rounded, onExport),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, bool enabled, VoidCallback onTap, String tooltip, {bool isActive = false}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            gradient: isActive ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]) : null,
            color: isActive ? null : (enabled ? Colors.grey[100] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200, width: 1.5),
            boxShadow: enabled ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Icon(icon, color: isActive ? Colors.white : (enabled ? Colors.grey[700] : Colors.grey[400]), size: 22.sp),
        ),
      ),
    );
  }

  Widget _buildGradientButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}


