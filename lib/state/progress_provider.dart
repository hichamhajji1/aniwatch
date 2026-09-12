import 'package:flutter/foundation.dart';

import '../data/models/anime.dart';
import '../data/models/watch_progress.dart';
import '../data/services/storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._storage);

  final StorageService _storage;
  final Map<int, WatchProgress> _byId = {};

  List<WatchProgress> get continueWatching {
    final items = _byId.values.where((item) => item.watchedCount > 0 && !item.isComplete).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  List<WatchProgress> get completed {
    final items = _byId.values.where((item) => item.isComplete).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  void load() {
    _byId
      ..clear()
      ..addEntries(
        _storage.loadProgress().map((item) => MapEntry(item.animeId, item)),
      );
    notifyListeners();
  }

  WatchProgress? progressFor(int animeId) => _byId[animeId];

  bool isEpisodeDone(int animeId, int episodeMalId) {
    return _byId[animeId]?.completedEpisodes.contains(episodeMalId) ?? false;
  }

  Future<void> toggleEpisode(Anime anime, int episodeMalId) async {
    final current = _byId[anime.malId];
    final completed = {...?current?.completedEpisodes};
    if (!completed.add(episodeMalId)) {
      completed.remove(episodeMalId);
    }
    _byId[anime.malId] = WatchProgress(
      animeId: anime.malId,
      animeTitle: anime.displayTitle,
      imageUrl: anime.poster,
      totalEpisodes: anime.episodes ?? current?.totalEpisodes,
      completedEpisodes: completed,
      updatedAt: DateTime.now(),
    );
    await _storage.saveProgress(_byId.values.toList());
    notifyListeners();
  }

  Future<void> clearAll() async {
    _byId.clear();
    await _storage.clearProgress();
    notifyListeners();
  }
}
