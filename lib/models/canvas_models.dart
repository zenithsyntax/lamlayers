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
  bool isLocked;
  String? groupId;
  DateTime createdAt;
  DateTime lastModified;

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
    this.isLocked = false,
    this.groupId,
    required this.createdAt,
    required this.lastModified,
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
    bool? isLocked,
    String? groupId,
    DateTime? createdAt,
    DateTime? lastModified,
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
      isLocked: isLocked ?? this.isLocked,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? DateTime.now(),
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


