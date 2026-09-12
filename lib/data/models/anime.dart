import '../../core/utils/date_formatter.dart';
import '../../core/utils/json_map.dart';
import 'streaming_link.dart';

class Anime {
  const Anime({
    required this.malId,
    required this.title,
    this.titleEnglish,
    this.titleJapanese,
    this.imageUrl,
    this.largeImageUrl,
    this.trailerUrl,
    this.trailerYoutubeId,
    this.type,
    this.source,
    this.episodes,
    this.status,
    this.airing = false,
    this.airedString,
    this.airedFrom,
    this.duration,
    this.rating,
    this.score,
    this.scoredBy,
    this.rank,
    this.popularity,
    this.synopsis,
    this.season,
    this.year,
    this.background,
    this.genres = const [],
    this.studios = const [],
    this.streaming = const [],
  });

  final int malId;
  final String title;
  final String? titleEnglish;
  final String? titleJapanese;
  final String? imageUrl;
  final String? largeImageUrl;
  final String? trailerUrl;
  final String? trailerYoutubeId;
  final String? type;
  final String? source;
  final int? episodes;
  final String? status;
  final bool airing;
  final String? airedString;
  final DateTime? airedFrom;
  final String? duration;
  final String? rating;
  final double? score;
  final int? scoredBy;
  final int? rank;
  final int? popularity;
  final String? synopsis;
  final String? season;
  final int? year;
  final String? background;
  final List<String> genres;
  final List<String> studios;
  final List<StreamingLink> streaming;

  String get displayTitle =>
      (titleEnglish != null && titleEnglish!.trim().isNotEmpty) ? titleEnglish! : title;

  String get poster => largeImageUrl ?? imageUrl ?? '';

  String? get playableTrailerId =>
      _youtubeIdFromValue(trailerYoutubeId) ?? _youtubeIdFromValue(trailerUrl);

  String get metaLine {
    final parts = <String>[
      if (type != null && type!.isNotEmpty) type!,
      if (year != null) '$year',
      if (episodes != null) '$episodes ep',
    ];
    return parts.join(' · ');
  }

