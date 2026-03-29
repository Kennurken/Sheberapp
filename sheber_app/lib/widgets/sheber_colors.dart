import 'package:flutter/material.dart';

/// Parses `#RRGGBB` / `RRGGBB` / `0xFF...` style colors from API.
Color sheberParseHexColor(String hex) {
  try {
    var h = hex.trim();
    if (h.startsWith('#')) {
      h = h.substring(1);
    }
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    if (h.startsWith('0x') || h.startsWith('0X')) {
      return Color(int.parse(h));
    }
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return const Color(0xFF1CB7FF);
  }
}

/// Deterministic accent for list tiles (matches tab_masters / tab_chat).
Color sheberColorFromSeed(int seed) {
  const colors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];
  return colors[seed.abs() % colors.length];
}
