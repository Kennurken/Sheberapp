import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';
import '../../models/user.dart';
import '../main_shell.dart';
import '../profession_select_screen.dart';
import '../profile_edit_screen.dart';
import '../../widgets/master_portfolio_section.dart';
import '../../services/fcm_sync.dart';

class TabProfile extends StatefulWidget {
  final VoidCallback onOpenNavMenu;

  const TabProfile({super.key, required this.onOpenNavMenu});

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        if (state.isLoggedIn) {
          return _LoggedInProfile(
            state: state,
            s: s,
            isDark: isDark,
            onOpenNavMenu: widget.onOpenNavMenu,
          );
        }
        return _AuthScreen(
          tabController: _tabController,
          s: s,
          isDark: isDark,
          onOpenNavMenu: widget.onOpenNavMenu,
        );
      },
    );
  }
}

// ─── Authenticated profile ───────────────────────────────────────────────────

class _LoggedInProfile extends StatefulWidget {
  final AppState state;
  final S s;
  final bool isDark;
  final VoidCallback onOpenNavMenu;

  const _LoggedInProfile({
    required this.state,
    required this.s,
    required this.isDark,
    required this.onOpenNavMenu,
  });

  @override
  State<_LoggedInProfile> createState() => _LoggedInProfileState();
}

class _LoggedInProfileState extends State<_LoggedInProfile> {
  int _completedOrders = 0;
  int _totalOrders = 0;
  /// После закрытия модалки «Профиль» пересобираем портфолио (фото могли добавить там).
  int _portfolioRefreshNonce = 0;