  factory Anime.fromJson(Map<String, dynamic> json) {
    final images = asJsonMap(json['images']);
    final jpg = asJsonMap(images?['jpg']);
    final webp = asJsonMap(images?['webp']);
    final imageUrl = _firstUrl([
      jpg?['image_url'],
      webp?['image_url'],
      jpg?['small_image_url'],
      webp?['small_image_url'],
    ]);
    final largeImageUrl = _firstUrl([
      jpg?['large_image_url'],
      webp?['large_image_url'],
      imageUrl,
    ]);
    final trailer = asJsonMap(json['trailer']);
    final aired = asJsonMap(json['aired']);
    return Anime(
      malId: _asInt(json['mal_id']) ?? 0,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : (json['title_english'] as String? ?? 'Untitled'),
      titleEnglish: json['title_english'] as String?,
      titleJapanese: json['title_japanese'] as String?,
      imageUrl: imageUrl,
      largeImageUrl: largeImageUrl,
      trailerUrl: trailer?['url'] as String?,
      trailerYoutubeId: _youtubeIdFromTrailer(trailer),
      type: json['type'] as String?,
      source: json['source'] as String?,
      episodes: _asInt(json['episodes']),
      status: json['status'] as String?,
      airing: json['airing'] == true,
      airedString: aired?['string'] as String?,
      airedFrom: DateFormatter.tryParse(aired?['from']),
      duration: json['duration'] as String?,
      rating: json['rating'] as String?,
      score: _asDouble(json['score']),
      scoredBy: _asInt(json['scored_by']),
      rank: _asInt(json['rank']),
      popularity: _asInt(json['popularity']),
      synopsis: json['synopsis'] as String?,
      season: json['season'] as String?,
      year: _asInt(json['year']) ?? DateFormatter.tryParse(aired?['from'])?.year,
      background: json['background'] as String?,
      genres: _uniqueNames([
        ..._namedList(json['genres']),
        ..._namedList(json['themes']),
        ..._namedList(json['demographics']),
      ]),
      studios: _namedList(json['studios']),
      streaming: LegalSources.fromAnimeJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'mal_id': malId,
        'title': title,
        'title_english': titleEnglish,
        'title_japanese': titleJapanese,
        'images': {
          'jpg': {
            'image_url': imageUrl,
            'large_image_url': largeImageUrl,
          },
        },
        'trailer': {
          'url': trailerUrl,
          'youtube_id': trailerYoutubeId,
        },
        'type': type,
        'source': source,
        'episodes': episodes,
        'status': status,
        'airing': airing,
        'aired': {
          'string': airedString,
          'from': airedFrom?.toIso8601String(),
        },
        'duration': duration,
        'rating': rating,
        'score': score,
        'scored_by': scoredBy,
        'rank': rank,
        'popularity': popularity,
        'synopsis': synopsis,
        'season': season,
        'year': year,
        'background': background,
        'genres': genres.map((name) => {'name': name}).toList(),
        'studios': studios.map((name) => {'name': name}).toList(),
        'streaming': streaming.map((link) => link.toJson()).toList(),
      };

  Anime mergedWith(Anime? other) {
    if (other == null) return this;
    String? pick(String? a, String? b) {
      if (a != null && a.trim().isNotEmpty) return a;
      if (b != null && b.trim().isNotEmpty) return b;
      return a ?? b;
    }

    return Anime(
      malId: malId,
      title: title.trim().isNotEmpty ? title : other.title,
      titleEnglish: pick(titleEnglish, other.titleEnglish),
      titleJapanese: pick(titleJapanese, other.titleJapanese),
      imageUrl: pick(imageUrl, other.imageUrl),
      largeImageUrl: pick(largeImageUrl, other.largeImageUrl),
      trailerUrl: pick(trailerUrl, other.trailerUrl),
      trailerYoutubeId: playableTrailerId ?? other.playableTrailerId,
      type: pick(type, other.type),
      source: pick(source, other.source),
      episodes: episodes ?? other.episodes,
      status: pick(status, other.status),
      airing: airing || other.airing,
      airedString: pick(airedString, other.airedString),
      airedFrom: airedFrom ?? other.airedFrom,
      duration: pick(duration, other.duration),
      rating: pick(rating, other.rating),
      score: score ?? other.score,
      scoredBy: scoredBy ?? other.scoredBy,
      rank: rank ?? other.rank,
      popularity: popularity ?? other.popularity,
      synopsis: pick(synopsis, other.synopsis),
      season: pick(season, other.season),
      year: year ?? other.year,
      background: pick(background, other.background),
      genres: genres.isNotEmpty ? genres : other.genres,
      studios: studios.isNotEmpty ? studios : other.studios,
      streaming: streaming.isNotEmpty ? streaming : other.streaming,
    );
  }

  Anime copyWith({
    List<StreamingLink>? streaming,
    String? synopsis,
    List<String>? genres,
    String? imageUrl,
    String? largeImageUrl,
    List<String>? studios,
    String? trailerUrl,
    String? trailerYoutubeId,
  }) {
    return Anime(
      malId: malId,
      title: title,
      titleEnglish: titleEnglish,
      titleJapanese: titleJapanese,
      imageUrl: imageUrl ?? this.imageUrl,
      largeImageUrl: largeImageUrl ?? this.largeImageUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      trailerYoutubeId: trailerYoutubeId ?? this.trailerYoutubeId,
      type: type,
      source: source,
      episodes: episodes,
      status: status,
      airing: airing,
      airedString: airedString,
      airedFrom: airedFrom,
      duration: duration,
      rating: rating,
      score: score,
      scoredBy: scoredBy,
      rank: rank,
      popularity: popularity,
      synopsis: synopsis ?? this.synopsis,
      season: season,
      year: year,
      background: background,
      genres: genres ?? this.genres,
      studios: studios ?? this.studios,
      streaming: streaming ?? this.streaming,
    );
  }

  static String? _youtubeIdFromTrailer(Map<String, dynamic>? trailer) {
    if (trailer == null) return null;
    return _youtubeIdFromValue(trailer['youtube_id']) ??
        _youtubeIdFromValue(trailer['url']) ??
        _youtubeIdFromValue(trailer['embed_url']);
  }

  static String? youtubeIdFrom(dynamic value) {
    if (value == null) return null;
    return _youtubeIdFromValue(value.toString());
  }

  static String? _youtubeIdFromValue(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.contains('/') && !trimmed.contains('?') && trimmed.length <= 15) {
      return trimmed;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) return queryId;
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    if (uri.host.contains('youtu.be')) return segments.first;
    final embedIndex = segments.indexOf('embed');
    if (embedIndex >= 0 && embedIndex + 1 < segments.length) {
      return segments[embedIndex + 1];
    }
    final shortsIndex = segments.indexOf('shorts');
    if (shortsIndex >= 0 && shortsIndex + 1 < segments.length) {
      return segments[shortsIndex + 1];
    }
    return null;
  }

  static String? _firstUrl(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static List<String> _namedList(dynamic value) {
    return asJsonMapList(value)
        .map((item) => (item['name'] as String?) ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static List<String> _uniqueNames(Iterable<String> names) {
    final seen = <String>{};
    return [
      for (final name in names)
        if (seen.add(name.toLowerCase())) name,
    ];
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
