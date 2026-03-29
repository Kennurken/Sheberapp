import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/order.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/categories.dart';
import '../order_chat_screen.dart';
import '../profile_screen.dart';
import 'master_bid_screen.dart';

class MasterHomeScreen extends StatefulWidget {
  const MasterHomeScreen({super.key});

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen> {
  int _currentIndex = 0;

  // GlobalKey to reload feed from outside (e.g. after profession change)
  final _feedKey = GlobalKey<_MasterFeedTabState>();

  void _onNavTap(int i) {
    setState(() => _currentIndex = i);
    // When switching BACK to feed tab, reload it (catches profession change)
    if (i == 0) _feedKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, _) {
        final isDark = state.darkMode;
        final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final selectedColor = const Color(0xFF3DDC84);
        final unselectedColor = isDark ? const Color(0xFF64748B) : Colors.grey.shade400;
        final sl = S.lang(state.language);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _MasterFeedTab(key: _feedKey),
              const _MasterMyOrdersTab(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _MasterNavItem(
                      icon: Icons.dynamic_feed_outlined,
                      activeIcon: Icons.dynamic_feed_rounded,
                      label: sl.newOrders,
                      isActive: _currentIndex == 0,
                      activeColor: selectedColor,
                      inactiveColor: unselectedColor,
                      onTap: () => _onNavTap(0),
                    ),
                    _MasterNavItem(
                      icon: Icons.work_outline_rounded,
                      activeIcon: Icons.work_rounded,
                      label: sl.myWork,
                      isActive: _currentIndex == 1,
                      activeColor: selectedColor,
                      inactiveColor: unselectedColor,
                      onTap: () => _onNavTap(1),
                    ),
                    _MasterNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: sl.profile,
                      isActive: _currentIndex == 2,
                      activeColor: selectedColor,
                      inactiveColor: unselectedColor,
                      onTap: () => _onNavTap(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MasterNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _MasterNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 26, color: isActive ? activeColor : inactiveColor),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ЛЕНТА ЗАКАЗОВ ============
class _MasterFeedTab extends StatefulWidget {
  const _MasterFeedTab({super.key});

  @override
  State<_MasterFeedTab> createState() => _MasterFeedTabState();
}

class _MasterFeedTabState extends State<_MasterFeedTab> {
  bool _loading = true;
  List<Order> _orders = [];
  int? _selectedCatId; // null = все категории
  int _unreadCount = 0;
  Timer? _notifTimer;
  Timer? _feedTimer;
  int _lastProfessionVersion = -1;

  static const _green = Color(0xFF3DDC84);

  List<Order> get _filteredOrders => _selectedCatId == null
      ? _orders
      : _orders.where((o) => o.categoryId == _selectedCatId).toList();

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _pollNotifications();
    _notifTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _pollNotifications();
    });
    _feedTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadFeedSilent();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload feed immediately when master changes profession
    final v = Provider.of<AppState>(context).professionVersion;
    if (_lastProfessionVersion != -1 && v != _lastProfessionVersion) {
      _loadFeed();
    }
    _lastProfessionVersion = v;
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _feedTimer?.cancel();
    super.dispose();
  }

  /// Called via GlobalKey when master switches back to feed tab
  void reload() => _loadFeed();

  Future<void> _loadFeed() async {
    if (mounted) setState(() => _loading = true);
    try {
        final city = context.read<AppState>().user?.city ?? '';
        final orders = await ApiClient().getOrdersFeed(city: city);
        if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFeedSilent() async {
    try {
        final city = context.read<AppState>().user?.city ?? '';
        final orders = await ApiClient().getOrdersFeed(city: city);
        if (mounted) setState(() => _orders = orders);
    } catch (_) {}
  }

  Future<void> _pollNotifications() async {
    final count = await ApiClient().getUnreadNotifications();
    if (mounted) setState(() => _unreadCount = count);
  }

  void _openBidScreen(Order order) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MasterBidScreen(order: order)),
    );
    if (submitted == true) _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final s = S.lang(appState.language);
    final isDark = appState.darkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final emptyIconColor = isDark ? const Color(0xFF334155) : Colors.grey.shade300;
    final emptyTextColor = isDark ? const Color(0xFF64748B) : Colors.grey.shade400;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Text(
                  s.newOrders,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: titleColor),
                ),
                const Spacer(),
                if (_unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          // Фильтр по категориям
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: s.all,
                  selected: _selectedCatId == null,
                  color: _green,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedCatId = null),
                ),
                ...kAppCategories.map((cat) => _CategoryChip(
                  label: appState.language == 'kz' ? cat.nameKz : cat.nameRu,
                  selected: _selectedCatId == cat.id,
                  color: cat.color,
                  isDark: isDark,
                  onTap: () => setState(() =>
                    _selectedCatId = _selectedCatId == cat.id ? null : cat.id),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? RefreshIndicator(
                    onRefresh: _loadFeed,
                    color: _green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.45,
                        child: const Center(child: CircularProgressIndicator(color: _green)),
                      ),
                    ),
                  )
                : _filteredOrders.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadFeed,
                        color: _green,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 80, color: emptyIconColor),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      _selectedCatId != null ? s.noOrdersInThisCategory : s.noNewOrders,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18, color: emptyTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        color: _green,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final order = _filteredOrders[i];
                            return _FeedOrderCard(
                              order: order,
                              s: s,
                              isDark: isDark,
                              onTap: () => _openBidScreen(order),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedBg = selected
        ? color
        : (isDark ? const Color(0xFF1E293B) : color.withValues(alpha: 0.1));
    final borderCol = selected ? color : (isDark ? const Color(0xFF334155) : color.withValues(alpha: 0.35));
    final textCol = selected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : color);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : unselectedBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedOrderCard extends StatelessWidget {
  final Order order;
  final S s;
  final bool isDark;
  final VoidCallback onTap;

  const _FeedOrderCard({required this.order, required this.s, required this.isDark, required this.onTap});

  static const _green = Color(0xFF3DDC84);
  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final alreadyBid = order.myBid != null;
    final hasBids = order.bidCount > 0;

    final cardBg = alreadyBid
        ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.45) : const Color(0xFFF0FFF4))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA));
    final borderColor = alreadyBid
        ? (isDark ? const Color(0xFF22C55E).withValues(alpha: 0.55) : const Color(0xFF86EFAC))
        : (isDark ? const Color(0xFF334155) : _green.withValues(alpha: 0.35));
    final textMain = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final badgeBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);
    final orangeBg = isDark ? const Color(0xFF422006) : Colors.orange.shade50;
    final orangeBorder = isDark ? const Color(0xFF9A3412) : Colors.orange.shade200;
    final orangeIcon = isDark ? const Color(0xFFFDBA74) : Colors.orange.shade600;
    final orangeText = isDark ? const Color(0xFFFED7AA) : Colors.orange.shade700;
    final bidChipBg = alreadyBid
        ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.6) : const Color(0xFFF0FFF4))
        : cardBg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.serviceTitle ?? (s.isKz ? 'Тапсырыс' : 'Заказ'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.price} ₸',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.description,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textMain),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      style: TextStyle(fontSize: 13, color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (hasBids)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: orangeBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: orangeBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_outlined, size: 13, color: orangeIcon),
                          const SizedBox(width: 4),
                          Text(
                            s.bidCount(order.bidCount),
                            style: TextStyle(fontSize: 12, color: orangeText, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  if (alreadyBid) ...[
                    if (hasBids) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bidChipBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.5) : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 13,
                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${s.myBidLabel}: ${order.myBid}₸',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF15803D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyBid ? _primary : _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: onTap,
                    child: Text(
                      alreadyBid ? s.bidAlreadySent : s.bidTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ МОИ ЗАКАЗЫ МАСТЕРА ============
class _MasterMyOrdersTab extends StatefulWidget {
  const _MasterMyOrdersTab();

  @override
  State<_MasterMyOrdersTab> createState() => _MasterMyOrdersTabState();
}

class _MasterMyOrdersTabState extends State<_MasterMyOrdersTab> {
  bool _loading = true;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await ApiClient().getMyOrders();
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new': return const Color(0xFF1CB7FF);
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        final textDark = isDark ? Colors.white : const Color(0xFF1A1A2E);
        final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA);
        final textGray = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500;
        final emptyIcon = isDark ? const Color(0xFF334155) : Colors.grey.shade300;
        final emptyText = isDark ? const Color(0xFF64748B) : Colors.grey.shade400;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  s.myWork,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
                ),
              ),
              Expanded(
                child: _loading
                    ? RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF3DDC84),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.45,
                            child: const Center(child: CircularProgressIndicator(color: Color(0xFF3DDC84))),
                          ),
                        ),
                      )
                    : _orders.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _load,
                            color: const Color(0xFF3DDC84),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.5,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                Icon(Icons.inbox_rounded, size: 80, color: emptyIcon),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    s.noOrdersYet,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 18, color: emptyText),
                                  ),
                                ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: const Color(0xFF3DDC84),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _orders.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final order = _orders[i];
                                final statusColor = _statusColor(order.status);
                                return Material(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => OrderChatScreen(order: order)),
                                      );
                                      _load(); // reload after chat closes
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  order.displayTitle,
                                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textDark),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  order.address,
                                                  style: TextStyle(fontSize: 14, color: textGray),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              s.orderStatus(order.status),
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
