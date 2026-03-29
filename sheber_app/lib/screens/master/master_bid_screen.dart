import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/order.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';

class MasterBidScreen extends StatefulWidget {
  final Order order;
  const MasterBidScreen({super.key, required this.order});

  @override
  State<MasterBidScreen> createState() => _MasterBidScreenState();
}

class _MasterBidScreenState extends State<MasterBidScreen> {
  late int _currentAmount;
  final TextEditingController _customCtrl = TextEditingController();
  bool _showCustomInput = false;
  bool _submitting = false;

  static const _green = Color(0xFF3DDC84);
  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    // Start from client's price or existing bid
    _currentAmount = widget.order.myBid ?? widget.order.price;
    _customCtrl.text = _currentAmount.toString();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int get _minAllowed => (widget.order.price * 0.5).ceil();

  void _adjust(int delta) {
    setState(() {
      _currentAmount = (_currentAmount + delta).clamp(_minAllowed, 9999999);
      _customCtrl.text = _currentAmount.toString();
      _showCustomInput = false;
    });
  }

  void _onCustomChanged(String val) {
    final parsed = int.tryParse(val.replaceAll(' ', ''));
    if (parsed != null) setState(() => _currentAmount = parsed);
  }

  Future<void> _submit() async {
    if (_currentAmount < _minAllowed) {
      final s = S.lang(Provider.of<AppState>(context, listen: false).language);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${s.bidMinNote}: $_minAllowed₸'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().submitBid(widget.order.id, _currentAmount);
      if (!mounted) return;
      if (res['ok'] == true) {
        final s = S.lang(Provider.of<AppState>(context, listen: false).language);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.bidSubmitted, style: const TextStyle(fontSize: 16)),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context, true); // true = bid was submitted
      } else {
        final err = res['error']?.toString() ?? 'error';
        String msg = err;
        if (err == 'bid_too_low') {
          msg = '${S.lang(Provider.of<AppState>(context, listen: false).language).bidMinNote}: ${res['min']}₸';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Байланыс қатесі'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final s = S.lang(appState.language);
    final order = widget.order;
    final alreadyBid = order.myBid != null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDark = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final cardColor = theme.cardColor;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.bidTitle,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.serviceTitle ?? (s.isKz ? 'Тапсырыс' : 'Заказ'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      order.description,
                      style: TextStyle(fontSize: 16, color: textDark),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 15, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 15, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          order.clientName ?? 'Клиент',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Text(
                          s.bidClientPrice,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const Spacer(),
                        Text(
                          '${order.price} ₸',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                    if (order.bidCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_alt_outlined, size: 14, color: Colors.orange.shade400),
                          const SizedBox(width: 4),
                          Text(
                            s.bidCount(order.bidCount),
                            style: TextStyle(fontSize: 13, color: Colors.orange.shade600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Already bid notice ───────────────────────────────────
              if (alreadyBid)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${s.myBidLabel}: ${order.myBid}₸',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Your bid amount ──────────────────────────────────────
              Text(
                s.bidYourOffer,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Big amount display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _currentAmount < _minAllowed
                        ? Colors.red.shade300
                        : const Color(0xFF3DDC84),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${_formatAmount(_currentAmount)} ₸',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _currentAmount < _minAllowed ? Colors.red.shade400 : textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Min note
              const SizedBox(height: 6),
              Text(
                '${s.bidMinNote}: ${_formatAmount(_minAllowed)}₸',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Quick +/- buttons
              Row(
                children: [
                  _QuickBtn(label: '-1000', onTap: () => _adjust(-1000)),
                  const SizedBox(width: 8),
                  _QuickBtn(label: '-100', onTap: () => _adjust(-100)),
                  const SizedBox(width: 8),
                  _QuickBtn(label: '+100', onTap: () => _adjust(100), positive: true),
                  const SizedBox(width: 8),
                  _QuickBtn(label: '+1000', onTap: () => _adjust(1000), positive: true),
                ],
              ),

              const SizedBox(height: 12),

              // Custom price input toggle
              GestureDetector(
                onTap: () => setState(() {
                  _showCustomInput = !_showCustomInput;
                  if (_showCustomInput) {
                    _customCtrl.text = _currentAmount.toString();
                    _customCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: _customCtrl.text.length),
                    );
                  }
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _showCustomInput ? _primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: _showCustomInput ? _primary : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.bidCustomPrice,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _showCustomInput ? _primary : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Custom input field
              if (_showCustomInput) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: true,
                    fillColor: cardColor,
                    suffixText: '₸',
                    suffixStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 2),
                    ),
                  ),
                  onChanged: _onCustomChanged,
                ),
              ],

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentAmount < _minAllowed
                        ? Colors.grey.shade300
                        : _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_submitting || _currentAmount < _minAllowed) ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          s.bidSubmit,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool positive;
  const _QuickBtn({required this.label, required this.onTap, this.positive = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: positive
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFFF7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: positive ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
