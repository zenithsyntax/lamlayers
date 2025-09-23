import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';

// Sticker Data Model
class StickerData {
  String id;
  Widget child;
  bool isText;
  Offset position;
  double scale;
  double rotation;
  String? text;
  TextStyle? textStyle;
  String? imageUrl;

  StickerData({
    required this.id,
    required this.child,
    required this.isText,
    this.position = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.text,
    this.textStyle,
    this.imageUrl,
  });

  StickerData copyWith({
    String? id,
    Widget? child,
    bool? isText,
    Offset? position,
    double? scale,
    double? rotation,
    String? text,
    TextStyle? textStyle,
    String? imageUrl,
  }) {
    return StickerData(
      id: id ?? this.id,
      child: child ?? this.child,
      isText: isText ?? this.isText,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      textStyle: textStyle ?? this.textStyle,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isText': isText,
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'rotation': rotation,
      'text': text,
      'imageUrl': imageUrl,
    };
  }
}

// History State for Undo/Redo
class EditorState {
  final List<StickerData> stickers;
  final String? selectedStickerId;

  EditorState({required this.stickers, this.selectedStickerId});

  EditorState copyWith({
    List<StickerData>? stickers,
    String? selectedStickerId,
  }) {
    return EditorState(
      stickers: stickers ?? this.stickers.map((s) => s.copyWith()).toList(),
      selectedStickerId: selectedStickerId ?? this.selectedStickerId,
    );
  }
}

class StickerEditorScreen extends StatefulWidget {
  const StickerEditorScreen({super.key});

  @override
  State<StickerEditorScreen> createState() => _StickerEditorScreenState();
}

