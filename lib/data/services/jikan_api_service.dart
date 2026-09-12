import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/utils/json_map.dart';
import '../../core/utils/network_exception.dart';
import '../../core/utils/rate_limiter.dart';
import '../models/anime.dart';
import '../models/character.dart';
import '../models/streaming_link.dart';

class JikanApiService {
  JikanApiService({
    http.Client? client,
    RateLimiter? rateLimiter,
  })  : _client = client ?? http.Client(),
        _limiter = rateLimiter ?? RateLimiter(maxPerSecond: ApiConstants.maxRequestsPerSecond);

  final http.Client _client;
  final RateLimiter _limiter;
  final Map<String, Map<String, dynamic>> _cache = {};

  Future<List<Anime>> fetchTopAnime({
    int limit = 25,
    String? type,
    String? filter,
  }) {
    final query = <String, String>{'limit': '$limit'};
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (filter != null && filter.isNotEmpty) query['filter'] = filter;
    return _fetchAnimeList(ApiConstants.topAnime, query: query);
  }

  Future<List<Anime>> fetchSeasonalAnime({int limit = 25}) {
    return _fetchAnimeList(
      ApiConstants.seasonsNow,
      query: {'limit': '$limit'},
    );
  }

  Future<List<Anime>> fetchUpcomingAnime({int limit = 25}) {
    return _fetchAnimeList(
      ApiConstants.seasonsUpcoming,
      query: {'limit': '$limit'},
    );
  }

