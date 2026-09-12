import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/services/journal_files.dart';

class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    this.url,
    this.malId,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final int? malId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final original = url?.trim() ?? '';
    if (original.isNotEmpty && _isLocalPath(original)) {
      final provider = journalImageProvider(original.replaceFirst('file://', ''));
      if (provider != null) {
        return Image(
          key: ValueKey('poster-file-$malId-$original'),
          image: provider,
          fit: fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const _PosterPlaceholder(),
        );
      }
      return const _PosterPlaceholder();
    }
    final sources = <_PosterSource>[];
    if (original.isNotEmpty) {
      if (kIsWeb) {
        sources.add(_PosterSource(original, html: true));
        sources.add(_PosterSource(_proxy(original)));
        sources.add(_PosterSource(_proxy(original, host: 'images.weserv.nl')));
      } else {
        sources.add(_PosterSource(original));
      }
    }
    return KeyedSubtree(
      key: ValueKey('poster-$malId-$original'),
      child: _PosterChain(malId: malId, fit: fit, sources: sources, index: 0),
    );
  }

  static String _proxy(String raw, {String host = 'wsrv.nl'}) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return raw;
    final current = uri.host.toLowerCase();
    if (current.contains('wsrv.nl') || current.contains('weserv.nl')) return raw;
    return 'https://$host/?url=${Uri.encodeComponent(raw)}&n=-1&w=800&output=jpg';
  }

  static bool _isLocalPath(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) return false;
    return value.startsWith('/') || value.startsWith('file:') || value.contains('journal_');
  }
}

class _PosterSource {
  const _PosterSource(this.url, {this.html = false});

  final String url;
  final bool html;
}

class _PosterChain extends StatelessWidget {
  const _PosterChain({
    required this.malId,
    required this.fit,
    required this.sources,
    required this.index,
  });

  final int? malId;
  final BoxFit fit;
  final List<_PosterSource> sources;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (index < sources.length) {
      final source = sources[index];
      return Image.network(
        source.url,
        fit: fit,
        gaplessPlayback: false,
        filterQuality: FilterQuality.medium,
        webHtmlElementStrategy:
            source.html ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
        errorBuilder: (_, _, _) => _PosterChain(
          malId: malId,
          fit: fit,
          sources: sources,
          index: index + 1,
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const ColoredBox(color: AppColors.surfaceHigh);
        },
      );
    }
    if (malId != null) {
      return Image.asset(
        'assets/posters/$malId.jpg',
        fit: fit,
        gaplessPlayback: false,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const _PosterPlaceholder(),
      );
    }
    return const _PosterPlaceholder();
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceHigh,
      child: Icon(Icons.movie_filter_rounded, color: AppColors.gold),
    );
  }
}
