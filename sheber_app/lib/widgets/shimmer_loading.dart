import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer plate; [isDark] shifts base/highlight colors.
class SheberShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool isDark;

  const SheberShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final highlight = isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Placeholder list while orders / masters load.
class SheberShimmerOrderList extends StatelessWidget {
  final bool isDark;
  final int itemCount;

  const SheberShimmerOrderList({
    super.key,
    required this.isDark,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              SheberShimmerBox(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(14),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SheberShimmerBox(width: double.infinity, height: 14, isDark: isDark),
                    const SizedBox(height: 8),
                    SheberShimmerBox(width: 160, height: 12, isDark: isDark),
                    const SizedBox(height: 6),
                    SheberShimmerBox(width: double.infinity, height: 12, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
