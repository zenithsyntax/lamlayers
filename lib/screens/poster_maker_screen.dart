import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/canvas_models.dart';
import '../widgets/canvas_grid_painter.dart';
import '../widgets/action_bar.dart';
import '../models/font_favorites.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:lamlayers/screens/add_images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:lamlayers/screens/google_font_screen.dart';
import 'dart:async'; // Import for Timer

import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:http/http.dart' as http;




class PosterMakerScreen extends StatefulWidget {
  final String? projectId;
  const PosterMakerScreen({super.key, this.projectId});

  @override
  State<PosterMakerScreen> createState() => _PosterMakerScreenState();
}

class _ShapePainter extends CustomPainter {
  final Map<String, dynamic> props;

  _ShapePainter(this.props);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final String shape = (props['shape'] as String?)?.toLowerCase() ?? 'rectangle';
    final double strokeWidth = (props['strokeWidth'] as double?) ?? 2.0;
    final Color fillColor = (props['fillColor'] as HiveColor?)?.toColor() ?? Colors.blue;
    final Color strokeColor = (props['strokeColor'] as HiveColor?)?.toColor() ?? Colors.black;
    final bool hasGradient = (props['hasGradient'] as bool?) ?? false;
    final List<Color> gradientColors = (props['gradientColors'] as List<dynamic>?)
            ?.map((e) => (e is HiveColor ? e : (e is int ? HiveColor(e) : null))?.toColor())
            .whereType<Color>()
            .toList() ??
        [];
    final double cornerRadius = (props['cornerRadius'] as double?) ?? 12.0;
    final ui.Image? fillImage = props['image'] as ui.Image?;
    final bool hasShadow = (props['hasShadow'] as bool?) ?? false;
    final HiveColor shadowColorHive = (props['shadowColor'] is HiveColor)
        ? (props['shadowColor'] as HiveColor)
        : (props['shadowColor'] is Color)
            ? HiveColor.fromColor(props['shadowColor'] as Color)
            : HiveColor.fromColor(Colors.black54);
    final double shadowBlur = (props['shadowBlur'] as double?) ?? 8.0;
    final Offset shadowOffset = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
    final double shadowOpacity = (props['shadowOpacity'] as double?) ?? 0.6;
    final double gradientAngle = (props['gradientAngle'] as double?) ?? 0.0; 

    final Path path = _buildPath(shape, rect, cornerRadius);

    if (hasShadow) {
      canvas.save();
      canvas.translate(shadowOffset.dx, shadowOffset.dy);
      // drawShadow uses elevation to approximate blur
      canvas.drawShadow(path, shadowColorHive.toColor().withOpacity(shadowOpacity.clamp(0.0, 1.0)), shadowBlur, true);
      canvas.restore();
    }

    if (fillImage != null) {
      // Draw image clipped to the shape path using BoxFit.cover
      canvas.save();
      canvas.clipPath(path);
      final Size imageSize = Size(fillImage.width.toDouble(), fillImage.height.toDouble());
      final FittedSizes fitted = applyBoxFit(BoxFit.cover, imageSize, size);
      final Rect inputSubrect = Alignment.center.inscribe(fitted.source, Offset.zero & imageSize);
      final Rect outputSubrect = Alignment.center.inscribe(fitted.destination, rect);
      canvas.drawImageRect(fillImage, inputSubrect, outputSubrect, Paint()..isAntiAlias = true);
      canvas.restore();
    } else {
      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      if (hasGradient) {
        final double rad = gradientAngle * math.pi / 180.0;
        final double cx = math.cos(rad);
        final double sy = math.sin(rad);
        final Alignment begin = Alignment(-cx, -sy);
        final Alignment end = Alignment(cx, sy);
        fillPaint.shader = LinearGradient(colors: gradientColors, begin: begin, end: end).createShader(rect);
      } else {
        fillPaint.color = fillColor;
      }
      canvas.drawPath(path, fillPaint);
    }

    if (strokeWidth > 0) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = strokeColor
        ..isAntiAlias = true;
      canvas.drawPath(path, strokePaint);
    }
  }

  Path _buildPath(String shape, Rect rect, double cornerRadius) {
    switch (shape) {
      case 'circle':
        return Path()..addOval(rect);
      case 'rectangle':
        return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));
      case 'triangle':
        return _trianglePath(rect, cornerRadius);
      case 'diamond':
        return _diamondPath(rect, cornerRadius);
      case 'hexagon':
        return _regularPolygonPath(rect, 6, cornerRadius);
      case 'star':
        return _starRoundedPath(rect, 5, cornerRadius);
      case 'heart':
        return _heartPathAccurate(rect, cornerRadius);
      default:
        return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));
    }
  }

  Path _trianglePath(Rect rect, double radius) {
    final List<Offset> points = [
      Offset(rect.center.dx, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];
    return _roundedPolygonPath(points, radius);
  }

  Path _diamondPath(Rect rect, double radius) {
    final List<Offset> points = [
      Offset(rect.center.dx, rect.top),
      Offset(rect.right, rect.center.dy),
      Offset(rect.center.dx, rect.bottom),
      Offset(rect.left, rect.center.dy),
    ];
    return _roundedPolygonPath(points, radius);
  }

  Path _regularPolygonPath(Rect rect, int sides, double cornerRadius) {
    final double cx = rect.center.dx;
    final double cy = rect.center.dy;
    final double r = math.min(rect.width, rect.height) / 2;
    final List<Offset> points = List.generate(sides, (i) {
      final double angle = (-math.pi / 2) + (2 * math.pi * i / sides);
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });
    return _roundedPolygonPath(points, cornerRadius);
  }

  Path _starRoundedPath(Rect rect, int points, double cornerRadius) {
    final double cx = rect.center.dx;
    final double cy = rect.center.dy;
    final double outerR = math.min(rect.width, rect.height) / 2;
    final double innerR = outerR * 0.5;
    final int total = points * 2;
    final List<Offset> vertices = List.generate(total, (i) {
      final double r = (i % 2 == 0) ? outerR : innerR;
      final double angle = (-math.pi / 2) + (i * math.pi / points);
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });
    return _roundedPolygonPath(vertices, cornerRadius);
  }

  // Build a rounded-corner polygon path from ordered vertices
  Path _roundedPolygonPath(List<Offset> vertices, double radius) {
    // If radius is zero or negative, fall back to sharp polygon
    if (radius <= 0) {
      final Path sharp = Path()..moveTo(vertices.first.dx, vertices.first.dy);
      for (int i = 1; i < vertices.length; i++) {
        sharp.lineTo(vertices[i].dx, vertices[i].dy);
      }
      sharp.close();
      return sharp;
    }

    final int n = vertices.length;
    final Path path = Path();

    Offset _trimPoint(Offset from, Offset to, double d) {
      final Offset vec = to - from;
      final double len = vec.distance;
      if (len == 0) return from;
      final double t = (d / len).clamp(0.0, 1.0);
      return from + vec * t;
    }

    // Compute first corner trimmed start point
    for (int i = 0; i < n; i++) {
      final Offset p0 = vertices[(i - 1 + n) % n];
      final Offset p1 = vertices[i];
      final Offset p2 = vertices[(i + 1) % n];

      final Offset v1 = (p0 - p1);
      final Offset v2 = (p2 - p1);

      final double len1 = v1.distance;
      final double len2 = v2.distance;
      if (len1 == 0 || len2 == 0) continue;

      final Offset u1 = v1 / len1;
      final Offset u2 = v2 / len2;

      // Angle between incoming and outgoing edges
      final double dot = (u1.dx * u2.dx + u1.dy * u2.dy).clamp(-1.0, 1.0);
      final double theta = math.acos(dot);
      // Avoid division by zero for straight lines
      final double tangent = math.tan(theta / 2);
      double offsetDist = tangent == 0 ? 0 : (radius / tangent);
      // Limit by half of each adjacent edge
      offsetDist = math.min(offsetDist, math.min(len1, len2) / 2 - 0.01);
      if (offsetDist.isNaN || offsetDist.isInfinite || offsetDist < 0) {
        offsetDist = 0;
      }

      final Offset start = _trimPoint(p1, p0, offsetDist);
      final Offset end = _trimPoint(p1, p2, offsetDist);

      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }

      // Use quadratic curve with control at the original vertex to handle concave and convex cases
      path.quadraticBezierTo(p1.dx, p1.dy, end.dx, end.dy);
    }

    path.close();
    return path;
  }

  // removed arrow path per request

  Path _heartPathAccurate(Rect rect, double radius) {
  final Path path = Path();
  final double w = rect.width;
  final double h = rect.height;
  final double x = rect.left;
  final double y = rect.top;
  final double cx = x + w / 2;

  // Dip at the top (between the lobes)
  final double dipY = y + h * 0.25; 

  // Start at dip
  path.moveTo(cx, dipY);

  // Left lobe top curve
  path.cubicTo(
    cx - w * 0.25, y,   // control 1
    x, y + h * 0.25,    // control 2
    x, y + h * 0.45,    // end of left lobe curve
  );

  // Left bottom curve
  path.cubicTo(
    x, y + h * 0.75, 
    cx - w * 0.25, y + h * 0.9, 
    cx, y + h, // bottom tip
  );

  // Right bottom curve
  path.cubicTo(
    cx + w * 0.25, y + h * 0.9, 
    x + w, y + h * 0.75, 
    x + w, y + h * 0.45, 
  );

  // Right lobe top curve
  path.cubicTo(
    x + w, y + h * 0.25, 
    cx + w * 0.25, y, 
    cx, dipY, // back to dip
  );

  path.close();
  return path;
}


  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    // Repaint whenever the parent rebuilds to reflect in-place mutations to props
    return true;
  }
}

