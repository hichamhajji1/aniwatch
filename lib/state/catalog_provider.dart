import 'package:flutter/foundation.dart';

import '../data/models/anime.dart';
import '../data/models/character.dart';
import '../data/models/streaming_link.dart';
import '../data/seed/popular_seed.dart';
import '../data/seed/seed_extras.dart';
import '../data/services/jikan_api_service.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api);

  final JikanApiService _api;

  List<Anime> topAnime = PopularSeed.titles.take(12).toList();
  List<Anime> seasonalAnime = PopularSeed.titles.skip(12).take(12).toList();
  List<Anime> popularAnime = PopularSeed.titles.take(16).toList();
  List<Anime> upcomingAnime = PopularSeed.titles.skip(20).take(12).toList();
  List<Anime> topMovies = PopularSeed.byType('Movie');
  List<Anime> searchResults = const [];
  Anime? details;
  List<AnimeCharacter> characters = const [];
  List<StreamingLink> streaming = const [];

  bool loadingHome = false;
  bool searching = false;
  bool loadingDetails = false;
  bool loadingCharacters = false;
  bool loadingStreaming = false;
  bool isOffline = false;
  String? homeError;
  String? searchError;
  String? detailsError;
  String? charactersError;
  String? streamingError;
  String lastQuery = '';
  String? lastTypeFilter;
  bool searchUsedFallback = false;
  int _searchToken = 0;
  int _detailsToken = 0;
  int? focusedMalId;
  final Map<int, Anime> _detailCache = {};
  final Map<int, List<AnimeCharacter>> _characterCache = {};
  final Map<int, List<StreamingLink>> _streamingCache = {};

  Anime? get hero {
    if (topAnime.isEmpty) return null;
    final ranked = [...topAnime]..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    return ranked.first;
  }

  bool isFocused(int malId) => focusedMalId == malId;

  List<Anime> get catalog {
    return _unique([
      ...searchResults,
      ...topAnime,
      ...seasonalAnime,
      ...popularAnime,
      ...upcomingAnime,
      ...topMovies,
      ...PopularSeed.titles,
    ]);
  }

  List<Anime> get tvSeries => _byType('TV');
  List<Anime> get movies => topMovies.isNotEmpty ? topMovies : _byType('Movie');
  List<Anime> get ovas => _byType('OVA');
  List<Anime> get onas => _byType('ONA');
  List<Anime> get specials => _byType('Special');

  List<Anime> get highestRated {
    final items = [...catalog]..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    return items.take(18).toList();
  }

  List<Anime> withGenre(String name) {
    final needle = name.toLowerCase();
    return catalog
        .where((anime) => anime.genres.any((genre) => genre.toLowerCase() == needle))
        .take(18)
        .toList();
  }

  List<Anime> _byType(String type) {
    final needle = type.toLowerCase();
    return catalog.where((anime) => (anime.type ?? '').toLowerCase() == needle).take(18).toList();
  }

  List<Anime> _unique(Iterable<Anime> items) {
    final seen = <int>{};
    return [for (final anime in items) if (seen.add(anime.malId)) anime];
  }

  Future<void> loadHome() async {
    loadingHome = true;
    homeError = null;
    notifyListeners();
    try {
      await _replaceIfFresh(() async => _api.fetchTopAnime(limit: 25), (items) {
        topAnime = items;
        popularAnime = items;
      });
      await _replaceIfFresh(() async => _api.fetchSeasonalAnime(limit: 25), (items) {
        seasonalAnime = items;
        upcomingAnime = items.where((anime) => anime.airing).toList();
        if (upcomingAnime.isEmpty) upcomingAnime = items;
      });
      final movies = _unique([
        ...PopularSeed.byType('Movie'),
        ...topAnime.where((anime) => (anime.type ?? '').toLowerCase() == 'movie'),
        ...seasonalAnime.where((anime) => (anime.type ?? '').toLowerCase() == 'movie'),
      ]);
      if (movies.isNotEmpty) topMovies = movies;
    } catch (_) {
      if (topAnime.isEmpty) topAnime = PopularSeed.titles.take(12).toList();
      if (seasonalAnime.isEmpty) {
        seasonalAnime = PopularSeed.titles.skip(12).take(12).toList();
      }
    } finally {
      isOffline = false;
      homeError = null;
      loadingHome = false;
      if (searchResults.isEmpty) {
        searchResults = catalog;
      }
      notifyListeners();
    }
  }

  Future<void> _replaceIfFresh(
    Future<List<Anime>> Function() loader,
    void Function(List<Anime> items) assign,
  ) async {
    try {
      final remote = await loader();
      if (remote.isNotEmpty) {
        assign(remote);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> search(String query, {String? type}) async {
    lastQuery = query.trim();
    lastTypeFilter = type;
    final token = ++_searchToken;
    final browsingType = lastQuery.isEmpty && type != null && type.isNotEmpty;

    final local = _localMatches(lastQuery, type);
    if (lastQuery.isEmpty && !browsingType) {
      searchResults = catalog;
      searchUsedFallback = false;
      searchError = null;
      searching = false;
      notifyListeners();
      return;
    }

    searchResults = lastQuery.isEmpty ? local : _rankMatches(local, lastQuery);
    searchUsedFallback = false;
    searchError = null;
    searching = browsingType || lastQuery.length >= 2;
    notifyListeners();

    if (!searching) {
      return;
    }

    try {
      final remote = browsingType
          ? await _api.browseAnime(type: type, limit: 25)
          : await _api.searchAnime(query: lastQuery, type: type, limit: 25);
      if (token != _searchToken) return;
      final merged = _unique([...remote, ...local]);
      searchResults = lastQuery.isEmpty ? merged : _rankMatches(merged, lastQuery);
    } catch (_) {
      if (token != _searchToken) return;
    } finally {
      if (token == _searchToken) {
        searching = false;
        searchError = null;
        notifyListeners();
      }
    }
  }

  List<Anime> _localMatches(String query, String? type) {
    final needle = query.toLowerCase();
    final seen = <int>{};
    final matches = <Anime>[];
    for (final anime in [
      ...topAnime,
      ...seasonalAnime,
      ...popularAnime,
      ...upcomingAnime,
      ...topMovies,
      ...PopularSeed.titles,
      ...searchResults,
    ]) {
      if (!seen.add(anime.malId)) continue;
      if (type != null && type.isNotEmpty) {
        final animeType = anime.type?.toLowerCase() ?? '';
        if (animeType != type.toLowerCase()) continue;
      }
      if (needle.isEmpty) {
        matches.add(anime);
        continue;
      }
      final haystack = '${anime.title} ${anime.titleEnglish ?? ''} ${anime.titleJapanese ?? ''}'.toLowerCase();
      if (needle.length == 1) {
        if (haystack.trimLeft().startsWith(needle) ||
            (anime.displayTitle.toLowerCase().startsWith(needle))) {
          matches.add(anime);
        }
        continue;
      }
      if (haystack.contains(needle)) {
        matches.add(anime);
      }
    }
    return matches;
  }

  List<Anime> _rankMatches(List<Anime> items, String query) {
    final needle = _normalizeTitle(query);
    if (needle.isEmpty) return items;

    int rank(Anime anime) {
      var best = 99;
      for (final raw in [anime.displayTitle, anime.title, anime.titleEnglish, anime.titleJapanese]) {
        if (raw == null || raw.trim().isEmpty) continue;
        final score = _titleRank(_normalizeTitle(raw), needle);
        if (score < best) best = score;
      }
      return best;
    }

    final ranked = [...items]..sort((a, b) {
      final byName = rank(a).compareTo(rank(b));
      if (byName != 0) return byName;
      final byLength = a.displayTitle.length.compareTo(b.displayTitle.length);
      if (byLength != 0) return byLength;
      final byPopularity = (a.popularity ?? 1 << 20).compareTo(b.popularity ?? 1 << 20);
      if (byPopularity != 0) return byPopularity;
      return (b.score ?? 0).compareTo(a.score ?? 0);
    });
    return ranked;
  }

  static final _titleNoise = RegExp(r'[^a-z0-9\s]+');
  static final _titleSpaces = RegExp(r'\s+');
  static const _typeSuffixes = {'tv', 'ova', 'ona', 'movie', 'special', 'tv special', 'film'};

  String _normalizeTitle(String value) {
    return value.toLowerCase().replaceAll('&', ' and ').replaceAll(_titleNoise, ' ').replaceAll(_titleSpaces, ' ').trim();
  }

  int _titleRank(String title, String needle) {
    if (title.isEmpty) return 99;
    if (title == needle) return 0;
    if (title.startsWith(needle)) {
      final rest = title.substring(needle.length).trim();
      if (rest.isEmpty) return 0;
      if (_typeSuffixes.contains(rest) || RegExp(r'^\d{2,4}$').hasMatch(rest)) return 1;
      if (title.startsWith('$needle ')) return 4;
      return 5;
    }
    if (RegExp('\\b${RegExp.escape(needle)}\\b').hasMatch(title)) return 6;
    if (title.contains(needle)) return 7;
    return 99;
  }

  Anime? _knownFromLists(int id) {
    for (final anime in [...topAnime, ...seasonalAnime, ...popularAnime, ...upcomingAnime, ...topMovies, ...searchResults, ...PopularSeed.titles]) {
      if (anime.malId == id) return anime;
    }
    return details?.malId == id ? details : null;
  }

  Future<void> loadDetails(int id) async {
    final token = ++_detailsToken;
    focusedMalId = id;
    final merged = _mergeAll([_detailCache[id], _knownFromLists(id)]);
    final known = merged == null ? null : _hydrate(merged);
    final cachedCharacters = _characterCache[id] ?? SeedExtras.characters(id);
    final cachedStreaming = _streamingCache[id] ?? LegalSources.unique(known?.streaming ?? const []);
    final hasCache = known != null &&
        (known.synopsis?.trim().isNotEmpty ?? false) &&
        known.playableTrailerId != null &&
        cachedCharacters.isNotEmpty;

    details = known;
    characters = cachedCharacters;
    streaming = LegalSources.withFallback(cachedStreaming);
    loadingDetails = !hasCache;
    loadingCharacters = !_characterCache.containsKey(id) && cachedCharacters.isEmpty;
    loadingStreaming = false;
    detailsError = null;
    charactersError = null;
    streamingError = null;
    notifyListeners();

    try {
      final full = await _api.fetchAnimeFull(id);
      if (token != _detailsToken) return;
      details = _hydrate(full.mergedWith(known));
      _remember(details!);
      if (details!.streaming.isNotEmpty) {
        streaming = LegalSources.unique(details!.streaming);
        _streamingCache[id] = streaming;
        notifyListeners();
      }
    } catch (_) {
      if (token != _detailsToken) return;
      details = known;
    }

    if (token != _detailsToken) return;
    if (streaming.isEmpty || streaming.every((link) => link.url.trim().isEmpty)) {
      await loadStreaming(id, token: token);
    } else {
      await _markStreamingReady(token);
    }

    if (token != _detailsToken) return;
    if (details?.playableTrailerId == null) {
      try {
        final promoId = await _api.fetchPromoTrailerId(id);
        if (token != _detailsToken) return;
        if (promoId != null && details != null) {
          details = details!.copyWith(trailerYoutubeId: promoId);
          _remember(details!);
        }
      } catch (_) {}
    }

    if (token == _detailsToken) {
      detailsError = null;
      loadingDetails = false;
      isOffline = false;
      notifyListeners();
    }

    if (token != _detailsToken) return;
    await loadCharacters(id, token: token);
  }

  Future<void> _markStreamingReady(int token) async {
    if (token != _detailsToken) return;
    loadingStreaming = false;
    streamingError = null;
    notifyListeners();
  }

  Future<void> loadCharacters(int id, {int? token}) async {
    final request = token ?? _detailsToken;
    if (characters.isEmpty) {
      loadingCharacters = true;
      charactersError = null;
      notifyListeners();
    }
    try {
      final remote = await _api.fetchCharacters(id);
      if (request != _detailsToken) return;
      final next = remote.isNotEmpty ? remote : SeedExtras.characters(id);
      characters = next;
      if (next.isNotEmpty) _characterCache[id] = next;
    } catch (_) {
      if (request != _detailsToken) return;
      characters = _characterCache[id] ?? SeedExtras.characters(id);
    } finally {
      if (request == _detailsToken) {
        charactersError = null;
        loadingCharacters = false;
        isOffline = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadStreaming(int id, {int? token}) async {
    final request = token ?? _detailsToken;
    if (streaming.isEmpty) {
      loadingStreaming = true;
      streamingError = null;
      notifyListeners();
    }
    try {
      final remote = LegalSources.unique(await _api.fetchStreaming(id));
      if (request != _detailsToken) return;
      if (remote.isNotEmpty) {
        streaming = remote;
        _streamingCache[id] = remote;
        if (details != null && details!.malId == id) {
          details = details!.copyWith(streaming: remote);
          _remember(details!);
        }
      } else {
        streaming = LegalSources.withFallback(streaming);
      }
    } catch (_) {
      if (request != _detailsToken) return;
      streaming = LegalSources.withFallback(streaming);
    } finally {
      if (request == _detailsToken) {
        streamingError = null;
        loadingStreaming = false;
        isOffline = false;
        notifyListeners();
      }
    }
  }

  Anime _hydrate(Anime anime) {
    return anime.copyWith(
      synopsis: (anime.synopsis != null && anime.synopsis!.trim().isNotEmpty)
          ? anime.synopsis
          : SeedExtras.synopsis(anime.malId),
      genres: anime.genres.isNotEmpty ? anime.genres : SeedExtras.genres(anime.malId),
    );
  }

  Anime? _mergeAll(Iterable<Anime?> items) {
    Anime? merged;
    for (final item in items) {
      if (item == null) continue;
      merged = merged == null ? item : merged.mergedWith(item);
    }
    return merged;
  }

  void _remember(Anime anime) {
    final current = _detailCache[anime.malId];
    _detailCache[anime.malId] = anime.mergedWith(current);
  }
}
