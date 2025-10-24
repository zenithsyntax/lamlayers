import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lamlayers/screens/hive_model.dart' as hive_model;

/// A widget that renders canvas content for read-only display purposes
/// Used in lambook reader to show actual canvas content when thumbnails aren't available
class CanvasRenderer extends StatelessWidget {
  final hive_model.PosterProject project;
  final double? width;
  final double? height;

  const CanvasRenderer({
    Key? key,
    required this.project,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? project.canvasWidth,
      height: height ?? project.canvasHeight,
      decoration: BoxDecoration(
        color: project.canvasBackgroundColor.toColor(),
        image: project.backgroundImagePath != null
            ? DecorationImage(
                image: FileImage(File(project.backgroundImagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Render canvas items
          ...(() {
            final items = [...project.canvasItems]
              ..sort((a, b) => a.layerIndex.compareTo(b.layerIndex));
            final visibleItems = items.where((it) => it.isVisible).toList();
            return visibleItems.map((it) => _buildCanvasItem(it)).toList();
          })(),
        ],
      ),
    );
  }

  Widget _buildCanvasItem(hive_model.HiveCanvasItem item) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: Transform.rotate(
        angle: item.rotation,
        child: Transform.scale(
          scale: item.scale,
          child: Opacity(
            opacity: item.opacity.clamp(0.0, 1.0),
            child: _buildItemContent(item),
          ),
        ),
      ),
    );
  }

  Widget _buildItemContent(hive_model.HiveCanvasItem item) {
    switch (item.type) {
      case hive_model.HiveCanvasItemType.text:
        return _buildTextItem(item);
      case hive_model.HiveCanvasItemType.image:
        return _buildImageItem(item);
      case hive_model.HiveCanvasItemType.shape:
        return _buildShapeItem(item);
      case hive_model.HiveCanvasItemType.sticker:
        return _buildStickerItem(item);
      case hive_model.HiveCanvasItemType.drawing:
        return _buildDrawingItem(item);
    }
  }

