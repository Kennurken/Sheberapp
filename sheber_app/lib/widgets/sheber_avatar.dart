import 'package:flutter/material.dart';
import '../utils/upload_url.dart';
import 'sheber_colors.dart';

/// Avatar: network image, or initial on colored background (hex or seed).
class SheberAvatar extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final int? colorSeed;
  final String? hexBackground;
  final double size;
  /// `null` → circle. Set e.g. `14` for rounded square (master cards).
  final double? cornerRadius;
  final Object? heroTag;

  const SheberAvatar({
    super.key,
    this.imageUrl,
    required this.label,
    this.colorSeed,
    this.hexBackground,
    this.size = 48,
    this.cornerRadius,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final bg = hexBackground != null && hexBackground!.isNotEmpty
        ? sheberParseHexColor(hexBackground!)
        : sheberColorFromSeed(colorSeed ?? label.hashCode);
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    final raw = imageUrl?.trim() ?? '';
    final resolved = raw.isNotEmpty ? resolveUploadUrl(raw) : '';
    final radius = cornerRadius ?? size / 2;

    Widget core;
    if (resolved.isNotEmpty) {
      core = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _InitialTile(
            size: size,
            radius: radius,
            backgroundColor: bg,
            initial: initial,
          ),
        ),
      );
    } else {
      core = _InitialTile(
        size: size,
        radius: radius,
        backgroundColor: bg,
        initial: initial,
      );
    }

    if (heroTag != null) {
      core = Hero(
        tag: heroTag!,
        child: Material(color: Colors.transparent, child: core),
      );
    }
    return core;
  }
}

class _InitialTile extends StatelessWidget {
  final double size;
  final double radius;
  final Color backgroundColor;
  final String initial;

  const _InitialTile({
    required this.size,
    required this.radius,
    required this.backgroundColor,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
