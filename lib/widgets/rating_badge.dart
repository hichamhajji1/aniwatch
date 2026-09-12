import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.score, this.compact = false});

  final double score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: compact ? 11 : 13, color: AppColors.gold),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
