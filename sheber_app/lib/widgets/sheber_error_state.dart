import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SheberErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool isDark;

  const SheberErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: textGray.withValues(alpha: 0.85)),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: textDark),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SheberTokens.radiusMd),
                  ),
                ),
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