  static const _primary = Color(0xFF2563EB);
  static const _tierMilestones = [5, 15, 30, 50];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final orders = await ApiClient().getMyOrders();
      if (!mounted) return;
      final done = orders.where((o) => o.status == 'completed').length;
      setState(() {
        _totalOrders = orders.length;
        _completedOrders = done;
      });
      // Show tier popup if this milestone hasn't been shown before
      final highestShown = widget.state.highestTierShown;
      if (_tierMilestones.contains(done) && done > highestShown) {
        await widget.state.markTierShown(done);
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showTierPopup(done));
      }
    } catch (_) {}
  }

  void _showTierPopup(int done) {
    final s = widget.s;
    final t = _tier(done);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(color: t.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(t.icon, color: t.color, size: 36),
              ),
              const SizedBox(height: 16),
              Text('🎉', style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                t.label,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: t.color),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s.isKz
                    ? '$done тапсырыс аяқталды! Сізге жаңа деңгей берілді.'
                    : '$done заказов выполнено! Вам открыт новый уровень.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              if (t.benefit.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(t.benefit, style: TextStyle(fontSize: 13, color: t.color, fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.confirm, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF3B82F6), Color(0xFF8B5CF6),
      Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  // ── Gamification tier ──────────────────────────────────────────────────────

  _GamTier _tier(int done) {
    if (done >= 50) return _GamTier(label: widget.s.tierGold,         color: const Color(0xFFD97706), icon: Icons.emoji_events_rounded,   benefit: widget.s.benefitGold,         next: 0);
    if (done >= 30) return _GamTier(label: widget.s.tierExpert,       color: const Color(0xFF7C3AED), icon: Icons.verified_rounded,        benefit: widget.s.benefitRecommended,  next: 50 - done);
    if (done >= 15) return _GamTier(label: widget.s.tierProfessional, color: const Color(0xFF2563EB), icon: Icons.workspace_premium_rounded, benefit: widget.s.benefitVerified,    next: 30 - done);
    if (done >= 5)  return _GamTier(label: widget.s.tierActive,       color: const Color(0xFF059669), icon: Icons.trending_up_rounded,     benefit: widget.s.benefitSearch,       next: 15 - done);
    return           _GamTier(label: widget.s.tierNewcomer,            color: const Color(0xFF64748B), icon: Icons.person_outline_rounded,  benefit: '',                           next: 5 - done);
  }

  // ── Edit profile (отдельный route вместо bottom sheet) ────────────────────

  Future<void> _openEditProfile() async {
    final user = widget.state.user!;
    final updated = await Navigator.of(context).push<User?>(
      MaterialPageRoute<User?>(
        fullscreenDialog: true,
        builder: (ctx) => ProfileEditScreen(
          initialUser: user,
          s: widget.s,
          isMaster: widget.state.role == 'master',
          isDark: widget.isDark,
        ),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      context.read<AppState>().setUser(updated);
    }
    setState(() => _portfolioRefreshNonce++);
  }

  // ── Immediate role change ─────────────────────────────────────────────────

  void _openRoleChange() {
    final s = widget.s;
    final isDark = widget.isDark;
    final currentRole = widget.state.role;

    showDialog(
      context: context,
      builder: (ctx) {
        bool switching = false;
        return StatefulBuilder(builder: (ctx, setS) {
          final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
          final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
          final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

          Widget roleCard(String role, IconData icon, Color color, Color bg2) {
            final isActive = role == currentRole;
            return GestureDetector(
              onTap: switching || isActive ? null : () async {
                final appState = Provider.of<AppState>(context, listen: false);
                setS(() => switching = true);
                try {
                  final res = await ApiClient().switchRole(role);
                  if (res['ok'] == true) {
                    appState.setRole(role);
                  }
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.1) : bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        role == 'master' ? s.masterRoleLabel : s.clientRoleLabel,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isActive ? color : textDark),
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle_rounded, color: color, size: 22)
                    else if (switching)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(s.changeRole, style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.currentRoleLabel(currentRole), style: TextStyle(fontSize: 13, color: textGray)),
                const SizedBox(height: 16),
                roleCard('client', Icons.home_work_rounded, _primary, const Color(0xFFEFF6FF)),
                const SizedBox(height: 10),
                roleCard('master', Icons.construction_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          );
        });
      },
    );
  }

  // ── Notifications dialog ────────────────────────────────────────────────────

  void _openNotifications() {
    showDialog(
      context: context,
      builder: (_) {
        return Consumer<AppState>(
          builder: (ctx, appState, _) {
            final s = widget.s;
            final isDark = widget.isDark;
            final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
            return AlertDialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(s.notifTitle, style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: appState.notificationsEnabled,
                    onChanged: (v) => appState.setNotifications(v),
                    activeThumbColor: _primary,
                    title: Text(s.notifPush, style: TextStyle(fontWeight: FontWeight.w500, color: textDark, fontSize: 15)),
                    subtitle: Text(s.notifPushSub, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: appState.notificationsEnabled,
                    onChanged: (v) => appState.setNotifications(v),
                    activeThumbColor: _primary,
                    title: Text(s.notifEmail, style: TextStyle(fontWeight: FontWeight.w500, color: textDark, fontSize: 15)),
                    subtitle: Text(s.notifEmailSub, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(widget.s.confirm, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  void _logout() {
    final s = widget.s;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.logoutLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(s.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AppState>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainShell()),
                (route) => false,
              );
            },
            child: Text(s.logoutLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isDark = widget.isDark;
    final state = widget.state;
    final user = state.user!;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    final name = user.name.isNotEmpty ? user.name : s.userDefault;
    final color = _avatarColor(name);
    final isMaster = state.role == 'master';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.menu_rounded, color: textDark, size: 26),
                  onPressed: widget.onOpenNavMenu,
                ),
              ),
              // Header — seamless with background
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'П',
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 4),
                    if (user.profession.isNotEmpty) ...[
                      Text(user.profession, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      const SizedBox(height: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isMaster
                            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                            : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isMaster ? s.masterRoleLabel : s.clientRoleLabel,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isMaster ? const Color(0xFF10B981) : _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(label: s.ordersLabel, value: _totalOrders.toString(), icon: Icons.assignment_rounded, isDark: isDark),
                    const SizedBox(width: 10),
                    _StatCard(label: s.statDone, value: _completedOrders.toString(), icon: Icons.check_circle_outline_rounded, isDark: isDark),
                    const SizedBox(width: 10),
                    _StatCard(label: s.ratingLabel, value: '—', icon: Icons.star_rounded, isDark: isDark),
                  ],
                ),
              ),

              // Gamification (masters only)
              if (isMaster) ...[
                const SizedBox(height: 12),
                _buildGamification(isDark, textDark),
              ],

              if (isMaster) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(s.tabPortfolio,
                      style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MasterPortfolioSection(
                    key: ValueKey(_portfolioRefreshNonce),
                    isDark: isDark,
                    s: s,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Settings menu
              _MenuSection(
                title: s.settingsSection,
                isDark: isDark,
                items: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: s.editProfile,
                    onTap: _openEditProfile,
                    isDark: isDark,
                  ),
                  _MenuItem(
                    icon: Icons.swap_horiz_rounded,
                    label: s.changeRole,
                    subtitle: s.currentRoleLabel(state.role),
                    onTap: _openRoleChange,
                    isDark: isDark,
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: s.notificationsLabel,
                    onTap: _openNotifications,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _MenuSection(
                title: s.additionalSettings,
                isDark: isDark,
                items: [
                  _MenuItem(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                    label: s.darkModeLabel,
                    isDark: isDark,
                    trailing: Switch(
                      value: state.darkMode,
                      onChanged: (_) => Provider.of<AppState>(context, listen: false).toggleDarkMode(),
                      activeThumbColor: _primary,
                    ),
                    onTap: null,
                  ),
                  _MenuItem(
                    icon: Icons.language_rounded,
                    label: s.languageLabel,
                    isDark: isDark,
                    trailing: _LangToggle(isDark: isDark),
                    onTap: null,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _MenuSection(
                isDark: isDark,
                items: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: s.logoutLabel,
                    iconColor: const Color(0xFFEF4444),
                    labelColor: const Color(0xFFEF4444),
                    onTap: _logout,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamification(bool isDark, Color textDark) {
    final s = widget.s;
    final t = _tier(_completedOrders);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Progress within tier
    final (tierMin, tierMax) = _tierRange(_completedOrders);
    final progress = tierMax > tierMin
        ? ((_completedOrders - tierMin) / (tierMax - tierMin)).clamp(0.0, 1.0)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(t.icon, color: t.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.color)),
                      if (t.benefit.isNotEmpty)
                        Text(t.benefit, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text(
                  '$_completedOrders',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: t.color),
                ),
              ],
            ),
            if (t.next > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(t.color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${t.next} ${s.ordersToNextLevel}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (int, int) _tierRange(int done) {
    if (done >= 50) return (50, 50);
    if (done >= 30) return (30, 50);
    if (done >= 15) return (15, 30);
    if (done >= 5)  return (5, 15);
    return (0, 5);
  }
}

class _GamTier {
  final String label;
  final Color color;
  final IconData icon;
  final String benefit;
  final int next;
  const _GamTier({required this.label, required this.color, required this.icon, required this.benefit, required this.next});
}

// ─── Auth screen ─────────────────────────────────────────────────────────────

class _AuthScreen extends StatelessWidget {
  final TabController tabController;
  final S s;
  final bool isDark;
  final VoidCallback onOpenNavMenu;

  const _AuthScreen({
    required this.tabController,
    required this.s,
    required this.isDark,
    required this.onOpenNavMenu,
  });

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu_rounded, color: textDark, size: 26),
                    onPressed: onOpenNavMenu,
                  ),
                  Expanded(
                    child: Text(
                      s.personalCabinet,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),

              // Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 16, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
                      child: TabBar(
                        controller: tabController,
                        labelColor: _primary,
                        unselectedLabelColor: textGray,
                        indicatorColor: _primary,
                        indicatorWeight: 2.5,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        tabs: [Tab(text: s.loginTabLabel), Tab(text: s.registerTabLabel)],
                      ),
                    ),
                    SizedBox(
                      height: 340,
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _LoginForm(isDark: isDark, s: s),
                          _RegisterForm(isDark: isDark, s: s),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SMS info hidden — WhatsApp Business API coming soon

              const SizedBox(height: 24),

              // SMS auth hidden — will be replaced with WhatsApp Business API
              // SizedBox(SMS button),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login form (email + password) ──────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  final bool isDark;
  final S s;
  const _LoginForm({required this.isDark, required this.s});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _primary = Color(0xFF2563EB);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().emailLogin(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      if (res['ok'] == true) {
        final user = User.fromJson(res['user'] as Map<String, dynamic>);
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setUser(user);
        if (res['csrf_token'] != null) {
          appState.setCsrfToken(res['csrf_token'].toString());
          ApiClient().setCsrfToken(res['csrf_token'].toString());
        }
        await syncFcmTokenToServer();
        if (user.city.isNotEmpty) appState.setSelectedCity(user.city);
      } else {
        final code = res['error']?.toString() ?? '';
        setState(() => _error = _errorMsg(code));
      }
    } catch (e) {
      setState(() => _error = widget.s.loadError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMsg(String code) {
    switch (code) {
      case 'invalid_credentials': return widget.s.invalidCredentials;
      case 'password_too_short': return widget.s.passwordTooShort;
      case 'invalid_email': return widget.s.invalidEmailFormat;
      case 'db_error':
      case 'server_error': return widget.s.errServerError;
      default: return widget.s.loadError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isDark = widget.isDark;
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final textStyle = TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _emailCtrl,
            style: textStyle,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: s.yourEmailHint,
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
              filled: true, fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            style: textStyle,
            decoration: InputDecoration(
              hintText: s.passwordHint,
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
              filled: true, fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(s.enterLoginBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Register form (name + email + password) ─────────────────────────────────

class _RegisterForm extends StatefulWidget {
  final bool isDark;
  final S s;
  const _RegisterForm({required this.isDark, required this.s});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String _role = 'client'; // 'client' or 'master'

  static const _primary = Color(0xFF2563EB);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().emailRegister(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        role: _role,
      );
      if (!mounted) return;
      if (res['ok'] == true) {
        final user = User.fromJson(res['user'] as Map<String, dynamic>);
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setUser(user);
        if (res['csrf_token'] != null) {
          appState.setCsrfToken(res['csrf_token'].toString());
          ApiClient().setCsrfToken(res['csrf_token'].toString());
        }
        await syncFcmTokenToServer();
        if (!mounted) return;
        if (user.city.isNotEmpty) appState.setSelectedCity(user.city);
        if (_role == 'master') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ProfessionSelectScreen()),
            (route) => false,
          );
        }
      } else {
        final code = res['error']?.toString() ?? '';
        setState(() => _error = _errorMsg(code));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[emailRegister] ERROR: $e');
      // Extract error code from DioException response body if available
      String code = '';
      if (e is DioException && e.response?.data is Map) {
        code = (e.response!.data as Map)['error']?.toString() ?? '';
      }
      setState(() => _error = code.isNotEmpty ? _errorMsg(code) : widget.s.errServerError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMsg(String code) {
    switch (code) {
      case 'email_taken':        return widget.s.emailTaken;
      case 'password_too_short': return widget.s.passwordTooShort;
      case 'missing_fields':     return widget.s.errFillAllFields;
      case 'invalid_email':      return widget.s.invalidEmailFormat;
      case 'db_error':
      case 'server_error':       return widget.s.errServerError;
      default: return widget.s.loadError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isDark = widget.isDark;
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final textStyle = TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              style: textStyle,
              decoration: InputDecoration(
                hintText: s.fullNameHint,
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF94A3B8)),
                filled: true, fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtrl,
              style: textStyle,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: s.yourEmailHint,
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
                filled: true, fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              style: textStyle,
              decoration: InputDecoration(
                hintText: s.passwordHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
                filled: true, fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            // Role selector
            Row(
              children: [
                Expanded(child: _RoleCard(
                  label: s.clientRoleLabel,
                  icon: Icons.person_outline_rounded,
                  selected: _role == 'client',
                  isDark: isDark,
                  onTap: () => setState(() => _role = 'client'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _RoleCard(
                  label: s.masterRoleLabel,
                  icon: Icons.engineering_rounded,
                  selected: _role == 'master',
                  isDark: isDark,
                  onTap: () => setState(() => _role = 'master'),
                )),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(s.registerBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatCard({required this.label, required this.value, required this.icon, required this.isDark});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: textGray), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String? title;
  final List<_MenuItem> items;
  final bool isDark;

  const _MenuSection({this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final titleColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor, letterSpacing: 0.3),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final isLast = e.key == items.length - 1;
                return Column(
                  children: [
                    e.value,
                    if (!isLast) Divider(height: 1, indent: 54, color: dividerColor),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.labelColor,
    this.trailing,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final effectiveIconColor = iconColor ?? const Color(0xFF2563EB);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: effectiveIconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: effectiveIconColor),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: labelColor ?? textDark),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 12, color: textGray))
          : null,
      trailing: trailing ??
          (onTap != null ? const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22) : null),
      onTap: onTap,
    );
  }
}

class _LangToggle extends StatelessWidget {
  final bool isDark;
  const _LangToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangBtn(lang: 'kz', label: 'KZ', isActive: state.language == 'kz', isDark: isDark),
          const SizedBox(width: 4),
          _LangBtn(lang: 'ru', label: 'RU', isActive: state.language == 'ru', isDark: isDark),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String lang;
  final String label;
  final bool isActive;
  final bool isDark;

  const _LangBtn({required this.lang, required this.label, required this.isActive, required this.isDark});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final inactiveBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    return GestureDetector(
      onTap: () => Provider.of<AppState>(context, listen: false).setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _primary : inactiveBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ─── Role selector card ───────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _RoleCard({required this.label, required this.icon, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);
    final bg = selected
        ? primary.withValues(alpha: 0.12)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC));
    final border = selected ? primary : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0));
    final textColor = selected ? primary : (isDark ? Colors.white70 : const Color(0xFF64748B));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }
}
