import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    );
  }
}

// Action model for undo/redo
class CanvasAction {
  final String type; // 'add', 'remove', 'modify', 'move'
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

class PosterMakerScreen extends StatefulWidget {
  const PosterMakerScreen({super.key});

  @override
  State<PosterMakerScreen> createState() => _PosterMakerScreenState();
}

class _PosterMakerScreenState extends State<PosterMakerScreen>
    with TickerProviderStateMixin {
  int selectedTabIndex = 0;
  List<CanvasItem> canvasItems = [];
  CanvasItem? selectedItem;
  bool showBottomSheet = false;
  bool snapToGrid = false;
  double canvasZoom = 1.0;
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

  final List<String> tabTitles = ['Text', 'Images', 'Stickers', 'Shapes'];

  // Enhanced sample data
  final List<Map<String, dynamic>> sampleTexts = [
    {'text': 'Heading', 'fontSize': 32.0, 'fontWeight': FontWeight.bold},
    {'text': 'Subtitle', 'fontSize': 24.0, 'fontWeight': FontWeight.w600},
    {'text': 'Body Text', 'fontSize': 16.0, 'fontWeight': FontWeight.normal},
    {'text': 'Caption', 'fontSize': 14.0, 'fontWeight': FontWeight.w300},
    {'text': 'Quote', 'fontSize': 20.0, 'fontWeight': FontWeight.w500},
  ];

  final List<IconData> sampleImages = [
    Icons.landscape_outlined,
    Icons.portrait_outlined,
    Icons.photo_outlined,
    Icons.camera_alt_outlined,
    Icons.image_outlined,
    Icons.photo_library_outlined,
    Icons.photo_camera_outlined,
    Icons.collections_outlined,
  ];

  final List<IconData> sampleStickers = [
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.emoji_emotions_outlined,
    Icons.local_fire_department_rounded,
    Icons.bolt_rounded,
    Icons.celebration_rounded,
    Icons.pets_rounded,
    Icons.music_note_rounded,
    Icons.wb_sunny_rounded,
    Icons.ac_unit_rounded,
  ];

  final List<Map<String, dynamic>> sampleShapes = [
    {'shape': 'rectangle', 'icon': Icons.crop_square_rounded},
    {'shape': 'circle', 'icon': Icons.circle_outlined},
    {'shape': 'triangle', 'icon': Icons.change_history_rounded},
    {'shape': 'hexagon', 'icon': Icons.hexagon_outlined},
    {'shape': 'diamond', 'icon': Icons.diamond_outlined},
    {'shape': 'star', 'icon': Icons.star_border_rounded},
    {'shape': 'arrow', 'icon': Icons.arrow_forward_rounded},
    {'shape': 'heart', 'icon': Icons.favorite_border_rounded},
  ];

  // Recent colors for color picker
  List<Color> recentColors = [
    Colors.black,
    Colors.red[400]!,
    Colors.blue[400]!,
    Colors.green[400]!,
  ];

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _selectionController.dispose();
    _itemAddController.dispose();
    super.dispose();
  }

  void _addAction(CanvasAction action) {
    // Remove any actions after current index (for branching undo/redo)
    if (currentActionIndex < actionHistory.length - 1) {
      actionHistory.removeRange(currentActionIndex + 1, actionHistory.length);
    }

    actionHistory.add(action);
    currentActionIndex++;

    // Limit history size
    if (actionHistory.length > 50) {
      actionHistory.removeAt(0);
      currentActionIndex--;
    }
  }

