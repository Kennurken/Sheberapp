import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import '../l10n/categories.dart';
import '../utils/upload_url.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/sheber_avatar.dart';
import '../widgets/sheber_card.dart';
import '../widgets/sheber_empty_state.dart';

class MasterProfileScreen extends StatefulWidget {
  final int masterId;
  const MasterProfileScreen({super.key, required this.masterId});

  @override
  State<MasterProfileScreen> createState() => _MasterProfileScreenState();
}

int _jsonInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _jsonDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

List<String> _portfolioPhotoUrls(List portfolio) {
  final out = <String>[];
  for (final e in portfolio) {
    if (e is Map) {
      final raw = e['url']?.toString().trim() ?? e['photo_url']?.toString().trim() ?? '';
      final u = resolveUploadUrl(raw);
      if (u.isNotEmpty) out.add(u);
    }
  }
  return out;
}

String _professionLabel(String profId, String lang) {
  for (final c in kAppCategories) {
    if (c.profId == profId) return c.name(lang);
  }
  if (profId.isEmpty) return '';
  return profId;
}

class _MasterProfileScreenState extends State<MasterProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().getMasterProfile(widget.masterId);
      if (!mounted) return;
      if (res['ok'] == true) {
        setState(() {
          _profile = Map<String, dynamic>.from(res['data'] as Map);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error']?.toString() ?? 'error';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.lang(state.language);
    final isDark = state.darkMode;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 56, color: textGray),
                        const SizedBox(height: 16),
                        Text(
                          s.connectionError,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: textGray),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(s.retry),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildBody(s, isDark, state),
    );
  }

  Widget _buildBody(S s, bool isDark, AppState state) {
    final p = _profile!;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final avatarRaw = p['avatar_url']?.toString() ?? '';
    final name = p['name']?.toString() ?? s.masterDefaultName;
    final professionRaw = p['profession']?.toString() ?? '';
    final profession = _professionLabel(professionRaw, state.language);
    final bio = p['bio']?.toString() ?? '';
    final experience = _jsonInt(p['experience']);
    final rating = _jsonDouble(p['avg_rating']);
    final reviewCount = _jsonInt(p['review_count']);
    final completedOrders = _jsonInt(p['completed_orders']);
    final isVerified = p['is_verified'] == true || p['is_verified'] == 1;
    final city = p['city']?.toString() ?? '';
    final phone = p['phone']?.toString() ?? '';
    final memberSince = p['member_since']?.toString() ?? '';
    final portfolio = (p['portfolio'] as List?) ?? [];
    final reviews = (p['reviews'] as List?) ?? [];
    final workHistory = (p['work_history'] as List?) ?? [];
    final masterIdVal = _jsonInt(p['id']);
    final isOwnProfile = state.user?.id == masterIdVal;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
        return [
          SliverOverlapAbsorber(
            handle: handle,
            sliver: SliverAppBar(
              expandedHeight: phone.isNotEmpty && !isOwnProfile ? 320 : 292,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF1E293B) : _primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadProfile,
                  tooltip: s.retry,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: innerBoxIsScrolled
                    ? Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      )
                    : null,
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [_primary, const Color(0xFF1D4ED8)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SheberAvatar(
                            heroTag: 'master_avatar_${widget.masterId}',
                            imageUrl: avatarRaw.trim().isEmpty ? null : avatarRaw.trim(),
                            label: name,
                            hexBackground: p['avatar_color']?.toString(),
                            size: 92,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: Color(0xFF3DDC84), size: 22),
                              ],
                            ],
                          ),
                          if (profession.isNotEmpty)
                            Text(
                              profession,
                              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.88)),
                            ),
                          if (city.isNotEmpty)
                            Text('📍 $city', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
                          if (memberSince.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${s.memberSinceLabel} ${_formatShortDate(memberSince)}',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                              ),
                            ),
                          if (phone.isNotEmpty && !isOwnProfile)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                onPressed: () async {
                                  final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s'), '')}');
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                },
                                icon: const Icon(Icons.phone_rounded, size: 20),
                                label: Text(s.callBtn),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SheberCard(
                isDark: isDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      value: rating.toStringAsFixed(1),
                      label: s.statRating,
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                      labelMuted: textGray,
                    ),
                    _StatItem(
                      value: '$completedOrders',
                      label: s.statJobsDone,
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      labelMuted: textGray,
                    ),
                    _StatItem(
                      value: '$reviewCount',
                      label: s.statReviewsShort,
                      icon: Icons.rate_review_rounded,
                      color: _primary,
                      labelMuted: textGray,
                    ),
                    _StatItem(
                      value: '$experience ${s.yearsShort}',
                      label: s.statExperienceShort,
                      icon: Icons.work_history_rounded,
                      color: const Color(0xFF8B5CF6),
                      labelMuted: textGray,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (bio.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SheberOutlinedCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.aboutMaster, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 8),
                      Text(bio, style: TextStyle(fontSize: 14, color: textGray, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              color: cardBg,
              language: state.language,
              tabBar: TabBar(
                controller: _tabController,
                labelColor: _primary,
                unselectedLabelColor: textGray,
                indicatorColor: _primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(text: s.tabPortfolio),
                  Tab(text: s.tabReviewsShort),
                  Tab(text: s.tabWorkHistory),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _PortfolioTab(
            portfolio: portfolio,
            isDark: isDark,
            textGray: textGray,
            isOwnProfile: isOwnProfile,
            s: s,
            onAfterUpload: _loadProfile,
          ),
          _ReviewsTab(
            reviews: reviews,
            isDark: isDark,
            textDark: textDark,
            textGray: textGray,
            s: s,
          ),
          _WorkHistoryTab(
            workHistory: workHistory,
            isDark: isDark,
            textDark: textDark,
            textGray: textGray,
            s: s,
          ),
        ],
      ),
    );
  }

  String _formatShortDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return d;
    }
  }

}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  final String language;

  _SliverTabBarDelegate({required this.tabBar, required this.color, required this.language});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: color,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: Colors.black26,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) =>
      oldDelegate.color != color || oldDelegate.language != language;
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color labelMuted;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.labelMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: labelMuted), textAlign: TextAlign.center),
      ],
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  final List portfolio;
  final bool isDark;
  final Color textGray;
  final bool isOwnProfile;
  final S s;
  final Future<void> Function() onAfterUpload;

  const _PortfolioTab({
    required this.portfolio,
    required this.isDark,
    required this.textGray,
    required this.isOwnProfile,
    required this.s,
    required this.onAfterUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

        if (portfolio.isEmpty && !isOwnProfile) {
          return CustomScrollView(
            key: const PageStorageKey<String>('portfolio_empty_guest'),
            slivers: [
              SliverOverlapInjector(handle: handle),
              SliverFillRemaining(
                hasScrollBody: false,
                child: SheberEmptyState(
                  icon: Icons.photo_library_outlined,
                  title: s.portfolioEmpty,
                  isDark: isDark,
                  emphasizeTitle: false,
                ),
              ),
            ],
          );
        }

        if (portfolio.isEmpty && isOwnProfile) {
          return CustomScrollView(
            key: const PageStorageKey<String>('portfolio_empty_own'),
            slivers: [
              SliverOverlapInjector(handle: handle),
              SliverFillRemaining(
                hasScrollBody: false,
                child: SheberEmptyState(
                  icon: Icons.add_photo_alternate_rounded,
                  title: s.portfolioEmpty,
                  isDark: isDark,
                  emphasizeTitle: false,
                  actionLabel: s.addPhoto,
                  onAction: () => _uploadPhoto(context),
                ),
              ),
            ],
          );
        }

        final addCell = isOwnProfile ? 1 : 0;
        final n = portfolio.length + addCell;

        return CustomScrollView(
          key: PageStorageKey<String>('portfolio_$n'),
          slivers: [
            SliverOverlapInjector(handle: handle),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (isOwnProfile && i == 0) {
                      return GestureDetector(
                        onTap: () => _uploadPhoto(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.45), width: 2),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, size: 40, color: Color(0xFF2563EB)),
                              SizedBox(height: 4),
                              Text('+', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                      );
                    }
                    final idx = i - addCell;
                    final item = portfolio[idx] as Map;
                    final urlRaw = item['url']?.toString() ?? item['photo_url']?.toString() ?? '';
                    final fullUrl = resolveUploadUrl(urlRaw);
                    final desc = item['caption']?.toString() ?? item['description']?.toString() ?? '';
                    final galleryUrls = _portfolioPhotoUrls(portfolio);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: galleryUrls.isEmpty || urlRaw.trim().isEmpty
                            ? null
                            : () => openSheberPhotoGallery(
                                  context,
                                  imageUrls: galleryUrls,
                                  initialIndex: idx.clamp(0, galleryUrls.length - 1),
                                ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              fullUrl.isNotEmpty
                                  ? Image.network(
                                      fullUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        child: const Icon(Icons.broken_image_rounded, size: 40, color: Color(0xFF94A3B8)),
                                      ),
                                    )
                                  : ColoredBox(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Color(0xFF94A3B8)),
                                    ),
                              if (desc.isNotEmpty)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                                      ),
                                    ),
                                    child: Text(
                                      desc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              if (fullUrl.isNotEmpty)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.zoom_in_rounded,
                                    size: 22,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: n,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    try {
      await ApiClient().uploadPortfolioPhoto(File(picked.path));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.portfolioUploadSuccess, style: const TextStyle(fontSize: 15)),
            backgroundColor: Colors.green.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await onAfterUpload();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.photoUploadError, style: const TextStyle(fontSize: 15)),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

