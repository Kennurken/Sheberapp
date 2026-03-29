import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/app_state.dart';

/// Экран «Вопросы и ответы» из бокового меню.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
        final card = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        Widget block(String q, String a) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark, height: 1.3)),
                  const SizedBox(height: 8),
                  Text(a, style: TextStyle(fontSize: 14, color: textGray, height: 1.45)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: textDark,
            elevation: 0,
            title: Text(s.navDrawerFaq, style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              block(s.faqHowToOrderQ, s.faqHowToOrderA),
              block(s.faqHowToPayQ, s.faqHowToPayA),
              block(s.faqSupportQ, s.faqSupportA),
              const SizedBox(height: 8),
              Text(
                'Sheber.kz',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary.withValues(alpha: 0.9)),
              ),
            ],
          ),
        );
      },
    );
  }
}
