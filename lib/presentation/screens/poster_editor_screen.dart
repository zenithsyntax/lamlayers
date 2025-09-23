import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/layer_data.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/layer_widget.dart';
import '../widgets/bottom_toolbar.dart';
import '../widgets/layer_manager.dart';
import '../widgets/text_editor.dart';
import 'image_editor_screen.dart';
import '../bloc/editor/editor_bloc.dart';
import '../bloc/editor/editor_event.dart';
import '../bloc/editor/editor_state.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/layer_kind.dart';
import '../../data/repositories/poster_repository.dart';

class PosterEditorScreen extends StatefulWidget {
  final String? posterId;
  const PosterEditorScreen({super.key, this.posterId});

  @override
  State<PosterEditorScreen> createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  String? _selectedLayerId;
  bool _showLayerManager = false;
  bool _showTextEditor = false;
  List<String> _savedIds = [];

  // A4 dimensions in pixels (at 300 DPI)
  static const double _a4Width = 595.0;  // A4 width in points (8.27 inches * 72 points/inch ≈ 595)
  static const double _a4Height = 842.0; // A4 height in points (11.69 inches * 72 points/inch ≈ 842)

  // Text editing variables
  final TextEditingController _textController = TextEditingController();
  double _fontSize = 24;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  Color _textColor = AppColors.primaryColor;
  TextAlign _textAlign = TextAlign.left;
  String _fontFamily = 'Roboto';

