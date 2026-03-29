import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final user = state.user;
        final isPremium = user?.isPremium ?? false;
        final daysLeft = user?.premiumDaysLeft ?? 0;
        final isTrial = (user?.subscriptionIsTrial ?? false) && isPremium;
        // Format trial end date as "19 апр." / "19 сәу."
        final trialEndLabel = _formatTrialEnd(user?.subscriptionExpiresAt, s.isKz);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: cardBg,
            title: Text(
              s.subscriptionTitle,
              style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: textDark),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current status banner
                if (isPremium)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isTrial
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isTrial
                              ? Icons.card_giftcard_rounded
                              : Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTrial ? s.subTrialPeriod : s.subPremiumActiveLabel,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                isTrial
                                    ? s.subTrialUntilDays(trialEndLabel, daysLeft)
                                    : s.subDaysLeftLine(daysLeft),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Color(0xFFF59E0B), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.subFreeTierPitch,
                            style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Comparison cards
                Row(
                  children: [
                    Expanded(child: _TierCard(
                      title: s.tierFreeLabel,
                      price: s.freePlan,
                      color: const Color(0xFF64748B),
                      isActive: !isPremium,
                      activeBadgeText: s.subStatusActiveShort,
                      features: [
                        _Feature(s.subFeatLast10Orders, true),
                        _Feature(s.subFeat5OrdersMonth, true),
                        _Feature(s.subFeatEditReview, false),
                        _Feature(s.subFeatVerifiedBadge, false),
                        _Feature(s.subFeatHigherSearch, false),
                      ],
                      isDark: isDark,
                      cardBg: cardBg,
                      textDark: textDark,
                      textGray: textGray,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _TierCard(
                      title: s.tierPremiumLabel,
                      price: s.subPriceMonthly,
                      color: const Color(0xFF6366F1),
                      isActive: isPremium,
                      activeBadgeText: s.subStatusActiveShort,
                      features: [
                        _Feature(s.subFeatAllOrders, true),
                        _Feature(s.subFeatUnlimitedOrders, true),
                        _Feature(s.subFeatEditReview3d, true),
                        _Feature(s.subFeatVerifiedBadge, true),
                        _Feature(s.subFeatHigherSearch, true),
                      ],
                      isDark: isDark,
                      cardBg: cardBg,
                      textDark: textDark,
                      textGray: textGray,
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                if (!isPremium)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.subBillingPauseNote,
                            style: TextStyle(color: textDark, fontSize: 14, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Format a DateTime as "19 апр." (ru) or "19 сәу." (kz)
String _formatTrialEnd(DateTime? dt, bool isKz) {
  if (dt == null) return '';
  const ruMonths = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
  const kzMonths = ['қаң', 'ақп', 'нау', 'сәу', 'мам', 'мау', 'шіл', 'там', 'қыр', 'қаз', 'қар', 'жел'];
  final months = isKz ? kzMonths : ruMonths;
  final m = months[dt.month - 1];
  return '${dt.day} $m.';
}

class _Feature {
  final String text;
  final bool enabled;
  const _Feature(this.text, this.enabled);
}

class _TierCard extends StatelessWidget {
  final String title;
  final String price;
  final Color color;
  final bool isActive;
  final String activeBadgeText;
  final List<_Feature> features;
  final bool isDark;
  final Color cardBg;
  final Color textDark;
  final Color textGray;

  const _TierCard({
    required this.title,
    required this.price,
    required this.color,
    required this.isActive,
    required this.activeBadgeText,
    required this.features,
    required this.isDark,
    required this.cardBg,
    required this.textDark,
    required this.textGray,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withAlpha(40), blurRadius: 16, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(price, style: TextStyle(fontSize: 13, color: textGray)),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Text(activeBadgeText, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  f.enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 16,
                  color: f.enabled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(f.text, style: TextStyle(fontSize: 12, color: f.enabled ? textDark : textGray))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
