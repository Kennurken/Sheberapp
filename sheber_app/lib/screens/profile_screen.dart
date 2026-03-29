import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../l10n/app_strings.dart';
import '../l10n/categories.dart';
import '../providers/app_state.dart';
import '../widgets/master_portfolio_section.dart';
import 'main_shell.dart';
import 'role_select_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = S.lang(state.language);
        final isDark = state.darkMode;
        final user = state.user;

        if (user == null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            body: Center(
              child: Text(s.notAuthorized,
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey.shade500)),
            ),
          );
        }

        final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final textGray = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500;
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

        // Find current profession label
        String profLabel = s.notSet;
        if (user.profession.isNotEmpty) {
          try {
            final cat = kAppCategories.firstWhere((c) => c.profId == user.profession);
            profLabel = cat.name(state.language);
          } catch (_) {
            profLabel = user.profession;
          }
        }

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Avatar with camera button overlay
                  _AvatarPicker(user: user, state: state, isDark: isDark, s: s),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(user.phone, style: TextStyle(fontSize: 15, color: textGray)),
                  const SizedBox(height: 8),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: user.role == 'master'
                          ? const Color(0xFF3DDC84).withValues(alpha: isDark ? 0.2 : 0.12)
                          : const Color(0xFF1CB7FF).withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role == 'master' ? s.masterRoleLabel : s.clientRoleLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: user.role == 'master' ? const Color(0xFF3DDC84) : const Color(0xFF1CB7FF),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section: Account
                  _sectionHeader(s.settingsSection, isDark),
                  const SizedBox(height: 10),

                  // Change role
                  _ProfileTile(
                    icon: Icons.swap_horiz_rounded,
                    color: const Color(0xFF2563EB),
                    label: s.changeRole,
                    subtitle: user.role == 'master' ? s.becomeClient : s.becomeMaster,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // City
                  _ProfileTile(
                    icon: Icons.location_city_rounded,
                    color: const Color(0xFF10B981),
                    label: s.cityLabel,
                    subtitle: user.city.isNotEmpty ? user.city : s.notSet,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    onTap: () => _editCity(context, state, s, isDark),
                  ),
                  const SizedBox(height: 10),

                  // Name
                  _ProfileTile(
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF8B5CF6),
                    label: s.name,
                    subtitle: user.name,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    onTap: () => _editName(context, state, s, isDark),
                  ),

                  // Phone (all users)
                  const SizedBox(height: 10),
                  _ProfileTile(
                    icon: Icons.phone_rounded,
                    color: const Color(0xFF0EA5E9),
                    label: s.phoneLabel,
                    subtitle: user.phone.isNotEmpty ? user.phone : s.notSet,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    onTap: () => _editPhone(context, state, s, isDark),
                  ),

                  // Profession + Bio + Experience (masters only)
                  if (user.role == 'master') ...[
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.engineering_rounded,
                      color: const Color(0xFFF59E0B),
                      label: s.professionLabel,
                      subtitle: profLabel,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      onTap: () => _changeProfession(context, state, s, isDark),
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.description_rounded,
                      color: const Color(0xFF8B5CF6),
                      label: s.descriptionBioLabel,
                      subtitle: user.bio.isNotEmpty ? user.bio : s.notSet,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      onTap: () => _editBio(context, state, s, isDark),
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.workspace_premium_rounded,
                      color: const Color(0xFFEC4899),
                      label: s.experienceYearsLabel,
                      subtitle: user.experience > 0 ? s.yearsExperience(user.experience) : s.notSet,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      onTap: () => _editExperience(context, state, s, isDark),
                    ),
                    if (user.role == 'master') ...[
                      const SizedBox(height: 24),
                      _sectionHeader(s.tabPortfolio, isDark),
                      const SizedBox(height: 10),
                      MasterPortfolioSection(isDark: isDark, s: s),
                    ],
                    // TODO: subscription tile — unhide in next update
                  ],

                  const SizedBox(height: 24),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(s.logoutLabel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        state.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (route) => false,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    ),
  );

  void _editCity(BuildContext context, AppState state, S s, bool isDark) {
    final ctrl = TextEditingController(text: state.user?.city ?? '');
    _showEditDialog(
      context: context,
      title: s.yourCity,
      hint: s.profileCityEditHint,
      controller: ctrl,
      isDark: isDark,
      s: s,
      onSave: (val) async {
        try {
          await ApiClient().updateProfile({'city': val});
          state.setUser(state.user!.copyWith(city: val));
        } catch (_) {}
      },
    );
  }

  void _editName(BuildContext context, AppState state, S s, bool isDark) {
    final ctrl = TextEditingController(text: state.user?.name ?? '');
    _showEditDialog(
      context: context,
      title: s.yourName,
      hint: s.yourNameHint,
      controller: ctrl,
      isDark: isDark,
      s: s,
      onSave: (val) async {
        try {
          await ApiClient().updateProfile({'name': val});
          state.setUser(state.user!.copyWith(name: val));
        } catch (_) {}
      },
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required TextEditingController controller,
    required bool isDark,
    required S s,
    required Future<void> Function(String) onSave,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 17, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isEmpty) return;
              // Сначала закрыть диалог — иначе setUser в onSave → notifyListeners
              // пока AlertDialog в дереве даёт тот же краш _dependents.isEmpty.
              if (ctx.mounted) Navigator.pop(ctx);
              try {
                await onSave(val);
              } catch (_) {}
            },
            child: Text(s.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editPhone(BuildContext context, AppState state, S s, bool isDark) {
    final ctrl = TextEditingController(text: state.user?.phone ?? '');
    _showEditDialog(
      context: context,
      title: s.phoneLabel,
      hint: '+7 777 000 00 00',
      controller: ctrl,
      isDark: isDark,
      s: s,
      onSave: (val) async {
        try {
          final u = state.user!;
          await ApiClient().updateProfile({'name': u.name, 'city': u.city, 'phone': val});
          state.setUser(u.copyWith(phone: val));
        } catch (_) {}
      },
    );
  }

  void _editBio(BuildContext context, AppState state, S s, bool isDark) {
    final ctrl = TextEditingController(text: state.user?.bio ?? '');
    _showEditDialog(
      context: context,
      title: s.profileEditBioShort,
      hint: s.profileBioEditHint,
      controller: ctrl,
      isDark: isDark,
      s: s,
      maxLines: 4,
      onSave: (val) async {
        try {
          final u = state.user!;
          await ApiClient().updateProfile({'name': u.name, 'city': u.city, 'bio': val});
          state.setUser(u.copyWith(bio: val));
        } catch (_) {}
      },
    );
  }

  void _editExperience(BuildContext context, AppState state, S s, bool isDark) {
    final ctrl = TextEditingController(
      text: (state.user?.experience ?? 0) > 0 ? '${state.user!.experience}' : '',
    );
    _showEditDialog(
      context: context,
      title: s.experienceYearsLabel,
      hint: s.profileExpEditHint,
      controller: ctrl,
      isDark: isDark,
      s: s,
      keyboardType: TextInputType.number,
      onSave: (val) async {
        final exp = int.tryParse(val) ?? 0;
        try {
          final u = state.user!;
          await ApiClient().updateProfile({'name': u.name, 'city': u.city, 'experience': exp});
          state.setUser(u.copyWith(experience: exp));
        } catch (_) {}
      },
    );
  }

  void _changeProfession(BuildContext context, AppState state, S s, bool isDark) {
    final currentProf = state.user?.profession ?? '';
    int initialCatId = 0;
    try {
      final cat = kAppCategories.firstWhere((c) => c.profId == currentProf);
      initialCatId = cat.id;
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfessionSheet(
        lang: state.language,
        initialCatId: initialCatId,
        isDark: isDark,
        s: s,
        onSave: (catId) async {
          final cat = kAppCategories.firstWhere((c) => c.id == catId);
          final u = state.user!;
          try {
            final resp = await ApiClient().updateProfile({
              'name': u.name,
              'city': u.city,
              'phone': u.phone,
              'bio': '',
              'profession': cat.profId,
              'profession_category_id': catId,
            });
            debugPrint('[changeProfession] server resp: $resp');
            state.setUser(u.copyWith(profession: cat.profId));
            state.bumpProfessionVersion(); // triggers feed reload in master home
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(s.professionChanged, style: const TextStyle(fontSize: 16)),
                backgroundColor: Colors.green.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }
          } catch (e) {
            debugPrint('[changeProfession] ERROR: $e');
          }
        },
      ),
    );
  }
}

