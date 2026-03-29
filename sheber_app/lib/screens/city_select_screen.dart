import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../providers/app_state.dart';
import 'main_shell.dart';
import '../l10n/app_strings.dart';
import '../screens/tabs/tab_city_picker.dart';
import 'profession_select_screen.dart';

class CitySelectScreen extends StatefulWidget {
  final bool isOnboarding;
  const CitySelectScreen({super.key, this.isOnboarding = false});

  @override
  State<CitySelectScreen> createState() => _CitySelectScreenState();
}

class _CitySelectScreenState extends State<CitySelectScreen> {
  String _selected = '';
  bool _saving = false;

  static const _primary = Color(0xFF2563EB);

  Future<void> _confirm() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiClient().updateProfile({'city': _selected});
    } catch (_) {}
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedCity(_selected);
    if (appState.user != null) {
      appState.setUser(appState.user!.copyWith(city: _selected));
    }
    final role = appState.user?.role ?? 'client';
    final Widget next = (widget.isOnboarding && role == 'master')
        ? const ProfessionSelectScreen()
        : const MainShell();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => next),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.lang(context.watch<AppState>().language);
    final isDark = context.watch<AppState>().darkMode;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);
    final cardIdle = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderIdle = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconMuted = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final btnDisabled = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.location_city_rounded, size: 40, color: _primary),
            ),
            const SizedBox(height: 20),

            Text(
              s.chooseYourCity,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(
              s.citySelectOnboardingSub,
              style: TextStyle(fontSize: 15, color: textGray),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // City list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kCities.length,
                itemBuilder: (_, i) {
                  final city = kCities[i];
                  final isSelected = city == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = city),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary : cardIdle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? _primary : borderIdle,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: _primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: isSelected ? Colors.white : iconMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            city,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textDark,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected.isEmpty ? btnDisabled : _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: (_selected.isEmpty || _saving) ? null : _confirm,
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          s.continueBtn,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
