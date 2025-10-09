import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:lamlayers/screens/hive_model.dart' as hive_model;
import 'package:lamlayers/widgets/export_dialog.dart' as export_dialog;
import 'package:device_info_plus/device_info_plus.dart';

class ExportManager {
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ uses READ_MEDIA_IMAGES for saving to Photos
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final int sdkInt = androidInfo.version.sdkInt ?? 33;
    if (sdkInt >= 33) {
      // On Android 13+ request READ_MEDIA_IMAGES (mapped to Permission.photos)
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    // Android 10-12: need storage permission; WRITE is only up to 29
    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;
    // As a last resort on some OEMs
    final manage = await Permission.manageExternalStorage.request();
    return manage.isGranted;
  }

  static double getPixelRatio(export_dialog.ExportClarity clarity) {
    switch (clarity) {
      case export_dialog.ExportClarity.high:
        return 3.0;
      case export_dialog.ExportClarity.medium:
        return 2.0;
      case export_dialog.ExportClarity.low:
        return 1.0;
    }
  }

  static ui.ImageByteFormat getImageFormat(export_dialog.ExportFormat format) {
    switch (format) {
      case export_dialog.ExportFormat.png:
        return ui.ImageByteFormat.png;
      case export_dialog.ExportFormat.jpg:
        return ui.ImageByteFormat.rawRgba;
    }
  }

  static String getFileExtension(export_dialog.ExportFormat format) {
    switch (format) {
      case export_dialog.ExportFormat.png:
        return 'png';
      case export_dialog.ExportFormat.jpg:
        return 'jpg';
    }
  }

