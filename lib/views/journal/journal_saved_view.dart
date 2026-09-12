import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../state/journal_provider.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/poster_image.dart';
import 'add_entry_sheet.dart';
import 'journal_details_view.dart';

class JournalSavedView extends StatelessWidget {
  const JournalSavedView({super.key});

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final items = journal.savedAnime;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Saved', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => _addToSaved(context),
                  icon: const Icon(Icons.add_rounded, color: AppColors.gold),
                  tooltip: 'Add to Saved',
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nothing in Saved yet. Bookmark a title, or tap + to add one here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 18),
                          GoldButton(
                            label: 'Add to Saved',
                            icon: Icons.add_rounded,
                            expand: false,
                            onPressed: () => _addToSaved(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.52,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final anime = items[index];
                      return AnimeCard(
                        key: ValueKey('saved-${anime.malId}'),
                        width: double.infinity,
                        anime: anime,
                        onTap: () => JournalDetailsView.openFromAnime(context, anime),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> _addToSaved(BuildContext context) async {
  final journal = context.read<JournalProvider>();
  final unsaved = journal.unsavedEntries;
  if (unsaved.isEmpty) {
    await AddEntrySheet.show(context, forSaved: true);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text('Add to Saved', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.chip,
                  child: Icon(Icons.add_rounded, color: AppColors.gold),
                ),
                title: const Text('Add a new title', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Create one and keep it in Saved'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  AddEntrySheet.show(context, forSaved: true);
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  'From your journal',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unsaved.length,
                  itemBuilder: (context, index) {
                    final entry = unsaved[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 40,
                          height: 56,
                          child: PosterImage(url: entry.imagePath, malId: entry.notificationId),
                        ),
                      ),
                      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(entry.kind.label),
                      trailing: const Icon(Icons.bookmark_add_outlined, color: AppColors.gold),
                      onTap: () async {
                        await journal.setSaved(entry, true);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
