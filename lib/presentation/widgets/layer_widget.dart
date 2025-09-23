import 'package:flutter/material.dart';
import '../../data/models/layer_data.dart';
import '../../core/constants/app_colors.dart';

class LayerWidget extends StatelessWidget {
  final LayerData layer;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(Offset) onPositionUpdate;
  final Function(double) onScaleUpdate;
  final Function(double) onRotationUpdate;
  final VoidCallback onTransformEnd;

  const LayerWidget({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.onTap,
    required this.onPositionUpdate,
    required this.onScaleUpdate,
    required this.onRotationUpdate,
    required this.onTransformEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: layer.position.dx,
      top: layer.position.dy,
      child: GestureDetector(
        onTap: onTap,
        onScaleUpdate: (details) {
          onPositionUpdate(layer.position + details.focalPointDelta);
          onScaleUpdate(layer.scale * details.scale);
          onRotationUpdate(layer.rotation + details.rotation);
        },
        onScaleEnd: (details) => onTransformEnd(),
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scale: layer.scale,
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: AppColors.accentColor, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              padding: isSelected ? const EdgeInsets.all(4) : null,
              child: layer.child,
            ),
          ),
        ),
      ),
    );
  }
}