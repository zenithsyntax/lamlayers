// models/hive_models.dart
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

part 'hive_model.g.dart'; // Generated file

// Main Project Model
@HiveType(typeId: 0)
class PosterProject extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime lastModified;

  @HiveField(5)
  List<HiveCanvasItem> canvasItems;

  @HiveField(6)
  ProjectSettings settings;

  @HiveField(7)
  String? thumbnailPath; // Path to saved thumbnail image

  @HiveField(8)
  List<String> tags; // For categorization

  @HiveField(9)
  bool isFavorite;

  @HiveField(10)
  double canvasWidth;

  @HiveField(11)
  double canvasHeight;

  @HiveField(12)
  HiveColor canvasBackgroundColor;

  @HiveField(13)
  String? backgroundImagePath;

  PosterProject({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.lastModified,
    required this.canvasItems,
    required this.settings,
    this.thumbnailPath,
    this.tags = const [],
    this.isFavorite = false,
    this.canvasWidth = 1080,
    this.canvasHeight = 1920,
    this.canvasBackgroundColor = const HiveColor(0xFFFFFFFF),
    this.backgroundImagePath,
  });

  // Helper methods
  PosterProject copyWith({
    String? name,
    String? description,
    List<HiveCanvasItem>? canvasItems,
    ProjectSettings? settings,
    String? thumbnailPath,
    List<String>? tags,
    bool? isFavorite,
    double? canvasWidth,
    double? canvasHeight,
    HiveColor? canvasBackgroundColor,
    String? backgroundImagePath,
  }) {
    return PosterProject(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      lastModified: DateTime.now(),
      canvasItems: canvasItems ?? List.from(this.canvasItems),
      settings: settings ?? this.settings.copyWith(),
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tags: tags ?? List.from(this.tags),
      isFavorite: isFavorite ?? this.isFavorite,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      canvasBackgroundColor: canvasBackgroundColor ?? this.canvasBackgroundColor,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }
}

// Project Settings
@HiveType(typeId: 1)
class ProjectSettings {
  @HiveField(0)
  bool snapToGrid;

  @HiveField(1)
  double gridSize;

  @HiveField(2)
  double canvasZoom;

  @HiveField(3)
  bool showGrid;

  @HiveField(4)
  ExportSettings exportSettings;

  ProjectSettings({
    this.snapToGrid = false,
    this.gridSize = 20.0,
    this.canvasZoom = 1.0,
    this.showGrid = false,
    required this.exportSettings,
  });

  ProjectSettings copyWith({
    bool? snapToGrid,
    double? gridSize,
    double? canvasZoom,
    bool? showGrid,
    ExportSettings? exportSettings,
  }) {
    return ProjectSettings(
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
      canvasZoom: canvasZoom ?? this.canvasZoom,
      showGrid: showGrid ?? this.showGrid,
      exportSettings: exportSettings ?? this.exportSettings,
    );
  }
}

// Export Settings
@HiveType(typeId: 2)
class ExportSettings {
  @HiveField(0)
  ExportFormat format;

  @HiveField(1)
  ExportQuality quality;

  @HiveField(2)
  bool includeBackground;

  @HiveField(3)
  double pixelRatio;

  ExportSettings({
    this.format = ExportFormat.png,
    this.quality = ExportQuality.high,
    this.includeBackground = true,
    this.pixelRatio = 3.0,
  });
}

// Canvas Item Model
@HiveType(typeId: 3)
class HiveCanvasItem {
  @HiveField(0)
  String id;

  @HiveField(1)
  HiveCanvasItemType type;

  @HiveField(2)
  Offset position;

  @HiveField(3)
  double scale;

  @HiveField(4)
  double rotation;

  @HiveField(5)
  double opacity;

  @HiveField(6)
  int layerIndex;

  @HiveField(7)
  bool isVisible;

  @HiveField(8)
  bool isLocked;

  @HiveField(9)
  Map<String, dynamic> properties;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime lastModified;

  @HiveField(12)
  String? groupId; // For grouping items

  HiveCanvasItem({
    required this.id,
    required this.type,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    required this.layerIndex,
    this.isVisible = true,
    this.isLocked = false,
    required this.properties,
    required this.createdAt,
    required this.lastModified,
    this.groupId,
  });

  HiveCanvasItem copyWith({
    String? id,
    HiveCanvasItemType? type,
    Offset? position,
    double? scale,
    double? rotation,
    double? opacity,
    int? layerIndex,
    bool? isVisible,
    bool? isLocked,
    Map<String, dynamic>? properties,
    String? groupId,
  }) {
    return HiveCanvasItem(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      layerIndex: layerIndex ?? this.layerIndex,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      properties: properties ?? Map.from(this.properties),
      createdAt: this.createdAt,
      lastModified: DateTime.now(),
      groupId: groupId ?? this.groupId,
    );
  }
}

// Custom Hive Types for Flutter types
@HiveType(typeId: 4)
class HiveColor {
  @HiveField(0)
  final int value;

