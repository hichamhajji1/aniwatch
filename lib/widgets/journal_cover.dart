import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/models/journal_entry.dart';
import '../data/services/journal_files.dart';

class JournalCover extends StatelessWidget {
  const JournalCover({
    super.key,
    required this.entry,
    this.previewBytes,
    this.radius = 18,
    this.showKind = true,
  });

  final JournalEntry entry;
  final Uint8List? previewBytes;
  final double radius;
  final bool showKind;

  @override
  Widget build(BuildContext context) {
    final bytes = previewBytes;
    final provider = entry.imagePath == null ? null : journalImageProvider(entry.imagePath!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [entry.kind.depth, AppColors.charcoal],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null && bytes.isNotEmpty)
              Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _Monogram(entry: entry),
              )
            else if (provider != null)
              Image(
                image: provider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _Monogram(entry: entry),
              )
            else
              _Monogram(entry: entry),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            if (showKind)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  entry.kind.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: entry.kind.depth,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(entry.kind.icon, color: entry.kind.glow, size: 28),
            const SizedBox(height: 8),
            Text(
              entry.monogram,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: entry.kind.glow,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
