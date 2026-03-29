import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/order.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';
import '../order_chat_screen.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiClient().getMyOrders();
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _activeOrders => _orders
      .where((o) => o.status == 'new' || o.status == 'in_progress')
      .toList();

  List<Order> get _completedOrders => _orders
      .where((o) => o.status == 'completed' || o.status == 'cancelled')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final s = S.lang(state.language);
      final isDark = state.darkMode;
      final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
      final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
      final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: headerBg,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.ordersTab,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF2563EB),
                      unselectedLabelColor: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      indicatorColor: const Color(0xFF2563EB),
                      indicatorWeight: 2.5,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: [
                        Tab(text: s.activeOrdersTab),
                        Tab(text: s.completedOrdersTab),
                        Tab(text: s.support),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2563EB)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1 — Active
                          _OrderList(
                            orders: _activeOrders,
                            isDark: isDark,
                            s: s,
                            emptyText: s.noActiveOrders,
                            emptyIcon: Icons.inbox_rounded,
                            onRefresh: _loadOrders,
                          ),

                          // Tab 2 — Completed
                          _OrderList(
                            orders: _completedOrders,
                            isDark: isDark,
                            s: s,
                            emptyText: s.noCompletedOrders,
                            emptyIcon: Icons.check_circle_outline_rounded,
                            onRefresh: _loadOrders,
                          ),

                          // Tab 3 — Support
                          _SupportPlaceholder(isDark: isDark, s: s),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Order List ──────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final bool isDark;
  final S s;
  final String emptyText;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.isDark,
    required this.s,
    required this.emptyText,
    required this.emptyIcon,
    required this.onRefresh,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'new':        return const Color(0xFF1CB7FF);
      case 'in_progress': return Colors.orange;
      case 'completed':  return Colors.green;
      case 'cancelled':  return Colors.red;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 80,
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF2563EB),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final order = orders[i];
          return _OrderCard(
            order: order,
            isDark: isDark,
            s: s,
            statusColor: _statusColor(order.status),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OrderChatScreen(order: order)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Order Card ──────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isDark;
  final S s;
  final Color statusColor;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.isDark,
    required this.s,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textMain = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    order.displayTitle,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.orderStatus(order.status),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: textSub),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.address,
                      style: TextStyle(fontSize: 13, color: textSub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${order.price} ₸',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1CB7FF))),
              ]),
              if (order.masterName != null &&
                  order.masterName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.person_outline_rounded,
                      size: 15, color: textSub),
                  const SizedBox(width: 4),
                  Text('Шебер: ${order.masterName}',
                      style: TextStyle(fontSize: 13, color: textSub)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Support Placeholder ─────────────────────────────────────────
class _SupportPlaceholder extends StatelessWidget {
  final bool isDark;
  final S s;
  const _SupportPlaceholder({required this.isDark, required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_rounded,
                size: 72,
                color: isDark
                    ? const Color(0xFF334155)
                    : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              s.support,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              s.supportResponseTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
