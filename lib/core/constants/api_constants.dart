class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.jikan.moe/v4';
  static const Duration requestTimeout = Duration(seconds: 20);
  static const int maxRequestsPerSecond = 1;
  static const int maxRetries = 3;

  static const String seasonsNow = '/seasons/now';
  static const String seasonsUpcoming = '/seasons/upcoming';
  static const String topAnime = '/top/anime';
  static const String searchAnime = '/anime';

  static String animeFull(int id) => '/anime/$id/full';
  static String anime(int id) => '/anime/$id';
  static String animeCharacters(int id) => '/anime/$id/characters';
  static String animeVideos(int id) => '/anime/$id/videos';
  static String animeStreaming(int id) => '/anime/$id/streaming';
}