class _PosterMakerScreenState extends State<PosterMakerScreen>
    with TickerProviderStateMixin {
  int selectedTabIndex = 0;
  List<CanvasItem> canvasItems = [];
  CanvasItem? selectedItem;
  bool showBottomSheet = false;
  bool snapToGrid = false;
  double canvasZoom = 1.0;
  int editTopbarTabIndex = 0; // 0: General, 1: Type
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _canvasRepaintKey = GlobalKey();

  // Undo/Redo system
  List<CanvasAction> actionHistory = [];
  int currentActionIndex = -1;

  // Animation controllers
  late AnimationController _bottomSheetController;
  late Animation<double> _bottomSheetAnimation;
  late AnimationController _selectionController;
  late Animation<double> _selectionAnimation;
  late AnimationController _itemAddController;
  late Animation<double> _itemAddAnimation;

  // Temp previous states for gesture-based history
  CanvasItem? _preDragState;
  CanvasItem? _preTransformState;

  final List<String> tabTitles = ['Text', 'Images',  'Shapes'];

  // Text items now driven by liked Google Fonts with a leading plus button
  List<String> get likedFontFamilies => FontFavorites.instance.likedFamilies;

  // Removed sample image icons; Images tab now only supports uploads


  final List<Map<String, dynamic>> sampleShapes = const [
    {'shape': 'rectangle', 'icon': Icons.crop_square_rounded},
    {'shape': 'circle', 'icon': Icons.circle_outlined},
    {'shape': 'triangle', 'icon': Icons.change_history_rounded},
    {'shape': 'hexagon', 'icon': Icons.hexagon_outlined},
    {'shape': 'diamond', 'icon': Icons.diamond_outlined},
    {'shape': 'star', 'icon': Icons.star_border_rounded},
    {'shape': 'heart', 'icon': Icons.favorite_border_rounded},
  ];

  // Recent colors for color picker
  List<Color> recentColors = [];
  final List<Color> favoriteColors = [
    Colors.black,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
  ];

  PosterProject? _currentProject;
  late Box<PosterProject> _projectBox;
  late Box<UserPreferences> _userPreferencesBox;
  late UserPreferences userPreferences;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _projectBox = Hive.box<PosterProject>('posterProjects');
    _userPreferencesBox = Hive.box<UserPreferences>('userPreferences');
    userPreferences = _userPreferencesBox.get('user_prefs_id') ?? UserPreferences();

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveProject();
    });

    if (widget.projectId != null) {
      _currentProject = _projectBox.get(widget.projectId);
    } else {
      _currentProject = PosterProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Project',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        canvasItems: [],
        settings: ProjectSettings(exportSettings: ExportSettings()),
      );
      _projectBox.put(_currentProject!.id, _currentProject!);
    }
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _bottomSheetAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomSheetController,
        curve: Curves.easeOutCubic,
      ),
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _selectionAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.elasticOut),
    );

    _itemAddController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _itemAddAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _itemAddController, curve: Curves.elasticOut),
    );

    if (_currentProject != null) {
      canvasItems = _currentProject!.canvasItems.map((hiveItem) => CanvasItem(
        id: hiveItem.id,
        type: CanvasItemType.values.firstWhere((e) => e.toString().split('.').last == hiveItem.type.toString().split('.').last),
        position: hiveItem.position,
        scale: hiveItem.scale,
        rotation: hiveItem.rotation,
        opacity: hiveItem.opacity,
        layerIndex: hiveItem.layerIndex,
        isVisible: hiveItem.isVisible,
        isLocked: hiveItem.isLocked,
        properties: hiveItem.properties,
        createdAt: hiveItem.createdAt,
        lastModified: hiveItem.lastModified,
        groupId: hiveItem.groupId,
      )).toList();
    } else {
      canvasItems = [];
    }
    if (userPreferences.recentColors.isEmpty) {
      userPreferences.recentColors = [
        Colors.black,
        Colors.redAccent,
        Colors.blueAccent,
        Colors.greenAccent,
      ].map((e) => HiveColor.fromColor(e)).toList();
    }

    if (userPreferences.recentColors.isNotEmpty) {
      final List<HiveColor> hiveRecentColors = List<HiveColor>.from(userPreferences.recentColors);
      for (var recentColor in hiveRecentColors) {
        recentColors.add(recentColor.toColor());
      }
    }
  }

  @override
  void dispose() {
    _saveProject();
    _bottomSheetController.dispose();
    _selectionController.dispose();
    _itemAddController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _saveProject() {
    if (_currentProject != null) {
      _currentProject!.lastModified = DateTime.now();
      // Convert current CanvasItems to HiveCanvasItems before saving
      _currentProject!.canvasItems = canvasItems.map((item) => HiveCanvasItem(
        id: item.id,
        type: HiveCanvasItemType.values.firstWhere((e) => e.toString().split('.').last == item.type.toString().split('.').last),
        position: item.position,
        scale: item.scale,
        rotation: item.rotation,
        opacity: item.opacity,
        layerIndex: item.layerIndex,
        isVisible: item.isVisible,
        isLocked: item.isLocked,
        properties: item.properties,
        createdAt: item.createdAt,
        lastModified: item.lastModified,
        groupId: item.groupId,
      )).toList();
      _projectBox.put(_currentProject!.id, _currentProject!);
    }
  }

  TextDecoration _intToTextDecoration(int value) {
    switch (value) {
      case 1:
        return TextDecoration.underline;
      case 2:
        return TextDecoration.overline;
      case 3:
        return TextDecoration.lineThrough;
      default:
        return TextDecoration.none;
    }
  }

  void _addAction(CanvasAction action) {
    if (currentActionIndex < actionHistory.length - 1) {
      actionHistory.removeRange(currentActionIndex + 1, actionHistory.length);
    }
    actionHistory.add(action);
    currentActionIndex++;
    if (actionHistory.length > 50) {
      actionHistory.removeAt(0);
      currentActionIndex--;
    }

    // Apply the action immediately if it's a modify operation
    if (action.type == 'modify' && action.item != null) {
      final idx = canvasItems.indexWhere((it) => it.id == action.item!.id);
      if (idx != -1) {
        canvasItems[idx] = action.item!;
      }
    }
  }

  void _undo() {
    if (currentActionIndex < 0) return;
    final action = actionHistory[currentActionIndex];
    setState(() {
      switch (action.type) {
        case 'add':
          canvasItems.removeWhere((it) => it.id == action.item!.id);
          break;
        case 'remove':
          canvasItems.add(action.item!);
          break;
        case 'modify':
          final idx = canvasItems.indexWhere((it) => it.id == action.item!.id);
          if (idx != -1 && action.previousState != null) {
            canvasItems[idx] = action.previousState!;
          }
          break;
      }
    });
    currentActionIndex--;
  }

  void _redo() {
    if (currentActionIndex >= actionHistory.length - 1) return;
    currentActionIndex++;
    final action = actionHistory[currentActionIndex];
    setState(() {
      switch (action.type) {
        case 'add':
          canvasItems.add(action.item!);
          break;
        case 'remove':
          canvasItems.removeWhere((it) => it.id == action.item!.id);
          break;
        case 'modify':
          final idx = canvasItems.indexWhere((it) => it.id == action.item!.id);
          if (idx != -1) {
            canvasItems[idx] = action.item!;
          }
          break;
      }
    });
  }

  void _addCanvasItem(CanvasItemType type, {Map<String, dynamic>? properties}) {
    final newItem = CanvasItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      position: Offset(100.w, 100.h),
      properties: properties ?? _getDefaultProperties(type),
      layerIndex: canvasItems.length,
      lastModified: DateTime.now(),
      createdAt: DateTime.now(),
    );
    setState(() {
      canvasItems.add(newItem);
      _selectItem(newItem);
    });
    _addAction(CanvasAction(type: 'add', item: newItem, timestamp: DateTime.now()));
    _itemAddController.forward().then((_) => _itemAddController.reset());
  }

  Map<String, dynamic> _getDefaultProperties(CanvasItemType type) {
    switch (type) {
      case CanvasItemType.text:
        return {
          'text': 'Sample Text',
          'fontSize': 24.0,
          'color': HiveColor.fromColor(Colors.black),
          'fontWeight': FontWeight.normal.index,
          'fontStyle': FontStyle.normal.index,
          'textAlign': TextAlign.center.index,
          'hasGradient': false,
          'gradientColors': const [],
          'gradientAngle': 0.0,
          'decoration': 0, // TextDecoration.none
          'letterSpacing': 0.0,
          'hasShadow': false,
          'shadowColor': HiveColor.fromColor(Colors.black.withOpacity(0.6)),
          'shadowOffset': const Offset(4, 4),
          'shadowBlur': 4.0,
          'shadowOpacity': 0.6,
        };
      case CanvasItemType.image:
        return {
          'tint': HiveColor.fromColor(Colors.transparent),
          'blur': 0.0,
          'hasGradient': false,
          'gradientColors': const [],
          'gradientAngle': 0.0,
          'hasShadow': false,
          'shadowColor': HiveColor.fromColor(Colors.black.withOpacity(0.6)),
          'shadowOffset': const Offset(8, 8),
          'shadowBlur': 8.0,
          'shadowOpacity': 0.6,
        };
      case CanvasItemType.sticker:
        return {
          'iconCodePoint': Icons.star.codePoint,
          'color': HiveColor.fromColor(Colors.yellow),
          'size': 60.0,
        };
      case CanvasItemType.shape:
        return {
          'shape': 'rectangle',
          'fillColor': HiveColor.fromColor(Colors.blue),
          'strokeColor': HiveColor.fromColor(Colors.black),
          'strokeWidth': 2.0,
          'hasGradient': false,
          'gradientColors': const [],
          'cornerRadius': 0.0,
          'hasShadow': false,
          'shadowColor': HiveColor.fromColor(Colors.black.withOpacity(0.6)),
          'shadowOffset': const Offset(8, 8),
          'shadowBlur': 8.0,
          'shadowOpacity': 0.6,
        };
    }
  }

void _selectItem(CanvasItem item) {
  setState(() {
    selectedItem = item;
    showBottomSheet = false;
  });
  // Removed: _selectionController.forward();
}

void _deselectItem() {
  setState(() {
    selectedItem = null;
    showBottomSheet = false;
  });
  _bottomSheetController.reverse();
  // Removed: _selectionController.reverse();
}

  void _removeItem(CanvasItem item) {
    setState(() {
      canvasItems.remove(item);
      if (selectedItem == item) {
        _deselectItem();
      }
    });
    _addAction(CanvasAction(type: 'remove', item: item, timestamp: DateTime.now()));
  }

  void _duplicateItem(CanvasItem item) {
    final duplicatedItem = item.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: item.position + const Offset(20, 20),
      layerIndex: canvasItems.length,
    );
    setState(() {
      canvasItems.add(duplicatedItem);
      _selectItem(duplicatedItem);
    });
    _addAction(CanvasAction(type: 'add', item: duplicatedItem, timestamp: DateTime.now()));
  }

  void _bringToFront(CanvasItem item) {
    setState(() {
      canvasItems.remove(item);
      item.layerIndex = canvasItems.length;
      canvasItems.add(item);
    });
  }

  void _sendToBack(CanvasItem item) {
    setState(() {
      canvasItems.remove(item);
      for (var existingItem in canvasItems) {
        existingItem.layerIndex++;
      }
      item.layerIndex = 0;
      canvasItems.insert(0, item);
    });
  }

  Widget _buildTopToolbar() {
    if (selectedItem != null) {
      return _buildTopEditToolbar();
    }
    return Container(
      height: 170.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              children: List.generate(tabTitles.length, (index) {
                final isSelected = selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTabIndex = index),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        tabTitles[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontSize: 15.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: _buildTabContent(),
            ),
          ),
          SizedBox(height: 10.h,)
        ],
      ),
    );
  }

  Widget _buildTopEditToolbar() {
    // Compact editing UI shown at the top when an item is selected
    return Container(
      height: 160.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(_getItemTypeIcon(selectedItem!.type), color: Colors.white, size: 20.sp),
                ),
                // SizedBox(width: 12.w),
                // Text('${selectedItem!.type.name.toUpperCase()} ', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const Spacer(),
                _buildEditModeSegmentedControl(),
                const Spacer(),
                GestureDetector(
                  onTap: _deselectItem,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 16.sp, color: Colors.grey[700]),
                        // SizedBox(width: 6.w),
                        // Text('Done', style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _buildTopbarQuickControls(),
              ),
            ),
          ),
          SizedBox(height: 10.h,)
        ],
      ),
    );
  }

