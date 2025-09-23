import 'package:bloc/bloc.dart';
import '../../../data/models/layer_data.dart';
import '../../../data/models/layer_dto.dart';
import '../../../data/repositories/poster_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/layer_kind.dart';
import 'editor_event.dart';
import 'editor_state.dart';
import 'package:flutter/material.dart';

class EditorBloc extends Bloc<EditorEvent, EditorBlocState> {
  final PosterRepository repository;

  final List<List<LayerData>> _history = [];
  int _historyIndex = -1;

  EditorBloc(this.repository) : super(EditorBlocState.initial()) {
    on<LoadPosterEvent>(_onLoad);
    on<AddLayerEvent>(_onAddLayer);
    on<UpdateLayerTransformEvent>(_onUpdateTransform);
    on<UpdateLayerContentEvent>(_onUpdateContent);
    on<SelectLayerEvent>(_onSelect);
    on<DeleteSelectedEvent>(_onDelete);
    on<UndoEvent>(_onUndo);
    on<RedoEvent>(_onRedo);
    on<SavePosterEvent>(_onSave);
  }

  void _snapshot(List<LayerData> layers) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(layers.map((e) => e.copyWith()).toList());
    _historyIndex = _history.length - 1;
  }

  Future<void> _onLoad(LoadPosterEvent event, Emitter<EditorBlocState> emit) async {
    if (event.posterId == null) {
      _snapshot(const []);
      emit(state.copyWith(layers: const [], selectedId: null, canUndo: false, canRedo: false));
      return;
    }
    final list = await repository.loadPoster(event.posterId!);
    final layers = list?.map((e) => e.toModel()).toList() ?? [];
    _snapshot(layers);
    emit(state.copyWith(layers: layers, selectedId: null, canUndo: false, canRedo: false));
  }

  void _onAddLayer(AddLayerEvent event, Emitter<EditorBlocState> emit) {
    final updated = [...state.layers, event.layer];
    _snapshot(updated);
    emit(state.copyWith(layers: updated, selectedId: event.layer.id, canUndo: _historyIndex > 0, canRedo: false));
  }

  void _onUpdateTransform(UpdateLayerTransformEvent event, Emitter<EditorBlocState> emit) {
    final index = state.layers.indexWhere((l) => l.id == event.id);
    if (index == -1) return;
    final updated = [...state.layers];
    final layer = updated[index];
    updated[index] = layer.copyWith(
      position: event.position ?? layer.position,
      scale: event.scale ?? layer.scale,
      rotation: event.rotation ?? layer.rotation,
    );
    // Do not snapshot during gesture updates; only emit for live feedback
    emit(state.copyWith(layers: updated));
  }

  void _onUpdateContent(UpdateLayerContentEvent event, Emitter<EditorBlocState> emit) {
    final index = state.layers.indexWhere((l) => l.id == event.id);
    if (index == -1) return;
    final updated = [...state.layers];
    updated[index] = event.updated;
    _snapshot(updated);
    emit(state.copyWith(layers: updated, canUndo: _historyIndex > 0, canRedo: false));
  }

  void _onSelect(SelectLayerEvent event, Emitter<EditorBlocState> emit) {
    emit(state.copyWith(selectedId: event.id));
  }

  void _onDelete(DeleteSelectedEvent event, Emitter<EditorBlocState> emit) {
    if (state.selectedId == null) return;
    final updated = state.layers.where((l) => l.id != state.selectedId).toList();
    _snapshot(updated);
    emit(state.copyWith(layers: updated, selectedId: null, canUndo: _historyIndex > 0, canRedo: false));
  }

  void _onUndo(UndoEvent event, Emitter<EditorBlocState> emit) {
    if (_historyIndex <= 0) return;
    _historyIndex--;
    final layers = _history[_historyIndex].map((e) => e.copyWith()).toList();
    emit(state.copyWith(layers: layers, canUndo: _historyIndex > 0, canRedo: _historyIndex < _history.length - 1));
  }

  void _onRedo(RedoEvent event, Emitter<EditorBlocState> emit) {
    if (_historyIndex >= _history.length - 1) return;
    _historyIndex++;
    final layers = _history[_historyIndex].map((e) => e.copyWith()).toList();
    emit(state.copyWith(layers: layers, canUndo: _historyIndex > 0, canRedo: _historyIndex < _history.length - 1));
  }

  Future<void> _onSave(SavePosterEvent event, Emitter<EditorBlocState> emit) async {
    final dtos = state.layers.map(LayerDto.fromModel).toList();
    await repository.savePoster(event.id, dtos);
  }

  // Helpers to generate new layers
  static LayerData createTextLayer({required BuildContext context}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final style = const TextStyle(fontSize: 24, color: AppColors.primaryColor, fontWeight: FontWeight.w600, fontFamily: 'Roboto');
    return LayerData(
      id: id,
      child: const Text('New Text', style: TextStyle(fontSize: 24, color: AppColors.primaryColor, fontWeight: FontWeight.w600, fontFamily: 'Roboto')),
      position: const Offset(100, 100),
      scale: 1,
      rotation: 0,
      kind: LayerKind.text,
      text: 'New Text',
      textStyle: style,
      fontFamily: 'Roboto',
      textAlign: TextAlign.left,
    );
  }
}


