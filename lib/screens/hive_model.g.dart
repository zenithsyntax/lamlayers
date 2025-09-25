// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PosterProjectAdapter extends TypeAdapter<PosterProject> {
  @override
  final int typeId = 0;

  @override
  PosterProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PosterProject(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      createdAt: fields[3] as DateTime,
      lastModified: fields[4] as DateTime,
      canvasItems: (fields[5] as List).cast<HiveCanvasItem>(),
      settings: fields[6] as ProjectSettings,
      thumbnailPath: fields[7] as String?,
      tags: (fields[8] as List).cast<String>(),
      isFavorite: fields[9] as bool,
      canvasWidth: fields[10] as double,
      canvasHeight: fields[11] as double,
      canvasBackgroundColor: fields[12] as HiveColor,
      backgroundImagePath: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PosterProject obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastModified)
      ..writeByte(5)
      ..write(obj.canvasItems)
      ..writeByte(6)
      ..write(obj.settings)
      ..writeByte(7)
      ..write(obj.thumbnailPath)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.isFavorite)
      ..writeByte(10)
      ..write(obj.canvasWidth)
      ..writeByte(11)
      ..write(obj.canvasHeight)
      ..writeByte(12)
      ..write(obj.canvasBackgroundColor)
      ..writeByte(13)
      ..write(obj.backgroundImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosterProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProjectSettingsAdapter extends TypeAdapter<ProjectSettings> {
  @override
  final int typeId = 1;

  @override
  ProjectSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectSettings(
      snapToGrid: fields[0] as bool,
      gridSize: fields[1] as double,
      canvasZoom: fields[2] as double,
      showGrid: fields[3] as bool,
      exportSettings: fields[4] as ExportSettings,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.snapToGrid)
      ..writeByte(1)
      ..write(obj.gridSize)
      ..writeByte(2)
      ..write(obj.canvasZoom)
      ..writeByte(3)
      ..write(obj.showGrid)
      ..writeByte(4)
      ..write(obj.exportSettings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportSettingsAdapter extends TypeAdapter<ExportSettings> {
  @override
  final int typeId = 2;

  @override
  ExportSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportSettings(
      format: fields[0] as ExportFormat,
      quality: fields[1] as ExportQuality,
      includeBackground: fields[2] as bool,
      pixelRatio: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ExportSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.format)
      ..writeByte(1)
      ..write(obj.quality)
      ..writeByte(2)
      ..write(obj.includeBackground)
      ..writeByte(3)
      ..write(obj.pixelRatio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCanvasItemAdapter extends TypeAdapter<HiveCanvasItem> {
  @override
  final int typeId = 3;

  @override
  HiveCanvasItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCanvasItem(
      id: fields[0] as String,
      type: fields[1] as HiveCanvasItemType,
      position: fields[2] as Offset,
      scale: fields[3] as double,
      rotation: fields[4] as double,
      opacity: fields[5] as double,
      layerIndex: fields[6] as int,
      isVisible: fields[7] as bool,
      isLocked: fields[8] as bool,
      properties: (fields[9] as Map).cast<String, dynamic>(),
      createdAt: fields[10] as DateTime,
      lastModified: fields[11] as DateTime,
      groupId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCanvasItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.scale)
      ..writeByte(4)
      ..write(obj.rotation)
      ..writeByte(5)
      ..write(obj.opacity)
      ..writeByte(6)
      ..write(obj.layerIndex)
      ..writeByte(7)
      ..write(obj.isVisible)
      ..writeByte(8)
      ..write(obj.isLocked)
      ..writeByte(9)
      ..write(obj.properties)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.lastModified)
      ..writeByte(12)
      ..write(obj.groupId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCanvasItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveColorAdapter extends TypeAdapter<HiveColor> {
  @override
  final int typeId = 4;

  @override
  HiveColor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveColor(
      fields[0] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveColor obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSizeAdapter extends TypeAdapter<HiveSize> {
  @override
  final int typeId = 5;

  @override
  HiveSize read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSize(
      fields[0] as double,
      fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSize obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.width)
      ..writeByte(1)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSizeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCanvasActionAdapter extends TypeAdapter<HiveCanvasAction> {
  @override
  final int typeId = 9;

  @override
  HiveCanvasAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCanvasAction(
      id: fields[0] as String,
      type: fields[1] as ActionType,
      item: fields[2] as HiveCanvasItem?,
      previousState: fields[3] as HiveCanvasItem?,
      timestamp: fields[4] as DateTime,
      description: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCanvasAction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.item)
      ..writeByte(3)
      ..write(obj.previousState)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCanvasActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveTextPropertiesAdapter extends TypeAdapter<HiveTextProperties> {
  @override
  final int typeId = 11;

  @override
  HiveTextProperties read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTextProperties(
      text: fields[0] as String,
      fontSize: fields[1] as double,
      color: fields[2] as HiveColor,
      fontWeight: fields[3] as FontWeight,
      fontStyle: fields[4] as FontStyle,
      textAlign: fields[5] as TextAlign,
      hasGradient: fields[6] as bool,
      gradientColors: (fields[7] as List).cast<HiveColor>(),
      gradientAngle: fields[8] as double,
      decoration: fields[9] as int,
      letterSpacing: fields[10] as double,
      hasShadow: fields[11] as bool,
      shadowColor: fields[12] as HiveColor,
      shadowOffset: fields[13] as Offset,
      shadowBlur: fields[14] as double,
      shadowOpacity: fields[15] as double,
      fontFamily: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveTextProperties obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.fontSize)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.fontWeight)
      ..writeByte(4)
      ..write(obj.fontStyle)
      ..writeByte(5)
      ..write(obj.textAlign)
      ..writeByte(6)
      ..write(obj.hasGradient)
      ..writeByte(7)
      ..write(obj.gradientColors)
      ..writeByte(8)
      ..write(obj.gradientAngle)
      ..writeByte(9)
      ..write(obj.decoration)
      ..writeByte(10)
      ..write(obj.letterSpacing)
      ..writeByte(11)
      ..write(obj.hasShadow)
      ..writeByte(12)
      ..write(obj.shadowColor)
      ..writeByte(13)
      ..write(obj.shadowOffset)
      ..writeByte(14)
      ..write(obj.shadowBlur)
      ..writeByte(15)
      ..write(obj.shadowOpacity)
      ..writeByte(16)
      ..write(obj.fontFamily);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTextPropertiesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveImagePropertiesAdapter extends TypeAdapter<HiveImageProperties> {
  @override
  final int typeId = 12;

  @override
  HiveImageProperties read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveImageProperties(
      filePath: fields[0] as String?,
      imageUrl: fields[1] as String?,
      tint: fields[2] as HiveColor,
      blur: fields[3] as double,
      hasGradient: fields[4] as bool,
      gradientColors: (fields[5] as List).cast<HiveColor>(),
      gradientAngle: fields[6] as double,
      hasShadow: fields[7] as bool,
      shadowColor: fields[8] as HiveColor,
      shadowOffset: fields[9] as Offset,
      shadowBlur: fields[10] as double,
      shadowOpacity: fields[11] as double,
      intrinsicWidth: fields[12] as double?,
      intrinsicHeight: fields[13] as double?,
      displayWidth: fields[14] as double?,
      displayHeight: fields[15] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveImageProperties obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(1)
      ..write(obj.imageUrl)
      ..writeByte(2)
      ..write(obj.tint)
      ..writeByte(3)
      ..write(obj.blur)
      ..writeByte(4)
      ..write(obj.hasGradient)
      ..writeByte(5)
      ..write(obj.gradientColors)
      ..writeByte(6)
      ..write(obj.gradientAngle)
      ..writeByte(7)
      ..write(obj.hasShadow)
      ..writeByte(8)
      ..write(obj.shadowColor)
      ..writeByte(9)
      ..write(obj.shadowOffset)
      ..writeByte(10)
      ..write(obj.shadowBlur)
      ..writeByte(11)
      ..write(obj.shadowOpacity)
      ..writeByte(12)
      ..write(obj.intrinsicWidth)
      ..writeByte(13)
      ..write(obj.intrinsicHeight)
      ..writeByte(14)
      ..write(obj.displayWidth)
      ..writeByte(15)
      ..write(obj.displayHeight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveImagePropertiesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveShapePropertiesAdapter extends TypeAdapter<HiveShapeProperties> {
  @override
  final int typeId = 13;

  @override
  HiveShapeProperties read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveShapeProperties(
      shape: fields[0] as String,
      fillColor: fields[1] as HiveColor,
      strokeColor: fields[2] as HiveColor,
      strokeWidth: fields[3] as double,
      hasGradient: fields[4] as bool,
      gradientColors: (fields[5] as List).cast<HiveColor>(),
      gradientAngle: fields[6] as double,
      cornerRadius: fields[7] as double,
      hasShadow: fields[8] as bool,
      shadowColor: fields[9] as HiveColor,
      shadowOffset: fields[10] as Offset,
      shadowBlur: fields[11] as double,
      shadowOpacity: fields[12] as double,
      imagePath: fields[13] as String?,
      size: fields[14] as HiveSize?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveShapeProperties obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.shape)
      ..writeByte(1)
      ..write(obj.fillColor)
      ..writeByte(2)
      ..write(obj.strokeColor)
      ..writeByte(3)
      ..write(obj.strokeWidth)
      ..writeByte(4)
      ..write(obj.hasGradient)
      ..writeByte(5)
      ..write(obj.gradientColors)
      ..writeByte(6)
      ..write(obj.gradientAngle)
      ..writeByte(7)
      ..write(obj.cornerRadius)
      ..writeByte(8)
      ..write(obj.hasShadow)
      ..writeByte(9)
      ..write(obj.shadowColor)
      ..writeByte(10)
      ..write(obj.shadowOffset)
      ..writeByte(11)
      ..write(obj.shadowBlur)
      ..writeByte(12)
      ..write(obj.shadowOpacity)
      ..writeByte(13)
      ..write(obj.imagePath)
      ..writeByte(14)
      ..write(obj.size);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveShapePropertiesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveStickerPropertiesAdapter extends TypeAdapter<HiveStickerProperties> {
  @override
  final int typeId = 14;

  @override
  HiveStickerProperties read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveStickerProperties(
      iconCodePoint: fields[0] as int,
      iconFontFamily: fields[1] as String?,
      color: fields[2] as HiveColor,
      size: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HiveStickerProperties obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.iconCodePoint)
      ..writeByte(1)
      ..write(obj.iconFontFamily)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.size);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveStickerPropertiesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProjectTemplateAdapter extends TypeAdapter<ProjectTemplate> {
  @override
  final int typeId = 15;

  @override
  ProjectTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      thumbnailPath: fields[3] as String,
      items: (fields[4] as List).cast<HiveCanvasItem>(),
      settings: fields[5] as ProjectSettings,
      tags: (fields[6] as List).cast<String>(),
      isPremium: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.thumbnailPath)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.settings)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.isPremium);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 16;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      autoSave: fields[0] as bool,
      autoSaveInterval: fields[1] as int,
      showGrid: fields[2] as bool,
      snapToGrid: fields[3] as bool,
      defaultExportFormat: fields[4] as ExportFormat,
      defaultExportQuality: fields[5] as ExportQuality,
      recentColors: (fields[6] as List).cast<HiveColor>(),
      recentFonts: (fields[7] as List).cast<String>(),
      enableHapticFeedback: fields[8] as bool,
      language: fields[9] as String,
      darkMode: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.autoSave)
      ..writeByte(1)
      ..write(obj.autoSaveInterval)
      ..writeByte(2)
      ..write(obj.showGrid)
      ..writeByte(3)
      ..write(obj.snapToGrid)
      ..writeByte(4)
      ..write(obj.defaultExportFormat)
      ..writeByte(5)
      ..write(obj.defaultExportQuality)
      ..writeByte(6)
      ..write(obj.recentColors)
      ..writeByte(7)
      ..write(obj.recentFonts)
      ..writeByte(8)
      ..write(obj.enableHapticFeedback)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.darkMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCanvasItemTypeAdapter extends TypeAdapter<HiveCanvasItemType> {
  @override
  final int typeId = 6;

  @override
  HiveCanvasItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveCanvasItemType.text;
      case 1:
        return HiveCanvasItemType.image;
      case 2:
        return HiveCanvasItemType.sticker;
      case 3:
        return HiveCanvasItemType.shape;
      default:
        return HiveCanvasItemType.text;
    }
  }

  @override
  void write(BinaryWriter writer, HiveCanvasItemType obj) {
    switch (obj) {
      case HiveCanvasItemType.text:
        writer.writeByte(0);
        break;
      case HiveCanvasItemType.image:
        writer.writeByte(1);
        break;
      case HiveCanvasItemType.sticker:
        writer.writeByte(2);
        break;
      case HiveCanvasItemType.shape:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCanvasItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportFormatAdapter extends TypeAdapter<ExportFormat> {
  @override
  final int typeId = 7;

  @override
  ExportFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExportFormat.png;
      case 1:
        return ExportFormat.jpg;
      case 2:
        return ExportFormat.pdf;
      case 3:
        return ExportFormat.svg;
      default:
        return ExportFormat.png;
    }
  }

  @override
  void write(BinaryWriter writer, ExportFormat obj) {
    switch (obj) {
      case ExportFormat.png:
        writer.writeByte(0);
        break;
      case ExportFormat.jpg:
        writer.writeByte(1);
        break;
      case ExportFormat.pdf:
        writer.writeByte(2);
        break;
      case ExportFormat.svg:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportQualityAdapter extends TypeAdapter<ExportQuality> {
  @override
  final int typeId = 8;

  @override
  ExportQuality read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExportQuality.low;
      case 1:
        return ExportQuality.medium;
      case 2:
        return ExportQuality.high;
      case 3:
        return ExportQuality.ultra;
      default:
        return ExportQuality.low;
    }
  }

  @override
  void write(BinaryWriter writer, ExportQuality obj) {
    switch (obj) {
      case ExportQuality.low:
        writer.writeByte(0);
        break;
      case ExportQuality.medium:
        writer.writeByte(1);
        break;
      case ExportQuality.high:
        writer.writeByte(2);
        break;
      case ExportQuality.ultra:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportQualityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActionTypeAdapter extends TypeAdapter<ActionType> {
  @override
  final int typeId = 10;

  @override
  ActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActionType.add;
      case 1:
        return ActionType.remove;
      case 2:
        return ActionType.modify;
      case 3:
        return ActionType.move;
      case 4:
        return ActionType.scale;
      case 5:
        return ActionType.rotate;
      case 6:
        return ActionType.duplicate;
      case 7:
        return ActionType.group;
      case 8:
        return ActionType.ungroup;
      default:
        return ActionType.add;
    }
  }

  @override
  void write(BinaryWriter writer, ActionType obj) {
    switch (obj) {
      case ActionType.add:
        writer.writeByte(0);
        break;
      case ActionType.remove:
        writer.writeByte(1);
        break;
      case ActionType.modify:
        writer.writeByte(2);
        break;
      case ActionType.move:
        writer.writeByte(3);
        break;
      case ActionType.scale:
        writer.writeByte(4);
        break;
      case ActionType.rotate:
        writer.writeByte(5);
        break;
      case ActionType.duplicate:
        writer.writeByte(6);
        break;
      case ActionType.group:
        writer.writeByte(7);
        break;
      case ActionType.ungroup:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