  void _undo() {
    if (currentActionIndex < 0) return;

    final action = actionHistory[currentActionIndex];
    setState(() {
      switch (action.type) {
        case 'add':
          canvasItems.removeWhere((item) => item.id == action.item!.id);
          break;
        case 'remove':
          canvasItems.add(action.item!);
          break;
        case 'modify':
          final index = canvasItems.indexWhere(
            (item) => item.id == action.item!.id,
          );
          if (index != -1 && action.previousState != null) {
            canvasItems[index] = action.previousState!;
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
          canvasItems.removeWhere((item) => item.id == action.item!.id);
          break;
        case 'modify':
          final index = canvasItems.indexWhere(
            (item) => item.id == action.item!.id,
          );
          if (index != -1) {
            canvasItems[index] = action.item!;
          }
          break;
      }
    });
  }

  void _addCanvasItem(CanvasItemType type, {Map<String, dynamic>? properties}) {
    final newItem = CanvasItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      position: Offset(
        MediaQuery.of(context).size.width * 0.4,
        MediaQuery.of(context).size.height * 0.3,
      ),
      properties: properties ?? _getDefaultProperties(type),
      layerIndex: canvasItems.length,
    );

    setState(() {
      canvasItems.add(newItem);
      _selectItem(newItem);
    });

    // Add to history
    _addAction(
      CanvasAction(type: 'add', item: newItem, timestamp: DateTime.now()),
    );

    // Animate new item
    _itemAddController.forward().then((_) {
      _itemAddController.reset();
    });
  }

  Map<String, dynamic> _getDefaultProperties(CanvasItemType type) {
    switch (type) {
      case CanvasItemType.text:
        return {
          'text': 'Sample Text',
          'fontSize': 24.0,
          'color': Colors.black,
          'fontWeight': FontWeight.normal,
          'fontStyle': FontStyle.normal,
          'textAlign': TextAlign.center,
          'hasGradient': false,
          'gradientColors': [Colors.blue, Colors.purple],
          'decoration': TextDecoration.none,
          'letterSpacing': 0.0,
          'hasShadow': false,
          'shadowColor': Colors.grey[400]!,
          'shadowOffset': const Offset(2, 2),
          'shadowBlur': 4.0,
        };
      case CanvasItemType.image:
        return {
          'icon': Icons.image_outlined,
          'color': Colors.blue[400],
          'tint': Colors.transparent,
          'blur': 0.0,
        };
      case CanvasItemType.sticker:
        return {'icon': Icons.favorite_rounded, 'color': Colors.red[400]};
      case CanvasItemType.shape:
        return {
          'shape': 'rectangle',
          'fillColor': Colors.blue[400],
          'strokeColor': Colors.blue[700],
          'strokeWidth': 2.0,
          'hasGradient': false,
          'gradientColors': [Colors.blue[300]!, Colors.blue[600]!],
          'cornerRadius': 12.0,
        };
    }
  }

  void _selectItem(CanvasItem item) {
    setState(() {
      selectedItem = item;
      showBottomSheet = true;
    });
    _bottomSheetController.forward();
    _selectionController.forward();
  }

  void _deselectItem() {
    setState(() {
      selectedItem = null;
      showBottomSheet = false;
    });
    _bottomSheetController.reverse();
    _selectionController.reverse();
  }

