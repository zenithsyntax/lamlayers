import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BottomToolbar extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddImage;
  final VoidCallback? onAddShape;
  final VoidCallback? onDelete;
  final VoidCallback? onEditText;
  final VoidCallback? onEditImage;

  const BottomToolbar({
    super.key,
    required this.onAddText,
    required this.onAddImage,
    this.onAddShape,
    this.onDelete,
    this.onEditText,
    this.onEditImage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildToolbarButton(Icons.text_fields, 'Add Text', onAddText),
            _buildToolbarButton(Icons.image, 'Add Image', onAddImage),
            _buildToolbarButton(Icons.category, 'Add Shape', onAddShape),
            _buildToolbarButton(Icons.delete, 'Delete', onDelete),
            _buildToolbarButton(Icons.edit, 'Edit Text', onEditText),
            _buildToolbarButton(Icons.photo_filter, 'Edit Image', onEditImage),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback? onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: onPressed != null
                    ? AppColors.primaryColor.withOpacity(0.3)
                    : Colors.grey,
              ),
            ),
            child: Icon(
              icon,
              color: onPressed != null ? AppColors.primaryColor : Colors.grey,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}