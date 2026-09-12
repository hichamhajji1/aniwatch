import '../../core/utils/json_map.dart';

class StreamingLink {
  const StreamingLink({required this.name, this.url = ''});

  final String name;
  final String url;

  factory StreamingLink.fromJson(Map<String, dynamic> json) {
    return StreamingLink(
      name: (json['name'] as String?)?.trim() ?? '',
      url: (json['url'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
      };
}

class LegalSources {
  LegalSources._();

  static const fallback = <StreamingLink>[
    StreamingLink(name: 'Crunchyroll'),
    StreamingLink(name: 'Netflix'),
    StreamingLink(name: 'HIDIVE'),
    StreamingLink(name: 'Prime Video'),
    StreamingLink(name: 'Disney+'),
  ];

  static const _platformNames = <String, String>{
    'crunchyroll': 'Crunchyroll',
    'netflix': 'Netflix',
    'hidive': 'HIDIVE',
    'prime video': 'Prime Video',
    'primevideo': 'Prime Video',
    'amazon.': 'Prime Video',
    'disney+': 'Disney+',
    'disneyplus': 'Disney+',
    'hulu': 'Hulu',
    'bilibili': 'Bilibili',
    'funimation': 'Funimation',
    'wakanim': 'Wakanim',
    'animationdigitalnetwork': 'ADN',
    'animation digital network': 'ADN',
    'hbomax': 'Max',
    'max.com': 'Max',
    'hbo max': 'Max',
    'apple tv': 'Apple TV',
    'tv.apple': 'Apple TV',
    'itunes': 'Apple TV',
    'youtube': 'YouTube',
    'tubitv': 'Tubi',
    'tubi.': 'Tubi',
    'iqiyi': 'iQIYI',
    'viu.com': 'Viu',
    'wetv': 'WeTV',
    'muse asia': 'Muse Asia',
  };

  static const _blocked = <String>[
    '9anime',
    'gogo',
    'zoro',
    'aniwatch',
    'hianime',
    'kissanime',
    'animix',
    'nyaa',
    'torrent',
    'search?q=',
  ];

  static List<StreamingLink> fromAnimeJson(Map<String, dynamic> json) {
    return unique([
      ...asJsonMapList(json['streaming']).map(StreamingLink.fromJson),
      ...asJsonMapList(json['external'])
          .map(StreamingLink.fromJson)
          .where((link) => _knownName(link) != null),
    ]);
  }

  static List<StreamingLink> unique(Iterable<StreamingLink> links) {
    final seen = <String>{};
    final result = <StreamingLink>[];
    for (final link in links) {
      final name = _displayName(link);
      if (name == null || !seen.add(name.toLowerCase())) continue;
      result.add(StreamingLink(name: name, url: link.url));
    }
    return result;
  }

  static List<StreamingLink> withFallback(Iterable<StreamingLink> links) {
    final cleaned = unique(links);
    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  static String? _knownName(StreamingLink link) {
    final hay = '${link.name} ${link.url}'.toLowerCase();
    for (final entry in _platformNames.entries) {
      if (hay.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? _displayName(StreamingLink link) {
    final hay = '${link.name} ${link.url}'.toLowerCase();
    if (hay.trim().isEmpty) return null;
    if (_blocked.any(hay.contains)) return null;
    final known = _knownName(link);
    if (known != null) return known;
    final trimmed = link.name.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'official site') return null;
    if (trimmed.toLowerCase().contains('twitter') ||
        trimmed.toLowerCase().contains('x.com') ||
        trimmed.toLowerCase().contains('instagram') ||
        trimmed.toLowerCase().contains('facebook') ||
        trimmed.toLowerCase().contains('wikipedia') ||
        trimmed.toLowerCase().contains('myanimelist')) {
      return null;
    }
    return trimmed;
  }
}
