import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../l10n/app_strings.dart';

/// Диалог смены пароля (общий для профиля и экрана редактирования).
class ChangePasswordDialog extends StatefulWidget {
  final S s;
  final bool isDark;

  const ChangePasswordDialog({super.key, required this.s, required this.isDark});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _cur = TextEditingController();
  final _n1 = TextEditingController();
  final _n2 = TextEditingController();
  bool? _hasPassword;
  bool _busy = false;

  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiClient().getPasswordStatus();
      if (!mounted) return;
      setState(() {
        _hasPassword = r['ok'] == true && r['has_password'] == true;
      });
    } catch (_) {
      if (mounted) setState(() => _hasPassword = true);
    }
  }

  @override
  void dispose() {
    _cur.dispose();
    _n1.dispose();
    _n2.dispose();
    super.dispose();
  }

  InputDecoration _pwdDec(String hint, Color fill, Color border, bool isDark) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      suffixIconColor: textDark,
    );
  }

  Future<void> _submit() async {
    final s = widget.s;
    if (!mounted) return;
    if (_n1.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.passwordTooShort)));
      return;
    }
    if (_n1.text != _n2.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.passwordsDoNotMatch)));
      return;
    }
    final has = _hasPassword == true;
    if (has && _cur.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.currentPasswordRequired)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (cctx) {
        final bg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = widget.isDark ? Colors.white : const Color(0xFF0F172A);
        return AlertDialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(s.confirmPasswordChangeTitle, style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
          content: Text(s.confirmPasswordChangeBody, style: TextStyle(color: textDark.withValues(alpha: 0.85), height: 1.35)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(cctx, false),
              child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(cctx, true),
              child: Text(s.confirm, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await ApiClient().changePassword(
        currentPassword: has ? _cur.text : null,
        newPassword: _n1.text,
      );
      if (!mounted) return;
      if (res['ok'] == true) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (mounted) Navigator.of(context).pop();
        messenger?.showSnackBar(SnackBar(
          content: Text(s.passwordChanged),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      final err = res['error']?.toString() ?? '';
      String msg;
      switch (err) {
        case 'wrong_current':
          msg = s.wrongCurrentPassword;
          break;
        case 'password_too_short':
          msg = s.passwordTooShort;
          break;
        default:
          msg = s.changePasswordFailed;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.s.changePasswordFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.changePasswordTitle, style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 18)),
      content: _hasPassword == null
          ? const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasPassword != true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        s.firstPasswordSubtitle,
                        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.35),
                      ),
                    ),
                  if (_hasPassword == true) ...[
                    TextField(
                      controller: _cur,
                      obscureText: true,
                      style: TextStyle(color: textDark),
                      decoration: _pwdDec(s.currentPasswordLabel, inputBg, borderColor, isDark),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _n1,
                    obscureText: true,
                    style: TextStyle(color: textDark),
                    decoration: _pwdDec(s.newPasswordLabel, inputBg, borderColor, isDark),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _n2,
                    obscureText: true,
                    style: TextStyle(color: textDark),
                    decoration: _pwdDec(s.repeatPasswordLabel, inputBg, borderColor, isDark),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: (_busy || _hasPassword == null) ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(s.changePasswordButton, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
