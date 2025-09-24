import 'package:flutter/material.dart';

// Enum for canvas item types
enum CanvasItemType { text, image, sticker, shape }

// Enum for blend modes
enum CustomBlendMode { normal, multiply, screen, overlay, darken, lighten }

// Model for canvas items
class CanvasItem {
  final String id;
  final CanvasItemType type;
  Offset position;
  double rotation;
  double scale;
  double opacity;
  CustomBlendMode blendMode;
  Map<String, dynamic> properties;
  int layerIndex;
  bool isVisible;

  CanvasItem({
    required this.id,
    required this.type,
    this.position = const Offset(100, 100),
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.blendMode = CustomBlendMode.normal,
    this.properties = const {},
    this.layerIndex = 0,
    this.isVisible = true,
  });

  CanvasItem copyWith({
    String? id,
    CanvasItemType? type,
    Offset? position,
    double? rotation,
    double? scale,
    double? opacity,
    CustomBlendMode? blendMode,
    Map<String, dynamic>? properties,
    int? layerIndex,
    bool? isVisible,
  }) {
    return CanvasItem(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      properties: properties ?? Map<String, dynamic>.from(this.properties),
      layerIndex: layerIndex ?? this.layerIndex,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

// Action model for undo/redo
class CanvasAction {
  final String type; // 'add', 'remove', 'modify'
  final CanvasItem? item;
  final CanvasItem? previousState;
  final DateTime timestamp;

  CanvasAction({
    required this.type,
    this.item,
    this.previousState,
    required this.timestamp,
  });
}