  static Future<String?> exportImage(
    GlobalKey canvasKey,
    export_dialog.ExportOptions options,
  ) async {
    try {
      // Ensure we have permissions where needed (Android public storage)
      final bool hasPerm = await requestPermissions();
      if (!hasPerm) {
        print('ExportManager: Storage permission not granted; using app temp');
      }
      final boundary =
          canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final pixelRatio = getPixelRatio(options.clarity);
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      final format = getImageFormat(options.format);
      final ByteData? byteData = await image.toByteData(format: format);

      if (byteData == null) return null;

      Uint8List imageBytes = byteData.buffer.asUint8List();

      // Convert RGBA to JPEG if needed
      if (options.format == export_dialog.ExportFormat.jpg) {
        imageBytes = await _convertToJpeg(
          imageBytes,
          image.width,
          image.height,
        );
      }

      // Save to gallery via GallerySaver (requires a file path)
      if (Platform.isAndroid) {
        final Directory tempDir = await getTemporaryDirectory();
        final String name =
            'LamLayers_${DateTime.now().millisecondsSinceEpoch}.${getFileExtension(options.format)}';
        final String tempPath = '${tempDir.path}/$name';
        final File tmp = File(tempPath);
        await tmp.writeAsBytes(imageBytes);

        final result = await SaverGallery.saveFile(
          filePath: tempPath,
          androidRelativePath: 'Pictures/LamLayers',
          fileName: name,
          skipIfExists: false,
        );

        if (result.isSuccess) {
          return tempPath;
        }
        // If gallery save failed, we still return tempPath below
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/LamLayers_${DateTime.now().millisecondsSinceEpoch}.${getFileExtension(options.format)}';
      await File(tempPath).writeAsBytes(imageBytes);
      return tempPath;
    } catch (e) {
      print('Error exporting image: $e');
      return null;
    }
  }

  static Future<Uint8List> _convertToJpeg(
    Uint8List rgbaBytes,
    int width,
    int height,
  ) async {
    // Flatten RGBA onto white (JPEG has no alpha), producing RGB bytes
    final int pixelCount = width * height;
    final Uint8List rgbBytes = Uint8List(pixelCount * 3);
    int src = 0;
    int dst = 0;
    for (int i = 0; i < pixelCount; i++) {
      final int r = rgbaBytes[src];
      final int g = rgbaBytes[src + 1];
      final int b = rgbaBytes[src + 2];
      final int a = rgbaBytes[src + 3];
      // Alpha blend over white: out = a*color + (1-a)*255
      final int outR = 255 - (((255 - r) * a) ~/ 255);
      final int outG = 255 - (((255 - g) * a) ~/ 255);
      final int outB = 255 - (((255 - b) * a) ~/ 255);
      rgbBytes[dst] = outR;
      rgbBytes[dst + 1] = outG;
      rgbBytes[dst + 2] = outB;
      src += 4;
      dst += 3;
    }

    // Create 3-channel image from RGB bytes and encode to JPEG
    final img.Image rgbImage = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbBytes.buffer,
      numChannels: 3,
      format: img.Format.uint8,
      order: img.ChannelOrder.rgb,
    );

    return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 90));
  }

  static Future<bool> saveToGallery(String filePath) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      final String name = filePath.split('/').last;
      final result = await SaverGallery.saveFile(
        filePath: filePath,
        androidRelativePath: 'Pictures/LamLayers',
        fileName: name,
        skipIfExists: true,
      );
      return result.isSuccess;
    } catch (e) {
      print('Error saving to gallery: $e');
      return false;
    }
  }

  static Future<void> shareImage(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'My poster');
    } catch (e) {
      print('Error sharing image: $e');
    }
  }

  static Future<String?> exportProject(hive_model.PosterProject project) async {
    try {
      print('ExportManager: Starting project export for "${project.name}"');
      print(
        'ExportManager: Project has ${project.canvasItems.length} canvas items',
      );

      // Request permissions on Android before attempting to write to public storage
      final bool hasPerm = await requestPermissions();
      if (!hasPerm) {
        print(
          'ExportManager: Storage permission not granted; will try app dir fallback',
        );
      }

      // Choose export directory: Downloads on Android, temp elsewhere
      Directory targetDir;
      if (Platform.isAndroid) {
        // Prefer Downloads; if not writable, fall back to app external, then temp
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          try {
            await targetDir.create(recursive: true);
          } catch (_) {}
        }
        if (!await _isWritableDirectory(targetDir)) {
          targetDir =
              (await getExternalStorageDirectory()) ??
              await getTemporaryDirectory();
        }
      } else {
        targetDir = await getTemporaryDirectory();
      }

      final String fileName =
          '${project.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.lamlayer';
      final String filePath = '${targetDir.path}/$fileName';

      print('ExportManager: Creating archive file at: $filePath');

      // Create archive
      final archive = Archive();

      // Add project data as JSON
      print('ExportManager: Converting project to JSON...');
      final projectJson = await _projectToJson(project);
      print(
        'ExportManager: JSON conversion completed, size: ${projectJson.length} bytes',
      );

      archive.addFile(
        ArchiveFile('project.json', projectJson.length, projectJson),
      );

      // Images are now embedded in the JSON data as base64
      print('ExportManager: Images embedded in JSON data');

      // Write archive to file
      print('ExportManager: Encoding archive...');
      final zipBytes = ZipEncoder().encode(archive);
      print('ExportManager: Archive encoded, size: ${zipBytes.length} bytes');

      final File file = File(filePath);
      print('ExportManager: Writing file to disk...');
      try {
        await file.writeAsBytes(zipBytes);
        print('ExportManager: File written successfully to $filePath');
      } catch (e) {
        print(
          'ExportManager: Failed to write to preferred location ($filePath): $e',
        );
        // Fallback to temp if writing failed
        final Directory tempDir = await getTemporaryDirectory();
        final String fallbackPath = '${tempDir.path}/$fileName';
        final File fallback = File(fallbackPath);
        await fallback.writeAsBytes(zipBytes);
        print('ExportManager: File written to fallback path: $fallbackPath');
        return fallbackPath;
      }

      return filePath;
    } catch (e) {
      print('ExportManager: Error exporting project: $e');
      print('ExportManager: Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  static Future<bool> _isWritableDirectory(Directory dir) async {
    try {
      final String testPath = '${dir.path}/.lamlayers_write_test';
      final File f = File(testPath);
      await f.writeAsBytes([1, 2, 3]);
      await f.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List> _projectToJson(
    hive_model.PosterProject project,
  ) async {
    try {
      print('ExportManager: Converting project to JSON...');

      // Convert project to comprehensive JSON with all data
      final Map<String, dynamic> projectData = {
        "id": project.id,
        "name": project.name,
        "description": project.description ?? '',
        "createdAt": project.createdAt.toIso8601String(),
        "lastModified": project.lastModified.toIso8601String(),
        "canvasWidth": project.canvasWidth,
        "canvasHeight": project.canvasHeight,
        "canvasBackgroundColor": {
          "value": project.canvasBackgroundColor.value,
          "alpha": project.canvasBackgroundColor.value >> 24 & 0xFF,
          "red": project.canvasBackgroundColor.value >> 16 & 0xFF,
          "green": project.canvasBackgroundColor.value >> 8 & 0xFF,
          "blue": project.canvasBackgroundColor.value & 0xFF,
        },
        // Preserve intended z-order explicitly
        "layerOrder": (() {
          final List<hive_model.HiveCanvasItem> items =
              List<hive_model.HiveCanvasItem>.from(project.canvasItems);
          items.sort((a, b) {
            final byLayer = a.layerIndex.compareTo(b.layerIndex);
            if (byLayer != 0) return byLayer;
            return a.createdAt.compareTo(b.createdAt);
          });
          return items.map((e) => e.id).toList();
        })(),
      };

      print('ExportManager: Encoding background image...');
      projectData["backgroundImageData"] = await _encodeImageToBase64(
        project.backgroundImagePath,
      );

      print('ExportManager: Encoding thumbnail...');
      projectData["thumbnailData"] = await _encodeImageToBase64(
        project.thumbnailPath,
      );

      print('ExportManager: Serializing canvas items...');
      projectData["canvasItems"] = await _serializeCanvasItems(
        project.canvasItems,
      );

      projectData["settings"] = {
        "snapToGrid": project.settings.snapToGrid,
        "gridSize": project.settings.gridSize,
        "canvasZoom": project.settings.canvasZoom,
        "showGrid": project.settings.showGrid,
        "exportSettings": {
          "format": project.settings.exportSettings.format.index,
          "quality": project.settings.exportSettings.quality.index,
          "includeBackground":
              project.settings.exportSettings.includeBackground,
          "pixelRatio": project.settings.exportSettings.pixelRatio,
        },
      };

      projectData["tags"] = project.tags;
      projectData["isFavorite"] = project.isFavorite;

      print('ExportManager: Encoding to JSON string...');
      // Use proper JSON encoding instead of custom serialization
      final jsonString = jsonEncode(projectData);
      print('ExportManager: JSON string length: ${jsonString.length}');

      return Uint8List.fromList(utf8.encode(jsonString));
    } catch (e) {
      print('ExportManager: Error converting project to JSON: $e');
      print('ExportManager: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static String _basename(String path) {
    if (path.isEmpty) return path;
    // Normalize Windows and POSIX separators
    final String normalized = path.replaceAll('\\', '/');
    final int idx = normalized.lastIndexOf('/');
    if (idx == -1) return normalized;
    return normalized.substring(idx + 1);
  }

  static Future<String?> _encodeImageToBase64(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('Image file does not exist: $imagePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        print('Image file is empty: $imagePath');
        return null;
      }

      // Encode to base64
      final base64String = base64Encode(bytes);
      print(
        'Successfully encoded image to base64: ${imagePath.split('/').last} (${bytes.length} bytes)',
      );
      return base64String;
    } catch (e) {
      print('Error encoding image to base64: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _serializeCanvasItems(
    List<hive_model.HiveCanvasItem> items,
  ) async {
    final List<Map<String, dynamic>> serializedItems = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final Map<String, dynamic> itemData = {
        "id": item.id,
        "type": item.type.index,
        "position": {"dx": item.position.dx, "dy": item.position.dy},
        "scale": item.scale,
        "rotation": item.rotation,
        "opacity": item.opacity,
        "layerIndex": item.layerIndex,
        "isVisible": item.isVisible,
        "isLocked": item.isLocked,
        "groupId": item.groupId,
        "createdAt": item.createdAt.toIso8601String(),
        "lastModified": item.lastModified.toIso8601String(),
        "properties": await _serializeItemProperties(item),
      };

      // Add image data for image items
      if (item.type == hive_model.HiveCanvasItemType.image) {
        // Prefer the flat filePath (stroked) first; fallback to nested original path
        String? filePathToEncode =
            (item.properties['filePath'] is String &&
                (item.properties['filePath'] as String).isNotEmpty)
            ? item.properties['filePath'] as String
            : null;

        if (filePathToEncode == null || filePathToEncode.isEmpty) {
          final hive_model.HiveImageProperties? nestedProps =
              item.properties['imageProperties']
                  as hive_model.HiveImageProperties?;
          if (nestedProps?.filePath != null &&
              nestedProps!.filePath!.isNotEmpty) {
            filePathToEncode = nestedProps.filePath;
          }
        }

        if (filePathToEncode != null && filePathToEncode.isNotEmpty) {
          final imageData = await _encodeImageToBase64(filePathToEncode);
          if (imageData != null) {
            itemData["imageData"] = imageData;
            itemData["originalImageName"] = _basename(filePathToEncode);
          } else {
            print('Warning: Failed to encode image for item ${item.id}');
          }
        }
      }

      // Add embedded image data for shape items that have an image fill
      if (item.type == hive_model.HiveCanvasItemType.shape) {
        // Redundantly mirror strokeColor for backward/forward compatibility across app versions
        try {
          final Map<String, dynamic> props = Map<String, dynamic>.from(
            itemData["properties"] as Map<String, dynamic>,
          );
          // If strokeColor exists as HiveColor serialization, also write a primitive value
          if (props.containsKey('strokeColor')) {
            final dynamic sc = props['strokeColor'];
            if (sc is Map && sc['value'] is int) {
              props['strokeColorValue'] = sc['value'];
            } else if (sc is int) {
              props['strokeColorValue'] = sc;
            }
          }
          // If nested shapeProperties exists, mirror strokeColor there too
          if (props['shapeProperties'] is Map<String, dynamic>) {
            final Map<String, dynamic> sp = Map<String, dynamic>.from(
              props['shapeProperties'] as Map,
            );
            if (sp.containsKey('strokeColor')) {
              final dynamic nsc = sp['strokeColor'];
              if (nsc is Map && nsc['value'] is int) {
                sp['strokeColorValue'] = nsc['value'];
              } else if (nsc is int) {
                sp['strokeColorValue'] = nsc;
              }
            }
            props['shapeProperties'] = sp;
          }
          itemData["properties"] = props;
        } catch (_) {}

        print(
          'ExportManager: Shape item ${item.id} - preparing image embedding',
        );
        // Prefer file path when available; otherwise fall back to any stored base64
        String? shapeImagePath;
        String? shapeImageData;

        final shapeProps =
            item.properties['shapeProperties']
                as hive_model.HiveShapeProperties?;
        if (shapeProps?.imagePath != null &&
            shapeProps!.imagePath!.isNotEmpty) {
          shapeImagePath = shapeProps.imagePath;
        }
        // Fallback to top-level imagePath used by runtime
        shapeImagePath ??=
            (item.properties['imagePath'] is String &&
                (item.properties['imagePath'] as String).isNotEmpty)
            ? item.properties['imagePath'] as String
            : null;

        if (shapeImagePath != null && shapeImagePath.isNotEmpty) {
          print(
            'ExportManager: Shape item ${item.id} - found imagePath: ' +
                shapeImagePath,
          );
          shapeImageData = await _encodeImageToBase64(shapeImagePath);
          if (shapeImageData == null) {
            print(
              'Warning: Failed to encode shape image from path for item ${item.id}',
            );
          }
        }

        // If we couldn't get bytes from path, use any base64 already present in properties
        if (shapeImageData == null || shapeImageData.isEmpty) {
          print(
            'ExportManager: Shape item ${item.id} - falling back to inline base64 in properties',
          );
          try {
            final Map<String, dynamic> props = Map<String, dynamic>.from(
              itemData["properties"] as Map<String, dynamic>,
            );
            String? inlineBase64;
            if (props['shapeProperties'] is Map<String, dynamic>) {
              final Map<String, dynamic> sp = Map<String, dynamic>.from(
                props['shapeProperties'] as Map<String, dynamic>,
              );
              inlineBase64 = sp['imageBase64'] as String?;
            }
            inlineBase64 ??= props['imageBase64'] as String?;
            if (inlineBase64 != null && inlineBase64.isNotEmpty) {
              shapeImageData = inlineBase64;
              print(
                'ExportManager: Shape item ${item.id} - inline base64 found, length: ' +
                    inlineBase64.length.toString(),
              );
            }
          } catch (_) {}
        }

        if (shapeImageData != null && shapeImageData.isNotEmpty) {
          print(
            'ExportManager: Shape item ${item.id} - embedding shapeImageData, length: ' +
                shapeImageData.length.toString(),
          );
          itemData["shapeImageData"] = shapeImageData;
          if (shapeImagePath != null) {
            itemData["originalShapeImageName"] = _basename(shapeImagePath);
          }
          // Also inline to properties so runtime doesn't depend on a file path
          try {
            final Map<String, dynamic> props = Map<String, dynamic>.from(
              itemData["properties"] as Map<String, dynamic>,
            );
            if (props["shapeProperties"] is Map<String, dynamic>) {
              final Map<String, dynamic> shapePropsMap =
                  Map<String, dynamic>.from(
                    props["shapeProperties"] as Map<String, dynamic>,
                  );
              // Write to nested map for structured consumers
              shapePropsMap["imageBase64"] = shapeImageData;
              shapePropsMap["imagePath"] = null;
              props["shapeProperties"] = shapePropsMap;
              // Also mirror to flat key so runtime that expects flat props can read it
              props["imageBase64"] = shapeImageData;
              props["imagePath"] = null;
            } else {
              // Flat properties path
              props["imageBase64"] = shapeImageData;
              props["imagePath"] = null;
            }
            itemData["properties"] = props;
          } catch (e) {
            print(
              'Warning: could not inline shape imageBase64 for item ${item.id}: $e',
            );
          }
        }
      }

      serializedItems.add(itemData);
    }

    return serializedItems;
  }

  static Future<Map<String, dynamic>> _serializeItemProperties(
    hive_model.HiveCanvasItem item,
  ) async {
    return _serializeDynamicMap(item.properties);
  }

  static Map<String, dynamic> _serializeDynamicMap(
    Map<String, dynamic> source,
  ) {
    final Map<String, dynamic> result = <String, dynamic>{};
    source.forEach((key, value) {
      result[key] = _serializeDynamicValue(value);
    });
    return result;
  }

  static dynamic _serializeDynamicValue(dynamic value) {
    if (value == null || value is num || value is String || value is bool) {
      return value;
    }

    if (value is Enum) {
      // Generic enum support: use the enum name for readability and stability
      final String name = value.toString().split('.').last;
      return {"enum": name};
    }

    if (value is hive_model.HiveColor) {
      final int v = value.value;
      return {
        "value": v,
        "alpha": (v >> 24) & 0xFF,
        "red": (v >> 16) & 0xFF,
        "green": (v >> 8) & 0xFF,
        "blue": v & 0xFF,
      };
    }

    if (value is Offset) {
      return {"dx": value.dx, "dy": value.dy};
    }

    if (value is hive_model.HiveSize) {
      return {"width": value.width, "height": value.height};
    }

    if (value is FontWeight) {
      return {"fontWeightValue": value.value};
    }

    if (value is FontStyle) {
      return {"fontStyle": value.index};
    }

    if (value is TextAlign) {
      return {"textAlign": value.index};
    }

    if (value is hive_model.HiveTextProperties) {
      return {
        "text": value.text,
        "fontSize": value.fontSize,
        "color": _serializeDynamicValue(value.color),
        "fontWeight": _serializeDynamicValue(value.fontWeight),
        "fontStyle": _serializeDynamicValue(value.fontStyle),
        "textAlign": _serializeDynamicValue(value.textAlign),
        "hasGradient": value.hasGradient,
        "gradientColors": value.gradientColors
            .map(_serializeDynamicValue)
            .toList(),
        "gradientAngle": value.gradientAngle,
        "decoration": value.decoration,
        "letterSpacing": value.letterSpacing,
        "hasShadow": value.hasShadow,
        "shadowColor": _serializeDynamicValue(value.shadowColor),
        "shadowOffset": _serializeDynamicValue(value.shadowOffset),
        "shadowBlur": value.shadowBlur,
        "shadowOpacity": value.shadowOpacity,
        "fontFamily": value.fontFamily,
      };
    }

    if (value is hive_model.HiveImageProperties) {
      return {
        "filePath": value.filePath,
        "imageUrl": value.imageUrl,
        "tint": _serializeDynamicValue(value.tint),
        "blur": value.blur,
        "hasGradient": value.hasGradient,
        "gradientColors": value.gradientColors
            .map(_serializeDynamicValue)
            .toList(),
        "gradientAngle": value.gradientAngle,
        "hasShadow": value.hasShadow,
        "shadowColor": _serializeDynamicValue(value.shadowColor),
        "shadowOffset": _serializeDynamicValue(value.shadowOffset),
        "shadowBlur": value.shadowBlur,
        "shadowOpacity": value.shadowOpacity,
        "intrinsicWidth": value.intrinsicWidth,
        "intrinsicHeight": value.intrinsicHeight,
        "displayWidth": value.displayWidth,
        "displayHeight": value.displayHeight,
      };
    }

    if (value is hive_model.HiveShapeProperties) {
      return {
        "shape": value.shape,
        "fillColor": _serializeDynamicValue(value.fillColor),
        "strokeColor": _serializeDynamicValue(value.strokeColor),
        "strokeWidth": value.strokeWidth,
        "hasGradient": value.hasGradient,
        "gradientColors": value.gradientColors
            .map(_serializeDynamicValue)
            .toList(),
        "gradientAngle": value.gradientAngle,
        "cornerRadius": value.cornerRadius,
        "hasShadow": value.hasShadow,
        "shadowColor": _serializeDynamicValue(value.shadowColor),
        "shadowOffset": _serializeDynamicValue(value.shadowOffset),
        "shadowBlur": value.shadowBlur,
        "shadowOpacity": value.shadowOpacity,
        "imagePath": value.imagePath,
        "size": _serializeDynamicValue(value.size),
      };
    }

    if (value is hive_model.HiveStickerProperties) {
      return {
        "iconCodePoint": value.iconCodePoint,
        "iconFontFamily": value.iconFontFamily,
        "color": _serializeDynamicValue(value.color),
        "size": value.size,
      };
    }

    if (value is Map) {
      final Map<String, dynamic> mapped = <String, dynamic>{};
      value.forEach((k, v) {
        mapped[k.toString()] = _serializeDynamicValue(v);
      });
      return mapped;
    }

    if (value is Iterable) {
      return value.map(_serializeDynamicValue).toList();
    }

    // Fallback to string to avoid jsonEncode failures for unexpected objects
    return value.toString();
  }

  static Future<hive_model.PosterProject?> loadProject(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find project.json
      ArchiveFile? projectFile;
      for (final file in archive) {
        if (file.name == 'project.json') {
          projectFile = file;
          break;
        }
      }

      if (projectFile == null) return null;

      // Parse project data
      final projectJson = String.fromCharCodes(projectFile.content);
      final projectData = jsonDecode(projectJson) as Map<String, dynamic>;

      // Extract images to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String projectDir =
          '${tempDir.path}/project_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(projectDir).create(recursive: true);

      // Decode and save background image
      String? backgroundImagePath;
      if (projectData['backgroundImageData'] != null) {
        try {
          final backgroundImageData =
              projectData['backgroundImageData'] as String;
          final backgroundBytes = base64Decode(backgroundImageData);
          final extension = _getImageFileExtension(null, backgroundBytes);
          final backgroundFile = File('$projectDir/background.$extension');
          await backgroundFile.writeAsBytes(backgroundBytes);
          backgroundImagePath = backgroundFile.path;
          print(
            'Successfully decoded background image: ${backgroundBytes.length} bytes as $extension',
          );
        } catch (e) {
          print('Error decoding background image: $e');
        }
      }

      // Decode and save thumbnail
      String? thumbnailPath;
      if (projectData['thumbnailData'] != null) {
        try {
          final thumbnailData = projectData['thumbnailData'] as String;
          final thumbnailBytes = base64Decode(thumbnailData);
          final extension = _getImageFileExtension(null, thumbnailBytes);
          final thumbnailFile = File('$projectDir/thumbnail.$extension');
          await thumbnailFile.writeAsBytes(thumbnailBytes);
          thumbnailPath = thumbnailFile.path;
          print(
            'Successfully decoded thumbnail: ${thumbnailBytes.length} bytes as $extension',
          );
        } catch (e) {
          print('Error decoding thumbnail: $e');
        }
      }

      // Deserialize canvas items
      final List<hive_model.HiveCanvasItem> canvasItems = [];
      final canvasItemsData = projectData['canvasItems'] as List<dynamic>;

      for (int i = 0; i < canvasItemsData.length; i++) {
        final itemData = canvasItemsData[i] as Map<String, dynamic>;

        // Decode image data if present
        String? imagePath;
        if (itemData['imageData'] != null) {
          try {
            final imageData = itemData['imageData'] as String;
            final imageBytes = base64Decode(imageData);

            // Determine proper file extension
            final originalName = itemData['originalImageName'] as String?;
            final extension = _getImageFileExtension(originalName, imageBytes);
            final fileName = originalName ?? 'item_${i}_image.$extension';
            final imageFile = File('$projectDir/$fileName');

            await imageFile.writeAsBytes(imageBytes);
            imagePath = imageFile.path;
            print(
              'Successfully decoded image for item ${i}: ${imageBytes.length} bytes as $extension',
            );
          } catch (e) {
            print('Error decoding image for item ${i}: $e');
          }
        }

        // For shape images, prefer keeping base64 instead of writing temp files
        String? shapeImageBase64;
        if (itemData['shapeImageData'] != null) {
          shapeImageBase64 = itemData['shapeImageData'] as String;
        }

        // Deserialize properties
        final properties = Map<String, dynamic>.from(
          itemData['properties'] as Map<String, dynamic>,
        );

        // Update image path in properties if image was decoded
        if (imagePath != null) {
          // Set flat runtime key used by editor
          properties['filePath'] = imagePath;

          // Also set nested imageProperties when present
          if (properties['imageProperties'] != null &&
              properties['imageProperties'] is Map<String, dynamic>) {
            final imageProps = Map<String, dynamic>.from(
              properties['imageProperties'] as Map<String, dynamic>,
            );
            imageProps['filePath'] = imagePath;
            properties['imageProperties'] = imageProps;
          }
        }

        // For shapes: store base64 directly and also materialize a temp file for code paths
        // that only read file paths. This maximizes compatibility across versions.
        if (shapeImageBase64 != null) {
          if (properties['shapeProperties'] != null &&
              properties['shapeProperties'] is Map<String, dynamic>) {
            final shapeProps = Map<String, dynamic>.from(
              properties['shapeProperties'] as Map<String, dynamic>,
            );
            shapeProps['imageBase64'] = shapeImageBase64;
            shapeProps['imagePath'] = null;
            properties['shapeProperties'] = shapeProps;
            // Mirror to flat keys as well to satisfy any code paths reading flat props
            properties['imageBase64'] = shapeImageBase64;
            properties['imagePath'] = null;
          } else {
            // Flat properties path (runtime uses top-level keys)
            properties['imageBase64'] = shapeImageBase64;
            properties['imagePath'] = null;
          }

          // Additionally, persist the image as a temp file and set imagePath, so UIs
          // that only look for a file path can still load and rasterize it.
          try {
            final Uint8List bytes = base64Decode(shapeImageBase64);
            final String ext = _getImageFileExtension(null, bytes);
            final File tmp = File('$projectDir/shape_item_${i}_image.$ext');
            await tmp.writeAsBytes(bytes, flush: true);
            properties['imagePath'] = tmp.path;
            if (properties['shapeProperties'] is Map<String, dynamic>) {
              final sp = Map<String, dynamic>.from(
                properties['shapeProperties'] as Map<String, dynamic>,
              );
              sp['imagePath'] = tmp.path;
              properties['shapeProperties'] = sp;
            }
          } catch (e) {
            print('Warning: failed to materialize shape image file: $e');
          }
        }

        // Convert serialized special values (colors, enums, etc.) back
        _deserializeSpecialValuesInProperties(properties);

        // Normalize shape colors: ensure fillColor/strokeColor are HiveColor
        // and provide sensible fallback for missing strokeColor
        if ((itemData['type'] as int) ==
            hive_model.HiveCanvasItemType.shape.index) {
          dynamic normalizeColor(dynamic v) {
            if (v is hive_model.HiveColor) return v;
            if (v is Color) return hive_model.HiveColor.fromColor(v);
            if (v is Map) {
              if (v['value'] is int) {
                return hive_model.HiveColor(v['value'] as int);
              }
              final hasChannels =
                  v.containsKey('red') &&
                  v.containsKey('green') &&
                  v.containsKey('blue');
              if (hasChannels) {
                final int a = (v['alpha'] is int) ? v['alpha'] as int : 255;
                final int r = (v['red'] as num).toInt().clamp(0, 255);
                final int g = (v['green'] as num).toInt().clamp(0, 255);
                final int b = (v['blue'] as num).toInt().clamp(0, 255);
                final int argb =
                    (a & 0xFF) << 24 |
                    (r & 0xFF) << 16 |
                    (g & 0xFF) << 8 |
                    (b & 0xFF);
                return hive_model.HiveColor(argb);
              }
            }
            if (v is int) return hive_model.HiveColor(v);
            return null;
          }

          if (properties.containsKey('fillColor')) {
            final fc = normalizeColor(properties['fillColor']);
            if (fc != null) properties['fillColor'] = fc;
          }
          if (properties.containsKey('strokeColor')) {
            final sc = normalizeColor(properties['strokeColor']);
            if (sc != null) properties['strokeColor'] = sc;
          }
          // Try alternate/legacy stroke color keys if primary is absent
          if (properties['strokeColor'] == null) {
            final List<String> legacyKeys = <String>[
              'outlineColor',
              'borderColor',
              'stroke',
              'strokeColour',
              'stroke_color',
              'border_color',
            ];
            for (final String k in legacyKeys) {
              if (properties.containsKey(k)) {
                final dynamic raw = properties[k];
                final dynamic alt = normalizeColor(raw);
                if (alt != null) {
                  properties['strokeColor'] = alt;
                  break;
                }
              }
            }
          }
          // Read mirrored primitive value when available
          if (properties['strokeColor'] == null &&
              properties['strokeColorValue'] is int) {
            properties['strokeColor'] = hive_model.HiveColor(
              properties['strokeColorValue'] as int,
            );
          }
          // Check nested shapeProperties mirrors
          if (properties['strokeColor'] == null &&
              properties['shapeProperties'] is Map<String, dynamic>) {
            final Map<String, dynamic> sp = Map<String, dynamic>.from(
              properties['shapeProperties'] as Map,
            );
            if (sp.containsKey('strokeColor')) {
              final dynamic nsc = normalizeColor(sp['strokeColor']);
              if (nsc != null) properties['strokeColor'] = nsc;
            }
            if (properties['strokeColor'] == null &&
                sp['strokeColorValue'] is int) {
              properties['strokeColor'] = hive_model.HiveColor(
                sp['strokeColorValue'] as int,
              );
            }
          }
          // If strokeColor missing or invalid, default to black with visible stroke
          if (properties['strokeColor'] == null ||
              properties['strokeColor'] is! hive_model.HiveColor) {
            properties['strokeColor'] = hive_model.HiveColor(
              Colors.black.value,
            );
            // Also default missing/invalid stroke width to a sensible visible width
            if (properties['strokeWidth'] == null ||
                (properties['strokeWidth'] is! num)) {
              properties['strokeWidth'] = 2.0;
            }
          }
        }

        final canvasItem = hive_model.HiveCanvasItem(
          id: itemData['id'] as String,
          type: hive_model.HiveCanvasItemType.values[itemData['type'] as int],
          position: Offset(
            (itemData['position'] as Map<String, dynamic>)['dx'] as double,
            (itemData['position'] as Map<String, dynamic>)['dy'] as double,
          ),
          scale: itemData['scale'] as double,
          rotation: itemData['rotation'] as double,
          opacity: itemData['opacity'] as double,
          layerIndex: itemData['layerIndex'] as int,
          isVisible: itemData['isVisible'] as bool,
          isLocked: itemData['isLocked'] as bool,
          properties: properties,
          createdAt: DateTime.parse(itemData['createdAt'] as String),
          lastModified: DateTime.parse(itemData['lastModified'] as String),
          groupId: itemData['groupId'] as String?,
        );

        canvasItems.add(canvasItem);
      }

      // Deserialize settings
      final settingsData = projectData['settings'] as Map<String, dynamic>;
      final exportSettingsData =
          settingsData['exportSettings'] as Map<String, dynamic>;

      final settings = hive_model.ProjectSettings(
        snapToGrid: settingsData['snapToGrid'] as bool,
        gridSize: settingsData['gridSize'] as double,
        canvasZoom: settingsData['canvasZoom'] as double,
        showGrid: settingsData['showGrid'] as bool,
        exportSettings: hive_model.ExportSettings(
          format: hive_model
              .ExportFormat
              .values[exportSettingsData['format'] as int],
          quality: hive_model
              .ExportQuality
              .values[exportSettingsData['quality'] as int],
          includeBackground: exportSettingsData['includeBackground'] as bool,
          pixelRatio: exportSettingsData['pixelRatio'] as double,
        ),
      );

      // Deserialize canvas background color
      final colorData =
          projectData['canvasBackgroundColor'] as Map<String, dynamic>;
      final canvasBackgroundColor = hive_model.HiveColor(
        colorData['value'] as int,
      );

      // Create and return project
      return hive_model.PosterProject(
        id: projectData['id'] as String,
        name: projectData['name'] as String,
        description: projectData['description'] as String?,
        createdAt: DateTime.parse(projectData['createdAt'] as String),
        lastModified: DateTime.parse(projectData['lastModified'] as String),
        canvasWidth: projectData['canvasWidth'] as double,
        canvasHeight: projectData['canvasHeight'] as double,
        canvasBackgroundColor: canvasBackgroundColor,
        backgroundImagePath: backgroundImagePath,
        thumbnailPath: thumbnailPath,
        canvasItems: canvasItems,
        settings: settings,
        tags: List<String>.from(projectData['tags'] as List<dynamic>),
        isFavorite: projectData['isFavorite'] as bool,
      );
    } catch (e) {
      print('Error loading project: $e');
      return null;
    }
  }

  static String _getImageFileExtension(
    String? originalName,
    Uint8List imageBytes,
  ) {
    // If we have an original name, try to extract extension from it
    if (originalName != null && originalName.contains('.')) {
      final extension = originalName.split('.').last.toLowerCase();
      if (['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'].contains(extension)) {
        return extension;
      }
    }

    // Try to detect format from image bytes
    if (imageBytes.length >= 8) {
      // PNG signature
      if (imageBytes[0] == 0x89 &&
          imageBytes[1] == 0x50 &&
          imageBytes[2] == 0x4E &&
          imageBytes[3] == 0x47) {
        return 'png';
      }
      // JPEG signature
      if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
        return 'jpg';
      }
      // GIF signature
      if (imageBytes[0] == 0x47 &&
          imageBytes[1] == 0x49 &&
          imageBytes[2] == 0x46) {
        return 'gif';
      }
      // WebP signature
      if (imageBytes.length >= 12 &&
          imageBytes[0] == 0x52 &&
          imageBytes[1] == 0x49 &&
          imageBytes[2] == 0x46 &&
          imageBytes[3] == 0x46 &&
          imageBytes[8] == 0x57 &&
          imageBytes[9] == 0x45 &&
          imageBytes[10] == 0x42 &&
          imageBytes[11] == 0x50) {
        return 'webp';
      }
    }

    // Default to PNG if we can't determine
    return 'png';
  }

  static void _deserializeSpecialValuesInProperties(
    Map<String, dynamic> target,
  ) {
    void walk(Map<String, dynamic> map) {
      map.forEach((key, value) {
        // Handle maps
        if (value is Map<String, dynamic>) {
          final lowerKey = key.toLowerCase();

          // Generic enum wrapper shape used by _serializeDynamicValue for enums
          // e.g. tool: {"enum": "textPath"}. Convert back to the raw enum name string
          // so downstream code can map it to actual enums per domain (e.g. DrawingTool).
          if (lowerKey == 'tool' && value.containsKey('enum')) {
            final dynamic enumName = value['enum'];
            if (enumName is String) {
              map[key] = enumName;
              return;
            }
          }

          // Color shape: { value: int, alpha/red/green/blue: int }
          if (value.containsKey('value') &&
              value['value'] is int &&
              (lowerKey.contains('color') || value.containsKey('alpha'))) {
            map[key] = hive_model.HiveColor(value['value'] as int);
            return;
          }

          // TextAlign shapes
          if (lowerKey == 'textalign' && value.containsKey('textAlign')) {
            final idx = (value['textAlign'] as num).toInt();
            map[key] =
                TextAlign.values[idx.clamp(0, TextAlign.values.length - 1)];
            return;
          }
          if (lowerKey == 'textalign' && value.containsKey('enum')) {
            final name = (value['enum'] as String).toLowerCase();
            final matched = TextAlign.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == name,
              orElse: () => TextAlign.left,
            );
            map[key] = matched;
            return;
          }

          // FontStyle shape: { fontStyle: index }
          if (lowerKey == 'fontstyle' && value.containsKey('fontStyle')) {
            final idx = (value['fontStyle'] as num).toInt();
            map[key] =
                FontStyle.values[idx.clamp(0, FontStyle.values.length - 1)];
            return;
          }

          // FontWeight shape: { fontWeightValue: 100..900 }
          if (lowerKey == 'fontweight' &&
              value.containsKey('fontWeightValue')) {
            final weight = (value['fontWeightValue'] as num).toInt();
            map[key] = _fontWeightFromNumeric(weight);
            return;
          }

          // Offset-like shapes for keys ending with 'offset'
          if (lowerKey.endsWith('offset') &&
              value.containsKey('dx') &&
              value.containsKey('dy')) {
            final dx = (value['dx'] as num).toDouble();
            final dy = (value['dy'] as num).toDouble();
            map[key] = Offset(dx, dy);
            return;
          }

          // Size-like shapes for key == 'size'
          if (lowerKey == 'size' &&
              value.containsKey('width') &&
              value.containsKey('height')) {
            final w = (value['width'] as num).toDouble();
            final h = (value['height'] as num).toDouble();
            map[key] = hive_model.HiveSize(w, h);
            return;
          }

          // Recurse for nested maps that didn't match known shapes
          walk(value);
          return;
        }

        // Handle lists (e.g., gradientColors)
        if (value is List) {
          for (int i = 0; i < value.length; i++) {
            final element = value[i];
            if (element is Map<String, dynamic>) {
              if (element.containsKey('value') && element['value'] is int) {
                value[i] = hive_model.HiveColor(element['value'] as int);
              } else if (element.containsKey('dx') &&
                  element.containsKey('dy')) {
                value[i] = Offset(
                  (element['dx'] as num).toDouble(),
                  (element['dy'] as num).toDouble(),
                );
              } else if (element.containsKey('width') &&
                  element.containsKey('height')) {
                value[i] = hive_model.HiveSize(
                  (element['width'] as num).toDouble(),
                  (element['height'] as num).toDouble(),
                );
              } else {
                // Deep-walk arbitrary maps inside lists
                walk(element);
              }
            }
          }
          return;
        }
      });
    }

    walk(target);
  }

  static FontWeight _fontWeightFromNumeric(int weight) {
    if (weight <= 100) return FontWeight.w100;
    if (weight <= 200) return FontWeight.w200;
    if (weight <= 300) return FontWeight.w300;
    if (weight <= 400) return FontWeight.w400;
    if (weight <= 500) return FontWeight.w500;
    if (weight <= 600) return FontWeight.w600;
    if (weight <= 700) return FontWeight.w700;
    if (weight <= 800) return FontWeight.w800;
    return FontWeight.w900;
  }
}
