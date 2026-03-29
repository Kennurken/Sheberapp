import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../l10n/app_strings.dart';
import '../models/user.dart';
import '../providers/app_state.dart';
import '../services/fcm_sync.dart';
import 'role_select_screen.dart';
import 'main_shell.dart';

class SmsCodeScreen extends StatefulWidget {
  final String phone;
  const SmsCodeScreen({super.key, required this.phone});

  @override
  State<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 60;
  bool _canResend = false;

  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    setState(() {
      _resendSeconds = 60;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendSeconds <= 1) {
        setState(() { _resendSeconds = 0; _canResend = true; });
        return false;
      }
      setState(() => _resendSeconds--);
      return true;
    });
  }

  Future<void> _verify() async {
    final s = S.lang(Provider.of<AppState>(context, listen: false).language);
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiClient().verifyCode(widget.phone, code);

      if (result['ok'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final csrf = data['csrf_token']?.toString() ?? '';

        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setUser(user);
        appState.setCsrfToken(csrf);
        ApiClient().setCsrfToken(csrf);
        await syncFcmTokenToServer();

        // Auto-set default city if missing
        const defaultCity = 'Қызылорда';
        if (user.city.isEmpty) {
          appState.setSelectedCity(defaultCity);
          appState.setUser(user.copyWith(city: defaultCity));
          try { await ApiClient().updateProfile({'city': defaultCity}); } catch (_) {}
        } else {
          appState.setSelectedCity(user.city);
        }

        if (!mounted) return;

        // Brand new user → pick role; otherwise → main
        final Widget nextScreen = (user.isNew || user.role.isEmpty)
            ? const RoleSelectScreen()
            : const MainShell();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
          (route) => false,
        );
      } else {
        _showError(result['error'] == 'wrong_code'
            ? s.errWrongCodeTryAgain
            : result['error']?.toString() ?? s.error);
        for (var c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      final msg = e.toString().replaceAll('DioException', '').replaceAll('Exception:', '').trim();
      _showError(s.errorColonMessage(msg));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    final s = S.lang(Provider.of<AppState>(context, listen: false).language);
    try {
      await ApiClient().sendCode(widget.phone);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.codeResentSuccess),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('DioException', '').replaceAll('Exception:', '').trim();
      _showError(s.errResendFailed(msg));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.lang(context.watch<AppState>().language);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDark = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final textGray = theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final inputFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.sms_rounded, size: 36, color: _primary),
              ),
              const SizedBox(height: 20),

              Text(
                s.enterCode,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.codeSentToPhone(widget.phone),
                style: TextStyle(fontSize: 15, color: textGray),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // 6-digit code inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 48,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        }
                        if (value.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        final code = _controllers.map((c) => c.text).join();
                        if (code.length == 6) _verify();
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _verify,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(s.verify, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 20),

              _canResend
                  ? TextButton(
                      onPressed: _resend,
                      child: Text(
                        s.resendCode,
                        style: const TextStyle(fontSize: 15, color: _primary, fontWeight: FontWeight.w600),
                      ),
                    )
                  : Text(
                      s.resendInSeconds(_resendSeconds),
                      style: TextStyle(fontSize: 14, color: textGray),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
