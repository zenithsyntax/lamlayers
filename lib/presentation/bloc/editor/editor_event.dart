import 'package:equatable/equatable.dart';
import '../../../data/models/layer_data.dart';
import 'package:flutter/material.dart';

abstract class EditorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPosterEvent extends EditorEvent {
  final String? posterId;
  LoadPosterEvent({this.posterId});
}

class AddLayerEvent extends EditorEvent {
  final LayerData layer;
  AddLayerEvent(this.layer);
  @override
  List<Object?> get props => [layer];
}

class UpdateLayerTransformEvent extends EditorEvent {
  final String id;
  final Offset? position;
  final double? scale;
  final double? rotation;
  UpdateLayerTransformEvent({required this.id, this.position, this.scale, this.rotation});
  @override
  List<Object?> get props => [id, position, scale, rotation];
}

class SelectLayerEvent extends EditorEvent {
  final String? id;
  SelectLayerEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteSelectedEvent extends EditorEvent {}

class UndoEvent extends EditorEvent {}
class RedoEvent extends EditorEvent {}

class SavePosterEvent extends EditorEvent {
  final String id;
  SavePosterEvent(this.id);
}

class UpdateLayerContentEvent extends EditorEvent {
  final String id;
  final LayerData updated;
  UpdateLayerContentEvent({required this.id, required this.updated});
  @override
  List<Object?> get props => [id, updated];
}