  const HiveColor(this.value);

  Color toColor() => Color(value);
  
  static HiveColor fromColor(Color color) => HiveColor(color.value);
}

@HiveType(typeId: 5)
class HiveSize {
  @HiveField(0)
  double width;

  @HiveField(1)
  double height;

  HiveSize(this.width, this.height);

  Size toSize() => Size(width, height);
  
  static HiveSize fromSize(Size size) => HiveSize(size.width, size.height);
}

// Adapter for Flutter's Color class
class ColorAdapter extends TypeAdapter<Color> {
  @override
  final typeId = 18; // Make sure this typeId is unique and not already used

  @override
  Color read(BinaryReader reader) {
    return Color(reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.value);
  }
}

// Enums
@HiveType(typeId: 6)
enum HiveCanvasItemType {
  @HiveField(0)
  text,
  
  @HiveField(1)
  image,
  
  @HiveField(2)
  sticker,
  
  @HiveField(3)
  shape,
}

@HiveType(typeId: 7)
enum ExportFormat {
  @HiveField(0)
  png,
  
  @HiveField(1)
  jpg,
  
  @HiveField(2)
  pdf,
  
  @HiveField(3)
  svg,
}

@HiveType(typeId: 8)
enum ExportQuality {
  @HiveField(0)
  low,
  
  @HiveField(1)
  medium,
  
  @HiveField(2)
  high,
  
  @HiveField(3)
  ultra,
}

// Action History for Undo/Redo
@HiveType(typeId: 9)
class HiveCanvasAction {
  @HiveField(0)
  String id;

  @HiveField(1)
  ActionType type;

  @HiveField(2)
  HiveCanvasItem? item;

  @HiveField(3)
  HiveCanvasItem? previousState;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  String description;

  HiveCanvasAction({
    required this.id,
    required this.type,
    this.item,
    this.previousState,
    required this.timestamp,
    this.description = '',
  });
}

@HiveType(typeId: 10)
enum ActionType {
  @HiveField(0)
  add,
  
  @HiveField(1)
  remove,
  
  @HiveField(2)
  modify,
  
  @HiveField(3)
  move,
  
  @HiveField(4)
  scale,
  
  @HiveField(5)
  rotate,
  
  @HiveField(6)
  duplicate,
  
  @HiveField(7)
  group,
  
  @HiveField(8)
  ungroup,
}

// Text Properties Model
@HiveType(typeId: 11)
class HiveTextProperties {
  @HiveField(0)
  String text;

  @HiveField(1)
  double fontSize;

  @HiveField(2)
  HiveColor color;

  @HiveField(3)
  FontWeight fontWeight; // FontWeight.w400, etc.

  @HiveField(4)
  FontStyle fontStyle; // FontStyle.normal = 0, FontStyle.italic = 1

  @HiveField(5)
  TextAlign textAlign; // TextAlign enum values

  @HiveField(6)
  bool hasGradient;

  @HiveField(7)
  List<HiveColor> gradientColors;

  @HiveField(8)
  double gradientAngle;

  @HiveField(9)
  int decoration; // TextDecoration enum

  @HiveField(10)
  double letterSpacing;

  @HiveField(11)
  bool hasShadow;

  @HiveField(12)
  HiveColor shadowColor;

  @HiveField(13)
  Offset shadowOffset;

  @HiveField(14)
  double shadowBlur;

  @HiveField(15)
  double shadowOpacity;

  @HiveField(16)
  String? fontFamily;

  HiveTextProperties({
    required this.text,
    required this.fontSize,
    required this.color,
    this.fontWeight = FontWeight.w400,
    this.fontStyle = FontStyle.normal,
    this.textAlign = TextAlign.center,
    this.hasGradient = false,
    this.gradientColors = const [],
    this.gradientAngle = 0.0,
    this.decoration = 0, // TextDecoration.none
    this.letterSpacing = 0.0,
    this.hasShadow = false,
    required this.shadowColor,
    required this.shadowOffset,
    this.shadowBlur = 4.0,
    this.shadowOpacity = 0.6,
    this.fontFamily,
  });
}

// Image Properties Model
@HiveType(typeId: 12)
class HiveImageProperties {
  @HiveField(0)
  String? filePath;

  @HiveField(1)
  String? imageUrl;

  @HiveField(2)
  HiveColor tint;

  @HiveField(3)
  double blur;

  @HiveField(4)
  bool hasGradient;

  @HiveField(5)
  List<HiveColor> gradientColors;

  @HiveField(6)
  double gradientAngle;

  @HiveField(7)
  bool hasShadow;

  @HiveField(8)
  HiveColor shadowColor;

  @HiveField(9)
  Offset shadowOffset;

  @HiveField(10)
  double shadowBlur;

  @HiveField(11)
  double shadowOpacity;

  @HiveField(12)
  double? intrinsicWidth;

  @HiveField(13)
  double? intrinsicHeight;

  @HiveField(14)
  double? displayWidth;

  @HiveField(15)
  double? displayHeight;