  @override
  void initState() {
    super.initState();
    // Ensure an EditorBloc is available for this screen
    if (context.read<EditorBloc?>() == null) {
      // No-op, but typically we'd wrap this page with a BlocProvider.
    }
    // Load poster if passed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<EditorBloc?>() != null) {
        context.read<EditorBloc>().add(LoadPosterEvent(posterId: widget.posterId));
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Layer management methods
  void _addTextLayer() {
    final layer = EditorBloc.createTextLayer(context: context);
    context.read<EditorBloc>().add(AddLayerEvent(layer));
    setState(() => _selectedLayerId = layer.id);
  }

  void _addImageLayer() {
    _pickAndEditImage();
  }

  void _addShapeLayer() {
    _showShapePicker();
  }

  void _deleteSelected() {
    if (_selectedLayerId == null) return;
    context.read<EditorBloc>().add(DeleteSelectedEvent());
    setState(() => _selectedLayerId = null);
  }

  void _selectLayer(String id) {
    final sel = _selectedLayerId == id ? null : id;
    context.read<EditorBloc>().add(SelectLayerEvent(sel));
    setState(() => _selectedLayerId = sel);
  }

  void _updateLayerPosition(String id, Offset position) {
    context.read<EditorBloc>().add(UpdateLayerTransformEvent(id: id, position: position));
  }

  void _updateLayerScale(String id, double scale) {
    context.read<EditorBloc>().add(UpdateLayerTransformEvent(id: id, scale: scale));
  }

  void _updateLayerRotation(String id, double rotation) {
    context.read<EditorBloc>().add(UpdateLayerTransformEvent(id: id, rotation: rotation));
  }

  void _openTextEditor() {
    final layers = context.read<EditorBloc>().state.layers;
    final layer = layers.firstWhere((l) => l.id == _selectedLayerId);
    _textController.text = layer.text ?? '';
    _fontSize = layer.textStyle?.fontSize ?? 24;
    _isBold = layer.textStyle?.fontWeight == FontWeight.bold;
    _isItalic = layer.textStyle?.fontStyle == FontStyle.italic;
    _isUnderlined = layer.textStyle?.decoration == TextDecoration.underline;
    _textColor = layer.textStyle?.color ?? AppColors.primaryColor;
    _fontFamily = layer.textStyle?.fontFamily ?? 'Roboto';

    setState(() {
      _showTextEditor = true;
    });
  }

  void _editImage() async {
    if (_selectedLayerId == null) return;
    final layer = context.read<EditorBloc>().state.layers.firstWhere((l) => l.id == _selectedLayerId);
    if (layer.imagePath == null) return;
    final file = File(layer.imagePath!);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    final editedBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(bytes: bytes),
      ),
    );
    if (editedBytes != null && editedBytes is Uint8List) {
      final savedPath = await _saveTempImage(editedBytes);
      final updated = layer.copyWith(
        kind: LayerKind.image,
        imagePath: savedPath,
        child: Image.file(File(savedPath), width: 150, height: 150, fit: BoxFit.cover),
      );
      context.read<EditorBloc>().add(UpdateLayerContentEvent(id: updated.id, updated: updated));
    }
  }

  Future<void> _pickAndEditImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final editedBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(bytes: bytes),
      ),
    );
    if (editedBytes != null && editedBytes is Uint8List) {
      final path = await _saveTempImage(editedBytes);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final layer = LayerData(
        id: id,
        child: Image.file(File(path), width: 150, height: 150, fit: BoxFit.cover),
        position: Offset(
          _a4Width / 2 - 75,
          _a4Height / 2 - 75,
        ),
        scale: 1,
        rotation: 0,
        kind: LayerKind.image,
        imagePath: path,
      );
      context.read<EditorBloc>().add(AddLayerEvent(layer));
      setState(() => _selectedLayerId = id);
    }
  }

  Future<String> _saveTempImage(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _savePoster() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    context.read<EditorBloc>().add(SavePosterEvent(id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poster saved')));
  }

  Future<void> _openLoadPicker() async {
    final repo = RepositoryProvider.of<PosterRepository>(context);
    final ids = await repo.listPosterIds();
    setState(() => _savedIds = ids);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: ListView.builder(
          itemCount: _savedIds.length,
          itemBuilder: (context, index) {
            final pid = _savedIds[index];
            return ListTile(
              title: Text('Poster $pid', style: const TextStyle(color: AppColors.primaryColor)),
              onTap: () {
                Navigator.pop(context);
                context.read<EditorBloc>().add(LoadPosterEvent(posterId: pid));
                setState(() {
                  _selectedLayerId = null;
                });
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasColor,
      appBar: AppBar(
        backgroundColor: AppColors.canvasColor,
        foregroundColor: AppColors.primaryColor,
        title: const Text(
          'Layers Poster Maker',
          style: TextStyle(color: AppColors.primaryColor),
        ),
        actions: [
          IconButton(
            onPressed: context.select((EditorBloc b) => b.state.canUndo)
                ? () => context.read<EditorBloc>().add(UndoEvent())
                : null,
            icon: const Icon(Icons.undo),
            color: context.select((EditorBloc b) => b.state.canUndo) ? AppColors.primaryColor : Colors.grey,
          ),
          IconButton(
            onPressed: context.select((EditorBloc b) => b.state.canRedo)
                ? () => context.read<EditorBloc>().add(RedoEvent())
                : null,
            icon: const Icon(Icons.redo),
            color: context.select((EditorBloc b) => b.state.canRedo) ? AppColors.primaryColor : Colors.grey,
          ),
          IconButton(
            onPressed: () =>
                setState(() => _showLayerManager = !_showLayerManager),
            icon: const Icon(Icons.layers),
            color: AppColors.primaryColor,
          ),
          IconButton(
            onPressed: _savePoster,
            icon: const Icon(Icons.save),
            color: AppColors.primaryColor,
          ),
          IconButton(
            onPressed: _openLoadPicker,
            icon: const Icon(Icons.folder_open),
            color: AppColors.primaryColor,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fixed A4 Canvas Area
          Padding(
            padding: const EdgeInsets.all(35.0),
            child: Center(
              child: Container(
                width: _a4Width,
                height: _a4Height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: BlocBuilder<EditorBloc, EditorBlocState>(
                    builder: (context, state) {
                      return Stack(
                        children: state.layers
                            .map((layer) => LayerWidget(
                                  layer: layer,
                                  isSelected: layer.id == _selectedLayerId,
                                  onTap: () => _selectLayer(layer.id),
                                  onPositionUpdate: (position) {
                                    // Constrain position within A4 canvas bounds
                                    final constrainedPosition = Offset(
                                      position.dx.clamp(0, _a4Width - 50), // Assuming minimum layer width of 50
                                      position.dy.clamp(0, _a4Height - 50), // Assuming minimum layer height of 50
                                    );
                                    _updateLayerPosition(layer.id, constrainedPosition);
                                  },
                                  onScaleUpdate: (scale) =>
                                      _updateLayerScale(layer.id, scale),
                                  onRotationUpdate: (rotation) =>
                                      _updateLayerRotation(layer.id, rotation),
                                  onTransformEnd: () {
                                    // Take snapshot once per gesture end
                                    final current = context.read<EditorBloc>().state.layers.firstWhere((l) => l.id == layer.id);
                                    context.read<EditorBloc>().add(UpdateLayerContentEvent(id: layer.id, updated: current));
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Layer Manager Panel
          if (_showLayerManager)
            BlocBuilder<EditorBloc, EditorBlocState>(
              builder: (context, state) {
                return LayerManager(
                  layers: state.layers,
                  selectedLayerId: _selectedLayerId,
                  onClose: () => setState(() => _showLayerManager = false),
                  onLayerSelect: _selectLayer,
                  onLayerReorder: (oldIndex, newIndex) {
                    final layers = [...state.layers];
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = layers.removeAt(oldIndex);
                    layers.insert(newIndex, item);
                    for (final l in layers) {
                      context.read<EditorBloc>().add(UpdateLayerContentEvent(id: l.id, updated: l));
                    }
                  },
                  onBringToFront: (id) {
                    final layers = [...state.layers];
                    final index = layers.indexWhere((l) => l.id == id);
                    if (index != -1) {
                      final layer = layers.removeAt(index);
                      layers.add(layer);
                      for (final l in layers) {
                        context.read<EditorBloc>().add(UpdateLayerContentEvent(id: l.id, updated: l));
                      }
                    }
                  },
                  onSendToBack: (id) {
                    final layers = [...state.layers];
                    final index = layers.indexWhere((l) => l.id == id);
                    if (index != -1) {
                      final layer = layers.removeAt(index);
                      layers.insert(0, layer);
                      for (final l in layers) {
                        context.read<EditorBloc>().add(UpdateLayerContentEvent(id: l.id, updated: l));
                      }
                    }
                  },
                );
              },
            ),

          // Text Editor Panel
          if (_showTextEditor)
            TextEditor(
              textController: _textController,
              fontSize: _fontSize,
              isBold: _isBold,
              isItalic: _isItalic,
              isUnderlined: _isUnderlined,
              textColor: _textColor,
              textAlign: _textAlign,
              fontFamily: _fontFamily,
              onClose: () => setState(() => _showTextEditor = false),
              onFontSizeChanged: (size) => setState(() => _fontSize = size),
              onBoldChanged: (bold) => setState(() => _isBold = bold),
              onItalicChanged: (italic) => setState(() => _isItalic = italic),
              onUnderlineChanged: (underline) =>
                  setState(() => _isUnderlined = underline),
              onColorChanged: (color) => setState(() => _textColor = color),
              onAlignChanged: (align) => setState(() => _textAlign = align),
              onFontFamilyChanged: (font) => setState(() => _fontFamily = font),
              onApply: () {
                if (_selectedLayerId == null) return;
                final state = context.read<EditorBloc>().state;
                final index = state.layers.indexWhere((l) => l.id == _selectedLayerId);
                if (index == -1) return;
                final newText = _textController.text.isNotEmpty ? _textController.text : 'New Text';
                final newTextStyle = TextStyle(
                  fontSize: _fontSize,
                  color: _textColor,
                  fontWeight: _isBold ? FontWeight.bold : FontWeight.w600,
                  fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: _isUnderlined ? TextDecoration.underline : null,
                  fontFamily: _fontFamily,
                );
                final updated = state.layers[index].copyWith(
                  text: newText,
                  textStyle: newTextStyle,
                  fontFamily: _fontFamily,
                  textAlign: _textAlign,
                  child: Text(newText, style: newTextStyle, textAlign: _textAlign),
                );
                context.read<EditorBloc>().add(UpdateLayerContentEvent(id: updated.id, updated: updated));
                setState(() => _showTextEditor = false);
              },
            ),

          // Bottom Toolbar
          BlocBuilder<EditorBloc, EditorBlocState>(
            builder: (context, state) {
              return BottomToolbar(
                onAddText: _addTextLayer,
                onAddImage: _addImageLayer,
                onAddShape: _addShapeLayer,
                onDelete: _selectedLayerId != null ? _deleteSelected : null,
                onEditText: _selectedLayerId != null &&
                        state.layers.any((l) => l.id == _selectedLayerId && l.isText)
                    ? _openTextEditor
                    : null,
                onEditImage: _selectedLayerId != null &&
                        state.layers.any((l) => l.id == _selectedLayerId && l.isImage)
                    ? _editImage
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showShapePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shapeButton('Rectangle', Icons.rectangle, () => _createShape('rectangle')),
                _shapeButton('Circle', Icons.circle, () => _createShape('circle')),
                _shapeButton('Line', Icons.horizontal_rule, () => _createShape('line')),
                _shapeButton('Triangle', Icons.change_history, () => _createShape('triangle')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shapeButton(String label, IconData icon, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: () { Navigator.pop(context); onTap(); }, icon: Icon(icon, color: AppColors.primaryColor)),
        Text(label, style: const TextStyle(color: AppColors.primaryColor))
      ],
    );
  }

  void _createShape(String kind) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    Widget child;
    switch (kind) {
      case 'rectangle':
        child = Container(width: 120, height: 80, color: Colors.blueAccent);
        break;
      case 'circle':
        child = Container(width: 100, height: 100, decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle));
        break;
      case 'line':
        child = Container(width: 140, height: 4, color: Colors.white);
        break;
      case 'triangle':
        child = CustomPaint(size: const Size(100, 100), painter: _TrianglePainterLocal(Colors.amber));
        break;
      default:
        child = const SizedBox.shrink();
    }
    final layer = LayerData(
      id: id,
      child: child,
      position: Offset(_a4Width / 2 - 50, _a4Height / 2 - 50), // Center on A4 canvas
      scale: 1,
      rotation: 0,
      kind: LayerKind.shape,
    );
    context.read<EditorBloc>().add(AddLayerEvent(layer));
    setState(() => _selectedLayerId = id);
  }
}

class _TrianglePainterLocal extends CustomPainter {
  final Color color;
  _TrianglePainterLocal(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}