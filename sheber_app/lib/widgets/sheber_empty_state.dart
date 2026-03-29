import 'package:flutter/material.dart';

/// Icon + title (+ optional subtitle and CTA).
class SheberEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;
  /// `false` — body-style title (e.g. “log in to see chats”).
  final bool emphasizeTitle;

  const SheberEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.isDark,
    this.emphasizeTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconColor = const Color(0xFFCBD5E1);
    final titleStyle = emphasizeTitle
        ? TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)
        : TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textGray);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: emphasizeTitle ? 64 : 56, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: titleStyle,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 14, color: textGray),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