  void _removeItem(CanvasItem item) {
    setState(() {
      canvasItems.remove(item);
      if (selectedItem == item) {
        _deselectItem();
      }
    });

    // Add to history
    _addAction(
      CanvasAction(type: 'remove', item: item, timestamp: DateTime.now()),
    );
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

    _addAction(
      CanvasAction(
        type: 'add',
        item: duplicatedItem,
        timestamp: DateTime.now(),
      ),
    );
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
      // Adjust other items' layer indices
      for (var existingItem in canvasItems) {
        existingItem.layerIndex++;
      }
      item.layerIndex = 0;
      canvasItems.insert(0, item);
    });
  }

  Widget _buildTopToolbar() {
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
        children: [
          // Tab buttons with enhanced styling
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              children: List.generate(tabTitles.length, (index) {
                final isSelected = selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [Colors.blue[400]!, Colors.blue[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey[200]!,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Text(
                        tabTitles[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontSize: 15.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Tab content with improved styling
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: _buildTabContent(),
            ),
          ),
        ],
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
                border: Border.all(color: Colors.grey[100]!, width: 2),
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
        return sampleTexts.length;
      case 1:
        return sampleImages.length + 1; // +1 for Upload from Gallery
      case 2:
        return sampleStickers.length;
      case 3:
        return sampleShapes.length;
      default:
        return 0;
    }
  }

  Widget _getTabItemWidget(int index) {
    switch (selectedTabIndex) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_fields_rounded,
              size: 24.sp,
              color: Colors.blue[600],
            ),
            SizedBox(height: 6.h),
            Text(
              sampleTexts[index]['text'],
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case 1:
        if (index == 0) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                size: 28.sp,
                color: Colors.blue[700],
              ),
              SizedBox(height: 6.h),
              Text(
                'Upload',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          );
        }
        return Icon(
          sampleImages[index - 1],
          size: 32.sp,
          color: Colors.blue[600],
        );
      case 2:
        return Icon(
          sampleStickers[index],
          size: 32.sp,
          color: Colors.orange[600],
        );
      case 3:
        return Icon(
          sampleShapes[index]['icon'],
          size: 32.sp,
          color: Colors.green[600],
        );
      default:
        return const SizedBox();
    }
  }

  void _onTabItemTap(int index) {
    switch (selectedTabIndex) {
      case 0:
        final textData = sampleTexts[index];
        _addCanvasItem(
          CanvasItemType.text,
          properties: {
            'text': textData['text'],
            'fontSize': textData['fontSize'],
            'color': Colors.black,
            'fontWeight': textData['fontWeight'],
            'fontStyle': FontStyle.normal,
            'textAlign': TextAlign.center,
            'hasGradient': false,
            'gradientColors': [Colors.blue, Colors.purple],
            'decoration': TextDecoration.none,
            'letterSpacing': 0.0,
            'hasShadow': false,
            'shadowColor': Colors.grey[400]!,
            'shadowOffset': const Offset(2, 2),
            'shadowBlur': 4.0,
          },
        );
        break;
      case 1:
        if (index == 0) {
          _pickImage();
        } else {
          _addCanvasItem(
            CanvasItemType.image,
            properties: {
              'icon': sampleImages[index - 1],
              'color': Colors.blue[600],
              'tint': Colors.transparent,
              'blur': 0.0,
              'filePath': null,
            },
          );
        }
        break;
      case 2:
        _addCanvasItem(
          CanvasItemType.sticker,
          properties: {
            'icon': sampleStickers[index],
            'color': Colors.orange[600],
          },
        );
        break;
      case 3:
        final shapeData = sampleShapes[index];
        _addCanvasItem(
          CanvasItemType.shape,
          properties: {
            'shape': shapeData['shape'],
            'fillColor': Colors.green[400],
            'strokeColor': Colors.green[700],
            'strokeWidth': 2.0,
            'hasGradient': false,
            'gradientColors': [Colors.green[300]!, Colors.green[600]!],
            'cornerRadius': 12.0,
          },
        );
        break;
    }
  }

  Widget _buildCanvas() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: RepaintBoundary(
            key: _canvasRepaintKey,
            child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            onInteractionUpdate: (details) {
              setState(() {
                canvasZoom = details.scale;
              });
            },
            child: Stack(
              children: [
                // Canvas background with grid
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
                // Canvas items (sorted by layer index)
                ...(() {
                  final items = [...canvasItems]
                    ..sort((a, b) => a.layerIndex.compareTo(b.layerIndex));
                  return items.map((item) => _buildCanvasItem(item)).toList();
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
      child: GestureDetector(
        onTap: () => _selectItem(item),
        onPanStart: (_) {
          if (selectedItem == item) {
            _preDragState = item.copyWith();
          }
        },
        onPanUpdate: (details) {
          if (selectedItem == item) {
            setState(() {
              Offset newPosition = item.position + details.delta;

              // Snap to grid if enabled
              if (snapToGrid) {
                const gridSize = 20.0;
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
          if (selectedItem == item && _preDragState != null) {
            _addAction(
              CanvasAction(
                type: 'modify',
                item: item.copyWith(),
                previousState: _preDragState,
                timestamp: DateTime.now(),
              ),
            );
            _preDragState = null;
          }
        },
        child: AnimatedBuilder(
          animation: isSelected
              ? _selectionAnimation
              : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.rotate(
              angle: item.rotation,
              child: Transform.scale(
                scale:
                    item.scale * (isSelected ? _selectionAnimation.value : 1.0),
                child: Opacity(
                  opacity: item.opacity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Bounding box for selected item
                      if (isSelected) _buildBoundingBox(item),
                      // Item content
                      Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.blue[400]!,
                                  width: 2,
                                ),
                              )
                            : null,
                        child: _buildItemContent(item),
                      ),
                      // Item controls
                      if (isSelected) _buildItemController(item),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBoundingBox(CanvasItem item) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue[400]!.withOpacity(0.6),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Stack(
          children: [
            // Corner handles for resize
            ..._buildCornerHandles(item),
            // Rotation handle
            _buildRotationHandle(item),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerHandles(CanvasItem item) {
    return [
      // Top-left
      Positioned(
        top: -6.h,
        left: -6.w,
        child: _buildResizeHandle(item, (details) {
          _handleResizeUpdate(item, details, scaleSign: -1);
        }),
      ),
      // Top-right
      Positioned(
        top: -6.h,
        right: -6.w,
        child: _buildResizeHandle(item, (details) {
          _handleResizeUpdate(item, details, scaleSign: 1);
        }),
      ),
      // Bottom-left
      Positioned(
        bottom: -6.h,
        left: -6.w,
        child: _buildResizeHandle(item, (details) {
          _handleResizeUpdate(item, details, scaleSign: 1);
        }),
      ),
      // Bottom-right
      Positioned(
        bottom: -6.h,
        right: -6.w,
        child: _buildResizeHandle(item, (details) {
          _handleResizeUpdate(item, details, scaleSign: 1);
        }),
      ),
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
          _addAction(
            CanvasAction(
              type: 'modify',
              item: item.copyWith(),
              previousState: _preTransformState,
              timestamp: DateTime.now(),
            ),
          );
          _preTransformState = null;
        }
      },
      child: Container(
        width: 12.w,
        height: 12.h,
        decoration: BoxDecoration(
          color: Colors.blue[400],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  void _handleResizeUpdate(
    CanvasItem item,
    DragUpdateDetails details, {
    int scaleSign = 1,
  }) {
    setState(() {
      // Scale proportional to drag distance. Consider zoom to keep feel consistent
      final double dragMagnitude = (details.delta.dx.abs() + details.delta.dy.abs()) / 2;
      final double scaleDelta = (dragMagnitude / 100.0) * scaleSign;
      final double newScale = (item.scale + scaleDelta).clamp(0.2, 5.0);
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
              _addAction(
                CanvasAction(
                  type: 'modify',
                  item: item.copyWith(),
                  previousState: _preTransformState,
                  timestamp: DateTime.now(),
                ),
              );
              _preTransformState = null;
            }
          },
          child: Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.green[400],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.rotate_right_rounded,
              color: Colors.white,
              size: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemContent(CanvasItem item) {
    switch (item.type) {
      case CanvasItemType.text:
        final props = item.properties;
        Widget textWidget = Text(
          props['text'] ?? 'Text',
          style: TextStyle(
            fontSize: (props['fontSize'] ?? 24.0),
            color: props['hasGradient'] == true ? null : props['color'],
            fontWeight: props['fontWeight'] ?? FontWeight.normal,
            fontStyle: props['fontStyle'] ?? FontStyle.normal,
            decoration: props['decoration'] ?? TextDecoration.none,
            decorationColor: props['color'],
            letterSpacing: props['letterSpacing'] ?? 0.0,
            shadows: props['hasShadow'] == true
                ? [
                    Shadow(
                      color: props['shadowColor'] ?? Colors.grey[400]!,
                      offset: props['shadowOffset'] ?? const Offset(2, 2),
                      blurRadius: props['shadowBlur'] ?? 4.0,
                    ),
                  ]
                : null,
          ),
          textAlign: props['textAlign'] ?? TextAlign.center,
        );

        if (props['hasGradient'] == true) {
          textWidget = ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: props['gradientColors'] ?? [Colors.blue, Colors.purple],
            ).createShader(bounds),
            child: textWidget,
          );
        }

        return Container(padding: EdgeInsets.all(16.w), child: textWidget);

      case CanvasItemType.image:
        final String? filePath = item.properties['filePath'] as String?;
        final double blur = (item.properties['blur'] ?? 0.0) as double;
        final Widget content = filePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  File(filePath),
                  width: 160.w,
                  height: 160.h,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                item.properties['icon'] ?? Icons.image,
                size: 90.sp,
                color: item.properties['color'] ?? Colors.blue,
              );
        return Container(
          padding: EdgeInsets.all(8.w),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              item.properties['tint'] ?? Colors.transparent,
              BlendMode.overlay,
            ),
            child: blur > 0
                ? ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: blur,
                      sigmaY: blur,
                    ),
                    child: content,
                  )
                : content,
          ),
        );
      case CanvasItemType.sticker:
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Icon(
            item.properties['icon'] ?? Icons.emoji_emotions_rounded,
            size: 60.sp,
            color: item.properties['color'] ?? Colors.orange,
          ),
        );

      case CanvasItemType.shape:
        return Container(
          width: 120.w,
          height: 120.h,
          decoration: _buildShapeDecoration(item.properties),
        );
    }
  }

  BoxDecoration _buildShapeDecoration(Map<String, dynamic> props) {
    final shape = props['shape'] ?? 'rectangle';

    return BoxDecoration(
      color: props['hasGradient'] == true ? null : props['fillColor'],
      gradient: props['hasGradient'] == true
          ? LinearGradient(
              colors: props['gradientColors'] ?? [Colors.blue, Colors.purple],
            )
          : null,
      border: Border.all(
        color: props['strokeColor'] ?? Colors.black,
        width: props['strokeWidth'] ?? 2.0,
      ),
      borderRadius: shape == 'rectangle'
          ? BorderRadius.circular(props['cornerRadius'] ?? 12.0)
          : null,
      shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
    );
  }

  Widget _buildItemController(CanvasItem item) {
    return Positioned(
      top: -60.h,
      left: -20.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlButton(
              Icons.delete_outline_rounded,
              () => _removeItem(item),
              Colors.red[400]!,
              'Delete',
            ),
            SizedBox(width: 12.w),
            _buildControlButton(
              Icons.content_copy_rounded,
              () => _duplicateItem(item),
              Colors.green[400]!,
              'Duplicate',
            ),
            SizedBox(width: 12.w),
            _buildControlButton(
              Icons.flip_to_front_rounded,
              () => _bringToFront(item),
              Colors.orange[400]!,
              'Front',
            ),
            SizedBox(width: 12.w),
            _buildControlButton(
              Icons.flip_to_back_rounded,
              () => _sendToBack(item),
              Colors.purple[400]!,
              'Back',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onTap,
    Color color,
    String tooltip,
  ) {
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
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),
                topRight: Radius.circular(32.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle with enhanced design
                Container(
                  width: 60.w,
                  height: 6.h,
                  margin: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                // Header with item type
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          _getItemTypeIcon(selectedItem!.type),
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedItem!.type.name.toUpperCase()} PROPERTIES',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Customize your ${selectedItem!.type.name}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
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
        Text(
          'GENERAL',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 16.h),
        _buildSliderOption(
          'Opacity',
          selectedItem!.opacity,
          0.1,
          1.0,
          (value) => setState(() => selectedItem!.opacity = value),
          Icons.opacity_rounded,
        ),
        SizedBox(height: 16.h),
        _buildSliderOption(
          'Scale',
          selectedItem!.scale,
          0.3,
          3.0,
          (value) => setState(() => selectedItem!.scale = value),
          Icons.zoom_out_map_rounded,
        ),
        SizedBox(height: 16.h),
        _buildSliderOption(
          'Rotation',
          selectedItem!.rotation * 180 / 3.14159, // Convert to degrees
          -180,
          180,
          (value) =>
              setState(() => selectedItem!.rotation = value * 3.14159 / 180),
          Icons.rotate_right_rounded,
        ),
      ],
    );
  }

  Widget _buildTypeSpecificOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${selectedItem!.type.name.toUpperCase()} OPTIONS',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
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
    return Column(
      children: [
        // Text input
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Text Content',
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
            ),
            onChanged: (value) => setState(() => props['text'] = value),
            controller: TextEditingController(text: props['text']),
          ),
        ),
        SizedBox(height: 20.h),
        _buildSliderOption(
          'Font Size',
          props['fontSize'] ?? 24.0,
          10.0,
          72.0,
          (value) => setState(() => props['fontSize'] = value),
          Icons.format_size_rounded,
        ),
        SizedBox(height: 16.h),
        _buildSliderOption(
          'Letter Spacing',
          props['letterSpacing'] ?? 0.0,
          -2.0,
          5.0,
          (value) => setState(() => props['letterSpacing'] = value),
          Icons.space_bar_rounded,
        ),
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
        _buildToggleOption(
          'Gradient',
          props['hasGradient'] ?? false,
          Icons.gradient_rounded,
          (value) => setState(() => props['hasGradient'] = value),
        ),
        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),
          _buildGradientPicker(props),
        ],
      ],
    );
  }

  Widget _buildGradientPicker(Map<String, dynamic> props) {
    return Row(
      children: [
        Text(
          'Gradient Colors',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showColorPicker('gradientColor1', isGradient: true),
              child: Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color:
                      (props['gradientColors'] as List<Color>?)?.first ??
                      Colors.blue,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16.sp,
              color: Colors.grey[600],
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => _showColorPicker('gradientColor2', isGradient: true),
              child: Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color:
                      (props['gradientColors'] as List<Color>?)?.last ??
                      Colors.purple,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextEffectsOptions(Map<String, dynamic> props) {
    return Column(
      children: [
        _buildToggleOption(
          'Shadow',
          props['hasShadow'] ?? false,
          Icons.shape_line,
          (value) => setState(() => props['hasShadow'] = value),
        ),
        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),
          _buildColorOption('Shadow Color', 'shadowColor', props),
          SizedBox(height: 16.h),
          _buildSliderOption(
            'Shadow Blur',
            props['shadowBlur'] ?? 4.0,
            0.0,
            20.0,
            (value) => setState(() => props['shadowBlur'] = value),
            Icons.blur_on_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildTextStyleOptions(Map<String, dynamic> props) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            'Bold',
            props['fontWeight'] == FontWeight.bold,
            Icons.format_bold_rounded,
            () => setState(() {
              props['fontWeight'] = props['fontWeight'] == FontWeight.bold
                  ? FontWeight.normal
                  : FontWeight.bold;
            }),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildToggleButton(
            'Italic',
            props['fontStyle'] == FontStyle.italic,
            Icons.format_italic_rounded,
            () => setState(() {
              props['fontStyle'] = props['fontStyle'] == FontStyle.italic
                  ? FontStyle.normal
                  : FontStyle.italic;
            }),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildToggleButton(
            'Underline',
            props['decoration'] == TextDecoration.underline,
            Icons.format_underlined_rounded,
            () => setState(() {
              props['decoration'] =
                  props['decoration'] == TextDecoration.underline
                  ? TextDecoration.none
                  : TextDecoration.underline;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isActive,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [Colors.blue[400]!, Colors.blue[600]!])
              : null,
          color: isActive ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[200]!,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 22.sp,
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue[400],
        ),
      ],
    );
  }

  Widget _buildImageOptions() {
    final props = selectedItem!.properties;
    return Column(
      children: [
        _buildColorOption('Tint Color', 'tint', props),
        SizedBox(height: 16.h),
        _buildSliderOption(
          'Blur',
          props['blur'] ?? 0.0,
          0.0,
          10.0,
          (value) => setState(() => props['blur'] = value),
          Icons.blur_on_rounded,
        ),
        SizedBox(height: 20.h),
        _buildOptionButton(
          'Replace Image',
          Icons.photo_library_rounded,
          Colors.blue[400]!,
          () {
            _pickImage(replace: true);
          },
        ),
      ],
    );
  }

  Widget _buildStickerOptions() {
    final props = selectedItem!.properties;
    return Column(
      children: [
        _buildColorOption('Sticker Color', 'color', props),
        SizedBox(height: 20.h),
        _buildOptionButton(
          'Change Sticker',
          Icons.emoji_emotions_rounded,
          Colors.orange[400]!,
          () {
            // Show sticker picker
          },
        ),
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
        _buildSliderOption(
          'Stroke Width',
          props['strokeWidth'] ?? 2.0,
          0.0,
          10.0,
          (value) => setState(() => props['strokeWidth'] = value),
          Icons.line_weight_rounded,
        ),
        SizedBox(height: 16.h),
        _buildSliderOption(
          'Corner Radius',
          props['cornerRadius'] ?? 12.0,
          0.0,
          50.0,
          (value) => setState(() => props['cornerRadius'] = value),
          Icons.rounded_corner_rounded,
        ),
        SizedBox(height: 20.h),
        _buildToggleOption(
          'Gradient Fill',
          props['hasGradient'] ?? false,
          Icons.gradient_rounded,
          (value) => setState(() => props['hasGradient'] = value),
        ),
        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),
          _buildGradientPicker(props),
        ],
      ],
    );
  }

  Widget _buildColorOption(
    String label,
    String property,
    Map<String, dynamic> props,
  ) {
    return Row(
      children: [
        Icon(Icons.palette_rounded, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showColorPicker(property),
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: props[property] ?? Colors.blue,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 20.sp, color: color),
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: color.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderOption(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: Colors.grey[600]),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue[400],
              inactiveTrackColor: Colors.blue[100],
              thumbColor: Colors.blue[600],
              overlayColor: Colors.blue.withOpacity(0.1),
              trackHeight: 6.0,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(String property, {bool isGradient = false}) {
    final predefinedColors = [
      Colors.black,
      Colors.white,
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
      Colors.amber[400]!,
      Colors.cyan[400]!,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 280.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.r),
            topRight: Radius.circular(32.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 6.h,
              margin: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Icon(
                    Icons.palette_rounded,
                    color: Colors.blue[400],
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Choose Color',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Recent colors
            if (recentColors.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RECENT',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ),
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
                          _selectColor(property, color, isGradient: isGradient);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 50.h,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
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
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                  ),
                  itemCount: predefinedColors.length,
                  itemBuilder: (context, index) {
                    final color = predefinedColors[index];
                    return GestureDetector(
                      onTap: () {
                        _selectColor(property, color, isGradient: isGradient);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
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
      ),
    );
  }

  Future<void> _pickImage({bool replace = false}) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) return;

      if (replace &&
          selectedItem != null &&
          selectedItem!.type == CanvasItemType.image) {
        final previous = selectedItem!.copyWith();
        setState(() {
          selectedItem!.properties['filePath'] = picked.path;
        });
        _addAction(
          CanvasAction(
            type: 'modify',
            item: selectedItem,
            previousState: previous,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        _addCanvasItem(
          CanvasItemType.image,
          properties: {
            'filePath': picked.path,
            'tint': Colors.transparent,
            'blur': 0.0,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image')));
    }
  }

  void _selectColor(String property, Color color, {bool isGradient = false}) {
    setState(() {
      if (selectedItem != null) {
        if (isGradient) {
          if (property == 'gradientColor1') {
            final currentGradient =
                selectedItem!.properties['gradientColors'] as List<Color>? ??
                [Colors.blue, Colors.purple];
            selectedItem!.properties['gradientColors'] = [
              color,
              currentGradient.last,
            ];
          } else if (property == 'gradientColor2') {
            final currentGradient =
                selectedItem!.properties['gradientColors'] as List<Color>? ??
                [Colors.blue, Colors.purple];
            selectedItem!.properties['gradientColors'] = [
              currentGradient.first,
              color,
            ];
          }
        } else {
          selectedItem!.properties[property] = color;
        }

        // Add to recent colors if not already present
        if (!recentColors.contains(color)) {
          recentColors.insert(0, color);
          if (recentColors.length > 8) {
            recentColors.removeLast();
          }
        }
      }
    });
  }

  Widget _buildActionBar() {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Undo/Redo buttons
          _buildActionButton(
            Icons.undo_rounded,
            currentActionIndex >= 0,
            _undo,
            'Undo',
          ),
          SizedBox(width: 12.w),
          _buildActionButton(
            Icons.redo_rounded,
            currentActionIndex < actionHistory.length - 1,
            _redo,
            'Redo',
          ),
          SizedBox(width: 24.w),

          // Grid toggle
          _buildActionButton(
            Icons.grid_on_rounded,
            true,
            () => setState(() => snapToGrid = !snapToGrid),
            snapToGrid ? 'Grid On' : 'Grid Off',
            isActive: snapToGrid,
          ),

          const Spacer(),

          // Layer controls
          _buildActionButton(
            Icons.layers_rounded,
            canvasItems.isNotEmpty,
            () => _showLayerPanel(),
            'Layers',
          ),
          SizedBox(width: 12.w),

          // Export button
          _buildGradientButton(
            'Export',
            Icons.file_download_rounded,
            () => _exportPoster(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    bool enabled,
    VoidCallback onTap,
    String tooltip, {
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: [Colors.blue[400]!, Colors.blue[600]!])
                : null,
            color: isActive
                ? null
                : (enabled ? Colors.grey[100] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isActive
                ? Colors.white
                : (enabled ? Colors.grey[700] : Colors.grey[400]),
            size: 22.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.r),
            topRight: Radius.circular(32.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 6.h,
              margin: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    color: Colors.blue[400],
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Layers',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${canvasItems.length} items',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                itemCount: canvasItems.length,
                itemBuilder: (context, index) {
                  final item = canvasItems.reversed
                      .toList()[index]; // Show top layers first
                  final isSelected = selectedItem == item;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [Colors.blue[50]!, Colors.blue[100]!],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue[200]!
                            : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getItemTypeIcon(item.type),
                          color: isSelected
                              ? Colors.blue[400]
                              : Colors.grey[600],
                          size: 24.sp,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.type.name.toUpperCase()} Layer',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.blue[700]
                                      : Colors.grey[800],
                                ),
                              ),
                              Text(
                                'Layer ${item.layerIndex + 1}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => setState(() {
                                item.opacity = item.opacity > 0 ? 0 : 1;
                              }),
                              icon: Icon(
                                item.opacity > 0
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: Colors.grey[600],
                                size: 20.sp,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _selectItem(item);
                                Navigator.pop(context);
                              },
                              icon: Icon(
                                Icons.edit_rounded,
                                color: Colors.blue[400],
                                size: 20.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPoster() async {
    try {
      final boundary = _canvasRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      // Increase pixel ratio for sharper export
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download_done_rounded, color: Colors.white),
              SizedBox(width: 12.w),
              Text(
                'Poster exported. Sharing...',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );

      await Share.shareXFiles([XFile(file.path)], text: 'My poster');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [_buildTopToolbar(), _buildCanvas(), _buildActionBar()],
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }
}

// Custom painter for canvas grid
class CanvasGridPainter extends CustomPainter {
  final bool showGrid;
  final double gridSize;

  CanvasGridPainter({required this.showGrid, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;

    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is CanvasGridPainter &&
        (oldDelegate.showGrid != showGrid || oldDelegate.gridSize != gridSize);
  }
}