// Replace the _buildEditModeSegmentedControl method with this updated version:

Widget _buildEditModeSegmentedControl() {
  final List<String> tabs = ['General', 'Type'];
  
  // Add Shadow and Gradient tabs based on item type
  if (selectedItem != null) {
    switch (selectedItem!.type) {
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.shape:
        tabs.addAll(['Shadow', 'Gradient']);
        break;
      case CanvasItemType.sticker:
        // Stickers don't typically have shadow/gradient options
        break;
    }
  }

  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final int index = entry.key;
          final String label = entry.value;
          return _buildSegmentButton(label, index);
        }).toList(),
      ),
    ),
  );
}

  Widget _buildSegmentButton(String label, int index) {
    final bool isActive = editTopbarTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => editTopbarTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

 List<Widget> _buildTopbarQuickControls() {
  if (selectedItem == null) return [];
  
  switch (editTopbarTabIndex) {
    case 0: // General controls
      return [
        _miniSlider('Opacity', selectedItem!.opacity, 0.1, 1.0, (v) => setState(() => selectedItem!.opacity = v), Icons.opacity_rounded),
        _miniSlider('Scale', selectedItem!.scale, 0.3, 10.0, (v) => setState(() => selectedItem!.scale = v), Icons.zoom_out_map_rounded),
        _miniSlider('Rotate', selectedItem!.rotation * 180 / 3.14159, -180, 180, (v) => setState(() => selectedItem!.rotation = v * 3.14159 / 180), Icons.rotate_right_rounded),
        _miniIconButton('Duplicate', Icons.copy_rounded, () => _duplicateItem(selectedItem!)),
        _miniIconButton('Delete', Icons.delete_rounded, () => _removeItem(selectedItem!)),
        _miniIconButton('Front', Icons.vertical_align_top_rounded, () => _bringToFront(selectedItem!)),
        _miniIconButton('Back', Icons.vertical_align_bottom_rounded, () => _sendToBack(selectedItem!)),
      ];
      
    case 1: // Type specific controls
      return _buildTypeSpecificQuickControls();
      
    case 2: // Shadow controls
      return _buildShadowQuickControls();
      
    case 3: // Gradient controls
      return _buildGradientQuickControls();
      
    default:
      return [];
  }
}

List<Widget> _buildShadowQuickControls() {
  if (selectedItem == null) return [];
  
  final props = selectedItem!.properties;
  final bool hasShadow = props['hasShadow'] == true;
  
  return [
    _miniToggleIcon('Enable Shadow', CupertinoIcons.moon_stars, hasShadow, () => setState(() {
      props['hasShadow'] = !hasShadow;
    })),
    if (hasShadow) ...[
      _miniColorSwatch(
        'Color',
        (props['shadowColor'] is HiveColor)
            ? (props['shadowColor'] as HiveColor).toColor()
            : (props['shadowColor'] is Color)
                ? (props['shadowColor'] as Color)
                : Colors.black54,
        () => _showColorPicker('shadowColor')
      ),
      _miniSlider('Blur', (props['shadowBlur'] as double?) ?? 4.0, 0.0, 40.0, 
        (v) => setState(() => props['shadowBlur'] = v), Icons.blur_on_rounded),
      _miniSlider('Opacity', (props['shadowOpacity'] as double?) ?? 0.6, 0.0, 1.0, 
        (v) => setState(() => props['shadowOpacity'] = v), Icons.opacity_rounded),
      _miniSlider('Offset X', (props['shadowOffset'] as Offset?)?.dx ?? 4.0, -100.0, 100.0, 
        (v) => setState(() {
          final cur = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
          props['shadowOffset'] = Offset(v, cur.dy);
        }), Icons.swap_horiz_rounded),
      _miniSlider('Offset Y', (props['shadowOffset'] as Offset?)?.dy ?? 4.0, -100.0, 100.0, 
        (v) => setState(() {
          final cur = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
          props['shadowOffset'] = Offset(cur.dx, v);
        }), Icons.swap_vert_rounded),
    ],
  ];
}

List<Widget> _buildGradientQuickControls() {
  if (selectedItem == null) return [];
  
  final props = selectedItem!.properties;
  final bool hasGradient = props['hasGradient'] == true;
  
  return [
    _miniToggleIcon('Enable Gradient', Icons.gradient_rounded, hasGradient, () => setState(() {
      props['hasGradient'] = !hasGradient;
      // Initialize gradient colors if not present
      if (hasGradient && (props['gradientColors'] == null || (props['gradientColors'] as List).isEmpty)) {
        props['gradientColors'] = [
          HiveColor.fromColor(Colors.blue), 
          HiveColor.fromColor(Colors.purple)
        ];
      }
    })),
    if (hasGradient) ...[
      _miniColorSwatch(
        'Color A',
        _getDisplayGradientColors().first,
        () => _showColorPicker('gradientColor1', isGradient: true),
      ),
      _miniColorSwatch(
        'Color B',
        _getDisplayGradientColors().last,
        () => _showColorPicker('gradientColor2', isGradient: true),
      ),
      _miniSlider('Angle', (props['gradientAngle'] as double?) ?? 0.0, -180.0, 180.0, 
        (v) => setState(() => props['gradientAngle'] = v), Icons.rotate_right_rounded),
    ],
  ];
}

List<Widget> _buildTypeSpecificQuickControls() {
  if (selectedItem == null) return [];
  
  switch (selectedItem!.type) {
    case CanvasItemType.text:
      return [
        _miniTextEditButton('Text', (selectedItem!.properties['text'] as String?) ?? '', 
          (v) => setState(() => selectedItem!.properties['text'] = v)),
        _miniSlider('Font Size', (selectedItem!.properties['fontSize'] as double?) ?? 24.0, 10.0, 72.0, 
          (v) => setState(() => selectedItem!.properties['fontSize'] = v), Icons.format_size_rounded),
        _miniToggleIcon('Bold', Icons.format_bold_rounded, 
          selectedItem!.properties['fontWeight'] == FontWeight.bold, () => setState(() {
            selectedItem!.properties['fontWeight'] = 
              (selectedItem!.properties['fontWeight'] == FontWeight.bold) ? FontWeight.normal : FontWeight.bold;
          })),
        _miniToggleIcon('Italic', Icons.format_italic_rounded, 
          selectedItem!.properties['fontStyle'] == FontStyle.italic, () => setState(() {
            selectedItem!.properties['fontStyle'] = 
              (selectedItem!.properties['fontStyle'] == FontStyle.italic) ? FontStyle.normal : FontStyle.italic;
          })),
        _miniColorSwatch(
          'Color',
          (selectedItem!.properties['color'] is HiveColor)
              ? (selectedItem!.properties['color'] as HiveColor).toColor()
              : Colors.black,
          () => _showColorPicker('color')
        ),
      ];
      
    case CanvasItemType.image:
      return [
        _miniIconButton('Edit Image', Icons.edit_rounded, _editSelectedImage),
        _miniIconButton('Replace', Icons.photo_library_rounded, () => _pickImage(replace: true)),
        // _miniColorSwatch('Tint', selectedItem!.properties['tint'] as Color? ?? Colors.transparent, 
        //   () => _showColorPicker('tint')),
        _miniSlider('Blur', (selectedItem!.properties['blur'] as double?) ?? 0.0, 0.0, 10.0, 
          (v) => setState(() => selectedItem!.properties['blur'] = v), Icons.blur_on_rounded),
      ];
      
    case CanvasItemType.shape:
      return [
        _miniColorSwatch(
          'Fill',
          (selectedItem!.properties['fillColor'] is HiveColor)
              ? (selectedItem!.properties['fillColor'] as HiveColor).toColor()
              : Colors.blue,
          () => _showColorPicker('fillColor')
        ),
        _miniColorSwatch(
          'Stroke',
          (selectedItem!.properties['strokeColor'] is HiveColor)
              ? (selectedItem!.properties['strokeColor'] as HiveColor).toColor()
              : Colors.black,
          () => _showColorPicker('strokeColor')
        ),
        _miniSlider('Stroke Width', (selectedItem!.properties['strokeWidth'] as double?) ?? 2.0, 0.0, 10.0, 
          (v) => setState(() => selectedItem!.properties['strokeWidth'] = v), Icons.line_weight_rounded),
        _miniSlider('Corner Radius', (selectedItem!.properties['cornerRadius'] as double?) ?? 12.0, 0.0, 50.0, 
          (v) => setState(() => selectedItem!.properties['cornerRadius'] = v), Icons.rounded_corner_rounded),
        _miniIconButton('Image Fill', Icons.photo_library_rounded, () => _pickShapeImage()),
        if (selectedItem!.properties['image'] != null)
          _miniIconButton('Clear Image', Icons.delete_sweep_rounded, 
            () => setState(() => selectedItem!.properties['image'] = null)),
      ];
      
    case CanvasItemType.sticker:
      return [
        _miniColorSwatch('Color', (selectedItem!.properties['color'] as HiveColor?)?.toColor() ?? Colors.orange, 
          () => _showColorPicker('color')),
      ];
      
    default:
      return [];
  }
}
  Widget _miniIconButton(String tooltip, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 10.w),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46.w,
            height: 46.h,
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey.shade200)),
            child: Icon(icon, size: 20.sp, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _miniSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, IconData icon) {
    final clamped = value.clamp(min, max);
    return Container(
      width: 220.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(clamped.toStringAsFixed(1), style: TextStyle(fontSize: 12.sp, color: Colors.blue.shade700, fontWeight: FontWeight.w700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue.shade400,
              inactiveTrackColor: Colors.blue.shade100,
              thumbColor: Colors.blue.shade600,
              overlayColor: Colors.blue.withOpacity(0.05),
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
            ),
            child: Slider(value: clamped, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _miniColorSwatch(String label, Color color, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 22.w, height: 22.h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6.r), border: Border.all(color: Colors.grey.shade300))),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], fontWeight: FontWeight.w600)),
          SizedBox(width: 8.w),
          _miniIconButton('Pick', Icons.palette_rounded, onTap),
        ],
      ),
    );
  }