  Widget _buildTextItem(hive_model.HiveCanvasItem item) {
    final props = item.properties;
    final text = props['text'] as String? ?? 'Sample Text';

    final bool textHasGradient = props['hasGradient'] == true;
    final bool textHasShadow = props['hasShadow'] == true;
    final double textShadowOpacity = (props['shadowOpacity'] as double?) ?? 0.6;

    final Color baseShadowColor = (props['shadowColor'] is hive_model.HiveColor)
        ? (props['shadowColor'] as hive_model.HiveColor).toColor()
        : (props['shadowColor'] is Color)
        ? (props['shadowColor'] as Color)
        : Colors.grey;

    final Color effectiveShadowColor = baseShadowColor.withOpacity(
      (baseShadowColor.opacity * textShadowOpacity).clamp(0.0, 1.0),
    );

    final Color baseTextColor = textHasGradient
        ? Colors.white
        : (props['color'] is hive_model.HiveColor)
        ? (props['color'] as hive_model.HiveColor).toColor()
        : (props['color'] is Color)
        ? (props['color'] as Color)
        : Colors.black;

    final TextStyle baseStyle = TextStyle(
      fontSize: (props['fontSize'] ?? 24.0) as double,
      color: baseTextColor,
      fontWeight: _parseFontWeight(props['fontWeight']),
      fontStyle: _parseFontStyle(props['fontStyle']),
      decoration: _intToTextDecoration((props['decoration'] as int?) ?? 0),
      letterSpacing: (props['letterSpacing'] as double?) ?? 0.0,
      shadows: textHasShadow
          ? [
              Shadow(
                color: effectiveShadowColor,
                offset:
                    _parseOffset(props['shadowOffset']) ?? const Offset(2, 2),
                blurRadius: (props['shadowBlur'] as double?) ?? 4.0,
              ),
            ]
          : null,
      fontFamily: props['fontFamily'] as String?,
    );

    Widget textWidget = Text(
      text,
      style: baseStyle,
      textAlign: _parseTextAlign(props['textAlign']),
    );

    if (textHasGradient) {
      final gradientColors = props['gradientColors'] as List<dynamic>? ?? [];
      if (gradientColors.isNotEmpty) {
        final colors = gradientColors
            .map((c) => c is hive_model.HiveColor ? c.toColor() : Colors.black)
            .toList();
        final angle = (props['gradientAngle'] as double?) ?? 0.0;

        textWidget = ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(angle),
          ).createShader(bounds),
          child: textWidget,
        );
      }
    }

    return textWidget;
  }

  Widget _buildImageItem(hive_model.HiveCanvasItem item) {
    final props = item.properties;
    final filePath = props['filePath'] as String?;

    if (filePath == null || !File(filePath).existsSync()) {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image),
      );
    }

    return Image.file(
      File(filePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      },
    );
  }

  Widget _buildShapeItem(hive_model.HiveCanvasItem item) {
    final props = item.properties;
    final shape = props['shape'] as String? ?? 'rectangle';
    final fillColor = (props['fillColor'] is hive_model.HiveColor)
        ? (props['fillColor'] as hive_model.HiveColor).toColor()
        : Colors.blue;
    final strokeColor = (props['strokeColor'] is hive_model.HiveColor)
        ? (props['strokeColor'] as hive_model.HiveColor).toColor()
        : Colors.black;
    final strokeWidth = (props['strokeWidth'] as double?) ?? 2.0;
    final cornerRadius = (props['cornerRadius'] as double?) ?? 0.0;

    // Check if shape has an image fill
    final imagePath = props['imagePath'] as String?;
    final imageBase64 = props['imageBase64'] as String?;

    Widget shapeWidget;

    if (imagePath != null && File(imagePath).existsSync()) {
      shapeWidget = ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildBasicShape(
              shape,
              fillColor,
              strokeColor,
              strokeWidth,
              cornerRadius,
            );
          },
        ),
      );
    } else if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64);
        shapeWidget = ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildBasicShape(
                shape,
                fillColor,
                strokeColor,
                strokeWidth,
                cornerRadius,
              );
            },
          ),
        );
      } catch (e) {
        shapeWidget = _buildBasicShape(
          shape,
          fillColor,
          strokeColor,
          strokeWidth,
          cornerRadius,
        );
      }
    } else {
      shapeWidget = _buildBasicShape(
        shape,
        fillColor,
        strokeColor,
        strokeWidth,
        cornerRadius,
      );
    }

    return shapeWidget;
  }

  Widget _buildBasicShape(
    String shape,
    Color fillColor,
    Color strokeColor,
    double strokeWidth,
    double cornerRadius,
  ) {
    switch (shape.toLowerCase()) {
      case 'circle':
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: Border.all(color: strokeColor, width: strokeWidth),
          ),
        );
      case 'triangle':
        return CustomPaint(
          size: const Size(100, 100),
          painter: TrianglePainter(fillColor, strokeColor, strokeWidth),
        );
      default: // rectangle, square, etc.
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(color: strokeColor, width: strokeWidth),
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
        );
    }
  }

  Widget _buildStickerItem(hive_model.HiveCanvasItem item) {
    final props = item.properties;
    final iconCodePoint = props['iconCodePoint'] as int? ?? 0xe7fd;
    final color = (props['color'] is hive_model.HiveColor)
        ? (props['color'] as hive_model.HiveColor).toColor()
        : Colors.black;
    final size = (props['size'] as double?) ?? 60.0;

    return Icon(
      IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
      color: color,
      size: size,
    );
  }

  Widget _buildDrawingItem(hive_model.HiveCanvasItem item) {
    // For drawing items, we'd need to render the drawing data
    // This is a simplified placeholder
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: const Icon(Icons.edit),
    );
  }

  // Helper methods for parsing properties
  FontWeight _parseFontWeight(dynamic fontWeight) {
    if (fontWeight is FontWeight) return fontWeight;
    if (fontWeight is Map && fontWeight['fontWeightValue'] is int) {
      final value = fontWeight['fontWeightValue'] as int;
      if (value <= 100) return FontWeight.w100;
      if (value <= 200) return FontWeight.w200;
      if (value <= 300) return FontWeight.w300;
      if (value <= 400) return FontWeight.w400;
      if (value <= 500) return FontWeight.w500;
      if (value <= 600) return FontWeight.w600;
      if (value <= 700) return FontWeight.w700;
      if (value <= 800) return FontWeight.w800;
      return FontWeight.w900;
    }
    return FontWeight.normal;
  }

  FontStyle _parseFontStyle(dynamic fontStyle) {
    if (fontStyle is FontStyle) return fontStyle;
    if (fontStyle is Map && fontStyle['fontStyle'] is int) {
      final index = fontStyle['fontStyle'] as int;
      return FontStyle.values[index.clamp(0, FontStyle.values.length - 1)];
    }
    return FontStyle.normal;
  }

  TextAlign _parseTextAlign(dynamic textAlign) {
    if (textAlign is TextAlign) return textAlign;
    if (textAlign is Map && textAlign['textAlign'] is int) {
      final index = textAlign['textAlign'] as int;
      return TextAlign.values[index.clamp(0, TextAlign.values.length - 1)];
    }
    return TextAlign.center;
  }

  TextDecoration _intToTextDecoration(int decoration) {
    switch (decoration) {
      case 1:
        return TextDecoration.underline;
      case 2:
        return TextDecoration.lineThrough;
      case 3:
        return TextDecoration.overline;
      default:
        return TextDecoration.none;
    }
  }

  Offset? _parseOffset(dynamic offset) {
    if (offset is Offset) return offset;
    if (offset is Map && offset['dx'] is num && offset['dy'] is num) {
      return Offset(
        (offset['dx'] as num).toDouble(),
        (offset['dy'] as num).toDouble(),
      );
    }
    return null;
  }
}

/// Custom painter for triangle shapes
class TrianglePainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  TrianglePainter(this.fillColor, this.strokeColor, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
