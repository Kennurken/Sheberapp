import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../l10n/app_strings.dart';
import '../models/user.dart';
import '../widgets/master_portfolio_section.dart';
import 'change_password_dialog.dart';

const _kProfItems = [
  ('plumber', 'Сантехник', 'Сантехник'),
  ('electrician', 'Электрик', 'Электрик'),
  ('repair', 'Жөндеуші', 'Ремонтник'),
  ('painter', 'Маляр', 'Маляр'),
  ('carpenter', 'Ағаш шебері', 'Плотник'),
  ('cleaner', 'Тазалаушы', 'Уборщик'),
  ('hvac', 'Климат-техника', 'Климат-техник'),
  ('locksmith', 'Слесарь', 'Слесарь'),
  ('windows', 'Терезе шебері', 'Оконщик'),
  ('welder', 'Дәнекерлеуші', 'Сварщик'),
  ('other', 'Басқа', 'Другое'),
];

Color _hexToColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return const Color(0xFF1CB7FF);
  }
}

/// Полноэкранное редактирование профиля (отдельный route вместо bottom sheet —
/// иначе при setUser во время снятия overlay возможен crash `_dependents.isEmpty`).
class ProfileEditScreen extends StatefulWidget {
  final User initialUser;
  final S s;
  final bool isMaster;
  final bool isDark;

  const ProfileEditScreen({
    super.key,
    required this.initialUser,
    required this.s,
    required this.isMaster,
    required this.isDark,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const _primary = Color(0xFF2563EB);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _expCtrl;
  late final Set<String> _selectedProfs;

  bool _saving = false;
  bool _avatarUploading = false;
  late String? _avatarUrlLocal;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUser;
    _nameCtrl = TextEditingController(text: u.name);
    _phoneCtrl = TextEditingController(text: u.phone);
    _bioCtrl = TextEditingController(text: u.bio);
    _expCtrl = TextEditingController(
      text: u.experience > 0 ? '${u.experience}' : '',
    );
    final existingIds = u.profession.split(',').map((e) => e.trim()).toSet();
    _selectedProfs = Set<String>.from(existingIds.where((e) => e.isNotEmpty));
    _avatarUrlLocal = u.avatarUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec(String hint, IconData icon, Color fill, Color border) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  Future<void> _pickAvatar() async {
    final s = widget.s;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _avatarUploading = true);
    try {
      final result = await ApiClient().uploadAvatar(File(picked.path));
      if (!mounted) return;
      if (result['ok'] == true) {
        final updated = result['data'] as Map<String, dynamic>?;
        final url = updated?['avatar_url']?.toString();
        if (url != null) {
          setState(() => _avatarUrlLocal = url);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.avatarUpdated),
            backgroundColor: Colors.green.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.photoUploadError),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  Future<void> _save() async {
    final isMaster = widget.isMaster;
    final nameTrim = _nameCtrl.text.trim();
    if (nameTrim.isEmpty) return;
    setState(() => _saving = true);
    final profValue = _selectedProfs.join(',');
    final fields = <String, dynamic>{
      'name': nameTrim,
      'phone': _phoneCtrl.text.trim(),
    };
    if (isMaster) {
      fields['profession'] = profValue;
      fields['bio'] = _bioCtrl.text.trim();
      var exp = int.tryParse(_expCtrl.text.trim()) ?? 0;
      if (exp < 0) exp = 0;
      if (exp > 80) exp = 80;
      fields['experience'] = exp;
    }
    try {
      await ApiClient().updateProfile(fields);
      if (!mounted) return;
      final u = widget.initialUser;
      final phoneVal = _phoneCtrl.text.trim();
      final bioVal = isMaster ? (fields['bio'] as String) : u.bio;
      final expVal = isMaster ? (fields['experience'] as int) : u.experience;
      final avatarUrl = _avatarUrlLocal ?? u.avatarUrl;
      final resultUser = u.copyWith(
        name: nameTrim,
        phone: phoneVal,
        profession: isMaster ? profValue : u.profession,
        bio: bioVal,
        experience: expVal,
        avatarUrl: avatarUrl,
      );
      Navigator.of(context).pop(resultUser);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isDark = widget.isDark;
    final isKz = s.isKz;
    final isMaster = widget.isMaster;
    final u = widget.initialUser;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final divColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final baseUrl = ApiClient().baseUrl;
    final avatarPath = _avatarUrlLocal;
    final fullAvatarUrl = avatarPath != null && avatarPath.isNotEmpty
        ? (avatarPath.startsWith('http') ? avatarPath : '$baseUrl/$avatarPath')
        : null;
    final avColor = _hexToColor(u.avatarColor);

    String avInitial(String n) {
      final t = n.trim();
      if (t.isEmpty) return '?';
      return t.substring(0, 1).toUpperCase();
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        title: Text(s.editProfileTitle, style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _avatarUploading ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: avColor,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: avColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                                  avInitial(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : u.name),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_avatarUploading)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _avatarUploading ? null : _pickAvatar,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18, color: Color(0xFF2563EB)),
                  label: Text(s.profileTapChangePhoto, style: const TextStyle(color: Color(0xFF2563EB))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: textDark),
            decoration: _inputDec(s.yourNameHint, Icons.person_outline_rounded, inputBg, borderColor),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: textDark),
            decoration: _inputDec(s.phoneLabel, Icons.phone_outlined, inputBg, borderColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => ChangePasswordDialog(s: s, isDark: isDark),
                );
              },
              child: Text(
                s.changePasswordButton,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (isMaster) ...[
            const SizedBox(height: 14),
            Text(s.profileEditBioShort, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _bioCtrl,
              style: TextStyle(color: textDark),
              maxLines: 4,
              maxLength: 500,
              decoration: _inputDec(s.profileBioEditHint, Icons.description_outlined, inputBg, borderColor).copyWith(
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              ),
            ),
            const SizedBox(height: 6),
            Text(s.experienceYearsLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _expCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textDark),
              decoration: _inputDec(s.profileExpEditHint, Icons.timelapse_outlined, inputBg, borderColor),
            ),
          ],
          if (isMaster) ...[
            const SizedBox(height: 14),
            Text(s.yourProfessionHint, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: divColor),
                borderRadius: BorderRadius.circular(12),
                color: inputBg,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView(
                  shrinkWrap: true,
                  children: _kProfItems.map((p) {
                    final id = p.$1;
                    final label = isKz ? p.$2 : p.$3;
                    final checked = _selectedProfs.contains(id);
                    return InkWell(
                      onTap: () => setState(() {
                        if (checked) {
                          _selectedProfs.remove(id);
                        } else {
                          _selectedProfs.add(id);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            Checkbox(
                              value: checked,
                              activeColor: _primary,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedProfs.add(id);
                                } else {
                                  _selectedProfs.remove(id);
                                }
                              }),
                            ),
                            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: textDark))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(s.tabPortfolio, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 4),
            Text(
              s.editProfilePortfolioHint,
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            MasterPortfolioSection(isDark: isDark, s: s),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(s.saveChanges, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