  Future<List<Anime>> browseAnime({
    String? type,
    int limit = 25,
    int page = 1,
  }) {
    final params = <String, String>{
      'limit': '$limit',
      'page': '$page',
      'sfw': 'true',
      'order_by': 'popularity',
      'sort': 'asc',
    };
    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }
    return _fetchAnimeList(ApiConstants.searchAnime, query: params);
  }

  Future<List<Anime>> searchAnime({
    required String query,
    String? type,
    int limit = 25,
  }) {
    final params = <String, String>{
      'q': query,
      'limit': '$limit',
      'sfw': 'true',
    };
    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }
    return _fetchAnimeList(ApiConstants.searchAnime, query: params);
  }

  Future<Anime> fetchAnimeFull(int id) async {
    try {
      return await _parseAnime(ApiConstants.animeFull(id));
    } catch (_) {
      return _parseAnime(ApiConstants.anime(id));
    }
  }

  Future<Anime> _parseAnime(String path) async {
    final json = await _get(path, priority: true);
    final data = asJsonMap(json['data']);
    if (data == null) {
      throw const NetworkException('Anime details were empty.');
    }
    return Anime.fromJson(data);
  }

  Future<List<AnimeCharacter>> fetchCharacters(int id) async {
    final json = await _get(
      ApiConstants.animeCharacters(id),
      allowNotFound: true,
      priority: true,
    );
    final raw = asJsonMapList(json['data']);
    raw.sort((a, b) {
      final roleA = (a['role'] as String? ?? '').toLowerCase() == 'main' ? 0 : 1;
      final roleB = (b['role'] as String? ?? '').toLowerCase() == 'main' ? 0 : 1;
      return roleA.compareTo(roleB);
    });
    return raw.take(28).map(AnimeCharacter.fromJson).toList();
  }

  Future<List<StreamingLink>> fetchStreaming(int id) async {
    final json = await _get(
      ApiConstants.animeStreaming(id),
      allowNotFound: true,
      priority: true,
    );
    return LegalSources.unique(
      asJsonMapList(json['data']).map(StreamingLink.fromJson),
    );
  }

  Future<String?> fetchPromoTrailerId(int id) async {
    final json = await _get(
      ApiConstants.animeVideos(id),
      allowNotFound: true,
      priority: true,
    );
    final data = asJsonMap(json['data']);
    for (final item in asJsonMapList(data?['promo'])) {
      final id = _youtubeFromVideoMap(asJsonMap(item['trailer']));
      if (id != null) return id;
    }
    for (final item in asJsonMapList(data?['music_videos'])) {
      final id = _youtubeFromVideoMap(asJsonMap(item['video']));
      if (id != null) return id;
    }
    return null;
  }

  String? _youtubeFromVideoMap(Map<String, dynamic>? video) {
    if (video == null) return null;
    return Anime.youtubeIdFrom(video['youtube_id']) ??
        Anime.youtubeIdFrom(video['url']) ??
        Anime.youtubeIdFrom(video['embed_url']);
  }

  Future<List<Anime>> _fetchAnimeList(
    String path, {
    Map<String, String>? query,
  }) async {
    final json = await _get(path, query: query);
    return asJsonMapList(json['data']).map(Anime.fromJson).toList();
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
    bool allowNotFound = false,
    bool priority = false,
  }) {
    final cacheKey = '$path?${Uri(queryParameters: query ?? const {})}';
    final cached = _cache[cacheKey];
    if (cached != null) return Future.value(cached);
    return _limiter.schedule(() async {
      try {
        final json = await _getWithRetry(
          path,
          query: query,
          allowNotFound: allowNotFound,
        );
        _cache[cacheKey] = json;
        return json;
      } on NetworkException {
        final fallback = _cache[cacheKey];
        if (fallback != null) return fallback;
        rethrow;
      }
    }, priority: priority);
  }

  Future<Map<String, dynamic>> _getWithRetry(
    String path, {
    Map<String, String>? query,
    bool allowNotFound = false,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < ApiConstants.maxRetries; attempt++) {
      try {
        return await _send(path, query: query, allowNotFound: allowNotFound);
      } on NetworkException catch (error) {
        lastError = error;
        if (_shouldRetry(error.statusCode) && attempt < ApiConstants.maxRetries - 1) {
          await Future<void>.delayed(Duration(milliseconds: 1100 * (attempt + 1)));
          continue;
        }
        rethrow;
      } on TimeoutException {
        lastError = const NetworkException('The request timed out.');
        if (attempt < ApiConstants.maxRetries - 1) {
          await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
          continue;
        }
      } catch (error) {
        lastError = error;
        if (attempt < ApiConstants.maxRetries - 1) {
          await Future<void>.delayed(Duration(milliseconds: 1100 * (attempt + 1)));
          continue;
        }
        if (_looksOffline(error)) {
          throw const NetworkException(
            'You appear to be offline. Check your connection and try again.',
            offline: true,
          );
        }
        throw NetworkException(error.toString());
      }
    }
    if (lastError is NetworkException) throw lastError;
    if (lastError != null && _looksOffline(lastError)) {
      throw const NetworkException(
        'You appear to be offline. Check your connection and try again.',
        offline: true,
      );
    }
    throw lastError ?? const NetworkException('Unable to reach Jikan right now.');
  }

  bool _shouldRetry(int? statusCode) {
    return statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  bool _looksOffline(Object error) {
    final label = '${error.runtimeType} $error'.toLowerCase();
    return error is http.ClientException ||
        label.contains('socket') ||
        label.contains('failed host lookup') ||
        label.contains('failed to fetch') ||
        label.contains('xmlhttprequest') ||
        label.contains('network is unreachable') ||
        label.contains('connection failed');
  }

  Future<Map<String, dynamic>> _send(
    String path, {
    Map<String, String>? query,
    bool allowNotFound = false,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path').replace(queryParameters: query);
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode == 404 && allowNotFound) {
      return const {'data': <dynamic>[]};
    }
    if (response.statusCode == 429) {
      throw const NetworkException(
        'Jikan is rate-limiting requests. Retrying shortly.',
        statusCode: 429,
      );
    }
    if (response.statusCode == 502 ||
        response.statusCode == 503 ||
        response.statusCode == 504) {
      throw NetworkException(
        'Jikan is busy or timed out. Please try again in a moment.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NetworkException(
        'Jikan returned HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    final map = asJsonMap(decoded);
    if (map == null) {
      throw const NetworkException('Unexpected response from Jikan.');
    }
    return map;
  }
}
