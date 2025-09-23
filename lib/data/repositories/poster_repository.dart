import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/layer_dto.dart';

class PosterRepository {
  static const String boxName = 'posters_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(boxName);
  }

  Future<String> savePoster(String id, List<LayerDto> layers) async {
    final box = Hive.box<String>(boxName);
    final data = jsonEncode(layers.map((e) => e.toMap()).toList());
    await box.put(id, data);
    return id;
  }

  Future<List<String>> listPosterIds() async {
    final box = Hive.box<String>(boxName);
    return box.keys.map((e) => e.toString()).toList();
  }

  Future<List<LayerDto>?> loadPoster(String id) async {
    final box = Hive.box<String>(boxName);
    final data = box.get(id);
    if (data == null) return null;
    final list = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    return list.map(LayerDto.fromMap).toList();
  }
}


