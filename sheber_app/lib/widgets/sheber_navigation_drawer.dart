import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../providers/app_state.dart';

const _kNavPrimary = Color(0xFF2563EB);

/// Выдвижное меню слева: навигация по разделам, тема/язык, поддержка, подпись Mili-tech.
class SheberNavigationDrawer extends StatelessWidget {
  final BuildContext drawerContext;
  final int currentTabIndex;
  final int unreadChatCount;
  final void Function(int tabIndex) onSelectTab;
  final VoidCallback onOpenFaq;
  final VoidCallback onOpenSupport;

  static const _wa = 'https://wa.me/77028301616';

  const SheberNavigationDrawer({
    super.key,
    required this.drawerContext,
    required this.currentTabIndex,
    required this.unreadChatCount,
    required this.onSelectTab,
    required this.onOpenFaq,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final tileIconColor = _kNavPrimary;

        final w = math.min(MediaQuery.sizeOf(context).width * 0.88, 320.0);

        return Drawer(
          width: w,
          backgroundColor: bg,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: headerBg,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(drawerContext);
                      onSelectTab(0);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Sheber',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                                    ),
                                    const TextSpan(
                                      text: '.kz',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kNavPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(s.navDrawerHomeHint, style: TextStyle(fontSize: 13, color: textGray)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _DrawerTile(
                        icon: Icons.person_rounded,
                        color: tileIconColor,
                        title: s.navProfile,
                        selected: currentTabIndex == 4,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(drawerContext);
                          onSelectTab(4);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.location_city_rounded,
                        color: tileIconColor,
                        title: s.navDrawerMastersInCity,
                        selected: currentTabIndex == 3,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(drawerContext);
                          onSelectTab(3);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.chat_bubble_rounded,
                        color: tileIconColor,
                        title: s.navDrawerMessages,
                        badge: unreadChatCount,
                        selected: currentTabIndex == 1,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(drawerContext);
                          onSelectTab(1);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.call_rounded,
                        color: tileIconColor,
                        title: s.navDrawerMastersDirect,
                        subtitle: s.navDrawerMastersDirectSub,
                        selected: false,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(drawerContext);
                          onSelectTab(3);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.help_outline_rounded,
                        color: tileIconColor,
                        title: s.navDrawerFaq,
                        selected: false,
                        isDark: isDark,
                        onTap: onOpenFaq,
                      ),
                      _DrawerTile(
                        icon: Icons.support_agent_rounded,
                        color: const Color(0xFF10B981),
                        title: s.supportServiceMenu,
                        selected: false,
                        isDark: isDark,
                        onTap: onOpenSupport,
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: Icon(Icons.language_rounded, color: tileIconColor),
                        title: Text(
                          s.isKz ? 'Тіл / Язык' : 'Язык / Тіл',
                          style: TextStyle(color: textDark, fontWeight: FontWeight.w500),
                        ),
                        trailing: _DrawerLangToggle(
                          state: state,
                          drawerContext: drawerContext,
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? Colors.amber : textGray,
                        ),
                        title: Text(
                          isDark ? s.navDrawerLightTheme : s.navDrawerDarkTheme,
                          style: TextStyle(color: textDark, fontWeight: FontWeight.w500),
                        ),
                        onTap: () {
                          // Закрыть drawer до notifyListeners: иначе Selector в main.dart
                          // пересобирает MaterialApp пока route drawer ещё в дереве → _dependents.isEmpty.
                          Navigator.pop(drawerContext);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            state.toggleDarkMode();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      Icon(Icons.apartment_rounded, size: 28, color: textGray.withValues(alpha: 0.6)),
                      const SizedBox(height: 6),
                      Text(
                        s.corporateFooterLine1,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.corporateFooterLine2,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: textGray, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> launchSupport() async {
    final u = Uri.parse(_wa);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }
}

class _DrawerLangToggle extends StatelessWidget {
  final AppState state;
  final BuildContext drawerContext;

  const _DrawerLangToggle({
    required this.state,
    required this.drawerContext,
  });

  @override
  Widget build(BuildContext context) {
    final isKz = state.language == 'kz';
    final isDark = state.darkMode;
    return GestureDetector(
      onTap: () {
        Navigator.pop(drawerContext);
        final next = isKz ? 'ru' : 'kz';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.setLanguage(next);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isKz
              ? _kNavPrimary
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ҚАЗ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isKz ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            Text('·', style: TextStyle(fontSize: 11, color: isKz ? Colors.white70 : const Color(0xFF94A3B8))),
            const SizedBox(width: 4),
            Text(
              'РУС',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isKz ? Colors.white70 : _kNavPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool isDark;
  final int badge;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bg = selected ? color.withValues(alpha: 0.12) : Colors.transparent;
    return Material(
      color: bg,
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 24),
            if (badge > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: textDark)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 12, color: textGray)) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
