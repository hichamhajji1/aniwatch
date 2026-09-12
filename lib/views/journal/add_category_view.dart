import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../state/journal_provider.dart';

class AddCategoryView extends StatelessWidget {
  const AddCategoryView({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddCategoryView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final choices = journal.availableShelves;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add a category')),
      body: choices.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Every category is already on Home.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: choices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final shelf = choices[index];
                return Material(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await journal.addHomeShelf(shelf);
                      if (context.mounted) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.chip,
                            child: Icon(shelf.kind?.icon ?? Icons.movie_filter_rounded, color: AppColors.gold),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              shelf.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
