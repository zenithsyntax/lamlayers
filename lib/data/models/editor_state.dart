import 'layer_data.dart';

class EditorState {
  final List<LayerData> layers;
  final String? selectedLayerId;

  EditorState({required this.layers, this.selectedLayerId});

  EditorState copyWith({
    List<LayerData>? layers,
    String? selectedLayerId,
  }) {
    return EditorState(
      layers: layers ?? this.layers.map((l) => l.copyWith()).toList(),
      selectedLayerId: selectedLayerId ?? this.selectedLayerId,
    );
  }
}