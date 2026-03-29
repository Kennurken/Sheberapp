import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../l10n/app_strings.dart';
import '../providers/app_state.dart';
import 'main_shell.dart';
import 'profession_select_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  bool _isLoading = false;

  static const _primary = Color(0xFF2563EB);

  Future<void> _selectRole(String role) async {
    final s = S.lang(Provider.of<AppState>(context, listen: false).language);
    setState(() => _isLoading = true);

    try {
      final result = await ApiClient().switchRole(role);
      if (result['ok'] == true) {
        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setRole(role);

        // Also set default city
        const defaultCity = 'Қызылорда';
        if (appState.user?.city.isEmpty ?? true) {
          appState.setSelectedCity(defaultCity);
          appState.setUser(appState.user!.copyWith(city: defaultCity));
          try { await ApiClient().updateProfile({'city': defaultCity}); } catch (_) {}
        }

        if (!mounted) return;
        final Widget next = role == 'master'
            ? const ProfessionSelectScreen()
            : const MainShell();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => next),
          (route) => false,
        );
      } else {
        _showError(s.roleSelectError);
      }
    } catch (e) {
      _showError(s.connectionError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.lang(state.language);
    final isDark = state.darkMode;
    final bgScaffold = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgScaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D3461) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.people_rounded, size: 36, color: _primary),
              ),
              const SizedBox(height: 20),
              Text(
                s.whoAreYou,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s.canChangeRoleLater,
                style: TextStyle(fontSize: 15, color: textGray),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Client card
              _RoleCard(
                icon: Icons.home_work_rounded,
                title: s.clientRoleLabel,
                subtitle: s.roleCardClientSubtitle,
                color: _primary,
                bgColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                isDark: isDark,
                isLoading: _isLoading,
                onTap: () => _selectRole('client'),
              ),

              const SizedBox(height: 16),

              // Master card
              _RoleCard(
                icon: Icons.construction_rounded,
                title: s.masterRoleLabel,
                subtitle: s.roleCardMasterSubtitle,
                color: const Color(0xFF059669),
                bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                isDark: isDark,
                isLoading: _isLoading,
                onTap: () => _selectRole('master'),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.isDark,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isLoading ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: subColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.7), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
