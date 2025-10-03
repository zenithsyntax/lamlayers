import 'package:flutter/material.dart';

// Enum for canvas item types
enum CanvasItemType { text, image, sticker, shape, drawing }

// Enum for drawing tools
enum DrawingTool {
  brush,
  pencil,
  rectangle,
  circle,
  triangle,
  line,
  arrow,
  dottedLine,
  dottedArrow,
}

// Enum for drawing modes
enum DrawingMode { enabled, disabled }

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

// Model for drawing layers
class DrawingLayer {
  final String id;
  final DrawingTool tool;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isDotted;
  final double opacity;
  final bool isVisible;
  final DateTime createdAt;

  DrawingLayer({
    required this.id,
    required this.tool,
    this.points = const [],
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.isDotted = false,
    this.opacity = 1.0,
    this.isVisible = true,
    required this.createdAt,
  });

  DrawingLayer copyWith({
    String? id,
    DrawingTool? tool,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isDotted,
    double? opacity,
    bool? isVisible,
    DateTime? createdAt,
  }) {
    return DrawingLayer(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      points: points ?? List<Offset>.from(this.points),
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDotted: isDotted ?? this.isDotted,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
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
