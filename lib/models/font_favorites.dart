import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'font_favorites.g.dart';

@HiveType(typeId: 18) // Assign a unique typeId
class FontFavorites extends ChangeNotifier {
  static const String _favoritesBoxName = 'fontFavoritesBox';

  @HiveField(0)
  List<String> _likedFamilies = <String>[];

  // Public unnamed constructor for Hive
  FontFavorites() { 
    _init();
  }

  // Private named constructor for the singleton instance
  FontFavorites._internal() {
    _init();
  }

  // Initialize method to be called by both constructors
  void _init() {
    // Load liked families from Hive only if not already loaded
    if (_likedFamilies.isEmpty) {
      init();
    }
  }

  static final FontFavorites instance = FontFavorites._internal();

  List<String> get likedFamilies => List.unmodifiable(_likedFamilies);

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(18)) { // Register adapter if not already registered
      Hive.registerAdapter(FontFavoritesAdapter());
    }
    final box = await Hive.openBox<List<dynamic>>(_favoritesBoxName);
    _likedFamilies = (box.get('likedFamilies')?.cast<String>() ?? []);
    notifyListeners();
  }

  bool isLiked(String family) {
    return _likedFamilies.contains(family);
  }

  Future<void> add(String family) async {
    if (!_likedFamilies.contains(family)) {
      _likedFamilies.add(family);
      await _saveToHive();
      notifyListeners();
    }
  }

  Future<void> remove(String family) async {
    if (_likedFamilies.remove(family)) {
      await _saveToHive();
      notifyListeners();
    }
  }

  Future<void> toggle(String family) async {
    if (isLiked(family)) {
      await remove(family);
    } else {
      await add(family);
    }
  }

  Future<void> _saveToHive() async {
    final box = await Hive.openBox<List<dynamic>>(_favoritesBoxName);
    await box.put('likedFamilies', _likedFamilies);
  }
}