// Replace the _miniTextField method with this button version:
Widget _miniTextEditButton(String label, String value, ValueChanged<String> onChanged) {
  return Container(
    width: 260.w,
    margin: EdgeInsets.only(right: 12.w),
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_fields_rounded, size: 16.sp, color: Colors.grey[600]),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: () => _showTextEditDialog(value, onChanged),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Tap to edit text' : value,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: value.isEmpty ? Colors.grey[400] : Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.edit_rounded, size: 14.sp, color: Colors.blue.shade400),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Add this method to show the text editing dialog:
void _showTextEditDialog(String currentText, ValueChanged<String> onChanged) {
  final TextEditingController controller = TextEditingController(text: currentText);
  final FocusNode focusNode = FocusNode();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: 300.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: Colors.white, size: 24.sp),
                    SizedBox(width: 12.w),
                    Text(
                      'Edit Text',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 18.sp),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Text editing area
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter your text:',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      // Multi-line text field
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            maxLines: null,
                            minLines: 5,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your text here...\nPress Enter for new lines',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14.sp,
                              ),
                              contentPadding: EdgeInsets.all(16.w),
                              border: InputBorder.none,
                            ),
                            onChanged: (text) {
                              // Real-time update on canvas
                              onChanged(text);
                            },
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Character count
                      Text(
                        '${controller.text.length} characters',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
                child: Row(
                  children: [
                    // Clear button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.clear();
                          onChanged('');
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.clear_rounded, color: Colors.red.shade600, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // Done button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          onChanged(controller.text);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.blue.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, color: Colors.white, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((_) {
    // Auto-focus the text field when dialog opens
    Future.delayed(const Duration(milliseconds: 100), () {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  });
}
  Widget _miniToggleIcon(String tooltip, IconData icon, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 10.w),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46.w,
            height: 46.h,
            decoration: BoxDecoration(
              gradient: isActive ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]) : null,
              color: isActive ? null : Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200),
              boxShadow: isActive ? [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : null,
            ),
            child: Icon(icon, size: 20.sp, color: isActive ? Colors.white : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _getTabItemCount(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: GestureDetector(
            onTap: () => _onTabItemTap(index),
            child: Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.grey.shade100, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: _getTabItemWidget(index)),
            ),
          ),
        );
      },
    );
  }

  int _getTabItemCount() {
    switch (selectedTabIndex) {
      case 0:
        // 1 for the leading plus button + liked fonts as items
        return 1 + likedFontFamilies.length;
      case 1:
        return 2; // Two options: Upload and Pixabay
      
      case 2:
        return sampleShapes.length;
      default:
        return 0;
    }
  }

  Widget _getTabItemWidget(int index) {
    switch (selectedTabIndex) {
      case 0:
        if (index == 0) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 28.sp, color: Colors.blue.shade700),
              SizedBox(height: 6.h),
              Text('Add Font', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700))
            ],
          );
        }
        final family = likedFontFamilies[index - 1];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields_rounded, size: 24.sp, color: Colors.blue.shade600),
            SizedBox(height: 6.h),
            Text(
              family,
              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case 1:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 28.sp, color: Colors.blue.shade700),
            SizedBox(height: 6.h),
            Text('Upload', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ],
        );
    
      case 2:
        return Icon(sampleShapes[index]['icon'] as IconData, size: 32.sp, color: Colors.green.shade600);
      default:
        return const SizedBox();
    }
  }

  void _onTabItemTap(int index) {
    HapticFeedback.lightImpact();
    switch (selectedTabIndex) {
      case 0:
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoogleFontsPage(onFontSelected: (fontFamily) {
                _addCanvasItem(CanvasItemType.text, properties: {
                  'text': 'New Text',
                  'color': Colors.black,
                  'fontSize': 24.0,
                  'fontWeight': FontWeight.normal,
                  'fontStyle': FontStyle.normal,
                  'textAlign': TextAlign.center,
                  'decoration': 0, // TextDecoration.none
                  'letterSpacing': 0.0,
                  'hasShadow': false,
                  'shadowColor': Colors.grey,
                  'shadowOffset': const Offset(2, 2),
                  'shadowBlur': 4.0,
                  'fontFamily': fontFamily,
                });
              }),
            ),
          );
        } else {
          final family = likedFontFamilies[index - 1];
          _addCanvasItem(CanvasItemType.text, properties: {
            'text': 'New Text',
            'color': Colors.black,
            'fontSize': 24.0,
            'fontWeight': FontWeight.normal,
            'fontStyle': FontStyle.normal,
            'textAlign': TextAlign.center,
            'decoration': 0, // TextDecoration.none
            'letterSpacing': 0.0,
            'hasShadow': false,
            'shadowColor': Colors.grey,
            'shadowOffset': const Offset(2, 2),
            'shadowBlur': 4.0,
            'fontFamily': family,
          });
        }
        break;
      case 1:
        if (index == 0) {
          _pickImage(); // Existing Upload functionality
        } else if (index == 1) {
          _navigateToPixabayImages(); // New Pixabay functionality
        }
        break;
  
    
      case 2:
        final shapeData = sampleShapes[index];
        _addCanvasItem(
          CanvasItemType.shape,
          properties: {
            'shape': shapeData['shape'],
            'fillColor': Colors.green,
            'strokeColor': Colors.greenAccent,
            'strokeWidth': 2.0,
            'hasGradient': false,
            'gradientColors': [HiveColor.fromColor(Colors.lightGreen), HiveColor.fromColor(Colors.green)],
            'cornerRadius': 0.0,
          },
        );
        break;
    }
  }

  Widget _buildCanvas() {
  return Expanded(
    child: InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      onInteractionUpdate: (details) {
        setState(() {
          canvasZoom = details.scale;
        });
      },
      child: Container(
        margin: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: _currentProject!.canvasBackgroundColor.toColor(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          child: RepaintBoundary(
            key: _canvasRepaintKey,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _deselectItem,
                    child: Container(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: CanvasGridPainter(
                          showGrid: snapToGrid,
                          gridSize: 20.0,
                        ),
                      ),
                    ),
                  ),
                ),
                ...(() {
                  final items = [...canvasItems]
                    ..sort((a, b) => a.layerIndex.compareTo(b.layerIndex));
                  final visibleItems = items.where((it) => it.isVisible).toList();
                  return visibleItems.map((it) => _buildCanvasItem(it)).toList();
                })(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}



  Widget _buildCanvasItem(CanvasItem item) {
  final isSelected = selectedItem == item;
  return Positioned(
    left: item.position.dx,
    top: item.position.dy,
    child: Transform.rotate(
      angle: item.rotation,
      child: Transform.scale(
        scale: item.scale,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!item.isLocked) {
              _selectItem(item);
            }
          },
          onPanStart: (_) {
            if (!item.isLocked && selectedItem == item) {
              _preDragState = item.copyWith();
            }
          },
          onPanUpdate: (details) {
            if (!item.isLocked && selectedItem == item) {
              setState(() {
                Offset newPosition = item.position + details.delta;
                if (snapToGrid) {
                  const double gridSize = 20.0;
                  newPosition = Offset(
                    (newPosition.dx / gridSize).round() * gridSize,
                    (newPosition.dy / gridSize).round() * gridSize,
                  );
                }
                item.position = newPosition;
              });
            }
          },
          onPanEnd: (_) {
            if (!item.isLocked && selectedItem == item && _preDragState != null) {
              _addAction(CanvasAction(
                type: 'modify',
                item: item.copyWith(),
                previousState: _preDragState,
                timestamp: DateTime.now(),
              ));
              _preDragState = null;
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Opacity(
                  opacity: item.opacity.clamp(0.0, 1.0),
                  child: _buildItemContent(item),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBoundingBox(CanvasItem item) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade400.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Stack(
          children: [
            ..._buildCornerHandles(item),
            _buildRotationHandle(item),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerHandles(CanvasItem item) {
    return [
      Positioned(top: -6.h, left: -6.w, child: _buildResizeHandle(item, (details) => _handleResizeUpdate(item, details, scaleSign: -1))),
      Positioned(top: -6.h, right: -6.w, child: _buildResizeHandle(item, (details) => _handleResizeUpdate(item, details, scaleSign: 1))),
      Positioned(bottom: -6.h, left: -6.w, child: _buildResizeHandle(item, (details) => _handleResizeUpdate(item, details, scaleSign: 1))),
      Positioned(bottom: -6.h, right: -6.w, child: _buildResizeHandle(item, (details) => _handleResizeUpdate(item, details, scaleSign: 1))),
    ];
  }

  Widget _buildResizeHandle(CanvasItem item, ValueChanged<DragUpdateDetails> onPanUpdate) {
    return GestureDetector(
      onPanStart: (_) {
        _preTransformState = item.copyWith();
      },
      onPanUpdate: onPanUpdate,
      onPanEnd: (_) {
        if (_preTransformState != null) {
          _addAction(CanvasAction(
            type: 'modify',
            item: item.copyWith(),
            previousState: _preTransformState,
            timestamp: DateTime.now(),
          ));
          _preTransformState = null;
        }
      },
      child: Container(
        width: 12.w,
        height: 12.h,
        decoration: BoxDecoration(
          color: Colors.blue.shade400,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
      ),
    );
  }

void _handleResizeUpdate(CanvasItem item, DragUpdateDetails details, {int scaleSign = 1}) {
  setState(() {
    final double dragMagnitude = (details.delta.dx.abs() + details.delta.dy.abs()) / 2;
    final double scaleDelta = (dragMagnitude / 100.0) * scaleSign;
    final double newScale = (item.scale + scaleDelta).clamp(0.2, 10.0); // Changed from 5.0 to 10.0
    item.scale = newScale;
  });
}

  Widget _buildRotationHandle(CanvasItem item) {
    return Positioned(
      top: -30.h,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onPanStart: (_) {
            _preTransformState = item.copyWith();
          },
          onPanUpdate: (details) {
            setState(() {
              item.rotation += details.delta.dx * 0.01;
            });
          },
          onPanEnd: (_) {
            if (_preTransformState != null) {
              _addAction(CanvasAction(
                type: 'modify',
                item: item.copyWith(),
                previousState: _preTransformState,
                timestamp: DateTime.now(),
              ));
              _preTransformState = null;
            }
          },
          child: Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.rotate_right_rounded, color: Colors.white, size: 14.sp),
          ),
        ),
      ),
    );
  }

  Widget _buildItemContent(CanvasItem item) {
  switch (item.type) {
    case CanvasItemType.text:
      final props = item.properties;
      final String? fontFamily = props['fontFamily'] as String?;
      final bool textHasGradient = props['hasGradient'] == true;
      final bool textHasShadow = props['hasShadow'] == true;
      final double textShadowOpacity = (props['shadowOpacity'] as double?) ?? 0.6;
      final Color baseShadowColor = (props['shadowColor'] is HiveColor)
          ? (props['shadowColor'] as HiveColor).toColor()
          : (props['shadowColor'] is Color)
              ? (props['shadowColor'] as Color)
              : Colors.grey;
      final Color effectiveShadowColor = baseShadowColor.withOpacity((baseShadowColor.opacity * textShadowOpacity).clamp(0.0, 1.0));
      final TextStyle baseStyle = TextStyle(
        fontSize: (props['fontSize'] ?? 24.0) as double,
        // Force solid white text when using ShaderMask gradient so the alpha is solid
        color: textHasGradient
            ? Colors.white
            : (props['color'] is HiveColor)
                ? (props['color'] as HiveColor).toColor()
                : (props['color'] is Color)
                    ? (props['color'] as Color)
                    : Colors.black,
        fontWeight: (props['fontWeight'] is FontWeight)
            ? (props['fontWeight'] as FontWeight)
            : FontWeight.values.firstWhere(
                  (e) => e.index == (props['fontWeight'] as int?),
                  orElse: () => FontWeight.normal,
                ),
        fontStyle: (props['fontStyle'] is FontStyle)
            ? (props['fontStyle'] as FontStyle)
            : FontStyle.values.firstWhere(
                  (e) => e.index == (props['fontStyle'] as int?),
                  orElse: () => FontStyle.normal,
                ),
        decoration: _intToTextDecoration((props['decoration'] as int?) ?? 0),
        decorationColor: (props['color'] is HiveColor)
            ? (props['color'] as HiveColor).toColor()
            : (props['color'] as Color?),
        letterSpacing: (props['letterSpacing'] as double?) ?? 0.0,
        shadows: textHasShadow
            ? [
                Shadow(
                  color: effectiveShadowColor,
                  offset: (props['shadowOffset'] as Offset?) ?? const Offset(2, 2),
                  blurRadius: (props['shadowBlur'] as double?) ?? 4.0,
                ),
              ]
            : null,
      );

      Widget textWidget;
      if (fontFamily != null) {
        try {
          final TextStyle gfStyle = GoogleFonts.getFont(fontFamily, textStyle: baseStyle);
          textWidget = Text(
            (props['text'] ?? 'Text') as String,
            style: gfStyle,
            textAlign: (props['textAlign'] as TextAlign?) ?? TextAlign.center,
          );
        } catch (_) {
          textWidget = Text(
            (props['text'] ?? 'Text') as String,
            style: baseStyle,
            textAlign: (props['textAlign'] as TextAlign?) ?? TextAlign.center,
          );
        }
      } else {
        textWidget = Text(
          (props['text'] ?? 'Text') as String,
          style: baseStyle,
          textAlign: (props['textAlign'] as TextAlign?) ?? TextAlign.center,
        );
      }
      if (textHasGradient) {
        final double angle = (props['gradientAngle'] as double?) ?? 0.0;
        final double rad = angle * math.pi / 180.0;
        final double cx = math.cos(rad);
        final double sy = math.sin(rad);
        final Alignment begin = Alignment(-cx, -sy);
        final Alignment end = Alignment(cx, sy);
        textWidget = ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: (props['gradientColors'] as List<dynamic>?)?.map((e) => (e as HiveColor).toColor()).toList() ?? [HiveColor.fromColor(Colors.blue).toColor(), HiveColor.fromColor(Colors.purple).toColor()],
            begin: begin,
            end: end,
          ).createShader(bounds),
          child: textWidget,
        );
      }
      return Container(padding: EdgeInsets.all(16.w), child: textWidget);

    case CanvasItemType.image:
      final String? filePath = item.properties['filePath'] as String?;
      final double blur = (item.properties['blur'] as double?) ?? 0.0;
      final bool hasGradient = (item.properties['hasGradient'] as bool?) ?? false;
      final List<Color> grad = (item.properties['gradientColors'] as List<dynamic>?)?.map((e) => (e is HiveColor ? e : (e is int ? HiveColor(e) : null))?.toColor()).whereType<Color>().toList() ?? [];
      final bool hasShadow = (item.properties['hasShadow'] as bool?) ?? false;
      final Color shadowColor = (item.properties['shadowColor'] is HiveColor)
          ? (item.properties['shadowColor'] as HiveColor).toColor()
          : (item.properties['shadowColor'] is Color)
              ? (item.properties['shadowColor'] as Color)
              : Colors.black54;
      final Offset shadowOffset = (item.properties['shadowOffset'] as Offset?) ?? const Offset(4, 4);
      final double shadowBlur = (item.properties['shadowBlur'] as double?) ?? 8.0;
      final double shadowOpacity = (item.properties['shadowOpacity'] as double?) ?? 0.6;
      final double gradientAngle = (item.properties['gradientAngle'] as double?) ?? 0.0;
      final Color tintColor = (item.properties['tint'] is HiveColor)
          ? (item.properties['tint'] as HiveColor).toColor()
          : (item.properties['tint'] is Color)
              ? (item.properties['tint'] as Color)
              : Colors.transparent;

      final double? displayW = (item.properties['displayWidth'] as double?);
      final double? displayH = (item.properties['displayHeight'] as double?);

      // Build the main image first
      Widget mainImage = _buildActualImage(filePath, item, tintColor, grad, hasGradient, gradientAngle);

      // Apply blur to the main image if needed
      if (blur > 0.0) {
        final ui.ImageFilter filter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);
        mainImage = ImageFiltered(imageFilter: filter, child: mainImage);
      }

      // Create shadow and main image stack
      Widget imageWidget = Stack(
        children: [
          // Colored shadow behind the image
          if (hasShadow)
            Transform.translate(
              offset: shadowOffset,
              child: Container(
                width: (displayW ?? 160.0).w,
                height: (displayH ?? 160.0).h,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(shadowOpacity.clamp(0.0, 1.0)),
                      blurRadius: shadowBlur,
                      spreadRadius: 0,
                      offset: Offset.zero, // Already offset by Transform.translate
                    ),
                  ],
                ),
              ),
            ),
          // Main image on top
          mainImage,
        ],
      );

      return imageWidget;

    case CanvasItemType.sticker:
      final props = item.properties;
      final int iconCodePoint = (props['iconCodePoint'] as int?) ?? Icons.star.codePoint;
      final String? iconFontFamily = props['iconFontFamily'] as String?;
      final Color color = (props['color'] is HiveColor) ? (props['color'] as HiveColor).toColor() : Colors.yellow;
      final double size = (props['size'] as double?) ?? 60.0;

      return FittedBox(
        fit: BoxFit.contain,
        child: Icon(
          IconData(iconCodePoint, fontFamily: iconFontFamily),
          color: color,
          size: size,
        ),
      );

case CanvasItemType.shape:
  final props = item.properties;
  final String shape = (props['shape'] as String?) ?? 'rectangle';
  final Color fillColor = (props['fillColor'] is HiveColor)
      ? (props['fillColor'] as HiveColor).toColor()
      : Colors.blue;
  final Color strokeColor = (props['strokeColor'] is HiveColor)
      ? (props['strokeColor'] as HiveColor).toColor()
      : Colors.black;
  final double strokeWidth = (props['strokeWidth'] as double?) ?? 2.0;
  final double cornerRadius = (props['cornerRadius'] as double?) ?? 0.0;
  final bool hasGradient = (props['hasGradient'] as bool?) ?? false;
  final List<Color> gradientColors = (props['gradientColors'] as List<dynamic>?)
          ?.map((e) => (e is HiveColor ? e : (e is int ? HiveColor(e) : null))?.toColor())
          .whereType<Color>()
          .toList() ??
      [];
  final double gradientAngle = (props['gradientAngle'] as double?) ?? 0.0;
  final bool hasShadow = (props['hasShadow'] as bool?) ?? false;
  final HiveColor shadowColorHive = (props['shadowColor'] is HiveColor)
      ? (props['shadowColor'] as HiveColor)
      : (props['shadowColor'] is Color)
          ? HiveColor.fromColor(props['shadowColor'] as Color)
          : HiveColor.fromColor(Colors.black54);
  final Offset shadowOffset = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
  final double shadowBlur = (props['shadowBlur'] as double?) ?? 8.0;
  final double shadowOpacity = (props['shadowOpacity'] as double?) ?? 0.6;
  final ui.Image? fillImage = props['image'] as ui.Image?; // Get the ui.Image
  final HiveSize? hiveSize = props['size'] as HiveSize?;

  Size itemSize = hiveSize?.toSize() ?? Size(100.0.w, 100.0.h);

  Widget shapeWidget = CustomPaint(
    painter: _ShapePainter(
      {
        'shape': shape,
        'fillColor': HiveColor.fromColor(fillColor),
        'strokeColor': HiveColor.fromColor(strokeColor),
        'strokeWidth': strokeWidth,
        'cornerRadius': cornerRadius,
        'hasGradient': hasGradient && fillImage == null, // Disable gradient if image is present
        'gradientColors': gradientColors.map((color) => HiveColor.fromColor(color)).toList(),
        'gradientAngle': gradientAngle,
        'hasShadow': hasShadow,
        'shadowColor': shadowColorHive,
        'shadowOffset': shadowOffset,
        'shadowBlur': shadowBlur,
        'shadowOpacity': shadowOpacity,
        'image': fillImage, // Pass the ui.Image to the painter
      }
    ),
    size: itemSize,
  );

  return SizedBox(
    width: itemSize.width,
    height: itemSize.height,
    child: FittedBox(fit: BoxFit.contain, child: shapeWidget),
  );
  }
}

  Widget _buildActualImage(String? filePath, CanvasItem item, Color tintColor, List<Color> grad, bool hasGradient, double gradientAngle) {
    final String? imageUrl = item.properties['imageUrl'] as String?;
    final double? displayW = (item.properties['displayWidth'] as double?);
    final double? displayH = (item.properties['displayHeight'] as double?);

    Widget imageWidget;

    if (filePath != null) {
      imageWidget = Image.file(
        File(filePath),
        fit: BoxFit.contain,
      );
    } else if (imageUrl != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      imageWidget = Icon(
        (item.properties['icon'] as IconData?) ?? Icons.image,
        size: 90.sp,
        color: (item.properties['color'] as HiveColor?)?.toColor() ?? Colors.blue,
      );
    }

    if (hasGradient) {
      final double rad = gradientAngle * math.pi / 180.0;
      final double cx = math.cos(rad);
      final double sy = math.sin(rad);
      final Alignment begin = Alignment(-cx, -sy);
      final Alignment end = Alignment(cx, sy);
      imageWidget = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(colors: grad, begin: begin, end: end).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: imageWidget,
      );
    } else {
      imageWidget = ColorFiltered(colorFilter: ColorFilter.mode(tintColor, BlendMode.overlay), child: imageWidget);
    }

    return SizedBox(
      width: (displayW ?? 160.0).w,
      height: (displayH ?? 160.0).h,
      child: imageWidget,
    );
  }

  BoxDecoration _buildShapeDecoration(Map<String, dynamic> props) {
    final String shape = (props['shape'] as String?) ?? 'rectangle';
    return BoxDecoration(
      color: (props['hasGradient'] == true) ? null : (props['fillColor'] as Color? ?? Colors.blue),
      gradient: (props['hasGradient'] == true)
          ? LinearGradient(colors: (props['gradientColors'] as List<Color>?) ?? [Colors.blue, Colors.purple])
          : null,
      border: Border.all(color: (props['strokeColor'] as Color?) ?? Colors.black, width: (props['strokeWidth'] as double?) ?? 2.0),
      borderRadius: shape == 'rectangle' ? BorderRadius.circular((props['cornerRadius'] as double?) ?? 12.0) : null,
      shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
    );
  }

  

  

  Widget _buildControlButton(IconData icon, VoidCallback onTap, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 20.sp, color: color),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    if (!showBottomSheet || selectedItem == null) return const SizedBox();
    return AnimatedBuilder(
      animation: _bottomSheetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _bottomSheetAnimation.value) * 320.h),
          child: Container(
            height: 320.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32.r), topRight: Radius.circular(32.r)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, -12)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60.w,
                  height: 6.h,
                  margin: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3.r)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(_getItemTypeIcon(selectedItem!.type), color: Colors.white, size: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${selectedItem!.type.name.toUpperCase()} PROPERTIES', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: 0.5)),
                          Text('Customize your ${selectedItem!.type.name}', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(child: _buildBottomSheetContent()),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getItemTypeIcon(CanvasItemType type) {
    switch (type) {
      case CanvasItemType.text:
        return Icons.text_fields_rounded;
      case CanvasItemType.image:
        return Icons.image_rounded;
      case CanvasItemType.sticker:
        return Icons.emoji_emotions_rounded;
      case CanvasItemType.shape:
        return Icons.category_rounded;
    }
  }

  Widget _buildBottomSheetContent() {
    if (selectedItem == null) return const SizedBox();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommonOptions(),
            SizedBox(height: 24.h),
            Divider(color: Colors.grey[200], thickness: 1),
            SizedBox(height: 24.h),
            _buildTypeSpecificOptions(),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GENERAL', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
        SizedBox(height: 16.h),
        _buildSliderOption('Opacity', selectedItem!.opacity, 0.1, 1.0, (value) => setState(() => selectedItem!.opacity = value), Icons.opacity_rounded),
        SizedBox(height: 16.h),
        _buildSliderOption('Scale', selectedItem!.scale, 0.3, 10.0, (value) => setState(() => selectedItem!.scale = value), Icons.zoom_out_map_rounded),
        SizedBox(height: 16.h),
        _buildSliderOption('Rotation', selectedItem!.rotation * 180 / 3.14159, -180, 180, (value) => setState(() => selectedItem!.rotation = value * 3.14159 / 180), Icons.rotate_right_rounded),
      ],
    );
  }

  Widget _buildTypeSpecificOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${selectedItem!.type.name.toUpperCase()} OPTIONS', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
        SizedBox(height: 16.h),
        _buildSpecificOptionsContent(),
      ],
    );
  }

  Widget _buildSpecificOptionsContent() {
    switch (selectedItem!.type) {
      case CanvasItemType.text:
        return _buildTextOptions();
      case CanvasItemType.image:
        return _buildImageOptions();
      case CanvasItemType.sticker:
        return _buildStickerOptions();
      case CanvasItemType.shape:
        return _buildShapeOptions();
    }
  }

  Widget _buildTextOptions() {
    final props = selectedItem!.properties;
    final controller = TextEditingController(text: props['text'] as String? ?? '');
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Colors.grey.shade200)),
          child: TextField(
            decoration: InputDecoration(labelText: 'Text Content', labelStyle: TextStyle(color: Colors.grey[600]), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h)),
            onChanged: (value) => setState(() => props['text'] = value),
            controller: controller,
          ),
        ),
        SizedBox(height: 20.h),
        _buildSliderOption('Font Size', (props['fontSize'] as double?) ?? 24.0, 10.0, 72.0, (value) => setState(() => props['fontSize'] = value), Icons.format_size_rounded),
        SizedBox(height: 16.h),
        _buildSliderOption('Letter Spacing', (props['letterSpacing'] as double?) ?? 0.0, -2.0, 5.0, (value) => setState(() => props['letterSpacing'] = value), Icons.space_bar_rounded),
        SizedBox(height: 20.h),
        _buildColorSection(props),
        SizedBox(height: 20.h),
        _buildTextStyleOptions(props),
        SizedBox(height: 20.h),
        _buildTextEffectsOptions(props),
      ],
    );
  }

  Widget _buildColorSection(Map<String, dynamic> props) {
    return Column(
      children: [
        _buildColorOption('Text Color', 'color', props),
        SizedBox(height: 16.h),
        _buildToggleOption('Gradient', (props['hasGradient'] as bool?) ?? false, Icons.gradient_rounded, (value) => setState(() => props['hasGradient'] = value)),
        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),
          _buildGradientPicker(props),
        ],
      ],
    );
  }

  Widget _buildGradientPicker(Map<String, dynamic> props) {
    final List<Color> grad = (props['gradientColors'] as List<Color>?) ?? [Colors.blue, Colors.purple];
    return Row(
      children: [
        Text('Gradient Colors', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
        const Spacer(),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showColorPicker('gradientColor1', isGradient: true),
              child: Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(color: grad.first, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.grey.shade300, width: 2)),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_rounded, size: 16.sp, color: Colors.grey[600]),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => _showColorPicker('gradientColor2', isGradient: true),
              child: Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(color: grad.last, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.grey.shade300, width: 2)),
              ),
            ),
            SizedBox(width: 12.w),
            Row(
              children: [
                Icon(Icons.rotate_right_rounded, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 6.w),
                Text('Angle', style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                SizedBox(width: 8.w),
                SizedBox(
                  width: 160.w,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      activeTrackColor: Colors.blue.shade400,
                      inactiveTrackColor: Colors.blue.shade100,
                      thumbColor: Colors.blue.shade600,
                    ),
                    child: Slider(
                      value: ((props['gradientAngle'] as double?) ?? 0.0).clamp(-180.0, 180.0),
                      min: -180.0,
                      max: 180.0,
                      onChanged: (v) => setState(() => props['gradientAngle'] = v),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextEffectsOptions(Map<String, dynamic> props) {
    return Column(
      children: [
        _buildToggleOption('Shadow', (props['hasShadow'] as bool?) ?? false, CupertinoIcons.moon_stars, (value) => setState(() => props['hasShadow'] = value)),
        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),
          _buildColorOption('Shadow Color', 'shadowColor', props),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Blur', (props['shadowBlur'] as double?) ?? 4.0, 0.0, 20.0, (value) => setState(() => props['shadowBlur'] = value), Icons.blur_on_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Opacity', (props['shadowOpacity'] as double?) ?? 0.6, 0.0, 1.0, (value) => setState(() => props['shadowOpacity'] = value), Icons.opacity_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Offset X', (props['shadowOffset'] as Offset?)?.dx ?? 2.0, -50.0, 50.0, (value) {
            setState(() {
              final Offset cur = (props['shadowOffset'] as Offset?) ?? const Offset(2, 2);
              props['shadowOffset'] = Offset(value, cur.dy);
            });
          }, Icons.swap_horiz_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Offset Y', (props['shadowOffset'] as Offset?)?.dy ?? 2.0, -50.0, 50.0, (value) {
            setState(() {
              final Offset cur = (props['shadowOffset'] as Offset?) ?? const Offset(2, 2);
              props['shadowOffset'] = Offset(cur.dx, value);
            });
          }, Icons.swap_vert_rounded),
        ],
      ],
    );
  }

  Widget _buildTextStyleOptions(Map<String, dynamic> props) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton('Bold', props['fontWeight'] == FontWeight.bold, Icons.format_bold_rounded, () => setState(() {
                props['fontWeight'] = (props['fontWeight'] == FontWeight.bold) ? FontWeight.normal : FontWeight.bold;
              })),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildToggleButton('Italic', props['fontStyle'] == FontStyle.italic, Icons.format_italic_rounded, () => setState(() {
                props['fontStyle'] = (props['fontStyle'] == FontStyle.italic) ? FontStyle.normal : FontStyle.italic;
              })),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildToggleButton('Underline', props['decoration'] == TextDecoration.underline, Icons.format_underlined_rounded, () => setState(() {
                props['decoration'] = (props['decoration'] == TextDecoration.underline) ? TextDecoration.none : TextDecoration.underline;
              })),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: isActive ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]) : null,
          color: isActive ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200),
          boxShadow: isActive ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade600, size: 22.sp),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool value, IconData icon, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
        const Spacer(),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: Colors.blue.shade400),
      ],
    );
  }

  Widget _buildImageOptions() {
    final props = selectedItem!.properties;
    return Column(
      children: [
          _buildOptionButton('Edit Image', Icons.edit_rounded, Colors.purple.shade400, _editSelectedImage),
      SizedBox(height: 20.h),
        _buildColorOption('Tint Color', 'tint', props),
        SizedBox(height: 16.h),
        _buildSliderOption('Blur', (props['blur'] as double?) ?? 0.0, 0.0, 10.0, (value) => setState(() => props['blur'] = value), Icons.blur_on_rounded),
        SizedBox(height: 20.h),
        _buildOptionButton('Replace Image', Icons.photo_library_rounded, Colors.blue.shade400, () {
          _pickImage(replace: true);
        }),
        SizedBox(height: 20.h),
        _buildToggleOption('Gradient', (props['hasGradient'] as bool?) ?? false, Icons.gradient_rounded, (value) => setState(() => props['hasGradient'] = value)),
        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),
          _buildGradientPicker(props),
        ],
        SizedBox(height: 16.h),
        _buildSliderOption('Shadow Opacity', (props['shadowOpacity'] as double?) ?? 0.6, 0.0, 1.0, (value) => setState(() => props['shadowOpacity'] = value), Icons.opacity_rounded),
        SizedBox(height: 20.h),
        _buildToggleOption('Shadow', (props['hasShadow'] as bool?) ?? false, CupertinoIcons.moon_stars, (value) => setState(() => props['hasShadow'] = value)),
        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),
          _buildColorOption('Shadow Color', 'shadowColor', props),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Blur', (props['shadowBlur'] as double?) ?? 8.0, 0.0, 40.0, (value) => setState(() => props['shadowBlur'] = value), Icons.blur_on_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Offset X', (props['shadowOffset'] as Offset?)?.dx ?? 4.0, -100.0, 100.0, (v) => setState(() {
            final cur = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
            props['shadowOffset'] = Offset(v, cur.dy);
          }), Icons.swap_horiz_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Offset Y', (props['shadowOffset'] as Offset?)?.dy ?? 4.0, -100.0, 100.0, (v) => setState(() {
            final cur = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
            props['shadowOffset'] = Offset(cur.dx, v);
          }), Icons.swap_vert_rounded),
        ],
      ],
    );
  }

  Widget _buildStickerOptions() {
    final props = selectedItem!.properties;
    return Column(
      children: [
        _buildColorOption('Sticker Color', 'color', props),
        SizedBox(height: 20.h),
        _buildOptionButton('Change Sticker', Icons.emoji_emotions_rounded, Colors.orange.shade400, () {}),
      ],
    );
  }

  Widget _buildShapeOptions() {
    final props = selectedItem!.properties;
    return Column(
      children: [
        _buildColorOption('Fill Color', 'fillColor', props),
        SizedBox(height: 16.h),
        _buildColorOption('Stroke Color', 'strokeColor', props),
        SizedBox(height: 16.h),
        _buildSliderOption('Stroke Width', (props['strokeWidth'] as double?) ?? 2.0, 0.0, 10.0, (v) => setState(() => props['strokeWidth'] = v), Icons.line_weight_rounded),
        SizedBox(height: 16.h),
        _buildSliderOption('Corner Radius', (props['cornerRadius'] as double?) ?? 12.0, 0.0, 50.0, (v) => setState(() => props['cornerRadius'] = v), Icons.rounded_corner_rounded),
        SizedBox(height: 20.h),
        _buildToggleOption('Gradient Fill', (props['hasGradient'] as bool?) ?? false, Icons.gradient_rounded, (value) => setState(() => props['hasGradient'] = value)),
        SizedBox(height: 16.h),
        _buildOptionButton('Pick Image Inside Shape', Icons.photo_library_rounded, Colors.blue.shade400, _pickShapeImage),
        if (props['image'] != null) ...[
          SizedBox(height: 12.h),
          _buildOptionButton('Clear Image', Icons.delete_sweep_rounded, Colors.red.shade400, () => setState(() => props['image'] = null)),
        ],
        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),
          _buildGradientPicker(props),
        ],
        SizedBox(height: 16.h),
        _buildToggleOption('Shadow', (props['hasShadow'] as bool?) ?? false, CupertinoIcons.moon_stars, (value) => setState(() => props['hasShadow'] = value)),
        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),
          _buildColorOption('Shadow Color', 'shadowColor', props),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Blur', (props['shadowBlur'] as double?) ?? 8.0, 0.0, 40.0, (v) => setState(() => props['shadowBlur'] = v), Icons.blur_on_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Opacity', (props['shadowOpacity'] as double?) ?? 0.6, 0.0, 1.0, (v) => setState(() => props['shadowOpacity'] = v), Icons.opacity_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Offset X', (props['shadowOffset'] as Offset?)?.dx ?? 4.0, -100.0, 100.0, (v) => setState(() {
            final Offset cur = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
            props['shadowOffset'] = Offset(v, cur.dy);
          }), Icons.swap_horiz_rounded),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Offset Y', (props['shadowOffset'] as Offset?)?.dy ?? 4.0, -100.0, 100.0, (v) => setState(() {
            final Offset cur = (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);
            props['shadowOffset'] = Offset(cur.dx, v);
          }), Icons.swap_vert_rounded),
        ],
      ],
    );
  }

  Widget _buildColorOption(String label, String property, Map<String, dynamic> props) {
    return Row(
      children: [
        Icon(Icons.palette_rounded, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
        const Spacer(),
        GestureDetector(
          onTap: () => _showColorPicker(property),
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: (props[property] is HiveColor)
                  ? (props[property] as HiveColor).toColor()
                  : (props[property] is int)
                      ? HiveColor(props[property] as int).toColor()
                      : (props[property] as Color?) ?? Colors.blue,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, size: 20.sp, color: color),
            ),
            SizedBox(width: 16.w),
            Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderOption(String label, double value, double min, double max, ValueChanged<double> onChanged, IconData icon) {
    final clamped = value.clamp(min, max);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: Colors.grey[600]),
              SizedBox(width: 12.w),
              Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.blue.shade200)),
                child: Text(clamped.toStringAsFixed(1), style: TextStyle(fontSize: 14.sp, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue.shade400,
              inactiveTrackColor: Colors.blue.shade100,
              thumbColor: Colors.blue.shade600,
              overlayColor: Colors.blue.withOpacity(0.1),
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            ),
            child: Slider(value: clamped, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(String property, {bool isGradient = false}) {
    final predefinedColors = <Color>[
      Colors.black,
      Colors.white,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
      Colors.amberAccent,
      Colors.cyanAccent,
    ];

    Color _selectedColorInPicker = isGradient ? Colors.blue : (recentColors.isNotEmpty ? recentColors.last : Colors.black);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 280.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32.r), topRight: Radius.circular(32.r)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -8)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60.w,
                  height: 6.h,
                  margin: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3.r)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Icon(Icons.palette_rounded, color: Colors.blue.shade400, size: 24.sp),
                      SizedBox(width: 12.w),
                      Text('Choose Color', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      SizedBox(width: 12.w),
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: _selectedColorInPicker,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                      ),
                      const Spacer(),
  IconButton(
  icon: Icon(Icons.add_circle, color: Colors.green, size: 24.sp),
  onPressed: () async {
    // Show advanced color picker in a new modal bottom sheet
    final pickedColor = await showColorPickerBottomSheet(
      context: context,
      initialColor: _selectedColorInPicker,
      onPreview: (color) {
        if (selectedItem == null) return;
        // Live update without committing to history
        setState(() {
          if (isGradient) {
            final List<Color> currentGradient = _getDisplayGradientColors();
            final Color first = currentGradient.first;
            final Color last = currentGradient.last;
            final Map<String, dynamic> newProperties = Map.from(selectedItem!.properties);
            if (property == 'gradientColor1') {
              newProperties['gradientColors'] = [HiveColor.fromColor(color), HiveColor.fromColor(last)];
            } else if (property == 'gradientColor2') {
              newProperties['gradientColors'] = [HiveColor.fromColor(first), HiveColor.fromColor(color)];
            } else {
              // Fallback: replace first color
              newProperties['gradientColors'] = [HiveColor.fromColor(color), HiveColor.fromColor(last)];
            }
            selectedItem = selectedItem!.copyWith(properties: newProperties);
          } else {
            final Map<String, dynamic> newProperties = Map.from(selectedItem!.properties);
            newProperties[property] = HiveColor.fromColor(color);
            selectedItem = selectedItem!.copyWith(properties: newProperties);
          }
        });
      },
    );

    if (pickedColor != null) {
      // Update state and save
      setState(() {
        _selectedColorInPicker = pickedColor;
        if (!recentColors.contains(pickedColor)) {
          recentColors.add(pickedColor); // or however you manage recentColors
        }
      });
      _selectColor(property, pickedColor, isGradient: isGradient);
      Navigator.pop(context); // Close the original bottom sheet
    }
  },
),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                if (recentColors.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('RECENT', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 50.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      itemCount: recentColors.length,
                      itemBuilder: (context, index) {
                        final color = recentColors[index];
                        return Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColorInPicker = color;
                              });
                              _selectColor(property, color, isGradient: isGradient);
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 50.h,
                              height: 50.h,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: BlockPicker(
                      pickerColor: _selectedColorInPicker,
                      onColorChanged: (color) {
                        setState(() {
                          _selectedColorInPicker = color;
                        });
                      },
                      availableColors: predefinedColors,
                      layoutBuilder: (context, colors, child) {
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                          ),
                          itemCount: colors.length,
                          itemBuilder: (context, index) {
                            return child(colors[index]);
                          },
                        );
                      },
                      itemBuilder: (color, isCurrentColor, changeColor) {
                        return GestureDetector(
                          onTap: () {
                            changeColor();
                            _selectColor(property, color, isGradient: isGradient);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

Future<Color?> showColorPickerBottomSheet({
  required BuildContext context,
  required Color initialColor,
  ValueChanged<Color>? onPreview,
}) async {
  Color currentColor = initialColor;

  return await showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Pick a Color',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Advanced Color Picker
                Expanded(
                  child: ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: (Color color) {
                      currentColor = color;
                      if (onPreview != null) {
                        onPreview(color);
                      }
                    },
                    colorPickerWidth: 300,
                    pickerAreaHeightPercent: 0.7,
                    showLabel: true,
                    displayThumbColor: true,
                    paletteType: PaletteType.hsv,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, currentColor);
                  },
                  child: Text('Select'),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Future<void> _pickImage({bool replace = false}) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      // Decode intrinsic dimensions to preserve original aspect ratio
      final File file = File(picked.path);
      final Uint8List bytes = await file.readAsBytes();
      final ui.Image decoded = await decodeImageFromList(bytes);
      final double intrinsicW = decoded.width.toDouble();
      final double intrinsicH = decoded.height.toDouble();
      // Set an initial displayed size that fits within a reasonable box while keeping ratio
      const double maxEdge = 240.0; // logical px baseline before user scaling
      double displayW = intrinsicW;
      double displayH = intrinsicH;
      if (intrinsicW > intrinsicH && intrinsicW > maxEdge) {
        displayW = maxEdge;
        displayH = maxEdge * (intrinsicH / intrinsicW);
      } else if (intrinsicH >= intrinsicW && intrinsicH > maxEdge) {
        displayH = maxEdge;
        displayW = maxEdge * (intrinsicW / intrinsicH);
      }
      if (replace && selectedItem != null && selectedItem!.type == CanvasItemType.image) {
        final previous = selectedItem!.copyWith();
        setState(() {
          selectedItem!.properties['filePath'] = picked.path;
          selectedItem!.properties['intrinsicWidth'] = intrinsicW;
          selectedItem!.properties['intrinsicHeight'] = intrinsicH;
          selectedItem!.properties['displayWidth'] = displayW;
          selectedItem!.properties['displayHeight'] = displayH;
        });
        _addAction(CanvasAction(type: 'modify', item: selectedItem, previousState: previous, timestamp: DateTime.now()));
      } else {
        _addCanvasItem(
          CanvasItemType.image,
          properties: {
            'filePath': picked.path,
            'tint': Colors.transparent,
            'blur': 0.0,
            'intrinsicWidth': intrinsicW,
            'intrinsicHeight': intrinsicH,
            'displayWidth': displayW,
            'displayHeight': displayH,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

 Future<void> _pickShapeImage() async {
  try {
    final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null || selectedItem == null || selectedItem!.type != CanvasItemType.shape) return;
    
    final Uint8List bytes = await File(picked.path).readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    
    final previous = selectedItem!.copyWith();
    setState(() {
      // Store both the ui.Image object and the file path
      selectedItem!.properties['image'] = image;
      selectedItem!.properties['imagePath'] = picked.path;
      // Disable gradient when using image fill
      selectedItem!.properties['hasGradient'] = false;
    });
    
    _addAction(CanvasAction(type: 'modify', item: selectedItem, previousState: previous, timestamp: DateTime.now()));
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load image for shape'))
    );
  }
}


  void _selectColor(String property, Color color, {bool isGradient = false}) {
    if (selectedItem == null) return;
    final previous = selectedItem!.copyWith();
    setState(() {
      if (selectedItem != null) {
        if (isGradient) {
          final currentGradient = (selectedItem!.properties['gradientColors'] as List<dynamic>?)?.map((e) => (e as HiveColor).toColor()).toList() ?? [Colors.blue, Colors.purple];
          final Map<String, dynamic> newProperties = Map.from(selectedItem!.properties);
          if (property == 'gradientColor1') {
            newProperties['gradientColors'] = [HiveColor.fromColor(color), HiveColor.fromColor(currentGradient.last)];
          } else if (property == 'gradientColor2') {
            newProperties['gradientColors'] = [HiveColor.fromColor(currentGradient.first), HiveColor.fromColor(color)];
          }
          selectedItem = selectedItem!.copyWith(properties: newProperties);
        } else {
          final Map<String, dynamic> newProperties = Map.from(selectedItem!.properties);
          newProperties[property] = HiveColor.fromColor(color);
          selectedItem = selectedItem!.copyWith(properties: newProperties);
        }
        if (!recentColors.contains(color)) {
          recentColors.insert(0, color);
          if (recentColors.length > 8) {
            recentColors.removeLast();
          }
          userPreferences.recentColors = recentColors.map((e) => HiveColor.fromColor(e)).toList();
          _userPreferencesBox.put('user_prefs_id', userPreferences);
        }
      }
    });
    // Add to action history for undo/redo
    if (selectedItem != null) {
      _addAction(CanvasAction(type: 'modify', item: selectedItem, previousState: previous, timestamp: DateTime.now()));
    }
  }

  Widget _buildActionBar() {
    return ActionBar(
      canUndo: currentActionIndex >= 0,
      canRedo: currentActionIndex < actionHistory.length - 1,
      onUndo: _undo,
      onRedo: _redo,
      snapToGrid: snapToGrid,
      onToggleGrid: (v) => setState(() => snapToGrid = v),
      hasItems: canvasItems.isNotEmpty,
      onShowLayers: _showLayerPanel,
      onExport: _exportPoster,
    );
  }

  void _showLayerPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32.r), topRight: Radius.circular(32.r)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -8))],
        ),
        child: Column(
          children: [
            Container(width: 60.w, height: 6.h, margin: EdgeInsets.symmetric(vertical: 16.h), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3.r))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Icon(Icons.layers_rounded, color: Colors.blue.shade400, size: 24.sp),
                  SizedBox(width: 12.w),
                  Text('Layers', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const Spacer(),
                  Text('${canvasItems.length} items', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: _buildReorderableLayersList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableLayersList() {
    // Top-most first list
    final List<CanvasItem> layersTopFirst = [...canvasItems]
      ..sort((a, b) => b.layerIndex.compareTo(a.layerIndex));

    return ReorderableListView.builder(
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: child,
      ),
      itemCount: layersTopFirst.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = layersTopFirst.removeAt(oldIndex);
          layersTopFirst.insert(newIndex, item);
          // After reordering, recompute layerIndex where index 0 is top-most
          final int n = layersTopFirst.length;
          for (int i = 0; i < n; i++) {
            layersTopFirst[i].layerIndex = n - 1 - i;
          }
        });
      },
      itemBuilder: (context, index) {
        final item = layersTopFirst[index];
        final isSelected = selectedItem == item;
        return Container(
          key: ValueKey(item.id),
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(colors: [Colors.blue.shade50!, Colors.blue.shade100!]) : null,
            color: isSelected ? null : Colors.grey[50],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(_getItemTypeIcon(item.type), color: isSelected ? Colors.blue.shade400 : Colors.grey.shade600, size: 24.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.type.name.toUpperCase()} Layer', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isSelected ? Colors.blue.shade700 : Colors.grey[800])),
                    Text('Layer ${item.layerIndex + 1}', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      item.isVisible = !item.isVisible;
                    }),
                    icon: Icon(item.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey[600], size: 20.sp),
                  ),
                  IconButton(
                    onPressed: () {
                      _selectItem(item);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.edit_rounded, color: Colors.blue.shade400, size: 20.sp),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportPoster() async {
    try {
      final boundary = _canvasRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.download_done_rounded, color: Colors.white), SizedBox(width: 12.w), Text('Poster exported. Sharing...', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500))]),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ));
      await Share.shareXFiles([XFile(file.path)], text: 'My poster');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed')));
    }
  }

  Future<void> _navigateToPixabayImages() async {
    final PixabayImage? selectedImage = await Navigator.push(context, MaterialPageRoute(builder: (context) => PixabayImagesPage()));

    if (selectedImage != null) {
      _addCanvasItem(
        CanvasItemType.image,
        properties: {
          'imageUrl': selectedImage.webformatURL, // Use imageUrl for network images
          'tint': Colors.transparent,
          'blur': 0.0,
          'intrinsicWidth': selectedImage.views.toDouble(), // Using views as a placeholder for intrinsic width
          'intrinsicHeight': selectedImage.downloads.toDouble(), // Using downloads as a placeholder for intrinsic height
          'displayWidth': 240.0, 
          'displayHeight': 240.0 * (selectedImage.downloads / selectedImage.views), 
        },
      );
    }
  }

  List<Color> _getDisplayGradientColors() {
    final dynamic rawGradientColors = selectedItem!.properties['gradientColors'];
    if (rawGradientColors is List) {
      final List<Color> convertedColors = rawGradientColors.map((e) {
        if (e is HiveColor) return e.toColor();
        if (e is Color) return e;
        if (e is int) return HiveColor(e).toColor();
        return Colors.transparent;
      }).whereType<Color>().toList();

      if (convertedColors.isNotEmpty) {
        if (convertedColors.length == 1) {
          return [convertedColors.first, convertedColors.first];
        }
        return convertedColors;
      }
    }
    return [Colors.lightBlue, Colors.blueAccent];
  }
