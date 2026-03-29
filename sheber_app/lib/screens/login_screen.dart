import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../l10n/app_strings.dart';
import '../providers/app_state.dart';
import 'sms_code_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  static const _primary = Color(0xFF2563EB);

  Future<void> _sendCode() async {
    final s = S.lang(Provider.of<AppState>(context, listen: false).language);
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length < 10) {
      _showError(s.errPhoneInvalid);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullPhone = '+7$phone';
      final result = await ApiClient().sendCode(fullPhone);

      if (result['ok'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SmsCodeScreen(phone: fullPhone),
          ),
        );
      } else {
        _showError(result['error']?.toString() ?? s.errSendCodeFailed);
      }
    } catch (e) {
      final msg = e.toString().replaceAll('DioException', '').replaceAll('Exception:', '').trim();
      _showError(s.errorColonMessage(msg));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.lang(context.watch<AppState>().language);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDark = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final textGray = theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B);
    final cardColor = theme.cardColor;
    final inputFill = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.build_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Sheber',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const TextSpan(
                      text: '.kz',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.appTagline,
                style: TextStyle(fontSize: 15, color: textGray),
              ),

              const SizedBox(height: 40),

              // Login card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.loginTabLabel,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.enterYourPhone,
                      style: TextStyle(fontSize: 14, color: textGray),
                    ),
                    const SizedBox(height: 20),

                    // Phone input
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Text(
                            '+7',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                        ),
                        hintText: '--- --- -- --',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade300,
                          letterSpacing: 1.5,
                        ),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _sendCode,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                s.getCode,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        s.loginFreeFooter,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Feature rows
              _FeatureRow(icon: Icons.search_rounded, text: s.loginFeatureFindMaster),
              const SizedBox(height: 12),
              _FeatureRow(icon: Icons.phone_rounded, text: s.loginFeatureDirectContact),
              const SizedBox(height: 12),
              _FeatureRow(icon: Icons.star_rounded, text: s.loginFeatureRating),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : const Color(0xFF334155));
    final iconBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
