import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/feature_flags.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/categories.dart';
import '../client/create_order_screen.dart';
import '../main_shell.dart';

class TabHome extends StatelessWidget {
  final VoidCallback onOpenNavMenu;

  const TabHome({super.key, required this.onOpenNavMenu});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header: hamburger + logo + notification ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        // Drawer / settings button
                        IconButton(
                          icon: Icon(Icons.menu_rounded, color: textDark, size: 28),
                          onPressed: onOpenNavMenu,
                        ),
                        const SizedBox(width: 4),
                        // Logo
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Sheber',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const TextSpan(
                                text: '.kz',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Notification bell
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: textDark,
                                size: 26,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.isKz ? 'Хабарландырулар жоқ' : 'Нет уведомлений'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Ad banner carousel ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: SizedBox(
                      height: 180,
                      child: _BannerCarousel(isDark: isDark, s: s),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search card
                        _SearchCard(s: s, isDark: isDark),

                        const SizedBox(height: 24),

                        // Categories header
                        Row(
                          children: [
                            Text(
                              s.categories,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                final shellState = context.findAncestorStateOfType<MainShellState>();
                                shellState?.switchToTab(3);
                              },
                              child: Text(
                                s.isKz ? 'Барлығы' : 'Все',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Horizontal category scroll
                        _CategoriesRow(s: s, isDark: isDark),

                        const SizedBox(height: 28),

                        // How it works
                        Text(
                          s.howItWorks,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _StepCard(
                          number: '1',
                          title: s.step1Title,
                          subtitle: s.step1Sub,
                          icon: Icons.post_add_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _StepCard(
                          number: '2',
                          title: s.step2Title,
                          subtitle: s.step2Sub,
                          icon: Icons.local_offer_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _StepCard(
                          number: '3',
                          title: s.step3Title,
                          subtitle: s.step3Sub,
                          icon: Icons.chat_rounded,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

// ── Banner carousel ──────────────────────────────────────────────────────────

class _BannerCarousel extends StatelessWidget {
  final bool isDark;
  final S s;
  const _BannerCarousel({required this.isDark, required this.s});

  @override
  Widget build(BuildContext context) {
    final banners = <_BannerData>[
      _BannerData(
        title: s.bannerPartnerStoreTitle,
        subtitle: s.bannerPartnerStoreSubtitle,
        gradientColors: [const Color(0xFF1B8A2E), const Color(0xFF2E7D32)],
        icon: Icons.store_rounded,
      ),
      if (kShowPremiumHomeBanner)
        _BannerData(
          title: s.bannerPremiumTitle,
          subtitle: s.bannerPremiumSubtitle,
          gradientColors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          icon: Icons.workspace_premium_rounded,
        ),
      _BannerData(
        title: s.bannerAdSlotTitle,
        subtitle: s.bannerAdSlotSubtitle,
        gradientColors: isDark
            ? [const Color(0xFF1D3461), const Color(0xFF1E3A5F)]
            : [const Color(0xFF1CB7FF), const Color(0xFF2563EB)],
        icon: Icons.campaign_rounded,
        opensAdDialog: true,
      ),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: banners.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final b = banners[i];
        return GestureDetector(
          onTap: () => _onBannerTap(context, b),
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: b.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: b.gradientColors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background icon
                Positioned(
                  right: -20, bottom: -20,
                  child: Icon(b.icon, size: 120, color: Colors.white.withValues(alpha: 0.1)),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(b.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          b.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBannerTap(BuildContext context, _BannerData banner) {
    if (!banner.opensAdDialog) return;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.advertiseDialogTitle),
          content: Text(s.advertiseDialogBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(s.reportClose)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: Text(s.whatsappLabel),
              onPressed: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('https://wa.me/77028301616'), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final bool opensAdDialog;
  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    this.opensAdDialog = false,
  });
}

// ── Search card ──────────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final S s;
  final bool isDark;
  const _SearchCard({required this.s, required this.isDark});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D3461) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded, size: 14, color: _primary),
                const SizedBox(width: 4),
                Text(
                  s.searchFree,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            s.findNearby,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.cityLabel}: Қызылорда',
            style: TextStyle(fontSize: 14, color: textGray),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.search_rounded, size: 20),
              label: Text(
                s.findMaster,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                final shellState = context.findAncestorStateOfType<MainShellState>();
                shellState?.switchToTab(3);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal categories row ────────────────────────────────────────────────

class _CategoriesRow extends StatelessWidget {
  final S s;
  final bool isDark;
  const _CategoriesRow({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kAppCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, i) => _CategoryItem(category: kAppCategories[i], isDark: isDark),
      ),
    );
  }
}

// ── Category item (vertical: icon card + label) ──────────────────────────────

class _CategoryItem extends StatelessWidget {
  final AppCategory category;
  final bool isDark;
  const _CategoryItem({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppState>(context, listen: false).language;
    final textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return GestureDetector(
      onTap: () {
        final state = Provider.of<AppState>(context, listen: false);
        if (!state.isLoggedIn || state.user?.role != 'client') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.language == 'kz'
                    ? 'Тапсырыс беру үшін клиент ретінде кіріңіз'
                    : 'Войдите как клиент, чтобы создать заказ',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateOrderScreen(initialCategoryId: category.id),
          ),
        );
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isDark
                    ? category.color.withValues(alpha: 0.15)
                    : category.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: category.color.withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(category.icon, color: category.color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              category.name(lang),
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step card (how it works) ─────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;

  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
  });

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D3461) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: textGray),
                ),
              ],
            ),
          ),
          Icon(icon, color: _primary, size: 24),
        ],
      ),
    );
  }
}