Future<void> _editSelectedImage() async {
  if (selectedItem == null || selectedItem!.type != CanvasItemType.image) return;
  
  try {
    final String? filePath = selectedItem!.properties['filePath'] as String?;
    final String? imageUrl = selectedItem!.properties['imageUrl'] as String?;
    
    Uint8List? imageBytes;
    
    // Get image bytes based on source
    if (filePath != null) {
      imageBytes = await File(filePath).readAsBytes();
    } else if (imageUrl != null) {
      // For network images, download first
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        imageBytes = response.bodyBytes;
      }
    }
    
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load image for editing'))
      );
      return;
    }

    // Navigate to image editor with white background theme
    final Uint8List? editedBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Theme(
          data: ThemeData.light().copyWith(
            // Set scaffold background to white
            scaffoldBackgroundColor: Colors.white,
            // Set app bar background to white
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            // Set bottom sheet background to white
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
            ),
            // Set dialog background to white
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
            // Set card background to white
            cardTheme: const CardThemeData(
              color: Colors.white,
            ),
            // Set color scheme with white surfaces
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
              surface: Colors.white,
              background: Colors.white,
            ),
          ),
          child: ImageEditor(
            image: imageBytes!,
          ),
        ),
      ),
    );

    // If user edited and saved the image
    if (editedBytes != null) {
      // Save edited image to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String editedFilePath = '${tempDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final File editedFile = File(editedFilePath);
      await editedFile.writeAsBytes(editedBytes);
      
      // Get new image dimensions
      final ui.Image decoded = await decodeImageFromList(editedBytes);
      final double intrinsicW = decoded.width.toDouble();
      final double intrinsicH = decoded.height.toDouble();
      
      // Calculate display size maintaining aspect ratio
      const double maxEdge = 240.0;
      double displayW = intrinsicW;
      double displayH = intrinsicH;
      if (intrinsicW > intrinsicH && intrinsicW > maxEdge) {
        displayW = maxEdge;
        displayH = maxEdge * (intrinsicH / intrinsicW);
      } else if (intrinsicH >= intrinsicW && intrinsicH > maxEdge) {
        displayH = maxEdge;
        displayW = maxEdge * (intrinsicW / intrinsicH);
      }

      // Update the canvas item with edited image
      final previous = selectedItem!.copyWith();
      setState(() {
        selectedItem!.properties['filePath'] = editedFilePath;
        selectedItem!.properties['imageUrl'] = null; // Clear network URL since we now have local file
        selectedItem!.properties['intrinsicWidth'] = intrinsicW;
        selectedItem!.properties['intrinsicHeight'] = intrinsicH;
        selectedItem!.properties['displayWidth'] = displayW;
        selectedItem!.properties['displayHeight'] = displayH;
      });
      
      _addAction(CanvasAction(
        type: 'modify', 
        item: selectedItem, 
        previousState: previous, 
        timestamp: DateTime.now()
      ));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12.w),
              Text('Image edited successfully!', 
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)
              ),
            ],
          ),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to edit image'))
    );
  }
}
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(_currentProject?.name ?? 'Poster Maker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProject,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(children: [ _buildActionBar(), _buildCanvas(), _buildTopToolbar(),]),
        ),
        bottomSheet: const SizedBox.shrink(),
      );
    }
  }