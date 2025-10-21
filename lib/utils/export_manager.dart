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
    final int sdkInt = androidInfo.version.sdkInt;
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
      rethrow; // Propagate the error so calling code can handle it
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
          '${project.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.lamlayers';
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

  // Export a full scrapbook (flip book) into a .lambook archive
  // This bundles:
  // - scrapbook.json (book-level metadata: size, background/cover colors or base64 images)
  // - pages/page_{index}.json for each PosterProject, using the same JSON format as exportProject's project.json
  static Future<String?> exportScrapbookLambook({
    required hive_model.Scrapbook scrapbook,
    required List<hive_model.PosterProject> pages,
    // View-level customization
    required Color scaffoldBgColor,
    String? scaffoldBgImagePath,
    required Color leftCoverColor,
    String? leftCoverImagePath,
    required Color rightCoverColor,
    String? rightCoverImagePath,
  }) async {
    try {
      final bool hasPerm = await requestPermissions();
      if (!hasPerm) {
        // Continue with app dir fallback; sharing will still work
      }

      // Choose target directory
      Directory targetDir;
      if (Platform.isAndroid) {
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

      final String safeName = scrapbook.name.replaceAll(' ', '_');
      final String fileName =
          '${safeName}_${DateTime.now().millisecondsSinceEpoch}.lambook';
      final String filePath = '${targetDir.path}/$fileName';

      final archive = Archive();

      // Build scrapbook.json
      final Map<String, dynamic> scrapbookData = {
        'id': scrapbook.id,
        'name': scrapbook.name,
        'createdAt': scrapbook.createdAt.toIso8601String(),
        'lastModified': DateTime.now().toIso8601String(),
        'pageWidth': scrapbook.pageWidth,
        'pageHeight': scrapbook.pageHeight,
        'scaffoldBackground': await _buildColorOrImagePayload(
          color: scaffoldBgColor,
          imagePath: scaffoldBgImagePath,
        ),
        'leftCover': await _buildColorOrImagePayload(
          color: leftCoverColor,
          imagePath: leftCoverImagePath,
        ),
        'rightCover': await _buildColorOrImagePayload(
          color: rightCoverColor,
          imagePath: rightCoverImagePath,
        ),
        'pageCount': pages.length,
      };

      final Uint8List scrapbookJsonBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(scrapbookData)),
      );
      archive.addFile(
        ArchiveFile(
          'scrapbook.json',
          scrapbookJsonBytes.length,
          scrapbookJsonBytes,
        ),
      );

      // Add each page as pages/page_{i}.json
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final Uint8List pageJson = await _projectToJson(page);
        archive.addFile(
          ArchiveFile(
            'pages/page_${i.toString().padLeft(3, '0')}.json',
            pageJson.length,
            pageJson,
          ),
        );
      }

      // Write archive
      final zipBytes = ZipEncoder().encode(archive);
      final File out = File(filePath);
      try {
        await out.writeAsBytes(zipBytes);
      } catch (_) {
        final Directory tmp = await getTemporaryDirectory();
        final String fallback = '${tmp.path}/$fileName';
        final File fb = File(fallback);
        await fb.writeAsBytes(zipBytes);
        return fallback;
      }
      return filePath;
    } catch (e) {
      print('ExportManager: Error exporting lambook: $e');
      return null;
    }
  }

  // Convenience: share a generated .lambook file path
  static Future<void> shareLambook(String filePath) async {
    try {
      await Share.shareXFiles([
        XFile(filePath, mimeType: 'application/zip'),
      ], text: 'Check out my flip book');
    } catch (e) {
      print('ExportManager: Error sharing lambook: $e');
      rethrow; // Propagate the error so calling code can handle it
    }
  }

  static Future<Map<String, dynamic>> _buildColorOrImagePayload({
    required Color color,
    String? imagePath,
  }) async {
    final Map<String, dynamic> payload = {
      'color': {
        'value': color.value,
        'alpha': (color.value >> 24) & 0xFF,
        'red': (color.value >> 16) & 0xFF,
        'green': (color.value >> 8) & 0xFF,
        'blue': color.value & 0xFF,
      },
    };
    if (imagePath != null && imagePath.isNotEmpty) {
      final String? base64Data = await _encodeImageToBase64(imagePath);
      if (base64Data != null) {
        payload['imageBase64'] = base64Data;
        payload['originalImageName'] = _basename(imagePath);
      }
    }
    return payload;
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

      // Generate new project ID and rename project for export to prevent conflicts
      final String newProjectId = 'p_${DateTime.now().millisecondsSinceEpoch}';
      final String exportedProjectName = '${project.name} (Exported)';

      // Convert project to comprehensive JSON with all data
      final Map<String, dynamic> projectData = {
        "id": newProjectId,
        "name": exportedProjectName,
        "description": project.description ?? '',
        "createdAt": project.createdAt.toIso8601String(),
        "lastModified": DateTime.now().toIso8601String(),
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

      // Add text data for text items
      if (item.type == hive_model.HiveCanvasItemType.text) {
        print('ExportManager: Processing text item ${item.id}');
        print(
          'ExportManager: Text item ${item.id} - all properties: ${item.properties.keys.toList()}',
        );

        // Ensure text content is properly serialized
        final textContent = item.properties['text'] as String?;
        if (textContent != null && textContent.isNotEmpty) {
          itemData["textContent"] = textContent;
          print(
            'ExportManager: Text item ${item.id} - text content: "$textContent"',
          );
        } else {
          print('ExportManager: Text item ${item.id} - no text content found');
        }

        // Log all text-related properties
        final textKeys = [
          'text',
          'fontSize',
          'color',
          'fontWeight',
          'fontStyle',
          'textAlign',
          'hasGradient',
          'gradientColors',
          'gradientAngle',
          'decoration',
          'letterSpacing',
          'hasShadow',
          'shadowColor',
          'shadowOffset',
          'shadowBlur',
          'shadowOpacity',
          'fontFamily',
        ];
        for (final key in textKeys) {
          if (item.properties.containsKey(key)) {
            print(
              'ExportManager: Text item ${item.id} - $key: ${item.properties[key]} (${item.properties[key].runtimeType})',
            );
          }
        }

        // Ensure text properties are properly serialized
        if (item.properties['textProperties']
            is hive_model.HiveTextProperties) {
          final textProps =
              item.properties['textProperties']
                  as hive_model.HiveTextProperties;
          itemData["textProperties"] = {
            "text": textProps.text,
            "fontSize": textProps.fontSize,
            "color": _serializeDynamicValue(textProps.color),
            "fontWeight": _serializeDynamicValue(textProps.fontWeight),
            "fontStyle": _serializeDynamicValue(textProps.fontStyle),
            "textAlign": _serializeDynamicValue(textProps.textAlign),
            "hasGradient": textProps.hasGradient,
            "gradientColors": textProps.gradientColors
                .map(_serializeDynamicValue)
                .toList(),
            "gradientAngle": textProps.gradientAngle,
            "decoration": textProps.decoration,
            "letterSpacing": textProps.letterSpacing,
            "hasShadow": textProps.hasShadow,
            "shadowColor": _serializeDynamicValue(textProps.shadowColor),
            "shadowOffset": _serializeDynamicValue(textProps.shadowOffset),
            "shadowBlur": textProps.shadowBlur,
            "shadowOpacity": textProps.shadowOpacity,
            "fontFamily": textProps.fontFamily,
          };
          print(
            'ExportManager: Text item ${item.id} - serialized text properties from HiveTextProperties',
          );
        } else {
          // Fallback: serialize individual text properties if textProperties doesn't exist
          print(
            'ExportManager: Text item ${item.id} - serializing individual text properties',
          );
          final Map<String, dynamic> textPropsMap = {};

          // Copy all text-related properties
          final textPropertyKeys = [
            'text',
            'fontSize',
            'color',
            'fontWeight',
            'fontStyle',
            'textAlign',
            'hasGradient',
            'gradientColors',
            'gradientAngle',
            'decoration',
            'letterSpacing',
            'hasShadow',
            'shadowColor',
            'shadowOffset',
            'shadowBlur',
            'shadowOpacity',
            'fontFamily',
          ];

          for (final key in textPropertyKeys) {
            if (item.properties.containsKey(key)) {
              textPropsMap[key] = _serializeDynamicValue(item.properties[key]);
            }
          }

          if (textPropsMap.isNotEmpty) {
            itemData["textProperties"] = textPropsMap;
            print(
              'ExportManager: Text item ${item.id} - serialized ${textPropsMap.length} individual text properties',
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
      print('ExportManager: Loading project from: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        print('ExportManager: File does not exist: $filePath');
        return null;
      }

      // Check file size
      final fileSize = await file.length();
      print('ExportManager: File size: $fileSize bytes');
      if (fileSize == 0) {
        print('ExportManager: File is empty');
        return null;
      }

      final bytes = await file.readAsBytes();
      print('ExportManager: Read ${bytes.length} bytes from file');

      // Validate ZIP header
      if (bytes.length < 4 ||
          !(bytes[0] == 0x50 &&
              bytes[1] == 0x4B &&
              (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
              (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08))) {
        print('ExportManager: Invalid ZIP file header');
        return null;
      }

      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
        print(
          'ExportManager: Successfully decoded ZIP archive with ${archive.length} files',
        );
      } catch (e) {
        print('ExportManager: Failed to decode ZIP archive: $e');
        return null;
      }

      // Find project.json
      ArchiveFile? projectFile;
      for (final file in archive) {
        if (file.name == 'project.json') {
          projectFile = file;
          break;
        }
      }

      if (projectFile == null) {
        print('ExportManager: project.json not found in archive');
        return null;
      }

      print('ExportManager: Found project.json (${projectFile.size} bytes)');

      // Parse project data
      final projectJson = String.fromCharCodes(projectFile.content);
      print(
        'ExportManager: Project JSON length: ${projectJson.length} characters',
      );

      Map<String, dynamic> projectData;
      try {
        projectData = jsonDecode(projectJson) as Map<String, dynamic>;
        print('ExportManager: Successfully parsed JSON data');
      } catch (e) {
        print('ExportManager: Failed to parse JSON: $e');
        return null;
      }

      // Validate required project data fields
      final requiredFields = [
        'name',
        'canvasWidth',
        'canvasHeight',
        'canvasItems',
        'settings',
      ];
      for (final field in requiredFields) {
        if (!projectData.containsKey(field)) {
          print('ExportManager: Missing required field: $field');
          return null;
        }
      }

      // Validate canvas dimensions
      final canvasWidth = projectData['canvasWidth'];
      final canvasHeight = projectData['canvasHeight'];
      if (canvasWidth is! num ||
          canvasHeight is! num ||
          canvasWidth <= 0 ||
          canvasHeight <= 0) {
        print(
          'ExportManager: Invalid canvas dimensions: ${canvasWidth}x${canvasHeight}',
        );
        return null;
      }

      print('ExportManager: Project validation passed');

      // Extract images to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String projectDir =
          '${tempDir.path}/project_${DateTime.now().millisecondsSinceEpoch}';

      try {
        await Directory(projectDir).create(recursive: true);
        print('ExportManager: Created temporary directory: $projectDir');
      } catch (e) {
        print('ExportManager: Failed to create temporary directory: $e');
        return null;
      }

      // Decode and save background image
      String? backgroundImagePath;
      if (projectData['backgroundImageData'] != null) {
        try {
          final backgroundImageData =
              projectData['backgroundImageData'] as String;
          if (backgroundImageData.isEmpty) {
            print('ExportManager: Background image data is empty');
          } else {
            // Validate base64 string
            if (!RegExp(
              r'^[A-Za-z0-9+/]*={0,2}$',
            ).hasMatch(backgroundImageData)) {
              print(
                'ExportManager: Invalid base64 format for background image',
              );
            } else {
              final backgroundBytes = base64Decode(backgroundImageData);
              if (backgroundBytes.isEmpty) {
                print('ExportManager: Background image decoded to empty bytes');
              } else {
                final extension = _getImageFileExtension(null, backgroundBytes);
                final backgroundFile = File(
                  '$projectDir/background.$extension',
                );
                await backgroundFile.writeAsBytes(backgroundBytes);
                backgroundImagePath = backgroundFile.path;
                print(
                  'ExportManager: Successfully decoded background image: ${backgroundBytes.length} bytes as $extension',
                );
              }
            }
          }
        } catch (e) {
          print('ExportManager: Error decoding background image: $e');
        }
      }

      // Decode and save thumbnail
      String? thumbnailPath;
      if (projectData['thumbnailData'] != null) {
        try {
          final thumbnailData = projectData['thumbnailData'] as String;
          if (thumbnailData.isEmpty) {
            print('ExportManager: Thumbnail data is empty');
          } else {
            // Validate base64 string
            if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(thumbnailData)) {
              print('ExportManager: Invalid base64 format for thumbnail');
            } else {
              final thumbnailBytes = base64Decode(thumbnailData);
              if (thumbnailBytes.isEmpty) {
                print('ExportManager: Thumbnail decoded to empty bytes');
              } else {
                final extension = _getImageFileExtension(null, thumbnailBytes);
                final thumbnailFile = File('$projectDir/thumbnail.$extension');
                await thumbnailFile.writeAsBytes(thumbnailBytes);
                thumbnailPath = thumbnailFile.path;
                print(
                  'ExportManager: Successfully decoded thumbnail: ${thumbnailBytes.length} bytes as $extension',
                );
              }
            }
          }
        } catch (e) {
          print('ExportManager: Error decoding thumbnail: $e');
        }
      }

      // Deserialize canvas items
      final List<hive_model.HiveCanvasItem> canvasItems = [];
      final canvasItemsData = projectData['canvasItems'];

      if (canvasItemsData is! List) {
        print(
          'ExportManager: canvasItems is not a list: ${canvasItemsData.runtimeType}',
        );
        return null;
      }

      print('ExportManager: Processing ${canvasItemsData.length} canvas items');

      for (int i = 0; i < canvasItemsData.length; i++) {
        try {
          final itemData = canvasItemsData[i];
          if (itemData is! Map<String, dynamic>) {
            print(
              'ExportManager: Canvas item $i is not a map: ${itemData.runtimeType}',
            );
            continue;
          }

          // Validate required item fields
          final requiredItemFields = [
            'type',
            'position',
            'scale',
            'rotation',
            'opacity',
            'layerIndex',
            'isVisible',
            'isLocked',
          ];
          bool hasRequiredFields = true;
          for (final field in requiredItemFields) {
            if (!itemData.containsKey(field)) {
              print(
                'ExportManager: Canvas item $i missing required field: $field',
              );
              hasRequiredFields = false;
            }
          }
          if (!hasRequiredFields) continue;

          // Decode image data if present
          String? imagePath;
          if (itemData['imageData'] != null) {
            try {
              final imageData = itemData['imageData'] as String;
              if (imageData.isEmpty) {
                print('ExportManager: Image data for item $i is empty');
              } else {
                // Validate base64 string
                if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(imageData)) {
                  print(
                    'ExportManager: Invalid base64 format for item $i image',
                  );
                } else {
                  final imageBytes = base64Decode(imageData);
                  if (imageBytes.isEmpty) {
                    print(
                      'ExportManager: Item $i image decoded to empty bytes',
                    );
                  } else {
                    // Determine proper file extension
                    final originalName =
                        itemData['originalImageName'] as String?;
                    final extension = _getImageFileExtension(
                      originalName,
                      imageBytes,
                    );
                    final fileName =
                        originalName ?? 'item_${i}_image.$extension';
                    final imageFile = File('$projectDir/$fileName');

                    await imageFile.writeAsBytes(imageBytes);
                    imagePath = imageFile.path;
                    print(
                      'ExportManager: Successfully decoded image for item ${i}: ${imageBytes.length} bytes as $extension',
                    );
                  }
                }
              }
            } catch (e) {
              print('ExportManager: Error decoding image for item ${i}: $e');
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

          // Handle text content for text items FIRST, before general deserialization
          if ((itemData['type'] as int) ==
              hive_model.HiveCanvasItemType.text.index) {
            print('ExportManager: Processing text item $i');
            print(
              'ExportManager: Text item $i - import data keys: ${itemData.keys.toList()}',
            );

            // Ensure text content is properly restored
            final textContent = itemData['textContent'] as String?;
            if (textContent != null && textContent.isNotEmpty) {
              properties['text'] = textContent;
              print(
                'ExportManager: Text item $i - restored text content: "$textContent"',
              );
            } else {
              // Fallback: try to get text from textProperties
              if (itemData['textProperties'] is Map<String, dynamic>) {
                final textPropsData =
                    itemData['textProperties'] as Map<String, dynamic>;
                final fallbackText = textPropsData['text'] as String?;
                if (fallbackText != null && fallbackText.isNotEmpty) {
                  properties['text'] = fallbackText;
                  print(
                    'ExportManager: Text item $i - restored text content from textProperties: "$fallbackText"',
                  );
                } else {
                  print(
                    'ExportManager: Text item $i - no text content found anywhere',
                  );
                }
              } else {
                print(
                  'ExportManager: Text item $i - no text content found in import data',
                );
              }
            }

            // Log what text properties are available in import data
            if (itemData['textProperties'] is Map<String, dynamic>) {
              final textPropsData =
                  itemData['textProperties'] as Map<String, dynamic>;
              print(
                'ExportManager: Text item $i - textProperties keys: ${textPropsData.keys.toList()}',
              );
              for (final key in textPropsData.keys) {
                print(
                  'ExportManager: Text item $i - textProperties[$key]: ${textPropsData[key]} (${textPropsData[key].runtimeType})',
                );
              }
            } else {
              print(
                'ExportManager: Text item $i - no textProperties found in import data',
              );
            }

            // Ensure text properties are properly restored
            if (itemData['textProperties'] is Map<String, dynamic>) {
              final textPropsData =
                  itemData['textProperties'] as Map<String, dynamic>;
              try {
                final textProps = hive_model.HiveTextProperties(
                  text: textPropsData['text'] as String? ?? 'Sample Text',
                  fontSize:
                      (textPropsData['fontSize'] as num?)?.toDouble() ?? 24.0,
                  color: textPropsData['color'] is hive_model.HiveColor
                      ? textPropsData['color'] as hive_model.HiveColor
                      : hive_model.HiveColor(Colors.black.value),
                  fontWeight: textPropsData['fontWeight'] is FontWeight
                      ? textPropsData['fontWeight'] as FontWeight
                      : FontWeight.normal,
                  fontStyle: textPropsData['fontStyle'] is FontStyle
                      ? textPropsData['fontStyle'] as FontStyle
                      : FontStyle.normal,
                  textAlign: textPropsData['textAlign'] is TextAlign
                      ? textPropsData['textAlign'] as TextAlign
                      : TextAlign.center,
                  hasGradient: textPropsData['hasGradient'] as bool? ?? false,
                  gradientColors:
                      (textPropsData['gradientColors'] as List<dynamic>?)
                          ?.map(
                            (e) => e is hive_model.HiveColor
                                ? e
                                : hive_model.HiveColor(Colors.black.value),
                          )
                          .toList() ??
                      [],
                  gradientAngle:
                      (textPropsData['gradientAngle'] as num?)?.toDouble() ??
                      0.0,
                  decoration: textPropsData['decoration'] as int? ?? 0,
                  letterSpacing:
                      (textPropsData['letterSpacing'] as num?)?.toDouble() ??
                      0.0,
                  hasShadow: textPropsData['hasShadow'] as bool? ?? false,
                  shadowColor:
                      textPropsData['shadowColor'] is hive_model.HiveColor
                      ? textPropsData['shadowColor'] as hive_model.HiveColor
                      : hive_model.HiveColor(Colors.black.value),
                  shadowOffset: textPropsData['shadowOffset'] is Offset
                      ? textPropsData['shadowOffset'] as Offset
                      : Offset.zero,
                  shadowBlur:
                      (textPropsData['shadowBlur'] as num?)?.toDouble() ?? 4.0,
                  shadowOpacity:
                      (textPropsData['shadowOpacity'] as num?)?.toDouble() ??
                      0.6,
                  fontFamily: textPropsData['fontFamily'] as String?,
                );
                properties['textProperties'] = textProps;
                print('ExportManager: Text item $i - restored text properties');

                // Also restore individual text properties for compatibility
                final textPropertyKeys = [
                  'text',
                  'fontSize',
                  'color',
                  'fontWeight',
                  'fontStyle',
                  'textAlign',
                  'hasGradient',
                  'gradientColors',
                  'gradientAngle',
                  'decoration',
                  'letterSpacing',
                  'hasShadow',
                  'shadowColor',
                  'shadowOffset',
                  'shadowBlur',
                  'shadowOpacity',
                  'fontFamily',
                ];

                for (final key in textPropertyKeys) {
                  if (textPropsData.containsKey(key)) {
                    properties[key] = textPropsData[key];
                    print(
                      'ExportManager: Text item $i - restored property[$key]: ${textPropsData[key]}',
                    );
                  }
                }
                print(
                  'ExportManager: Text item $i - restored individual text properties for compatibility',
                );

                // Log final properties state
                print(
                  'ExportManager: Text item $i - final properties keys: ${properties.keys.toList()}',
                );
                for (final key in textPropertyKeys) {
                  if (properties.containsKey(key)) {
                    print(
                      'ExportManager: Text item $i - final property[$key]: ${properties[key]} (${properties[key].runtimeType})',
                    );
                  }
                }
              } catch (e) {
                print(
                  'ExportManager: Error restoring text properties for item $i: $e',
                );
              }
            }

            // Ensure individual text properties are restored even if textProperties object creation failed
            if (itemData['textProperties'] is Map<String, dynamic>) {
              final textPropsData =
                  itemData['textProperties'] as Map<String, dynamic>;
              print(
                'ExportManager: Text item $i - ensuring individual properties are restored',
              );
              final textPropertyKeys = [
                'text',
                'fontSize',
                'color',
                'fontWeight',
                'fontStyle',
                'textAlign',
                'hasGradient',
                'gradientColors',
                'gradientAngle',
                'decoration',
                'letterSpacing',
                'hasShadow',
                'shadowColor',
                'shadowOffset',
                'shadowBlur',
                'shadowOpacity',
                'fontFamily',
              ];
              for (final key in textPropertyKeys) {
                if (textPropsData.containsKey(key) &&
                    !properties.containsKey(key)) {
                  properties[key] = textPropsData[key];
                  print(
                    'ExportManager: Text item $i - restored missing property[$key]: ${textPropsData[key]}',
                  );
                }
              }
            }
          }

          // Convert serialized special values (colors, enums, etc.) back AFTER text handling
          print(
            'ExportManager: Text item $i - before deserialization, properties keys: ${properties.keys.toList()}',
          );
          _deserializeSpecialValuesInProperties(properties);
          print(
            'ExportManager: Text item $i - after deserialization, properties keys: ${properties.keys.toList()}',
          );

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

          // Generate new canvas item ID to prevent conflicts
          final String newCanvasItemId = DateTime.now().millisecondsSinceEpoch
              .toString();

          // Validate item type
          final itemTypeIndex = itemData['type'] as int;
          if (itemTypeIndex < 0 ||
              itemTypeIndex >= hive_model.HiveCanvasItemType.values.length) {
            print(
              'ExportManager: Invalid item type index $itemTypeIndex for item $i',
            );
            continue;
          }

          // Validate position
          final positionData = itemData['position'] as Map<String, dynamic>;
          if (!positionData.containsKey('dx') ||
              !positionData.containsKey('dy')) {
            print('ExportManager: Missing position data for item $i');
            continue;
          }

          final canvasItem = hive_model.HiveCanvasItem(
            id: newCanvasItemId,
            type: hive_model.HiveCanvasItemType.values[itemTypeIndex],
            position: Offset(
              (positionData['dx'] as num).toDouble(),
              (positionData['dy'] as num).toDouble(),
            ),
            scale: (itemData['scale'] as num).toDouble(),
            rotation: (itemData['rotation'] as num).toDouble(),
            opacity: (itemData['opacity'] as num).toDouble(),
            layerIndex: (itemData['layerIndex'] as num).toInt(),
            isVisible: itemData['isVisible'] as bool,
            isLocked: itemData['isLocked'] as bool,
            properties: properties,
            createdAt: DateTime.parse(itemData['createdAt'] as String),
            lastModified: DateTime.now(),
            groupId: itemData['groupId'] as String?,
          );

          canvasItems.add(canvasItem);
          print('ExportManager: Successfully processed canvas item $i');
        } catch (e) {
          print('ExportManager: Error processing canvas item $i: $e');
          // Continue with next item instead of failing completely
        }
      }

      // Deserialize settings
      final settingsData = projectData['settings'];
      if (settingsData is! Map<String, dynamic>) {
        print(
          'ExportManager: Settings data is not a map: ${settingsData.runtimeType}',
        );
        return null;
      }

      final exportSettingsData = settingsData['exportSettings'];
      if (exportSettingsData is! Map<String, dynamic>) {
        print(
          'ExportManager: Export settings data is not a map: ${exportSettingsData.runtimeType}',
        );
        return null;
      }

      // Validate export format and quality indices
      final formatIndex = exportSettingsData['format'] as int;
      final qualityIndex = exportSettingsData['quality'] as int;

      if (formatIndex < 0 ||
          formatIndex >= hive_model.ExportFormat.values.length) {
        print('ExportManager: Invalid export format index: $formatIndex');
        return null;
      }

      if (qualityIndex < 0 ||
          qualityIndex >= hive_model.ExportQuality.values.length) {
        print('ExportManager: Invalid export quality index: $qualityIndex');
        return null;
      }

      final settings = hive_model.ProjectSettings(
        snapToGrid: settingsData['snapToGrid'] as bool? ?? false,
        gridSize: (settingsData['gridSize'] as num?)?.toDouble() ?? 20.0,
        canvasZoom: (settingsData['canvasZoom'] as num?)?.toDouble() ?? 1.0,
        showGrid: settingsData['showGrid'] as bool? ?? false,
        exportSettings: hive_model.ExportSettings(
          format: hive_model.ExportFormat.values[formatIndex],
          quality: hive_model.ExportQuality.values[qualityIndex],
          includeBackground:
              exportSettingsData['includeBackground'] as bool? ?? true,
          pixelRatio:
              (exportSettingsData['pixelRatio'] as num?)?.toDouble() ?? 1.0,
        ),
      );

      // Deserialize canvas background color
      final colorData = projectData['canvasBackgroundColor'];
      if (colorData is! Map<String, dynamic>) {
        print(
          'ExportManager: Canvas background color data is not a map: ${colorData.runtimeType}',
        );
        return null;
      }

      final colorValue = colorData['value'];
      if (colorValue is! int) {
        print(
          'ExportManager: Canvas background color value is not an int: ${colorValue.runtimeType}',
        );
        return null;
      }

      final canvasBackgroundColor = hive_model.HiveColor(colorValue);

      // Generate new project ID and rename project for import to prevent conflicts
      final String newProjectId = 'p_${DateTime.now().millisecondsSinceEpoch}';
      final String originalName = projectData['name'] as String;
      final String importedProjectName = originalName.contains('(Exported)')
          ? originalName.replaceAll('(Exported)', '(Imported)')
          : '$originalName (Imported)';

      // Validate tags
      final tagsData = projectData['tags'];
      final List<String> tags = [];
      if (tagsData is List) {
        for (final tag in tagsData) {
          if (tag is String) {
            tags.add(tag);
          }
        }
      }

      print(
        'ExportManager: Successfully loaded project with ${canvasItems.length} canvas items',
      );

      // Create and return project
      return hive_model.PosterProject(
        id: newProjectId,
        name: importedProjectName,
        description: projectData['description'] as String?,
        createdAt: DateTime.parse(projectData['createdAt'] as String),
        lastModified: DateTime.now(),
        canvasWidth: canvasWidth.toDouble(),
        canvasHeight: canvasHeight.toDouble(),
        canvasBackgroundColor: canvasBackgroundColor,
        backgroundImagePath: backgroundImagePath,
        thumbnailPath: thumbnailPath,
        canvasItems: canvasItems,
        settings: settings,
        tags: tags,
        isFavorite: projectData['isFavorite'] as bool? ?? false,
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
          print(
            'ExportManager: Deserializing key: $key (lowerKey: $lowerKey), value keys: ${value.keys.toList()}',
          );

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

          // HiveTextProperties reconstruction
          if ((lowerKey == 'textproperties' || lowerKey == 'textProperties') &&
              value.containsKey('text') &&
              value.containsKey('fontSize') &&
              value.containsKey('color')) {
            print('ExportManager: Found textProperties to deserialize: $key');
            try {
              // Deserialize nested values first
              walk(value);

              final textProps = hive_model.HiveTextProperties(
                text: value['text'] as String? ?? 'Sample Text',
                fontSize: (value['fontSize'] as num?)?.toDouble() ?? 24.0,
                color: value['color'] is hive_model.HiveColor
                    ? value['color'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.black.value),
                fontWeight: value['fontWeight'] is FontWeight
                    ? value['fontWeight'] as FontWeight
                    : FontWeight.normal,
                fontStyle: value['fontStyle'] is FontStyle
                    ? value['fontStyle'] as FontStyle
                    : FontStyle.normal,
                textAlign: value['textAlign'] is TextAlign
                    ? value['textAlign'] as TextAlign
                    : TextAlign.center,
                hasGradient: value['hasGradient'] as bool? ?? false,
                gradientColors:
                    (value['gradientColors'] as List<dynamic>?)
                        ?.map(
                          (e) => e is hive_model.HiveColor
                              ? e
                              : hive_model.HiveColor(Colors.black.value),
                        )
                        .toList() ??
                    [],
                gradientAngle:
                    (value['gradientAngle'] as num?)?.toDouble() ?? 0.0,
                decoration: value['decoration'] as int? ?? 0,
                letterSpacing:
                    (value['letterSpacing'] as num?)?.toDouble() ?? 0.0,
                hasShadow: value['hasShadow'] as bool? ?? false,
                shadowColor: value['shadowColor'] is hive_model.HiveColor
                    ? value['shadowColor'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.black.value),
                shadowOffset: value['shadowOffset'] is Offset
                    ? value['shadowOffset'] as Offset
                    : Offset.zero,
                shadowBlur: (value['shadowBlur'] as num?)?.toDouble() ?? 4.0,
                shadowOpacity:
                    (value['shadowOpacity'] as num?)?.toDouble() ?? 0.6,
                fontFamily: value['fontFamily'] as String?,
              );
              map[key] = textProps;

              // Also populate individual text properties for rendering compatibility
              // This ensures the rendering code can access text properties directly
              map['text'] = textProps.text;
              map['fontSize'] = textProps.fontSize;
              map['color'] = textProps.color;
              map['fontWeight'] = textProps.fontWeight;
              map['fontStyle'] = textProps.fontStyle;
              map['textAlign'] = textProps.textAlign;
              map['hasGradient'] = textProps.hasGradient;
              map['gradientColors'] = textProps.gradientColors;
              map['gradientAngle'] = textProps.gradientAngle;
              map['decoration'] = textProps.decoration;
              map['letterSpacing'] = textProps.letterSpacing;
              map['hasShadow'] = textProps.hasShadow;
              map['shadowColor'] = textProps.shadowColor;
              map['shadowOffset'] = textProps.shadowOffset;
              map['shadowBlur'] = textProps.shadowBlur;
              map['shadowOpacity'] = textProps.shadowOpacity;
              map['fontFamily'] = textProps.fontFamily;

              return;
            } catch (e) {
              print('Warning: Failed to deserialize HiveTextProperties: $e');
            }
          }

          // HiveImageProperties reconstruction
          if (lowerKey == 'imageproperties' &&
              value.containsKey('tint') &&
              value.containsKey('shadowColor')) {
            try {
              // Deserialize nested values first
              walk(value);

              final imageProps = hive_model.HiveImageProperties(
                filePath: value['filePath'] as String?,
                imageUrl: value['imageUrl'] as String?,
                tint: value['tint'] is hive_model.HiveColor
                    ? value['tint'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.white.value),
                blur: (value['blur'] as num?)?.toDouble() ?? 0.0,
                hasGradient: value['hasGradient'] as bool? ?? false,
                gradientColors:
                    (value['gradientColors'] as List<dynamic>?)
                        ?.map(
                          (e) => e is hive_model.HiveColor
                              ? e
                              : hive_model.HiveColor(Colors.white.value),
                        )
                        .toList() ??
                    [],
                gradientAngle:
                    (value['gradientAngle'] as num?)?.toDouble() ?? 0.0,
                hasShadow: value['hasShadow'] as bool? ?? false,
                shadowColor: value['shadowColor'] is hive_model.HiveColor
                    ? value['shadowColor'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.black.value),
                shadowOffset: value['shadowOffset'] is Offset
                    ? value['shadowOffset'] as Offset
                    : Offset.zero,
                shadowBlur: (value['shadowBlur'] as num?)?.toDouble() ?? 8.0,
                shadowOpacity:
                    (value['shadowOpacity'] as num?)?.toDouble() ?? 0.6,
                intrinsicWidth: (value['intrinsicWidth'] as num?)?.toDouble(),
                intrinsicHeight: (value['intrinsicHeight'] as num?)?.toDouble(),
                displayWidth: (value['displayWidth'] as num?)?.toDouble(),
                displayHeight: (value['displayHeight'] as num?)?.toDouble(),
              );
              map[key] = imageProps;
              return;
            } catch (e) {
              print('Warning: Failed to deserialize HiveImageProperties: $e');
            }
          }

          // HiveShapeProperties reconstruction
          if (lowerKey == 'shapeproperties' &&
              value.containsKey('shape') &&
              value.containsKey('fillColor') &&
              value.containsKey('strokeColor')) {
            try {
              // Deserialize nested values first
              walk(value);

              final shapeProps = hive_model.HiveShapeProperties(
                shape: value['shape'] as String? ?? 'rectangle',
                fillColor: value['fillColor'] is hive_model.HiveColor
                    ? value['fillColor'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.blue.value),
                strokeColor: value['strokeColor'] is hive_model.HiveColor
                    ? value['strokeColor'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.black.value),
                strokeWidth: (value['strokeWidth'] as num?)?.toDouble() ?? 2.0,
                hasGradient: value['hasGradient'] as bool? ?? false,
                gradientColors:
                    (value['gradientColors'] as List<dynamic>?)
                        ?.map(
                          (e) => e is hive_model.HiveColor
                              ? e
                              : hive_model.HiveColor(Colors.blue.value),
                        )
                        .toList() ??
                    [],
                gradientAngle:
                    (value['gradientAngle'] as num?)?.toDouble() ?? 0.0,
                cornerRadius:
                    (value['cornerRadius'] as num?)?.toDouble() ?? 0.0,
                hasShadow: value['hasShadow'] as bool? ?? false,
                shadowColor: value['shadowColor'] is hive_model.HiveColor
                    ? value['shadowColor'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.black.value),
                shadowOffset: value['shadowOffset'] is Offset
                    ? value['shadowOffset'] as Offset
                    : Offset.zero,
                shadowBlur: (value['shadowBlur'] as num?)?.toDouble() ?? 8.0,
                shadowOpacity:
                    (value['shadowOpacity'] as num?)?.toDouble() ?? 0.6,
                imagePath: value['imagePath'] as String?,
                size: value['size'] is hive_model.HiveSize
                    ? value['size'] as hive_model.HiveSize
                    : null,
              );
              map[key] = shapeProps;
              return;
            } catch (e) {
              print('Warning: Failed to deserialize HiveShapeProperties: $e');
            }
          }

          // HiveStickerProperties reconstruction
          if (lowerKey == 'stickerproperties' &&
              value.containsKey('iconCodePoint') &&
              value.containsKey('color')) {
            try {
              // Deserialize nested values first
              walk(value);

              final stickerProps = hive_model.HiveStickerProperties(
                iconCodePoint: value['iconCodePoint'] as int? ?? 0xe7fd,
                iconFontFamily: value['iconFontFamily'] as String?,
                color: value['color'] is hive_model.HiveColor
                    ? value['color'] as hive_model.HiveColor
                    : hive_model.HiveColor(Colors.black.value),
                size: (value['size'] as num?)?.toDouble() ?? 60.0,
              );
              map[key] = stickerProps;
              return;
            } catch (e) {
              print('Warning: Failed to deserialize HiveStickerProperties: $e');
            }
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

  // Parse a project JSON (same shape as export) into a PosterProject, extracting images to a temp directory
  static Future<hive_model.PosterProject?> _parseProjectFromJson(
    Map<String, dynamic> projectData,
    Directory tempDir,
  ) async {
    final requiredFields = [
      'name',
      'canvasWidth',
      'canvasHeight',
      'canvasItems',
      'settings',
    ];
    for (final f in requiredFields) {
      if (!projectData.containsKey(f)) return null;
    }

    final canvasWidth = projectData['canvasWidth'];
    final canvasHeight = projectData['canvasHeight'];
    if (canvasWidth is! num ||
        canvasHeight is! num ||
        canvasWidth <= 0 ||
        canvasHeight <= 0)
      return null;

    final String projectDir =
        '${tempDir.path}/project_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(projectDir).create(recursive: true);

    String? backgroundImagePath;
    if (projectData['backgroundImageData'] is String &&
        (projectData['backgroundImageData'] as String).isNotEmpty) {
      final data = base64Decode(projectData['backgroundImageData'] as String);
      final ext = _getImageFileExtension(null, data);
      final f = File('$projectDir/background.$ext');
      await f.writeAsBytes(data);
      backgroundImagePath = f.path;
    }

    String? thumbnailPath;
    if (projectData['thumbnailData'] is String &&
        (projectData['thumbnailData'] as String).isNotEmpty) {
      final data = base64Decode(projectData['thumbnailData'] as String);
      final ext = _getImageFileExtension(null, data);
      final f = File('$projectDir/thumbnail.$ext');
      await f.writeAsBytes(data);
      thumbnailPath = f.path;
    }

    final List<hive_model.HiveCanvasItem> canvasItems = [];
    final canvasItemsData = projectData['canvasItems'];
    if (canvasItemsData is! List) return null;
    for (int i = 0; i < canvasItemsData.length; i++) {
      try {
        final itemData = canvasItemsData[i] as Map<String, dynamic>;
        final properties = Map<String, dynamic>.from(
          itemData['properties'] as Map<String, dynamic>,
        );
        _deserializeSpecialValuesInProperties(properties);

        if (itemData['imageData'] is String &&
            (itemData['imageData'] as String).isNotEmpty) {
          final imageBytes = base64Decode(itemData['imageData'] as String);
          final originalName = itemData['originalImageName'] as String?;
          final ext = _getImageFileExtension(originalName, imageBytes);
          final ff = File(
            '$projectDir/${originalName ?? 'item_${i}_image.$ext'}',
          );
          await ff.writeAsBytes(imageBytes);
          properties['filePath'] = ff.path;
        }

        final itemTypeIndex = itemData['type'] as int;
        final positionData = itemData['position'] as Map<String, dynamic>;
        final canvasItem = hive_model.HiveCanvasItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: hive_model.HiveCanvasItemType.values[itemTypeIndex],
          position: Offset(
            (positionData['dx'] as num).toDouble(),
            (positionData['dy'] as num).toDouble(),
          ),
          scale: (itemData['scale'] as num).toDouble(),
          rotation: (itemData['rotation'] as num).toDouble(),
          opacity: (itemData['opacity'] as num).toDouble(),
          layerIndex: (itemData['layerIndex'] as num).toInt(),
          isVisible: itemData['isVisible'] as bool,
          isLocked: itemData['isLocked'] as bool,
          properties: properties,
          createdAt:
              DateTime.tryParse(itemData['createdAt'] as String? ?? '') ??
              DateTime.now(),
          lastModified: DateTime.now(),
          groupId: itemData['groupId'] as String?,
        );
        canvasItems.add(canvasItem);
      } catch (_) {}
    }

    final settingsData = projectData['settings'] as Map<String, dynamic>;
    final exportSettingsData =
        settingsData['exportSettings'] as Map<String, dynamic>;
    final settings = hive_model.ProjectSettings(
      snapToGrid: settingsData['snapToGrid'] as bool? ?? false,
      gridSize: (settingsData['gridSize'] as num?)?.toDouble() ?? 20.0,
      canvasZoom: (settingsData['canvasZoom'] as num?)?.toDouble() ?? 1.0,
      showGrid: settingsData['showGrid'] as bool? ?? false,
      exportSettings: hive_model.ExportSettings(
        format: hive_model.ExportFormat.values[exportSettingsData['format']],
        quality: hive_model.ExportQuality.values[exportSettingsData['quality']],
        includeBackground:
            exportSettingsData['includeBackground'] as bool? ?? true,
        pixelRatio:
            (exportSettingsData['pixelRatio'] as num?)?.toDouble() ?? 1.0,
      ),
    );

    final colorData =
        projectData['canvasBackgroundColor'] as Map<String, dynamic>;
    final canvasBackgroundColor = hive_model.HiveColor(
      colorData['value'] as int,
    );

    final String newProjectId = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final String originalName =
        (projectData['name'] as String?) ?? 'Imported Page';
    final String importedProjectName = originalName.contains('(Exported)')
        ? originalName.replaceAll('(Exported)', '(Imported)')
        : '$originalName (Imported)';

    final tagsData = projectData['tags'];
    final List<String> tags = (tagsData is List)
        ? tagsData.whereType<String>().toList()
        : <String>[];

    return hive_model.PosterProject(
      id: newProjectId,
      name: importedProjectName,
      description: projectData['description'] as String?,
      createdAt:
          DateTime.tryParse(projectData['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastModified: DateTime.now(),
      canvasWidth: (canvasWidth).toDouble(),
      canvasHeight: (canvasHeight).toDouble(),
      canvasBackgroundColor: canvasBackgroundColor,
      backgroundImagePath: backgroundImagePath,
      thumbnailPath: thumbnailPath,
      canvasItems: canvasItems,
      settings: settings,
      tags: tags,
      isFavorite: projectData['isFavorite'] as bool? ?? false,
    );
  }

  // Load a .lambook file (ZIP) into in-memory metadata and pages for read-only viewing
  // Optionally reports progress from 1..100 via onProgress
  static Future<LambookData?> loadLambook(
    String filePath, {
    void Function(int percent)? onProgress,
  }) async {
    try {
      void report(int p) {
        if (onProgress != null) {
          // Clamp to [1, 100] and report
          final int clamped = p.clamp(1, 100);
          onProgress(clamped);
        }
      }

      report(1);
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      report(10);
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      report(25);

      ArchiveFile? book;
      for (final f in archive) {
        if (f.name == 'scrapbook.json') {
          book = f;
          break;
        }
      }
      if (book == null) return null;
      report(30);
      final Map<String, dynamic> sb =
          jsonDecode(String.fromCharCodes(book.content))
              as Map<String, dynamic>;
      report(35);

      Color _readColor(dynamic v) {
        if (v is Map && v['value'] is int) return Color(v['value'] as int);
        if (v is int) return Color(v);
        return const Color(0xFFF1F5F9);
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String baseDir =
          '${tempDir.path}/lambook_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(baseDir).create(recursive: true);
      report(40);

      Future<String?> _decodeImageFromPayload(
        Map<String, dynamic>? payload,
        String name,
      ) async {
        if (payload == null) return null;
        final String? b64 = payload['imageBase64'] as String?;
        if (b64 == null || b64.isEmpty) return null;
        final Uint8List data = base64Decode(b64);
        final String ext = _getImageFileExtension(null, data);
        final File out = File('$baseDir/$name.$ext');
        await out.writeAsBytes(data);
        return out.path;
      }

      final scaffoldPayload = sb['scaffoldBackground'] as Map<String, dynamic>?;
      final leftPayload = sb['leftCover'] as Map<String, dynamic>?;
      final rightPayload = sb['rightCover'] as Map<String, dynamic>?;

      final meta = LambookMeta(
        id:
            (sb['id'] as String?) ??
            's_${DateTime.now().millisecondsSinceEpoch}',
        name: (sb['name'] as String?) ?? 'Imported Lambook',
        pageWidth: (sb['pageWidth'] as num?)?.toDouble() ?? 1600,
        pageHeight: (sb['pageHeight'] as num?)?.toDouble() ?? 1200,
        scaffoldBgColor: _readColor(scaffoldPayload?['color']),
        scaffoldBgImagePath: await _decodeImageFromPayload(
          scaffoldPayload,
          'scaffold_bg',
        ),
        leftCoverColor: _readColor(leftPayload?['color']),
        leftCoverImagePath: await _decodeImageFromPayload(
          leftPayload,
          'left_cover',
        ),
        rightCoverColor: _readColor(rightPayload?['color']),
        rightCoverImagePath: await _decodeImageFromPayload(
          rightPayload,
          'right_cover',
        ),
      );
      report(55);

      final List<ArchiveFile> pageFiles =
          archive
              .where(
                (f) =>
                    f.name.startsWith('pages/page_') &&
                    f.name.endsWith('.json'),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      final List<hive_model.PosterProject> pages = [];
      final int pageCount = pageFiles.length == 0 ? 1 : pageFiles.length;
      int processed = 0;
      for (final pf in pageFiles) {
        try {
          final Map<String, dynamic> pageJson =
              jsonDecode(String.fromCharCodes(pf.content))
                  as Map<String, dynamic>;
          final project = await _parseProjectFromJson(pageJson, tempDir);
          if (project != null) pages.add(project);
        } catch (_) {}
        processed += 1;
        // Allocate 40% of progress to page processing (55 -> 95)
        final int percent = 55 + ((processed * 40) / pageCount).round();
        report(percent);
      }
      if (pages.isEmpty) return null;
      report(100);
      return LambookData(meta: meta, pages: pages);
    } catch (e) {
      print('ExportManager: Error loading lambook: $e');
      return null;
    }
  }
}

// Minimal metadata for a .lambook to drive the read-only UI
class LambookMeta {
  final String id;
  final String name;
  final double pageWidth;
  final double pageHeight;
  final Color scaffoldBgColor;
  final String? scaffoldBgImagePath;
  final Color leftCoverColor;
  final String? leftCoverImagePath;
  final Color rightCoverColor;
  final String? rightCoverImagePath;
  LambookMeta({
    required this.id,
    required this.name,
    required this.pageWidth,
    required this.pageHeight,
    required this.scaffoldBgColor,
    this.scaffoldBgImagePath,
    required this.leftCoverColor,
    this.leftCoverImagePath,
    required this.rightCoverColor,
    this.rightCoverImagePath,
  });
}

// In-memory parsed .lambook content
class LambookData {
  final LambookMeta meta;
  final List<hive_model.PosterProject> pages;
  LambookData({required this.meta, required this.pages});
}
