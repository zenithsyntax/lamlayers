import 'package:lamlayers/data/models/canvas_item.dart';

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


