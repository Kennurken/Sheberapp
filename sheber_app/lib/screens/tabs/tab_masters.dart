import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/categories.dart';
import '../../api/api_client.dart';
import '../../models/master.dart';
import '../../models/order.dart';
import '../master_profile_screen.dart';
import '../order_chat_screen.dart';
import '../../widgets/sheber_avatar.dart';
import '../../widgets/sheber_card.dart';
import '../../services/master_location_service.dart';

class TabMasters extends StatefulWidget {
  final VoidCallback onOpenNavMenu;

  const TabMasters({super.key, required this.onOpenNavMenu});

  @override
  State<TabMasters> createState() => _TabMastersState();
}

class _TabMastersState extends State<TabMasters> {
  List<Master> _masters = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  int? _selectedCatId; // null = все профессии
  bool _onlyTopRated = false; // фильтр 4.9+

  static const _primary = Color(0xFF2563EB);
  static const _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.role != 'master') {
        _loadMasters();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _debouncedSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final q = _searchController.text.trim();
      setState(() => _searchQuery = q);
      _loadMasters();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreMasters();
      }
    }
  }

  Future<void> _loadMasters() async {
    setState(() { _isLoading = true; _error = null; _hasMore = true; });
    try {
      final masters = await ApiClient().getMasters(
        '',
        allCities: true,
        query: _searchQuery,
        limit: _pageSize,
        categoryId: _selectedCatId,
        minRating: _onlyTopRated ? 4.9 : 0,
      );
      if (mounted) {
        setState(() {
          _masters = masters;
          _hasMore = masters.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreMasters() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final more = await ApiClient().getMasters(
        '',
        allCities: true,
        query: _searchQuery,
        offset: _masters.length,
        limit: _pageSize,
        categoryId: _selectedCatId,
        minRating: _onlyTopRated ? 4.9 : 0,
      );
      if (mounted) {
        setState(() {
          _masters.addAll(more);
          _hasMore = more.length >= _pageSize;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _selectCategory(int? catId) {
    setState(() => _selectedCatId = catId);
    _loadMasters();
  }

  void _pickCity() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🏙️ Қала'),
        content: const Text(
          'Қазір тек Қызылорда қаласы тестілеу режимінде қол жетімді.\n\n'
          'Жақын арада Алматы, Астана және басқа қалаларды қосамыз!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Түсіндім'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;

        // Masters see their own dashboard
        if (state.role == 'master') {
          return _MasterHomeView(isDark: isDark, s: s, onOpenNavMenu: widget.onOpenNavMenu);
        }

        // Clients see master list
        final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
        final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: headerBg,
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu_rounded, color: textDark, size: 26),
                            onPressed: widget.onOpenNavMenu,
                          ),
                          Expanded(
                            child: Text(
                              s.mastersTitle,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.mastersSubtitleAll,
                        style: TextStyle(fontSize: 14, color: textGray),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: _primary, size: 18),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.cityShortLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: textGray,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        state.selectedCity.isEmpty ? s.notSelected : state.selectedCity,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: state.selectedCity.isEmpty ? textGray : textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: _pickCity,
                            child: Text(s.select, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => _debouncedSearch(),
                        style: TextStyle(color: textDark, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: s.searchMastersHint,
                          prefixIcon: Icon(Icons.search_rounded, color: textGray, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, color: textGray),
                                  onPressed: () {
                                    _searchDebounce?.cancel();
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    _loadMasters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          isDense: true,
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
                            borderSide: const BorderSide(color: _primary, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profession filter chips
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ProfChip(
                        label: s.all,
                        icon: Icons.people_rounded,
                        color: const Color(0xFF3DDC84),
                        selected: _selectedCatId == null,
                        isDark: isDark,
                        onTap: () => _selectCategory(null),
                      ),
                      const SizedBox(width: 8),
                      ...kAppCategories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ProfChip(
                            label: state.language == 'kz' ? cat.nameKz : cat.nameRu,
                            icon: cat.icon,
                            color: cat.color,
                            selected: _selectedCatId == cat.id,
                            isDark: isDark,
                            onTap: () => _selectCategory(cat.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Top-rated toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _onlyTopRated = !_onlyTopRated);
                      _loadMasters();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _onlyTopRated
                            ? Colors.amber.shade400
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _onlyTopRated ? Colors.amber.shade400 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 16,
                              color: _onlyTopRated ? Colors.white : Colors.amber.shade500),
                          const SizedBox(width: 6),
                          Text(
                            '4.9+ рейтинг',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _onlyTopRated
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Ad banner
                _AdBanner(isDark: isDark),
                const SizedBox(height: 8),

                Expanded(
                  child: RefreshIndicator(
                          onRefresh: () => _loadMasters(),
                          color: _primary,
                          child: _isLoading
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.sizeOf(context).height * 0.45,
                                    child: const Center(child: CircularProgressIndicator(color: _primary)),
                                  ),
                                )
                              : _error != null
                                  ? SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: SizedBox(
                                        height: MediaQuery.sizeOf(context).height * 0.5,
                                        child: _ErrorState(
                                          message: s.loadError,
                                          retryLabel: s.tryAgain,
                                          onRetry: () => _loadMasters(),
                                          isDark: isDark,
                                        ),
                                      ),
                                    )
                                  : _masters.isEmpty
                                      ? SingleChildScrollView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          child: SizedBox(
                                            height: MediaQuery.sizeOf(context).height * 0.5,
                                            child: _NoMastersState(s: s, isDark: isDark),
                                          ),
                                        )
                                      : ListView.separated(
                                          controller: _scrollController,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(16),
                                          itemCount: _masters.length + (_hasMore ? 1 : 0),
                                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                                          itemBuilder: (_, i) {
                                            if (i == _masters.length) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                child: Center(
                                                  child: _isLoadingMore
                                                      ? const CircularProgressIndicator(color: _primary, strokeWidth: 2)
                                                      : const SizedBox.shrink(),
                                                ),
                                              );
                                            }
                                            return _MasterCard(
                                              master: _masters[i],
                                              isDark: isDark,
                                              s: s,
                                            );
                                          },
                                        ),
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

// ── Master home dashboard ─────────────────────────────────────────────────────

class _MasterHomeView extends StatefulWidget {
  final bool isDark;
  final S s;
  final VoidCallback onOpenNavMenu;

  const _MasterHomeView({
    required this.isDark,
    required this.s,
    required this.onOpenNavMenu,
  });

  @override
  State<_MasterHomeView> createState() => _MasterHomeViewState();
}

class _MasterHomeViewState extends State<_MasterHomeView> {
  List<Order> _feed = [];
  List<Order> _myOrders = [];
  bool _loading = false;
  final Set<int> _accepting = {};
  bool _bannerDismissed = false;
  int _lastKnownFeedCount = 0;
  int? _selectedCatId; // null = все категории

  static const _primary = Color(0xFF2563EB);

  List<Order> get _filteredFeed => _selectedCatId == null
      ? _feed
      : _feed.where((o) => o.categoryId == _selectedCatId).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final feed = await ApiClient().getOrdersFeed();
      final mine = await ApiClient().getMyOrders();
      if (mounted) {
        setState(() {
          if (feed.length > _lastKnownFeedCount) {
            _bannerDismissed = false;
          }
          _lastKnownFeedCount = feed.length;
          _feed = feed;
          _myOrders = mine;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(int orderId) async {
    setState(() => _accepting.add(orderId));
    try {
      await ApiClient().acceptOrder(orderId);
      MasterLocationService.instance.startTracking(orderId);
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _accepting.remove(orderId));
    }
  }

  List<Order> get _activeOrders =>
      _myOrders.where((o) => o.status == 'in_progress').toList();
  List<Order> get _completedOrders =>
      _myOrders.where((o) => o.status == 'completed').toList();

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final s = widget.s;
    final state = context.read<AppState>();

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final showBanner = !_bannerDismissed && !_loading && _feed.isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── New order notification banner ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: showBanner ? null : 0,
              child: showBanner
                  ? GestureDetector(
                      onTap: () => setState(() => _bannerDismissed = true),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.s.isKz
                                        ? '${_feed.length} жаңа тапсырыс бар!'
                                        : '${_feed.length} новых заказов!',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    widget.s.isKz ? 'Төменде қараңыз' : 'Смотрите ниже',
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (showBanner) const SizedBox(height: 8),

            Expanded(child: RefreshIndicator(
          onRefresh: _load,
          color: _primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  color: headerBg,
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu_rounded, color: textDark, size: 26),
                            onPressed: widget.onOpenNavMenu,
                          ),
                          Expanded(
                            child: Text(
                              s.masterDashTitle,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (state.selectedCity.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: textGray),
                            const SizedBox(width: 4),
                            Text(
                              state.selectedCity,
                              style: TextStyle(fontSize: 13, color: textGray),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          _StatCard(
                            label: s.statNew,
                            count: _feed.length,
                            color: _primary,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: s.statActive,
                            count: _activeOrders.length,
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: s.statDone,
                            count: _completedOrders.length,
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _primary)),
                )
              else ...[
                // New orders section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      s.newOrders,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),

                // Category filter chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CategoryFilterChip(
                          label: s.isKz ? 'Барлығы' : 'Все',
                          selected: _selectedCatId == null,
                          color: _primary,
                          onTap: () => setState(() => _selectedCatId = null),
                        ),
                        ...kAppCategories.map((cat) => _CategoryFilterChip(
                          label: cat.nameRu,
                          selected: _selectedCatId == cat.id,
                          color: cat.color,
                          onTap: () => setState(() =>
                            _selectedCatId = _selectedCatId == cat.id ? null : cat.id),
                        )),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                if (_filteredFeed.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptySection(
                      message: _selectedCatId != null
                          ? (s.isKz ? 'Бұл санатта тапсырыс жоқ' : 'Нет заказов в этой категории')
                          : s.noNewOrders,
                      isDark: isDark,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _FeedOrderCard(
                          order: _filteredFeed[i],
                          isDark: isDark,
                          s: s,
                          isAccepting: _accepting.contains(_filteredFeed[i].id),
                          onAccept: () => _accept(_filteredFeed[i].id),
                        ),
                      ),
                      childCount: _filteredFeed.length,
                    ),
                  ),

                // My active work section
                if (_activeOrders.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Text(
                        s.myWork,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _ActiveOrderCard(
                          order: _activeOrders[i],
                          isDark: isDark,
                          s: s,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderChatScreen(order: _activeOrders[i]),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                      childCount: _activeOrders.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        )),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.count, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : color.withValues(alpha: 0.08);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: textGray, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feed order card (with Accept button) ─────────────────────────────────────

class _FeedOrderCard extends StatelessWidget {
  final Order order;
  final bool isDark;
  final S s;
  final bool isAccepting;
  final VoidCallback onAccept;

  const _FeedOrderCard({
    required this.order,
    required this.isDark,
    required this.s,
    required this.isAccepting,
    required this.onAccept,
  });

  static const _primary = Color(0xFF2563EB);
  static const _green = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
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
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.serviceTitle ?? 'Жалпы',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
              const Spacer(),
              if (order.price > 0)
                Text(
                  '${order.price} ₸',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.description,
            style: TextStyle(fontSize: 14, color: textDark, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: textGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.address,
                  style: TextStyle(fontSize: 13, color: textGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: isAccepting ? null : onAccept,
              child: isAccepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      s.acceptOrder,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active order card (go to chat) ───────────────────────────────────────────

class _ActiveOrderCard extends StatelessWidget {
  final Order order;
  final bool isDark;
  final S s;
  final VoidCallback onTap;

  const _ActiveOrderCard({
    required this.order,
    required this.isDark,
    required this.s,
    required this.onTap,
  });

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final clientName = order.clientName ?? 'Клиент';
    final initial = clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C';

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.displayTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clientName,
                      style: TextStyle(fontSize: 13, color: textGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.orderStatus(order.status),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _amber,
                  ),
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

// ── Empty section ─────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final String message;
  final bool isDark;
  const _EmptySection({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 20, color: textGray),
            const SizedBox(width: 10),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: textGray),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Client view helper widgets ────────────────────────────────────────────────

class _NoMastersState extends StatelessWidget {
  final S s;
  final bool isDark;
  const _NoMastersState({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_search_rounded, size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            s.noMastersFound,
            style: TextStyle(fontSize: 16, color: textGray, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            s.tryAdjustSearchOrFilters,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: textGray)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  final Master master;
  final bool isDark;
  final S s;
  const _MasterCard({required this.master, required this.isDark, required this.s});

  static const _primary = Color(0xFF2563EB);

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return SheberCard(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MasterProfileScreen(masterId: master.id),
      )),
      child: Column(
        children: [
          Row(
            children: [
              SheberAvatar(
                imageUrl: master.avatarUrl,
                colorSeed: master.id,
                label: master.name,
                size: 52,
                cornerRadius: 14,
                heroTag: 'master_avatar_${master.id}',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            master.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (master.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      master.profession,
                      style: TextStyle(fontSize: 13, color: textGray),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade500),
                        const SizedBox(width: 3),
                        Text(
                          master.rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${master.reviewsCount})',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        if (master.experience > 0) ...[
                          const SizedBox(width: 10),
                          Text('·', style: TextStyle(color: textGray)),
                          const SizedBox(width: 10),
                          Text(
                            '${master.experience} ${s.years}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: Text(s.callBtn, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: master.phone.isNotEmpty ? () => _call(master.phone) : null,
                ),
              ),
              if (master.hasWhatsapp) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: master.phone.isNotEmpty ? () => _whatsapp(master.phone) : null,
                  ),
                ),
              ],
            ],
          ),

          // Reviews button
          if (master.reviewsCount > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                icon: const Icon(Icons.star_outline_rounded, size: 16),
                label: Text(
                  'Жұмыстары мен пікірлер (${master.reviewsCount})',
                  style: const TextStyle(fontSize: 13),
                ),
                onPressed: () => _showReviews(context, isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviews(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MasterReviewsSheet(master: master, isDark: isDark),
    );
  }
}

// ── Master Reviews Bottom Sheet ───────────────────────────────────────────────

class _MasterReviewsSheet extends StatefulWidget {
  final Master master;
  final bool isDark;
  const _MasterReviewsSheet({required this.master, required this.isDark});

  @override
  State<_MasterReviewsSheet> createState() => _MasterReviewsSheetState();
}

class _MasterReviewsSheetState extends State<_MasterReviewsSheet> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiClient().getMasterReviews(widget.master.id);
    if (mounted) setState(() { _reviews = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade500, size: 22),
              const SizedBox(width: 8),
              Text(
                '${widget.master.name} — пікірлер',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          else if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Пікірлер жоқ', style: TextStyle(color: textGray, fontSize: 16)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _reviews.length,
                separatorBuilder: (context, index) => Divider(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                itemBuilder: (context, i) {
                  final r = _reviews[i];
                  final rating = (r['rating'] as int?) ?? 5;
                  final comment = r['comment']?.toString() ?? '';
                  final clientName = r['client_name']?.toString() ?? 'Клиент';
                  final orderTitle = r['order_title']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...List.generate(5, (j) => Icon(
                              j < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16,
                              color: Colors.amber.shade500,
                            )),
                            const SizedBox(width: 8),
                            Text(clientName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
                          ],
                        ),
                        if (orderTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(orderTitle, style: TextStyle(fontSize: 12, color: textGray)),
                        ],
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(comment, style: TextStyle(fontSize: 14, color: textDark)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profession Chip Widget ─────────────────────────────────────
class _ProfChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: isDark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ad Banner Widget ────────────────────────────────────────────
class _AdBanner extends StatelessWidget {
  final bool isDark;
  const _AdBanner({required this.isDark});

  void _showAdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📢 Жарнама орналастыру'),
        content: const Text(
          'Sheber.kz-те жарнама орналастыру үшін бізге хабарласыңыз:\n\n'
          '📱 WhatsApp: +7 702 830 1616\n'
          '📧 Email: militechcampus@gmail.com\n\n'
          'Мақсатты аудитория: үй жөндеу қызметтерін іздейтін адамдар',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Жабу'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAdDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E3A5F), const Color(0xFF0F2137)]
                : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.4 : 0.3),
          ),
        ),
        child: Row(children: [
          const Icon(Icons.campaign_rounded,
              color: Color(0xFF3B82F6), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Мұнда сіздің жарнамаңыз болуы мүмкін!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Құрылыс дүкені, жабдықтаушылар және т.б.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Color(0xFF3B82F6), size: 14),
        ]),
      ),
    );
  }
}