class _StickerEditorScreenState extends State<StickerEditorScreen> {
  static const Color canvasColor = Color(0xFF000000);
  static const Color primaryColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF4DD0E1);

  List<StickerData> _stickers = [];
  String? _selectedStickerId;
  bool _showLayerManager = false;
  bool _showTextEditor = false;

  // History management
  List<EditorState> _history = [];
  int _historyIndex = -1;

  // Text editing variables
  final TextEditingController _textController = TextEditingController();
  double _fontSize = 24;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  Color _textColor = primaryColor;
  TextAlign _textAlign = TextAlign.left;
  String _fontFamily = 'Roboto';

  final List<String> _fontFamilies = ['Roboto', 'Arial', 'Times New Roman'];
  final List<Color> _colorSwatches = [
    Color(0xFFFFFFFF),
    Color(0xFFE0E0E0),
    Color(0xFF4DD0E1),
    Color(0xFFFF5722),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();
    _saveState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // History management methods
  void _saveState() {
    final newState = EditorState(
      stickers: _stickers.map((s) => s.copyWith()).toList(),
      selectedStickerId: _selectedStickerId,
    );

    // Remove future states if we're not at the end
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(newState);
    _historyIndex = _history.length - 1;

    // Limit history size
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      final state = _history[_historyIndex];
      setState(() {
        _stickers = state.stickers.map((s) => s.copyWith()).toList();
        _selectedStickerId = state.selectedStickerId;
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      final state = _history[_historyIndex];
      setState(() {
        _stickers = state.stickers.map((s) => s.copyWith()).toList();
        _selectedStickerId = state.selectedStickerId;
      });
    }
  }

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  // Sticker management methods
  void _addTextSticker() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final textStyle = TextStyle(
      fontSize: 24,
      color: primaryColor,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
    );

    final sticker = StickerData(
      id: id,
      isText: true,
      text: 'New Text',
      textStyle: textStyle,
      child: Text('New Text', style: textStyle),
      position: Offset(
        MediaQuery.of(context).size.width / 2 - 50,
        MediaQuery.of(context).size.height / 2 - 12,
      ),
    );

    setState(() {
      _stickers.add(sticker);
      _selectedStickerId = id;
    });
    _saveState();
  }

  void _addImageSticker() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final imageUrl = 'https://picsum.photos/300';

    final sticker = StickerData(
      id: id,
      isText: false,
      imageUrl: imageUrl,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.broken_image,
                color: primaryColor,
                size: 40,
              ),
            );
          },
        ),
      ),
      position: Offset(
        MediaQuery.of(context).size.width / 2 - 75,
        MediaQuery.of(context).size.height / 2 - 75,
      ),
    );

    setState(() {
      _stickers.add(sticker);
      _selectedStickerId = id;
    });
    _saveState();
  }

  void _deleteSelected() {
    if (_selectedStickerId != null) {
      setState(() {
        _stickers.removeWhere((s) => s.id == _selectedStickerId);
        _selectedStickerId = null;
      });
      _saveState();
    }
  }

  void _selectSticker(String id) {
    setState(() {
      _selectedStickerId = _selectedStickerId == id ? null : id;
    });
  }

  void _updateStickerPosition(String id, Offset position) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1) {
      setState(() {
        _stickers[index] = _stickers[index].copyWith(position: position);
      });
    }
  }

  void _updateStickerScale(String id, double scale) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1) {
      setState(() {
        _stickers[index] = _stickers[index].copyWith(scale: scale);
      });
    }
  }

  void _updateStickerRotation(String id, double rotation) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1) {
      setState(() {
        _stickers[index] = _stickers[index].copyWith(rotation: rotation);
      });
    }
  }

  // Layer management methods
  void _reorderStickers(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _stickers.removeAt(oldIndex);
      _stickers.insert(newIndex, item);
    });
    _saveState();
  }

  void _bringToFront(String id) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1) {
      setState(() {
        final sticker = _stickers.removeAt(index);
        _stickers.add(sticker);
      });
      _saveState();
    }
  }

  void _sendToBack(String id) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1) {
      setState(() {
        final sticker = _stickers.removeAt(index);
        _stickers.insert(0, sticker);
      });
      _saveState();
    }
  }

  // Text editing methods
  void _openTextEditor() {
    final sticker = _stickers.firstWhere((s) => s.id == _selectedStickerId);
    _textController.text = sticker.text ?? '';
    _fontSize = sticker.textStyle?.fontSize ?? 24;
    _isBold = sticker.textStyle?.fontWeight == FontWeight.bold;
    _isItalic = sticker.textStyle?.fontStyle == FontStyle.italic;
    _isUnderlined = sticker.textStyle?.decoration == TextDecoration.underline;
    _textColor = sticker.textStyle?.color ?? primaryColor;
    _fontFamily = sticker.textStyle?.fontFamily ?? 'Roboto';

    setState(() {
      _showTextEditor = true;
    });
  }

  void _applyTextChanges() {
    if (_selectedStickerId != null) {
      final index = _stickers.indexWhere((s) => s.id == _selectedStickerId);
      if (index != -1) {
        final newTextStyle = TextStyle(
          fontSize: _fontSize,
          color: _textColor,
          fontWeight: _isBold ? FontWeight.bold : FontWeight.w600,
          fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: _isUnderlined ? TextDecoration.underline : null,
          fontFamily: _fontFamily,
        );

        final newText = _textController.text.isNotEmpty
            ? _textController.text
            : 'New Text';

        setState(() {
          _stickers[index] = _stickers[index].copyWith(
            text: newText,
            textStyle: newTextStyle,
            child: Text(newText, style: newTextStyle, textAlign: _textAlign),
          );
          _showTextEditor = false;
        });
        _saveState();
      }
    }
  }

  void _cancelTextChanges() {
    setState(() {
      _showTextEditor = false;
    });
  }

  // Navigation to image editor
  void _editImage() async {
    if (_selectedStickerId != null) {
      final sticker = _stickers.firstWhere((s) => s.id == _selectedStickerId);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditorScreen(original: sticker),
        ),
      );

      if (result != null && result is StickerData) {
        final index = _stickers.indexWhere((s) => s.id == _selectedStickerId);
        if (index != -1) {
          setState(() {
            _stickers[index] = result;
          });
          _saveState();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        backgroundColor: canvasColor,
        foregroundColor: primaryColor,
        title: const Text(
          ' Editor',
          style: TextStyle(color: primaryColor),
        ),
        actions: [
          IconButton(
            onPressed: _canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
            color: _canUndo ? primaryColor : Colors.grey,
          ),
          IconButton(
            onPressed: _canRedo ? _redo : null,
            icon: const Icon(Icons.redo),
            color: _canRedo ? primaryColor : Colors.grey,
          ),
          IconButton(
            onPressed: () =>
                setState(() => _showLayerManager = !_showLayerManager),
            icon: const Icon(Icons.layers),
            color: primaryColor,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas Area
          Center(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(1000), // allow free pan
              minScale: 0.5,
              maxScale: 3.0,
              child: Container(
                width: 1000,
                height: 1414,
                decoration: BoxDecoration(
                  color: Colors.white, // A4 white background
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Stack(
                  children: _stickers
                      .map((sticker) => _buildStickerWidget(sticker))
                      .toList(),
                ),
              ),
            ),
          ),

          // Layer Manager Panel
          if (_showLayerManager) _buildLayerManager(),

          // Text Editor Panel
          if (_showTextEditor) _buildTextEditor(),

          // Bottom Toolbar
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  Widget _buildStickerWidget(StickerData sticker) {
    final isSelected = sticker.id == _selectedStickerId;

    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onTap: () => _selectSticker(sticker.id),
        onScaleUpdate: (details) {
          setState(() {
            // Update position (translation)
            sticker.position += details.focalPointDelta;

            // Update scale
            sticker.scale *= details.scale;

            // Update rotation
            sticker.rotation += details.rotation;
          });
        },
        onScaleEnd: (details) => _saveState(),
        child: Transform.rotate(
          angle: sticker.rotation,
          child: Transform.scale(
            scale: sticker.scale,
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: accentColor, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              padding: isSelected ? const EdgeInsets.all(4) : null,
              child: sticker.child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildToolbarButton(Icons.text_fields, 'Add Text', _addTextSticker),
            _buildToolbarButton(Icons.image, 'Add Image', _addImageSticker),
            _buildToolbarButton(
              Icons.delete,
              'Delete',
              _selectedStickerId != null ? _deleteSelected : null,
            ),
            _buildToolbarButton(
              Icons.edit,
              'Edit Text',
              _selectedStickerId != null &&
                      _stickers.any(
                        (s) => s.id == _selectedStickerId && s.isText,
                      )
                  ? _openTextEditor
                  : null,
            ),
            _buildToolbarButton(
              Icons.photo_filter,
              'Edit Image',
              _selectedStickerId != null &&
                      _stickers.any(
                        (s) => s.id == _selectedStickerId && !s.isText,
                      )
                  ? _editImage
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback? onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: onPressed != null
                    ? primaryColor.withOpacity(0.3)
                    : Colors.grey,
              ),
            ),
            child: Icon(
              icon,
              color: onPressed != null ? primaryColor : Colors.grey,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerManager() {
    return Positioned(
      right: 20,
      top: 100,
      bottom: 120,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Layers',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showLayerManager = false),
                  icon: const Icon(Icons.close, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView(
                onReorder: _reorderStickers,
                children: _stickers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sticker = entry.value;
                  return _buildLayerItem(sticker, index);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerItem(StickerData sticker, int index) {
    final isSelected = sticker.id == _selectedStickerId;

    return Container(
      key: ValueKey(sticker.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: sticker.isText
                ? const Icon(Icons.text_fields, color: primaryColor, size: 20)
                : const Icon(Icons.image, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sticker.isText ? (sticker.text ?? 'Text') : 'Image',
                  style: const TextStyle(color: primaryColor, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sticker.id,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: primaryColor),
            color: Colors.grey[800],
            onSelected: (value) {
              switch (value) {
                case 'front':
                  _bringToFront(sticker.id);
                  break;
                case 'back':
                  _sendToBack(sticker.id);
                  break;
                case 'select':
                  _selectSticker(sticker.id);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'front',
                child: Text(
                  'Bring to Front',
                  style: TextStyle(color: primaryColor),
                ),
              ),
              const PopupMenuItem(
                value: 'back',
                child: Text(
                  'Send to Back',
                  style: TextStyle(color: primaryColor),
                ),
              ),
              const PopupMenuItem(
                value: 'select',
                child: Text('Select', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
          // Drag handle
          const Icon(Icons.drag_handle, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTextEditor() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 100,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Edit Text',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _cancelTextChanges,
                  icon: const Icon(Icons.close, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text input
            TextField(
              controller: _textController,
              style: const TextStyle(color: primaryColor),
              decoration: InputDecoration(
                hintText: 'Enter text...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Font size slider
            Row(
              children: [
                const Text('Size:', style: TextStyle(color: primaryColor)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 8,
                    max: 120,
                    divisions: 112,
                    activeColor: accentColor,
                    inactiveColor: Colors.grey,
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                ),
                Text(
                  '${_fontSize.round()}',
                  style: const TextStyle(color: primaryColor),
                ),
              ],
            ),

            // Style toggles
            Row(
              children: [
                _buildToggleButton(
                  Icons.format_bold,
                  _isBold,
                  (value) => setState(() => _isBold = value),
                ),
                _buildToggleButton(
                  Icons.format_italic,
                  _isItalic,
                  (value) => setState(() => _isItalic = value),
                ),
                _buildToggleButton(
                  Icons.format_underlined,
                  _isUnderlined,
                  (value) => setState(() => _isUnderlined = value),
                ),
                const SizedBox(width: 16),
                _buildAlignmentButton(Icons.format_align_left, TextAlign.left),
                _buildAlignmentButton(
                  Icons.format_align_center,
                  TextAlign.center,
                ),
                _buildAlignmentButton(
                  Icons.format_align_right,
                  TextAlign.right,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Font family dropdown
            Row(
              children: [
                const Text('Font:', style: TextStyle(color: primaryColor)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _fontFamily,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: primaryColor),
                    onChanged: (value) => setState(() => _fontFamily = value!),
                    items: _fontFamilies.map((font) {
                      return DropdownMenuItem(
                        value: font,
                        child: Text(font, style: TextStyle(fontFamily: font)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Color swatches
            const Text('Color:', style: TextStyle(color: primaryColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colorSwatches
                  .map((color) => _buildColorSwatch(color))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelTextChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyTextChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    IconData icon,
    bool isActive,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChanged(!isActive),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? accentColor.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? accentColor : primaryColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? accentColor : primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlignmentButton(IconData icon, TextAlign alignment) {
    final isActive = _textAlign == alignment;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _textAlign = alignment),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? accentColor.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? accentColor : primaryColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? accentColor : primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(Color color) {
    final isSelected = _textColor == color;
    return GestureDetector(
      onTap: () => setState(() => _textColor = color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? accentColor : primaryColor.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.black, size: 16)
            : null,
      ),
    );
  }
}

// Image Editor Screen
class ImageEditorScreen extends StatefulWidget {
  final StickerData original;

  const ImageEditorScreen({super.key, required this.original});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  static const Color canvasColor = Color(0xFF000000);
  static const Color primaryColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF4DD0E1);

  late StickerData _editedSticker;

  // Filter values
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _hue = 0.0;
  double _blur = 0.0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _editedSticker = widget.original.copyWith();
  }

  void _applyChanges() {
    Navigator.pop(context, _editedSticker);
  }

  void _resetFilters() {
    setState(() {
      _brightness = 0.0;
      _contrast = 0.0;
      _saturation = 0.0;
      _hue = 0.0;
      _blur = 0.0;
      _opacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        backgroundColor: canvasColor,
        foregroundColor: primaryColor,
        title: const Text(
          'Image Editor',
          style: TextStyle(color: primaryColor),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset', style: TextStyle(color: accentColor)),
          ),
          TextButton(
            onPressed: _applyChanges,
            child: const Text('Apply', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview Area
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Center(
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(_getColorMatrix()),
                  child: Opacity(
                    opacity: _opacity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.original.imageUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.broken_image,
                              color: primaryColor,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls Area
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSliderControl('Brightness', _brightness, -1.0, 1.0, (
                      value,
                    ) {
                      setState(() => _brightness = value);
                    }),
                    _buildSliderControl('Contrast', _contrast, -1.0, 1.0, (
                      value,
                    ) {
                      setState(() => _contrast = value);
                    }),
                    _buildSliderControl('Saturation', _saturation, -1.0, 1.0, (
                      value,
                    ) {
                      setState(() => _saturation = value);
                    }),
                    _buildSliderControl('Hue', _hue, -180.0, 180.0, (value) {
                      setState(() => _hue = value);
                    }),
                    _buildSliderControl('Blur', _blur, 0.0, 10.0, (value) {
                      setState(() => _blur = value);
                    }),
                    _buildSliderControl('Opacity', _opacity, 0.0, 1.0, (value) {
                      setState(() => _opacity = value);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  List<double> _getColorMatrix() {
    // Base identity matrix
    List<double> matrix = [
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];

    // Apply brightness
    for (int i = 0; i < 3; i++) {
      matrix[i * 5 + 4] = _brightness * 255;
    }

    // Apply contrast
    double contrast = _contrast + 1;
    for (int i = 0; i < 3; i++) {
      matrix[i * 5 + i] = contrast;
      matrix[i * 5 + 4] += (1 - contrast) * 128;
    }

    // Apply saturation
    double saturation = _saturation + 1;
    double lumR = 0.299;
    double lumG = 0.587;
    double lumB = 0.114;

    matrix[0] = lumR * (1 - saturation) + saturation;
    matrix[1] = lumG * (1 - saturation);
    matrix[2] = lumB * (1 - saturation);
    matrix[5] = lumR * (1 - saturation);
    matrix[6] = lumG * (1 - saturation) + saturation;
    matrix[7] = lumB * (1 - saturation);
    matrix[10] = lumR * (1 - saturation);
    matrix[11] = lumG * (1 - saturation);
    matrix[12] = lumB * (1 - saturation) + saturation;

    return matrix;
  }
}

// Main App
void main() {
  runApp(const StickerEditorApp());
}

class StickerEditorApp extends StatelessWidget {
  const StickerEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticker Editor',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Color(0xFFFFFFFF),
        ),
      ),
      home: const StickerEditorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
