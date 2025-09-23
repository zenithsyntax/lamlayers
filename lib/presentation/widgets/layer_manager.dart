import 'package:flutter/material.dart';
import '../../data/models/layer_data.dart';
import '../../core/constants/app_colors.dart';

class LayerManager extends StatelessWidget {
  final List<LayerData> layers;
  final String? selectedLayerId;
  final VoidCallback onClose;
  final Function(String) onLayerSelect;
  final Function(int, int) onLayerReorder;
  final Function(String) onBringToFront;
  final Function(String) onSendToBack;

  const LayerManager({
    super.key,
    required this.layers,
    this.selectedLayerId,
    required this.onClose,
    required this.onLayerSelect,
    required this.onLayerReorder,
    required this.onBringToFront,
    required this.onSendToBack,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      top: 100,
      bottom: 120,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Layers',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: AppColors.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Layers List
            Expanded(
              child: layers.isEmpty
                  ? const Center(
                      child: Text(
                        'No layers yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ReorderableListView(
                      onReorder: onLayerReorder,
                      children: layers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final layer = entry.value;
                        return _buildLayerItem(layer, index);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerItem(LayerData layer, int index) {
    final isSelected = layer.id == selectedLayerId;
    
    return Container(
      key: ValueKey(layer.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accentColor.withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.accentColor : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: layer.isText
                ? const Icon(Icons.text_fields, color: AppColors.primaryColor, size: 20)
                : const Icon(Icons.image, color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Layer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer.isText ? (layer.text ?? 'Text') : 'Image',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Layer ${index + 1}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Layer Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryColor),
            color: Colors.grey[800],
            onSelected: (value) {
              switch (value) {
                case 'select':
                  onLayerSelect(layer.id);
                  break;
                case 'front':
                  onBringToFront(layer.id);
                  break;
                case 'back':
                  onSendToBack(layer.id);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select',
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: AppColors.primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text('Select', style: TextStyle(color: AppColors.primaryColor)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'front',
                child: Row(
                  children: [
                    Icon(Icons.flip_to_front, color: AppColors.primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text('Bring to Front', style: TextStyle(color: AppColors.primaryColor)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'back',
                child: Row(
                  children: [
                    Icon(Icons.flip_to_back, color: AppColors.primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text('Send to Back', style: TextStyle(color: AppColors.primaryColor)),
                  ],
                ),
              ),
            ],
          ),

          // Drag Handle
          const Icon(Icons.drag_handle, color: Colors.grey),
        ],
      ),
    );
  }
}