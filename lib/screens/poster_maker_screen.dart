import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/canvas_models.dart';
import '../widgets/canvas_grid_painter.dart';
import '../widgets/action_bar.dart';



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

  final List<String> tabTitles = ['Text', 'Images', 'Stickers', 'Shapes'];

  // Enhanced sample data
  final List<Map<String, dynamic>> sampleTexts = [
    {'text': 'Heading', 'fontSize': 32.0, 'fontWeight': FontWeight.bold},
    {'text': 'Subtitle', 'fontSize': 24.0, 'fontWeight': FontWeight.w600},
    {'text': 'Body Text', 'fontSize': 16.0, 'fontWeight': FontWeight.normal},
    {'text': 'Caption', 'fontSize': 14.0, 'fontWeight': FontWeight.w300},
    {'text': 'Quote', 'fontSize': 20.0, 'fontWeight': FontWeight.w500},
  ];

  // Removed sample image icons; Images tab now only supports uploads

  final List<IconData> sampleStickers = const [
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

  final List<Map<String, dynamic>> sampleShapes = const [
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
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
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
    if (currentActionIndex < actionHistory.length - 1) {
      actionHistory.removeRange(currentActionIndex + 1, actionHistory.length);
    }
    actionHistory.add(action);
    currentActionIndex++;
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
      position: const Offset(140, 120),
      properties: properties ?? _getDefaultProperties(type),
      layerIndex: canvasItems.length,
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
          'color': Colors.black,
          'fontWeight': FontWeight.normal,
          'fontStyle': FontStyle.normal,
          'textAlign': TextAlign.center,
          'hasGradient': false,
          'gradientColors': [Colors.blue, Colors.purple],
          'decoration': TextDecoration.none,
          'letterSpacing': 0.0,
          'hasShadow': false,
          'shadowColor': Colors.grey,
          'shadowOffset': const Offset(2, 2),
          'shadowBlur': 4.0,
        };
      case CanvasItemType.image:
        return {
          'icon': Icons.image_outlined,
          'color': Colors.blue,
          'tint': Colors.transparent,
          'blur': 0.0,
        };
      case CanvasItemType.sticker:
        return {'icon': Icons.favorite_rounded, 'color': Colors.redAccent};
      case CanvasItemType.shape:
        return {
          'shape': 'rectangle',
          'fillColor': Colors.blue,
          'strokeColor': Colors.blueAccent,
          'strokeWidth': 2.0,
          'hasGradient': false,
          'gradientColors': [Colors.lightBlue, Colors.blueAccent],
          'cornerRadius': 12.0,
        };
    }
  }

  void _selectItem(CanvasItem item) {
    setState(() {
      selectedItem = item;
      showBottomSheet = false;
    });
    // Editing will be shown in the top toolbar instead of bottom sheet
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
                SizedBox(width: 12.w),
                Text('${selectedItem!.type.name.toUpperCase()} ', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const Spacer(),
                _buildEditModeSegmentedControl(),
                SizedBox(width: 12.w),
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
                        Icon(Icons.close_rounded, size: 16.sp, color: Colors.grey[700]),
                        SizedBox(width: 6.w),
                        Text('Done', style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], fontWeight: FontWeight.w600)),
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

  Widget _buildEditModeSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _buildSegmentButton('General', 0),
          _buildSegmentButton('Type', 1),
        ],
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
    if (editTopbarTabIndex == 0) {
      // General controls
      return [
        _miniSlider('Opacity', selectedItem!.opacity, 0.1, 1.0, (v) => setState(() => selectedItem!.opacity = v), Icons.opacity_rounded),
        _miniSlider('Scale', selectedItem!.scale, 0.3, 3.0, (v) => setState(() => selectedItem!.scale = v), Icons.zoom_out_map_rounded),
        _miniSlider('Rotate', selectedItem!.rotation * 180 / 3.14159, -180, 180, (v) => setState(() => selectedItem!.rotation = v * 3.14159 / 180), Icons.rotate_right_rounded),
        _miniIconButton('Duplicate', Icons.copy_rounded, () => _duplicateItem(selectedItem!)),
        _miniIconButton('Delete', Icons.delete_rounded, () => _removeItem(selectedItem!)),
        _miniIconButton('Front', Icons.vertical_align_top_rounded, () => _bringToFront(selectedItem!)),
        _miniIconButton('Back', Icons.vertical_align_bottom_rounded, () => _sendToBack(selectedItem!)),
      ];
    }
    // Type specific
    switch (selectedItem!.type) {
      case CanvasItemType.text:
        return [
          _miniTextField('Text', (selectedItem!.properties['text'] as String?) ?? '', (v) => setState(() => selectedItem!.properties['text'] = v)),
          _miniSlider('Font', (selectedItem!.properties['fontSize'] as double?) ?? 24.0, 10.0, 72.0, (v) => setState(() => selectedItem!.properties['fontSize'] = v), Icons.format_size_rounded),
          _miniToggleIcon('Bold', Icons.format_bold_rounded, selectedItem!.properties['fontWeight'] == FontWeight.bold, () => setState(() {
            selectedItem!.properties['fontWeight'] = (selectedItem!.properties['fontWeight'] == FontWeight.bold) ? FontWeight.normal : FontWeight.bold;
          })),
          _miniToggleIcon('Italic', Icons.format_italic_rounded, selectedItem!.properties['fontStyle'] == FontStyle.italic, () => setState(() {
            selectedItem!.properties['fontStyle'] = (selectedItem!.properties['fontStyle'] == FontStyle.italic) ? FontStyle.normal : FontStyle.italic;
          })),
          _miniToggleIcon('Underline', Icons.format_underlined_rounded, selectedItem!.properties['decoration'] == TextDecoration.underline, () => setState(() {
            selectedItem!.properties['decoration'] = (selectedItem!.properties['decoration'] == TextDecoration.underline) ? TextDecoration.none : TextDecoration.underline;
          })),
          _miniColorSwatch('Color', selectedItem!.properties['color'] as Color? ?? Colors.black, () => _showColorPicker('color')),
        ];
      case CanvasItemType.image:
        return [
          _miniColorSwatch('Tint', selectedItem!.properties['tint'] as Color? ?? Colors.transparent, () => _showColorPicker('tint')),
          _miniSlider('Blur', (selectedItem!.properties['blur'] as double?) ?? 0.0, 0.0, 10.0, (v) => setState(() => selectedItem!.properties['blur'] = v), Icons.blur_on_rounded),
          _miniIconButton('Replace', Icons.photo_library_rounded, () => _pickImage(replace: true)),
        ];
      case CanvasItemType.sticker:
        return [
          _miniColorSwatch('Color', selectedItem!.properties['color'] as Color? ?? Colors.orange, () => _showColorPicker('color')),
        ];
      case CanvasItemType.shape:
        return [
          _miniColorSwatch('Fill', selectedItem!.properties['fillColor'] as Color? ?? Colors.blue, () => _showColorPicker('fillColor')),
          _miniColorSwatch('Stroke', selectedItem!.properties['strokeColor'] as Color? ?? Colors.black, () => _showColorPicker('strokeColor')),
          _miniSlider('Stroke', (selectedItem!.properties['strokeWidth'] as double?) ?? 2.0, 0.0, 10.0, (v) => setState(() => selectedItem!.properties['strokeWidth'] = v), Icons.line_weight_rounded),
          _miniSlider('Radius', (selectedItem!.properties['cornerRadius'] as double?) ?? 12.0, 0.0, 50.0, (v) => setState(() => selectedItem!.properties['cornerRadius'] = v), Icons.rounded_corner_rounded),
        ];
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

  Widget _miniTextField(String label, String value, ValueChanged<String> onChanged) {
    return Container
      (
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              style: TextStyle(fontSize: 12.sp),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                border: InputBorder.none,
                hintText: 'Enter text',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
        ],
      ),
    );
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
        return sampleTexts.length;
      case 1:
        return 1; // Only the Upload option
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
            Icon(Icons.text_fields_rounded, size: 24.sp, color: Colors.blue.shade600),
            SizedBox(height: 6.h),
            Text(
              sampleTexts[index]['text'] as String,
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
        return Icon(sampleStickers[index], size: 32.sp, color: Colors.orange.shade600);
      case 3:
        return Icon(sampleShapes[index]['icon'] as IconData, size: 32.sp, color: Colors.green.shade600);
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
            'shadowColor': Colors.grey,
            'shadowOffset': const Offset(2, 2),
            'shadowBlur': 4.0,
          },
        );
        break;
      case 1:
        _pickImage();
        break;
      case 2:
        _addCanvasItem(
          CanvasItemType.sticker,
          properties: {'icon': sampleStickers[index], 'color': Colors.orange},
        );
        break;
      case 3:
        final shapeData = sampleShapes[index];
        _addCanvasItem(
          CanvasItemType.shape,
          properties: {
            'shape': shapeData['shape'],
            'fillColor': Colors.green,
            'strokeColor': Colors.greenAccent,
            'strokeWidth': 2.0,
            'hasGradient': false,
            'gradientColors': [Colors.lightGreen, Colors.green],
            'cornerRadius': 12.0,
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
          color: Colors.white,
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
            _addAction(CanvasAction(
              type: 'modify',
              item: item.copyWith(),
              previousState: _preDragState,
              timestamp: DateTime.now(),
            ));
            _preDragState = null;
          }
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: Transform.scale(
            scale: item.scale * (isSelected ? _selectionAnimation.value : 1.0),
            child: Stack(
                clipBehavior: Clip.none,
                children: [
                  
                  Container(
                    decoration: isSelected
                        ? BoxDecoration(
                           
                            border: Border.all(color: Colors.blue.shade400, width: 2),
                          )
                        : null,
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
        Widget textWidget = Text(
          (props['text'] ?? 'Text') as String,
          style: TextStyle(
            fontSize: (props['fontSize'] ?? 24.0) as double,
            color: (props['hasGradient'] == true) ? null : (props['color'] as Color? ?? Colors.black),
            fontWeight: (props['fontWeight'] as FontWeight?) ?? FontWeight.normal,
            fontStyle: (props['fontStyle'] as FontStyle?) ?? FontStyle.normal,
            decoration: (props['decoration'] as TextDecoration?) ?? TextDecoration.none,
            decorationColor: props['color'] as Color?,
            letterSpacing: (props['letterSpacing'] as double?) ?? 0.0,
            shadows: (props['hasShadow'] == true)
                ? [
                    Shadow(
                      color: (props['shadowColor'] as Color?) ?? Colors.grey,
                      offset: (props['shadowOffset'] as Offset?) ?? const Offset(2, 2),
                      blurRadius: (props['shadowBlur'] as double?) ?? 4.0,
                    ),
                  ]
                : null,
          ),
          textAlign: (props['textAlign'] as TextAlign?) ?? TextAlign.center,
        );
        if (props['hasGradient'] == true) {
          textWidget = ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: (props['gradientColors'] as List<Color>?) ?? [Colors.blue, Colors.purple],
            ).createShader(bounds),
            child: textWidget,
          );
        }
        return Container(padding: EdgeInsets.all(16.w), child: textWidget);
      case CanvasItemType.image:
        final String? filePath = item.properties['filePath'] as String?;
        final double blur = (item.properties['blur'] as double?) ?? 0.0;
        final double? displayW = (item.properties['displayWidth'] as double?);
        final double? displayH = (item.properties['displayHeight'] as double?);
        final Widget content = filePath != null
            ? SizedBox(
                width: (displayW ?? 160.0).w,
                height: (displayH ?? 160.0).h,
                child: Image.file(
                  File(filePath),
                  fit: BoxFit.contain,
                ),
              )
            : Icon((item.properties['icon'] as IconData?) ?? Icons.image, size: 90.sp, color: (item.properties['color'] as Color?) ?? Colors.blue);
        return Container(
          padding: EdgeInsets.all(8.w),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode((item.properties['tint'] as Color?) ?? Colors.transparent, BlendMode.overlay),
            child: blur > 0
                ? ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: content,
                  )
                : content,
          ),
        );
      case CanvasItemType.sticker:
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Icon((item.properties['icon'] as IconData?) ?? Icons.emoji_emotions_rounded, size: 60.sp, color: (item.properties['color'] as Color?) ?? Colors.orange),
        );
      case CanvasItemType.shape:
        return Container(width: 120.w, height: 120.h, decoration: _buildShapeDecoration(item.properties));
    }
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
        _buildSliderOption('Scale', selectedItem!.scale, 0.3, 3.0, (value) => setState(() => selectedItem!.scale = value), Icons.zoom_out_map_rounded),
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
          ],
        ),
      ],
    );
  }

  Widget _buildTextEffectsOptions(Map<String, dynamic> props) {
    return Column(
      children: [
        _buildToggleOption('Shadow', (props['hasShadow'] as bool?) ?? false, Icons.shape_line, (value) => setState(() => props['hasShadow'] = value)),
        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),
          _buildColorOption('Shadow Color', 'shadowColor', props),
          SizedBox(height: 16.h),
          _buildSliderOption('Shadow Blur', (props['shadowBlur'] as double?) ?? 4.0, 0.0, 20.0, (value) => setState(() => props['shadowBlur'] = value), Icons.blur_on_rounded),
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
        _buildColorOption('Tint Color', 'tint', props),
        SizedBox(height: 16.h),
        _buildSliderOption('Blur', (props['blur'] as double?) ?? 0.0, 0.0, 10.0, (value) => setState(() => props['blur'] = value), Icons.blur_on_rounded),
        SizedBox(height: 20.h),
        _buildOptionButton('Replace Image', Icons.photo_library_rounded, Colors.blue.shade400, () {
          _pickImage(replace: true);
        }),
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
        _buildSliderOption('Stroke Width', (props['strokeWidth'] as double?) ?? 2.0, 0.0, 10.0, (value) => setState(() => props['strokeWidth'] = value), Icons.line_weight_rounded),
        SizedBox(height: 16.h),
        _buildSliderOption('Corner Radius', (props['cornerRadius'] as double?) ?? 12.0, 0.0, 50.0, (value) => setState(() => props['cornerRadius'] = value), Icons.rounded_corner_rounded),
        SizedBox(height: 20.h),
        _buildToggleOption('Gradient Fill', (props['hasGradient'] as bool?) ?? false, Icons.gradient_rounded, (value) => setState(() => props['hasGradient'] = value)),
        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),
          _buildGradientPicker(props),
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
              color: (props[property] as Color?) ?? Colors.blue,
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
      ),
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

  void _selectColor(String property, Color color, {bool isGradient = false}) {
    setState(() {
      if (selectedItem != null) {
        if (isGradient) {
          final currentGradient = (selectedItem!.properties['gradientColors'] as List<Color>?) ?? [Colors.blue, Colors.purple];
          if (property == 'gradientColor1') {
            selectedItem!.properties['gradientColors'] = [color, currentGradient.last];
          } else if (property == 'gradientColor2') {
            selectedItem!.properties['gradientColors'] = [currentGradient.first, color];
          }
        } else {
          selectedItem!.properties[property] = color;
        }
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

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Column(children: [ _buildActionBar(), _buildCanvas(), _buildTopToolbar(),]),
        ),
        bottomSheet: const SizedBox.shrink(),
      );
    }
  }