class _ReviewsTab extends StatelessWidget {
  final List reviews;
  final bool isDark;
  final Color textDark;
  final Color textGray;
  final S s;

  const _ReviewsTab({
    required this.reviews,
    required this.isDark,
    required this.textDark,
    required this.textGray,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

        if (reviews.isEmpty) {
          return CustomScrollView(
            key: const PageStorageKey<String>('reviews_empty'),
            slivers: [
              SliverOverlapInjector(handle: handle),
              SliverFillRemaining(
                hasScrollBody: false,
                child: SheberEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: s.noReviewsYet,
                  isDark: isDark,
                  emphasizeTitle: false,
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          key: PageStorageKey<String>('reviews_${reviews.length}'),
          slivers: [
            SliverOverlapInjector(handle: handle),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final r = reviews[i] as Map;
                    final rating = _jsonInt(r['rating']).clamp(1, 5);
                    final comment = r['comment']?.toString() ?? '';
                    final clientName = r['client_name']?.toString() ?? (s.isKz ? 'Клиент' : 'Клиент');
                    final date = r['created_at']?.toString() ?? '';
                    final cAv = r['client_avatar_url']?.toString().trim() ?? '';

                    return Padding(
                      padding: EdgeInsets.only(bottom: i < reviews.length - 1 ? 12 : 0),
                      child: SheberOutlinedCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SheberAvatar(
                                  imageUrl: cAv.isEmpty ? null : cAv,
                                  label: clientName,
                                  hexBackground: r['client_avatar_color']?.toString(),
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(clientName, style: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (idx) => Icon(
                                            idx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 18,
                                            color: const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (date.isNotEmpty)
                                  Text(_formatDate(date), style: TextStyle(fontSize: 11, color: textGray)),
                              ],
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(comment, style: TextStyle(fontSize: 14, color: textGray, height: 1.45)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: reviews.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

class _WorkHistoryTab extends StatelessWidget {
  final List workHistory;
  final bool isDark;
  final Color textDark;
  final Color textGray;
  final S s;

  const _WorkHistoryTab({
    required this.workHistory,
    required this.isDark,
    required this.textDark,
    required this.textGray,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

        if (workHistory.isEmpty) {
          return CustomScrollView(
            key: const PageStorageKey<String>('work_empty'),
            slivers: [
              SliverOverlapInjector(handle: handle),
              SliverFillRemaining(
                hasScrollBody: false,
                child: SheberEmptyState(
                  icon: Icons.work_history_outlined,
                  title: s.noCompletedWork,
                  isDark: isDark,
                  emphasizeTitle: false,
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          key: PageStorageKey<String>('work_${workHistory.length}'),
          slivers: [
            SliverOverlapInjector(handle: handle),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final w = workHistory[i] as Map;
                    final title = w['service_title']?.toString() ?? (s.isKz ? 'Тапсырыс' : 'Заказ');
                    final desc = w['description']?.toString() ?? '';
                    final address = w['address']?.toString() ?? '';
                    final price = _jsonInt(w['price']);
                    final date = w['completed_at']?.toString() ?? '';

                    return Padding(
                      padding: EdgeInsets.only(bottom: i < workHistory.length - 1 ? 10 : 0),
                      child: SheberOutlinedCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 15)),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(desc, style: TextStyle(fontSize: 13, color: textGray), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  if (address.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: textGray),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(fontSize: 12, color: textGray),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$price₸', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 15)),
                                if (date.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(_formatDate(date), style: TextStyle(fontSize: 10, color: textGray)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: workHistory.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return d;
    }
  }
}
