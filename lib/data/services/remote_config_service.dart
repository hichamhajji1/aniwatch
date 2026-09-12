import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/json_map.dart';

/// Remote flags from the shared gist. Ani reads `show_an.show_ads`.
class RemoteConfigService {
  RemoteConfigService({http.Client? client}) : _client = client ?? http.Client();

  static const gistId = '8614461bb7a9fd2c78fa3c641ed0ecb0';
  static const gistFile = 'gistfile1.txt';
  static const gistApiUrl = 'https://api.github.com/gists/$gistId';
  static const gistUrl =
      'https://gist.githubusercontent.com/hichamhajji1/$gistId/raw/$gistFile';
  static const appKey = 'show_an';

  static const _noCacheHeaders = {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };

  final http.Client _client;

  /// Gist flag `show_an.show_ads`. When false, hide onboarding and all anime.
  bool showAds = false;

  Future<void> load() async {
    try {
      final body = await _fetchFreshGist();
      final decoded = jsonDecode(_extractJson(body));
      final block = asJsonMap(asJsonMap(decoded)?[appKey]);
      showAds = block?['show_ads'] == true;
    } catch (_) {
      showAds = false;
    }
  }

  Future<String> _fetchFreshGist() async {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final api = await _client
          .get(
            Uri.parse(gistApiUrl).replace(queryParameters: {'t': stamp}),
            headers: {
              ..._noCacheHeaders,
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'AnShow-Anime-show',
            },
          )
          .timeout(const Duration(seconds: 4));
      if (api.statusCode == 200) {
        final content = _contentFromGistApi(api.body);
        if (content != null && content.trim().isNotEmpty) return content;
      }
    } catch (_) {}

    final raw = await _client
        .get(
          Uri.parse(gistUrl).replace(queryParameters: {'t': stamp}),
          headers: _noCacheHeaders,
        )
        .timeout(const Duration(seconds: 4));
    if (raw.statusCode != 200) {
      throw StateError('Gist returned HTTP ${raw.statusCode}.');
    }
    return raw.body;
  }

  static String? _contentFromGistApi(String body) {
    final decoded = asJsonMap(jsonDecode(body));
    final files = asJsonMap(decoded?['files']);
    if (files == null || files.isEmpty) return null;
    final named = asJsonMap(files[gistFile]);
    final namedContent = named?['content'];
    if (namedContent is String && namedContent.trim().isNotEmpty) return namedContent;
    for (final value in files.values) {
      final content = asJsonMap(value)?['content'];
      if (content is String && content.trim().isNotEmpty) return content;
    }
    return null;
  }

  static String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return '{}';
    return raw.substring(start, end + 1);
  }
}
