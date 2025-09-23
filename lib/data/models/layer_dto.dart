import 'package:flutter/material.dart';
import 'dart:io';
import '../../domain/entities/layer_kind.dart';
import '../../domain/entities/shape_kind.dart';
import 'layer_data.dart';

class LayerDto {
  final String id;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final String kind;

  final String? text;
  final double? fontSize;
  final int? textColor;
  final String? fontFamily;
  final String? textAlign;

  final String? imagePath;

  final String? shapeKind;
  final int? fillColor;
  final double? opacity;

  const LayerDto({
    required this.id,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.kind,
    this.text,
    this.fontSize,
    this.textColor,
    this.fontFamily,
    this.textAlign,
    this.imagePath,
    this.shapeKind,
    this.fillColor,
    this.opacity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
      'kind': kind,
      'text': text,
      'fontSize': fontSize,
      'textColor': textColor,
      'fontFamily': fontFamily,
      'textAlign': textAlign,
      'imagePath': imagePath,
      'shapeKind': shapeKind,
      'fillColor': fillColor,
      'opacity': opacity,
    };
  }

  static LayerDto fromMap(Map<String, dynamic> map) {
    return LayerDto(
      id: map['id'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      scale: (map['scale'] as num).toDouble(),
      rotation: (map['rotation'] as num).toDouble(),
      kind: map['kind'] as String,
      text: map['text'] as String?,
      fontSize: (map['fontSize'] as num?)?.toDouble(),
      textColor: map['textColor'] as int?,
      fontFamily: map['fontFamily'] as String?,
      textAlign: map['textAlign'] as String?,
      imagePath: map['imagePath'] as String?,
      shapeKind: map['shapeKind'] as String?,
      fillColor: map['fillColor'] as int?,
      opacity: (map['opacity'] as num?)?.toDouble(),
    );
  }

  static LayerDto fromModel(LayerData layer) {
    return LayerDto(
      id: layer.id,
      x: layer.position.dx,
      y: layer.position.dy,
      scale: layer.scale,
      rotation: layer.rotation,
      kind: layer.kind.name,
      text: layer.text,
      fontSize: layer.textStyle?.fontSize,
      textColor: layer.textStyle?.color?.value,
      fontFamily: layer.fontFamily,
      textAlign: layer.textAlign?.name,
      imagePath: layer.imagePath,
      shapeKind: layer.shapeKind?.name,
      fillColor: layer.fillColor?.value,
      opacity: layer.opacity,
    );
  }

  LayerData toModel() {
    final layerKind = LayerKind.values.firstWhere((e) => e.name == kind);
    final shape = shapeKind != null
        ? ShapeKind.values.firstWhere((e) => e.name == shapeKind)
        : null;

    Widget child;
    if (layerKind == LayerKind.text) {
      final style = TextStyle(
        fontSize: fontSize ?? 24,
        color: textColor != null ? Color(textColor!) : Colors.black,
        fontFamily: fontFamily,
      );
      child = Text(text ?? 'Text', style: style, textAlign: _mapAlign(textAlign));
    } else if (layerKind == LayerKind.image) {
      child = imagePath != null
          ? Image.file(File(imagePath!), width: 150, height: 150, fit: BoxFit.cover)
          : const SizedBox.shrink();
    } else {
      final color = fillColor != null ? Color(fillColor!) : Colors.blue;
      switch (shape) {
        case ShapeKind.rectangle:
          child = Container(width: 120, height: 80, color: color.withOpacity(opacity ?? 1));
          break;
        case ShapeKind.circle:
          child = Container(width: 100, height: 100, decoration: BoxDecoration(color: color.withOpacity(opacity ?? 1), shape: BoxShape.circle));
          break;
        case ShapeKind.line:
          child = Container(width: 140, height: 4, color: color.withOpacity(opacity ?? 1));
          break;
        case ShapeKind.triangle:
          child = CustomPaint(size: const Size(100, 100), painter: _TrianglePainter(color.withOpacity(opacity ?? 1)));
          break;
        default:
          child = const SizedBox.shrink();
      }
    }

    return LayerData(
      id: id,
      child: child,
      position: Offset(x, y),
      scale: scale,
      rotation: rotation,
      kind: layerKind,
      text: text,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: textColor != null ? Color(textColor!) : null,
        fontFamily: fontFamily,
      ),
      fontFamily: fontFamily,
      textAlign: _mapAlign(textAlign),
      imagePath: imagePath,
      shapeKind: shape,
      fillColor: fillColor != null ? Color(fillColor!) : null,
      opacity: opacity,
    );
  }

  static TextAlign _mapAlign(String? name) {
    switch (name) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      case 'left':
      default:
        return TextAlign.left;
    }
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