  HiveImageProperties({
    this.filePath,
    this.imageUrl,
    required this.tint,
    this.blur = 0.0,
    this.hasGradient = false,
    this.gradientColors = const [],
    this.gradientAngle = 0.0,
    this.hasShadow = false,
    required this.shadowColor,
    required this.shadowOffset,
    this.shadowBlur = 8.0,
    this.shadowOpacity = 0.6,
    this.intrinsicWidth,
    this.intrinsicHeight,
    this.displayWidth,
    this.displayHeight,
  });
}

// Shape Properties Model
@HiveType(typeId: 13)
class HiveShapeProperties {
  @HiveField(0)
  String shape;

  @HiveField(1)
  HiveColor fillColor;

  @HiveField(2)
  HiveColor strokeColor;

  @HiveField(3)
  double strokeWidth;

  @HiveField(4)
  bool hasGradient;

  @HiveField(5)
  List<HiveColor> gradientColors;

  @HiveField(6)
  double gradientAngle;

  @HiveField(7)
  double cornerRadius;

  @HiveField(8)
  bool hasShadow;

  @HiveField(9)
  HiveColor shadowColor;

  @HiveField(10)
  Offset shadowOffset;

  @HiveField(11)
  double shadowBlur;

  @HiveField(12)
  double shadowOpacity;

  @HiveField(13)
  String? imagePath; // For image-filled shapes

  @HiveField(14)
  HiveSize? size;

  HiveShapeProperties({
    required this.shape,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.0,
    this.hasGradient = false,
    this.gradientColors = const [],
    this.gradientAngle = 0.0,
    this.cornerRadius = 0.0,
    this.hasShadow = false,
    required this.shadowColor,
    required this.shadowOffset,
    this.shadowBlur = 8.0,
    this.shadowOpacity = 0.6,
    this.imagePath,
    this.size,
  });
}

// Sticker Properties Model
@HiveType(typeId: 14)
class HiveStickerProperties {
  @HiveField(0)
  int iconCodePoint;

  @HiveField(1)
  String? iconFontFamily;

  @HiveField(2)
  HiveColor color;

  @HiveField(3)
  double size;

  HiveStickerProperties({
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.color,
    this.size = 60.0,
  });
}

// Project Template Model
@HiveType(typeId: 15)
class ProjectTemplate {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  String thumbnailPath;

  @HiveField(4)
  List<HiveCanvasItem> items;

  @HiveField(5)
  ProjectSettings settings;

  @HiveField(6)
  List<String> tags;

  @HiveField(7)
  bool isPremium;

  ProjectTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailPath,
    required this.items,
    required this.settings,
    this.tags = const [],
    this.isPremium = false,
  });
}

// User Preferences
@HiveType(typeId: 16)
class UserPreferences {
  @HiveField(0)
  bool autoSave;

  @HiveField(1)
  int autoSaveInterval; // in seconds

  @HiveField(2)
  bool showGrid;

  @HiveField(3)
  bool snapToGrid;

  @HiveField(4)
  ExportFormat defaultExportFormat;

  @HiveField(5)
  ExportQuality defaultExportQuality;

  @HiveField(6)
  List<HiveColor> recentColors;

  @HiveField(7)
  List<String> recentFonts;

  @HiveField(8)
  bool enableHapticFeedback;

  @HiveField(9)
  String language;

  @HiveField(10)
  bool darkMode;

  UserPreferences({
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.showGrid = false,
    this.snapToGrid = false,
    this.defaultExportFormat = ExportFormat.png,
    this.defaultExportQuality = ExportQuality.high,
    this.recentColors = const [],
    this.recentFonts = const [],
    this.enableHapticFeedback = true,
    this.language = 'en',
    this.darkMode = false,
  });
}

class FontWeightAdapter extends TypeAdapter<FontWeight> {
  @override
  final typeId = 19; // Unique typeId

  @override
  FontWeight read(BinaryReader reader) {
    return FontWeight.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, FontWeight obj) {
    writer.writeByte(obj.index);
  }
}

class FontStyleAdapter extends TypeAdapter<FontStyle> {
  @override
  final typeId = 20; // Unique typeId

  @override
  FontStyle read(BinaryReader reader) {
    return FontStyle.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, FontStyle obj) {
    writer.writeByte(obj.index);
  }
}

class TextAlignAdapter extends TypeAdapter<TextAlign> {
  @override
  final typeId = 21; // Unique typeId

  @override
  TextAlign read(BinaryReader reader) {
    return TextAlign.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TextAlign obj) {
    writer.writeByte(obj.index);
  }
}

class OffsetAdapter extends TypeAdapter<Offset> {
  @override
  final typeId = 22; // Unique typeId

  @override
  Offset read(BinaryReader reader) {
    final dx = reader.readDouble();
    final dy = reader.readDouble();
    return Offset(dx, dy);
  }

  @override
  void write(BinaryWriter writer, Offset obj) {
    writer.writeDouble(obj.dx);
    writer.writeDouble(obj.dy);
  }
}