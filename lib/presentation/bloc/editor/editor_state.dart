import 'package:equatable/equatable.dart';
import '../../../data/models/layer_data.dart';

class EditorBlocState extends Equatable {
  final List<LayerData> layers;
  final String? selectedId;
  final bool canUndo;
  final bool canRedo;

  const EditorBlocState({
    required this.layers,
    required this.selectedId,
    required this.canUndo,
    required this.canRedo,
  });

  factory EditorBlocState.initial() => const EditorBlocState(
        layers: [],
        selectedId: null,
        canUndo: false,
        canRedo: false,
      );

  EditorBlocState copyWith({
    List<LayerData>? layers,
    String? selectedId,
    bool? canUndo,
    bool? canRedo,
  }) {
    return EditorBlocState(
      layers: layers ?? this.layers,
      selectedId: selectedId ?? this.selectedId,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }

  @override
  List<Object?> get props => [layers, selectedId, canUndo, canRedo];
}


