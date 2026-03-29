import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';
import '../../api/api_client.dart';
import '../../models/order.dart';
import '../order_chat_screen.dart';
import '../../widgets/sheber_avatar.dart';
import '../../widgets/sheber_empty_state.dart';
import '../../widgets/shimmer_loading.dart';

class TabChat extends StatefulWidget {
  final VoidCallback onOpenNavMenu;

  const TabChat({super.key, required this.onOpenNavMenu});

  @override
  State<TabChat> createState() => TabChatState();
}

// Public state so MainShell can call reload() via GlobalKey
class TabChatState extends State<TabChat> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Order> _allOrders = [];
  bool _loading = false;

  static const _primary = Color(0xFF2563EB);

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // Background timer — silent (no spinner)
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _loadSilent();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Called from outside (MainShell via GlobalKey) — shows spinner
  void reload() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final orders = await ApiClient().getMyOrders();
      if (mounted) setState(() { _allOrders = orders; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSilent() async {
    try {
      final orders = await ApiClient().getMyOrders();
      if (mounted) setState(() => _allOrders = orders);
    } catch (_) {}
  }

  List<Order> get _activeOrders => _allOrders
      .where((o) => o.status == 'new' || o.status == 'in_progress')
      .toList();

  List<Order> get _completedOrders => _allOrders
      .where((o) => o.status == 'completed' || o.status == 'cancelled')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: headerBg,
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu_rounded, color: textDark, size: 26),
                            onPressed: widget.onOpenNavMenu,
                          ),
                          Expanded(
                            child: Text(
                              s.ordersTab,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TabBar(
                        controller: _tabController,
                        labelColor: _primary,
                        unselectedLabelColor: textGray,
                        indicatorColor: _primary,
                        indicatorWeight: 2.5,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(fontSize: 14),
                        tabs: [
                          Tab(text: s.activeOrdersTab),
                          Tab(text: s.completedOrdersTab),
                          Tab(text: s.support),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OrdersListTab(
                        orders: _activeOrders,
                        loading: _loading,
                        emptyMessage: s.noActiveOrders,
                        emptySubtitle: s.chatWillBeHere,
                        isDark: isDark,
                        isLoggedIn: state.isLoggedIn,
                        loginMsg: s.loginToUseChat,
                        onRefresh: _load,
                        onOrderTap: (order) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OrderChatScreen(order: order)),
                          );
                          _load();
                        },
                        role: state.role,
                      ),
                      _OrdersListTab(
                        orders: _completedOrders,
                        loading: _loading,
                        emptyMessage: s.noCompletedOrders,
                        emptySubtitle: '',
                        isDark: isDark,
                        isLoggedIn: state.isLoggedIn,
                        loginMsg: s.loginToUseChat,
                        onRefresh: _load,
                        onOrderTap: (order) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OrderChatScreen(order: order)),
                          );
                          _load();
                        },
                        role: state.role,
                      ),
                      _SupportTab(isDark: isDark, s: s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Orders list tab ────────────────────────────────────────────────────────────

class _OrdersListTab extends StatelessWidget {
  final List<Order> orders;
  final bool loading;
  final String emptyMessage;
  final String emptySubtitle;
  final bool isDark;
  final bool isLoggedIn;
  final String loginMsg;
  final Future<void> Function() onRefresh;
  final void Function(Order) onOrderTap;
  final String role;

  const _OrdersListTab({
    required this.orders,
    required this.loading,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.isDark,
    required this.isLoggedIn,
    required this.loginMsg,
    required this.onRefresh,
    required this.onOrderTap,
    required this.role,
  });

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return SheberEmptyState(
        icon: Icons.lock_outline_rounded,
        title: loginMsg,
        isDark: isDark,
        emphasizeTitle: false,
      );
    }
    if (loading) return SheberShimmerOrderList(isDark: isDark);
    if (orders.isEmpty) {
      return SheberEmptyState(
        icon: Icons.inbox_rounded,
        title: emptyMessage,
        subtitle: emptySubtitle.isEmpty ? null : emptySubtitle,
        isDark: isDark,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _OrderChatTile(
          order: orders[i],
          isDark: isDark,
          role: role,
          onTap: () => onOrderTap(orders[i]),
        ),
      ),
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────

class _OrderChatTile extends StatelessWidget {
  final Order order;
  final bool isDark;
  final String role;
  final VoidCallback onTap;

  const _OrderChatTile({
    required this.order,
    required this.isDark,
    required this.role,
    required this.onTap,
  });

  static const _primary = Color(0xFF2563EB);

  Color _statusColor(String status) {
    switch (status) {
      case 'new': return _primary;
      case 'in_progress': return const Color(0xFFF59E0B);
      case 'completed': return const Color(0xFF10B981);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final hasMsg = order.lastMessage != null && order.lastMessage!.isNotEmpty;
    final appSt = Provider.of<AppState>(context, listen: false);
    final s2 = S.lang(appSt.language);
    final otherName = role == 'master'
        ? (order.clientName?.isNotEmpty == true ? order.clientName! : s2.clientRoleLabel)
        : (order.masterName?.isNotEmpty == true ? order.masterName! : s2.searchingMaster);
    final imageUrl = role == 'master' ? order.clientAvatarUrl : order.masterAvatarUrl;
    final hexBg = role == 'master' ? order.clientAvatarColor : order.masterAvatarColor;
    final statusColor = _statusColor(order.status);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SheberAvatar(
                imageUrl: imageUrl,
                hexBackground: hexBg,
                colorSeed: order.id,
                label: otherName,
                size: 50,
                cornerRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.displayTitle,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Consumer<AppState>(
                            builder: (_, st, _) => Text(
                              S.lang(st.language).orderStatus(order.status),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(otherName, style: TextStyle(fontSize: 12, color: textGray)),
                    if (hasMsg) ...[
                      const SizedBox(height: 4),
                      Text(
                        order.lastMessage!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: textGray, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Support tab ───────────────────────────────────────────────────────────────

class _SupportTab extends StatefulWidget {
  final bool isDark;
  final S s;
  const _SupportTab({required this.isDark, required this.s});

  @override
  State<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<_SupportTab> {
  final List<_Message> _messages = [];
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _isSending = false;
  int _lastMsgId = 0;
  Timer? _pollTimer;

  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(text: widget.s.aiIntro, isMe: false, id: 0));
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiClient().getSupportMessages(since: _lastMsgId);
      if (!mounted || msgs.isEmpty) return;
      final seenIds = <int>{
        for (final x in _messages)
          if (x.id > 0) x.id,
      };
      setState(() {
        for (final m in msgs) {
          final id = (m['id'] is num) ? (m['id'] as num).toInt() : int.tryParse('${m['id']}') ?? 0;
          if (id > 0 && seenIds.contains(id)) continue;
          final dir = m['direction'] as String? ?? 'in';
          final text = m['message'] as String? ?? '';
          _messages.add(_Message(text: text, isMe: dir == 'in', id: id));
          if (id > 0) seenIds.add(id);
          if (id > _lastMsgId) _lastMsgId = id;
        }
      });
      _scrollToBottom();
    } catch (_) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    setState(() => _isSending = true);
    try {
      final res = await ApiClient().sendSupportMessage(text);
      if (!mounted) return;
      if (res['ok'] == true) {
        await _loadMessages();
      } else {
        setState(() => _controller.text = text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.s.error}: ${res['error'] ?? 'support_send'}',
                style: const TextStyle(fontSize: 15),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _controller.text = text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.s.connectionError, style: const TextStyle(fontSize: 15)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final inputBorderColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final footerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final aiBannerBg = isDark ? const Color(0xFF1D3461) : const Color(0xFFEFF6FF);
    final aiBannerBorder = isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: aiBannerBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: aiBannerBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sheber AI',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    Text(
                      widget.s.aiOnline,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
              ),
            ],
          ),
        ),

        // 24-hour notice banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFFFE69C),
            ),
          ),
          child: Row(children: [
            Icon(Icons.schedule_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF856404),
                size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.s.supportResponseTime,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF856404),
                ),
              ),
            ),
          ]),
        ),

        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _MessageBubble(message: _messages[i], isDark: isDark),
          ),
        ),

        Container(
          color: footerBg,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: widget.s.typeMessage,
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: inputBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: inputBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final int id;
  const _Message({required this.text, required this.isMe, this.id = 0});
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final bool isDark;
  const _MessageBubble({required this.message, required this.isDark});

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final bubbleBg = message.isMe
        ? _primary
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final textColor = message.isMe
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
        ),
      ),
    );
  }
}

