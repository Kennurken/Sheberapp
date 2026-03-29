import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import '../widgets/sheber_navigation_drawer.dart';
import 'faq_screen.dart';
import 'tabs/tab_home.dart';
import 'tabs/tab_chat.dart';
import 'tabs/tab_masters.dart';
import 'tabs/tab_profile.dart';
import 'client/create_order_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _notifTimer;

  static const _primary = Color(0xFF2563EB);

  final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();

  // GlobalKey so we can call reload() on TabChatState from here
  final _chatKey = GlobalKey<TabChatState>();

  @override
  void initState() {
    super.initState();
    _pollNotifications();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollNotifications());
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollNotifications() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (!state.isLoggedIn) return;
    try {
      final count = await ApiClient().getUnreadNotifications();
      if (mounted && count != _unreadCount) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  void _switchToChat() {
    setState(() {
      _currentIndex = 1;
      _unreadCount = 0;
    });
    _chatKey.currentState?.reload();
  }

  /// Public method for child widgets to switch tabs (e.g., TabHome → Masters)
  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openDrawer() {
    _shellScaffoldKey.currentState?.openDrawer();
  }

  void _onSelectTabFromDrawer(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) _unreadCount = 0;
    });
    if (index == 1) _chatKey.currentState?.reload();
  }

  void _onPlusTap() {
    final state = Provider.of<AppState>(context, listen: false);
    if (!state.isLoggedIn) {
      setState(() => _currentIndex = 4);
      return;
    }
    if (state.role == 'master') {
      final s = S.lang(state.language);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.switchToClientForOrder),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()))
        .then((_) => _switchToChat());
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) _unreadCount = 0;
    });
    if (index == 1) _chatKey.currentState?.reload();
  }

  Widget _bottomNavItem({
    required BuildContext context,
    required AppState state,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isDark = state.darkMode;
    final selected = _currentIndex == index;
    final inactive = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final color = selected ? _primary : inactive;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (index == 1 && _unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void openFaqFromDrawer(BuildContext drawerCtx) {
      Navigator.pop(drawerCtx);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FaqScreen()));
    }

    void openSupportFromDrawer(BuildContext drawerCtx) {
      Navigator.pop(drawerCtx);
      SheberNavigationDrawer.launchSupport();
    }

    return Scaffold(
      key: _shellScaffoldKey,
      drawer: Builder(
        builder: (drawerCtx) {
          return SheberNavigationDrawer(
            drawerContext: drawerCtx,
            currentTabIndex: _currentIndex,
            unreadChatCount: _unreadCount,
            onSelectTab: _onSelectTabFromDrawer,
            onOpenFaq: () => openFaqFromDrawer(drawerCtx),
            onOpenSupport: () => openSupportFromDrawer(drawerCtx),
          );
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TabHome(onOpenNavMenu: _openDrawer),
          TabChat(key: _chatKey, onOpenNavMenu: _openDrawer),
          const SizedBox.shrink(),
          TabMasters(onOpenNavMenu: _openDrawer),
          TabProfile(onOpenNavMenu: _openDrawer),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _onPlusTap();
        },
        backgroundColor: _primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Consumer<AppState>(
        builder: (context, state, _) {
          final s = S.lang(state.language);
          final barColor = state.darkMode ? const Color(0xFF1E293B) : Colors.white;
          return BottomAppBar(
            color: barColor,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            height: 56,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                _bottomNavItem(context: context, state: state, index: 0, icon: Icons.home_rounded, label: s.navHome),
                _bottomNavItem(context: context, state: state, index: 1, icon: Icons.chat_bubble_outline_rounded, label: s.navChat),
                const SizedBox(width: 56),
                _bottomNavItem(context: context, state: state, index: 3, icon: Icons.handyman_outlined, label: s.navMasters),
                _bottomNavItem(context: context, state: state, index: 4, icon: Icons.person_outline_rounded, label: s.navProfile),
              ],
            ),
          );
        },
      ),
    );
  }
}

