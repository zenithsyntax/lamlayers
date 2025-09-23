import 'package:flutter/material.dart';
import '../../domain/entities/layer_kind.dart';
import '../../domain/entities/shape_kind.dart';

class LayerData {
  String id;
  Widget child;
  Offset position;
  double scale;
  double rotation;

  // Common meta
  LayerKind kind;

  // Text
  String? text;
  TextStyle? textStyle;
  String? fontFamily;
  TextAlign? textAlign;

  // Image
  String? imagePath;

  // Shape
  ShapeKind? shapeKind;
  Color? fillColor;
  double? opacity;

  LayerData({
    required this.id,
    required this.child,
    this.position = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
    required this.kind,
    this.text,
    this.textStyle,
    this.fontFamily,
    this.textAlign,
    this.imagePath,
    this.shapeKind,
    this.fillColor,
    this.opacity,
  });

  bool get isText => kind == LayerKind.text;
  bool get isImage => kind == LayerKind.image;
  bool get isShape => kind == LayerKind.shape;

  LayerData copyWith({
    String? id,
    Widget? child,
    Offset? position,
    double? scale,
    double? rotation,
    LayerKind? kind,
    String? text,
    TextStyle? textStyle,
    String? fontFamily,
    TextAlign? textAlign,
    String? imagePath,
    ShapeKind? shapeKind,
    Color? fillColor,
    double? opacity,
  }) {
    return LayerData(
      id: id ?? this.id,
      child: child ?? this.child,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      textStyle: textStyle ?? this.textStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      imagePath: imagePath ?? this.imagePath,
      shapeKind: shapeKind ?? this.shapeKind,
      fillColor: fillColor ?? this.fillColor,
      opacity: opacity ?? this.opacity,
    );
  }
}