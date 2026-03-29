import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import 'main_shell.dart';

class DiplomaScreen extends StatefulWidget {
  const DiplomaScreen({super.key});

  @override
  State<DiplomaScreen> createState() => _DiplomaScreenState();
}

class _DiplomaScreenState extends State<DiplomaScreen> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  bool _saving = false;

  static const _primary = Color(0xFF2563EB);

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addField() {
    if (_controllers.length >= 5) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeField(int index) {
    if (_controllers.length <= 1) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    final diplomas = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (diplomas.isEmpty) {
      _goToMain();
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiClient().updateProfile({'bio': diplomas.join('\n')});
    } catch (_) {}
    if (!mounted) return;
    _goToMain();
  }

  void _goToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
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
    final fieldFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final addRowBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final addRowBorder = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

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
              child: const Icon(Icons.workspace_premium_outlined, size: 36, color: _primary),
            ),
            const SizedBox(height: 16),
            Text(
              s.diplomaTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              s.diplomaSubtitle,
              style: TextStyle(fontSize: 14, color: textSub),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Diploma fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ...List.generate(_controllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[i],
                                style: TextStyle(fontSize: 15, color: textMain),
                                decoration: InputDecoration(
                                  hintText: '${s.diplomaHint} ${i + 1}',
                                  hintStyle: TextStyle(color: hintColor),
                                  filled: true,
                                  fillColor: fieldFill,
                                  prefixIcon: const Icon(Icons.verified_outlined, color: Color(0xFF2563EB), size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _primary, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            if (_controllers.length > 1) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeField(i),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    if (_controllers.length < 5)
                      GestureDetector(
                        onTap: _addField,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: addRowBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: addRowBorder, style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, color: _primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                s.addDiploma,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _saving ? null : _save,
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
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _saving ? null : _goToMain,
                    child: Text(
                      s.skipForNow,
                      style: TextStyle(fontSize: 15, color: textSub),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
