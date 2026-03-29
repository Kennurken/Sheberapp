import 'package:flutter/material.dart';

/// Unified category list — mirrors the `categories` table in the DB.
/// Used by both client order creation and master profession selection.
class AppCategory {
  final int id;           // DB category id (1–8)
  final String profId;    // profession string stored in users.profession
  final String nameKz;
  final String nameRu;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.id,
    required this.profId,
    required this.nameKz,
    required this.nameRu,
    required this.icon,
    required this.color,
  });

  String name(String lang) => lang == 'kz' ? nameKz : nameRu;
}

const List<AppCategory> kAppCategories = [
  AppCategory(id: 1, profId: 'plumber',     nameKz: 'Сантехника',    nameRu: 'Сантехника',   icon: Icons.plumbing_rounded,              color: Color(0xFF3B82F6)),
  AppCategory(id: 2, profId: 'electrician', nameKz: 'Электрик',       nameRu: 'Электрик',     icon: Icons.electrical_services_rounded,   color: Color(0xFFF59E0B)),
  AppCategory(id: 3, profId: 'repair',      nameKz: 'Жөндеу',         nameRu: 'Ремонт',       icon: Icons.home_repair_service_rounded,   color: Color(0xFF8B5CF6)),
  AppCategory(id: 4, profId: 'cleaner',     nameKz: 'Тазалық',        nameRu: 'Уборка',       icon: Icons.cleaning_services_rounded,     color: Color(0xFF10B981)),
  AppCategory(id: 5, profId: 'windows',     nameKz: 'Терезе',         nameRu: 'Окна',         icon: Icons.window_rounded,                color: Color(0xFF06B6D4)),
  AppCategory(id: 6, profId: 'painter',     nameKz: 'Бояу',           nameRu: 'Покраска',     icon: Icons.format_paint_rounded,          color: Color(0xFFEF4444)),
  AppCategory(id: 7, profId: 'carpenter',   nameKz: 'Ағаш жұмысы',   nameRu: 'Плотник',      icon: Icons.carpenter_rounded,             color: Color(0xFF78716C)),
  AppCategory(id: 8, profId: 'other',       nameKz: 'Басқа',          nameRu: 'Другое',       icon: Icons.more_horiz_rounded,            color: Color(0xFF6366F1)),
];
