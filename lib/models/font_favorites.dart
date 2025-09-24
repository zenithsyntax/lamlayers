import 'package:flutter/foundation.dart';

class FontFavorites extends ChangeNotifier {
  FontFavorites._internal();
  static final FontFavorites instance = FontFavorites._internal();

  final List<String> _likedFamilies = <String>[];

  List<String> get likedFamilies => List.unmodifiable(_likedFamilies);

  bool isLiked(String family) {
    return _likedFamilies.contains(family);
  }

  void add(String family) {
    if (!_likedFamilies.contains(family)) {
      _likedFamilies.add(family);
      notifyListeners();
    }
  }

  void remove(String family) {
    if (_likedFamilies.remove(family)) {
      notifyListeners();
    }
  }

  void toggle(String family) {
    if (isLiked(family)) {
      remove(family);
    } else {
      add(family);
    }
  }
}


