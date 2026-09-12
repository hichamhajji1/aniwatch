import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible, this.onRetry});

  final bool visible;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFF3A2A12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'You are offline. Showing saved data when available.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry', style: TextStyle(color: AppColors.gold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorFallback extends StatelessWidget {
  const ErrorFallback({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: AppColors.gold, size: compact ? 22 : 36),
          SizedBox(height: compact ? 8 : 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
              child: const Text('Try again', style: TextStyle(color: Color(0xFF1A1408))),
            ),
          ],
        ],
      ),
    );
  }
}
