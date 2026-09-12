import 'anime_kind.dart';

class JournalShelf {
  const JournalShelf({
    required this.id,
    required this.title,
    this.kindId,
    this.format,
  });

  final String id;
  final String title;
  final String? kindId;
  final String? format;

  AnimeKind? get kind => kindId == null ? null : AnimeKind.byId(kindId);

  static const top = JournalShelf(id: 'top', title: 'Top Anime');
  static const airing = JournalShelf(id: 'airing', title: 'Currently Airing Season');
  static const popular = JournalShelf(id: 'popular', title: 'Most Popular');
  static const movies = JournalShelf(id: 'movies', title: 'Movies', format: 'movie');
  static const upcoming = JournalShelf(id: 'upcoming', title: 'Upcoming');
  static const rated = JournalShelf(id: 'rated', title: 'Highest Rated');
  static const tv = JournalShelf(id: 'tv', title: 'TV Series', format: 'tv');
  static const action = JournalShelf(id: 'action', title: 'Action', kindId: 'action');
  static const fantasy = JournalShelf(id: 'fantasy', title: 'Fantasy', kindId: 'fantasy');
  static const romance = JournalShelf(id: 'romance', title: 'Romance', kindId: 'romance');
  static const ova = JournalShelf(id: 'ova', title: 'OVA', format: 'ova');
  static const ona = JournalShelf(id: 'ona', title: 'ONA', format: 'ona');
  static const specials = JournalShelf(id: 'specials', title: 'Specials', format: 'special');
  static const slice = JournalShelf(id: 'slice', title: 'Slice of Life', kindId: 'slice');
  static const comedy = JournalShelf(id: 'comedy', title: 'Comedy', kindId: 'comedy');
  static const thriller = JournalShelf(id: 'thriller', title: 'Thriller', kindId: 'thriller');
  static const sciFi = JournalShelf(id: 'scifi', title: 'Sci-Fi', kindId: 'scifi');
  static const horror = JournalShelf(id: 'horror', title: 'Horror', kindId: 'horror');
  static const sports = JournalShelf(id: 'sports', title: 'Sports', kindId: 'sports');
  static const mystery = JournalShelf(id: 'mystery', title: 'Mystery', kindId: 'mystery');

  static const List<JournalShelf> defaults = [
    top,
    airing,
    popular,
    upcoming,
    rated,
    movies,
    tv,
    action,
    fantasy,
    romance,
    ova,
    ona,
    specials,
  ];

  static const List<JournalShelf> catalog = [
    top,
    airing,
    popular,
    upcoming,
    rated,
    movies,
    tv,
    action,
    fantasy,
    romance,
    ova,
    ona,
    specials,
    slice,
    comedy,
    thriller,
    sciFi,
    horror,
    sports,
    mystery,
  ];

  static const List<String> defaultIds = [
    'top',
    'airing',
    'popular',
    'upcoming',
    'rated',
    'movies',
    'tv',
    'action',
    'fantasy',
    'romance',
    'ova',
    'ona',
    'specials',
  ];

  static JournalShelf byId(String id) {
    for (final shelf in catalog) {
      if (shelf.id == id) return shelf;
    }
    return JournalShelf(id: id, title: id);
  }

  static JournalShelf? forKind(String? kindId) {
    if (kindId == null || kindId.isEmpty) return null;
    for (final shelf in catalog) {
      if (shelf.kindId == kindId) return shelf;
    }
    return null;
  }

  static JournalShelf? forFormat(String? format) {
    if (format == null || format.isEmpty) return null;
    for (final shelf in catalog) {
      if (shelf.format == format) return shelf;
    }
    return null;
  }
}
