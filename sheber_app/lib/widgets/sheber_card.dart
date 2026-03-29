import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rounded surface with optional tap — orders, masters, bids.
class SheberCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const SheberCard({
    super.key,
    required this.child,
    required this.isDark,
    this.onTap,
    this.padding,
    this.radius = SheberTokens.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inner = Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      child: onTap == null
          ? Padding(padding: padding ?? EdgeInsets.zero, child: child)
          : InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: inner,
    );
  }
}

/// Bordered tile without outer shadow (e.g. bid row in chat).
class SheberOutlinedCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const SheberOutlinedCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final cardInner = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Material(
      color: cardInner,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: padding ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}