// ── Avatar Picker ─────────────────────────────────────────────────────────────

class _AvatarPicker extends StatefulWidget {
  final dynamic user;
  final AppState state;
  final bool isDark;
  final S s;

  const _AvatarPicker({required this.user, required this.state, required this.isDark, required this.s});

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  bool _uploading = false;

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF1CB7FF);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final result = await ApiClient().uploadAvatar(File(picked.path));
      if (!mounted) return;
      if (result['ok'] == true) {
        final updated = result['data'] as Map<String, dynamic>?;
        if (updated != null) {
          widget.state.setUser(widget.state.user!.copyWith(
            avatarUrl: updated['avatar_url']?.toString(),
          ));
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.s.avatarUpdated),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.s.photoUploadError),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final avatarColor = _parseColor(user.avatarColor as String);
    final avatarUrl = user.avatarUrl as String?;
    final baseUrl = ApiClient().baseUrl;
    final fullAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty
        ? (avatarUrl.startsWith('http') ? avatarUrl : '$baseUrl/$avatarUrl')
        : null;

    return GestureDetector(
      onTap: _uploading ? null : _pickAvatar,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              image: fullAvatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(fullAvatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: fullAvatarUrl == null
                ? Center(
                    child: Text(
                      (user.name as String).isNotEmpty
                          ? (user.name as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                : null,
          ),
          // Camera icon overlay
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _uploading
                  ? const Padding(
                      padding: EdgeInsets.all(5),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile tile ─────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textGray = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: textGray)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textGray, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profession bottom sheet ───────────────────────────────────────────────────

class _ProfessionSheet extends StatefulWidget {
  final String lang;
  final int initialCatId;
  final bool isDark;
  final S s;
  final Future<void> Function(int catId) onSave;

  const _ProfessionSheet({
    required this.lang,
    required this.initialCatId,
    required this.isDark,
    required this.s,
    required this.onSave,
  });

  @override
  State<_ProfessionSheet> createState() => _ProfessionSheetState();
}

class _ProfessionSheetState extends State<_ProfessionSheet> {
  late int _selectedCatId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCatId = widget.initialCatId;
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = widget.isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(widget.s.pickProfession, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: kAppCategories.length,
            itemBuilder: (_, i) {
              final cat = kAppCategories[i];
              final isSelected = cat.id == _selectedCatId;
              return GestureDetector(
                onTap: () => setState(() => _selectedCatId = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color : cat.color.withValues(alpha: widget.isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? cat.color : cat.color.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, size: 26, color: isSelected ? Colors.white : cat.color),
                      const SizedBox(height: 4),
                      Text(
                        cat.name(widget.lang),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : (widget.isDark ? Colors.white70 : const Color(0xFF0F172A)),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedCatId == 0 ? const Color(0xFFCBD5E1) : const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: (_selectedCatId == 0 || _saving) ? null : () async {
                setState(() => _saving = true);
                await widget.onSave(_selectedCatId);
                if (context.mounted) Navigator.pop(context);
              },
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(widget.s.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
