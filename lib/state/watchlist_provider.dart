import 'package:flutter/foundation.dart';

import '../data/models/anime.dart';
import '../data/services/storage_service.dart';

class WatchlistProvider extends ChangeNotifier {
  WatchlistProvider(this._storage);

  final StorageService _storage;
  final List<Anime> _bookmarks = [];
  final List<Anime> _watched = [];

  List<Anime> get bookmarks => List.unmodifiable(_bookmarks);
  List<Anime> get watchedHistory => List.unmodifiable(_watched);

  void load() {
    _bookmarks
      ..clear()
      ..addAll(_storage.loadWatchlist());
    _watched
      ..clear()
      ..addAll(_storage.loadWatchedHistory());
    notifyListeners();
  }

  bool isBookmarked(int malId) => _bookmarks.any((item) => item.malId == malId);

  bool isWatched(int malId) => _watched.any((item) => item.malId == malId);

  Future<void> toggleBookmark(Anime anime) async {
    final index = _bookmarks.indexWhere((item) => item.malId == anime.malId);
    if (index >= 0) {
      _bookmarks.removeAt(index);
    } else {
      _bookmarks.insert(0, anime);
    }
    await _storage.saveWatchlist(_bookmarks, watched: _watched);
    notifyListeners();
  }

  Future<void> markWatched(Anime anime) async {
    _watched.removeWhere((item) => item.malId == anime.malId);
    _watched.insert(0, anime);
    await _storage.saveWatchedHistory(_watched, bookmarks: _bookmarks);
    notifyListeners();
  }

  Future<void> removeWatched(int malId) async {
    _watched.removeWhere((item) => item.malId == malId);
    await _storage.saveWatchedHistory(_watched, bookmarks: _bookmarks);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _bookmarks.clear();
    _watched.clear();
    await _storage.clearWatchlist();
    notifyListeners();
  }
}
