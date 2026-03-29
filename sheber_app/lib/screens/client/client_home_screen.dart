import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_state.dart';
import 'create_order_screen.dart';
import 'client_orders_screen.dart';
import '../profile_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = S.lang(app.language);
    final isDark = app.darkMode;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowAlpha = isDark ? 0.25 : 0.05;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ClientMainTab(s: s, isDark: isDark),
          const ClientOrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowAlpha),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: navBg,
          elevation: 0,
          selectedItemColor: const Color(0xFF1CB7FF),
          unselectedItemColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
              activeIcon: const Icon(Icons.add_circle_rounded, size: 28),
              label: s.create,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_rounded, size: 28),
              activeIcon: const Icon(Icons.list_alt_rounded, size: 28),
              label: s.myOrders,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded, size: 28),
              activeIcon: const Icon(Icons.person_rounded, size: 28),
              label: s.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientMainTab extends StatelessWidget {
  final S s;
  final bool isDark;
  const _ClientMainTab({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = app.user?.name ?? s.userDefault;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade500;
    final ctaColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              s.helloName(name),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.whatToFix,
              style: TextStyle(fontSize: 18, color: subtitleColor),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CB7FF),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1CB7FF).withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                          );
                        },
                        child: const Icon(Icons.add_rounded, size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.createOrder,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: ctaColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.clientOrderTeaser,
                    style: TextStyle(fontSize: 16, color: subtitleColor),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
