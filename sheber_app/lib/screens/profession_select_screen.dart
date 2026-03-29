import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import '../l10n/categories.dart';
import 'diploma_screen.dart';

class ProfessionSelectScreen extends StatefulWidget {
  const ProfessionSelectScreen({super.key});

  @override
  State<ProfessionSelectScreen> createState() => _ProfessionSelectScreenState();
}

class _ProfessionSelectScreenState extends State<ProfessionSelectScreen> {
  int _selectedCatId = 0;   // DB category id (1–8)
  bool _saving = false;

  static const _primary = Color(0xFF2563EB);

  Future<void> _confirm() async {
    if (_selectedCatId == 0) return;
    setState(() => _saving = true);

    final cat = kAppCategories.firstWhere((c) => c.id == _selectedCatId);

    try {
      await ApiClient().updateProfile({
        'profession': cat.profId,
        'profession_category_id': _selectedCatId,
      });
    } catch (_) {}

    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.user != null) {
      appState.setUser(appState.user!.copyWith(profession: cat.profId));
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DiplomaScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lang = app.language;
    final s = S.lang(lang);
    final isDark = app.darkMode;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);
    final cardIdle = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderIdle = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final btnDisabled = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Icon + titles
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.engineering_rounded, size: 36, color: _primary),
            ),
            const SizedBox(height: 16),
            Text(
              s.professionTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              s.professionSubtitle,
              style: TextStyle(fontSize: 14, color: textSub),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: kAppCategories.length,
                itemBuilder: (_, i) {
                  final cat = kAppCategories[i];
                  final isSelected = cat.id == _selectedCatId;
                  final label = cat.name(lang);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCatId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color : cardIdle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? cat.color : borderIdle,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: cat.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.icon, size: 32, color: isSelected ? Colors.white : cat.color),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textMain,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    backgroundColor: _selectedCatId == 0 ? btnDisabled : _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: (_selectedCatId == 0 || _saving) ? null : _confirm,
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          s.saveAndContinue,
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
