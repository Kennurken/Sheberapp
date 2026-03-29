import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../models/order.dart';
import '../models/bid.dart';
import '../models/review.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import '../utils/upload_url.dart';
import '../services/master_location_service.dart';
import '../widgets/master_map_sheet.dart';
import 'order_status_screen.dart';

class OrderChatScreen extends StatefulWidget {
  final Order order;
  const OrderChatScreen({super.key, required this.order});

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  List<Bid> _bids = [];
  bool _loading = true;
  bool _bidsLoading = false;
  Timer? _pollTimer;

  // Review: 3-day edit window
  Review? _review;
  bool    _reviewLoaded = false;

  // Prevent double-tap on "Finish order" button
  bool _finishing = false;
  // Local done flag — prevents button reappearing after finish if Order object is stale
  bool _myDoneLocally = false;
  // Prevent double send while uploading media
  bool _sending = false;
  /// После перехода отзыва на 5★ один раз закрываем экран (и у клиента, и у мастера по опросу).
  bool _didAutoPopPerfect = false;

  @override
  void initState() {
    super.initState();
    // Pre-seed _myDoneLocally from the Order object so the hourglass icon
    // shows immediately on re-entry even before the orders list refreshes.
    final appState = context.read<AppState>();
    if (appState.role == 'master') {
      _myDoneLocally = (widget.order.masterDone != 0);
    } else {
      _myDoneLocally = (widget.order.clientDone != 0);
    }
    _loadMessages();
    _loadBids();
    // Load existing review if order is completed (client only)
    if (widget.order.status == 'completed') _loadReview();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadMessages(silent: true);
        _loadBids(silent: true);
        if (widget.order.status == 'completed') _loadReview();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final st = Provider.of<AppState>(context, listen: false);
      if (st.role == 'master' && widget.order.status == 'in_progress') {
        MasterLocationService.instance.startTracking(widget.order.id);
      }
    });
  }

  Future<void> _loadReview() async {
    try {
      final result = await ApiClient().getReview(widget.order.id);
      if (!mounted) return;
      final prevRating = _review?.rating;
      if (result['ok'] == true && result['data'] != null) {
        final newReview = Review.fromJson(result['data'] as Map<String, dynamic>);
        setState(() {
          _review = newReview;
          _reviewLoaded = true;
        });
        if (prevRating != null && prevRating < 5 && newReview.rating >= 5) {
          _onPerfectRatingChatClose();
        }
      } else {
        setState(() => _reviewLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _reviewLoaded = true);
    }
  }

  void _onPerfectRatingChatClose() {
    if (!mounted || _didAutoPopPerfect) return;
    _didAutoPopPerfect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  bool _isMessageInputLocked(AppState appState) {
    if (appState.role == 'client' &&
        widget.order.status == 'new' &&
        (widget.order.masterId ?? 0) <= 0) {
      return true;
    }
    if (widget.order.status == 'completed' &&
        _reviewLoaded &&
        _review != null &&
        _review!.rating >= 5) {
      return true;
    }
    return false;
  }

  Future<void> _editReview(S s) async {
    if (_review == null || !_review!.canEdit || _review!.rating >= 5) return;

    final result = await showDialog<_RatingResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RatingDialog(
        s: s,
        initialRating:  _review!.rating,
        initialComment: _review!.comment,
        isEdit: true,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final res = await ApiClient().updateReview(
        reviewId: _review!.id,
        rating:   result.rating,
        comment:  result.comment,
      );
      if (!mounted) return;
      if (res['ok'] == true) {
        await _loadReview();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Отзыв обновлён', style: TextStyle(fontSize: 15)),
            backgroundColor: Colors.green.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (res['error']?.toString() == 'edit_window_closed' ||
          res['error']?.toString() == 'review_finalized') {
        await _loadReview();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['error']?.toString() == 'review_finalized'
                  ? (s.isKz ? '5 жұлдыз — пікірді өзгерту мүмкін емес' : 'Оценка 5★ — отзыв нельзя изменить')
                  : 'Окно редактирования закрыто',
              style: const TextStyle(fontSize: 15),
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadBids({bool silent = false}) async {
    final appState = Provider.of<AppState>(context, listen: false);
    // Only clients need to see bids
    if (appState.role != 'client') return;
    if (widget.order.status != 'new') return;
    if (!silent) setState(() => _bidsLoading = true);
    try {
      final bids = await ApiClient().getBids(widget.order.id);
      if (mounted) setState(() { _bids = bids; _bidsLoading = false; });
    } catch (_) {
      if (mounted && !silent) setState(() => _bidsLoading = false);
    }
  }

  Future<void> _acceptBid(S s, Bid bid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.acceptBid, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${bid.masterName} — ${bid.amount}₸\n${s.cancelOrderConfirm.replaceAll('заказ', 'предложение').replaceAll('тапсырысты', 'ұсынысты')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DDC84),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.yes),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await ApiClient().respondBid(bid.id, 'accept');
      if (!mounted) return;
      if (res['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.bidAccepted, style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        setState(() => _bids.clear());
        _loadMessages();
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  Future<void> _rejectBid(S s, Bid bid) async {
    try {
      await ApiClient().respondBid(bid.id, 'reject');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.bidRejected, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.orange.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      setState(() => _bids.removeWhere((b) => b.id == bid.id));
    } catch (_) {}
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      if (kDebugMode) {
        debugPrint('[chat] loading messages for order ${widget.order.id}');
      }
      final msgs = await ApiClient().getMessages(widget.order.id);
      if (kDebugMode) {
        debugPrint('[chat] loaded ${msgs.length} messages');
        if (msgs.isNotEmpty) {
          debugPrint('[chat] first msg: ${msgs.first}');
          debugPrint('[chat] last msg: ${msgs.last}');
        }
      }
      if (!mounted) return;
      final wasAtBottom = !_scrollController.hasClients ||
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 80;
      setState(() { _messages = msgs; _loading = false; });
      if (wasAtBottom && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[chat] ERROR loading messages: $e');
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  String _chatSendErrorText(S s, String? code) {
    if (code == 'chat_locked') return s.chatLockedWaitingMaster;
    if (code == 'chat_closed_perfect') return s.chatSendErrorClosedPerfect;
    if (code != null && code.isNotEmpty) return '${s.error}: $code';
    return s.loadError;
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;
    final appState = context.read<AppState>();
    if (_isMessageInputLocked(appState)) return;
    final o = widget.order;
    if (appState.role == 'client' && o.status == 'new' && (o.masterId ?? 0) <= 0) return;
    final s = S.lang(appState.language);
    setState(() => _sending = true);
    _msgController.clear();
    try {
      if (kDebugMode) {
        debugPrint('[chat] sending to order ${widget.order.id}: "$text"');
      }
      final res = await ApiClient().sendMessage(widget.order.id, text);
      if (kDebugMode) debugPrint('[chat] response: $res');
      if (res['ok'] == true) {
        _loadMessages();
      } else if (mounted) {
        final err = res['error']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_chatSendErrorText(s, err), style: const TextStyle(fontSize: 15)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _msgController.text = text;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.connectionError, style: const TextStyle(fontSize: 15)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _msgController.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMedia() async {
    if (_sending) return;
    final appState = context.read<AppState>();
    if (_isMessageInputLocked(appState)) return;
    final o = widget.order;
    if (appState.role == 'client' && o.status == 'new' && (o.masterId ?? 0) <= 0) return;
    final isDarkMode = appState.darkMode;
    final strings = S.lang(appState.language);
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF1CB7FF)),
              title: Text(strings.isKz ? 'Камера' : 'Камера'),
              onTap: () async {
                final f = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (mounted) Navigator.pop(context, f);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
              title: Text(strings.isKz ? 'Галерея' : 'Галерея'),
              onTap: () async {
                final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (mounted) Navigator.pop(context, f);
              },
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      final res = await ApiClient().sendMediaMessage(widget.order.id, picked.path);
      if (res['ok'] == true) {
        _loadMessages();
      } else if (mounted) {
        final err = res['error']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            err == 'chat_locked'
                ? strings.chatLockedWaitingMaster
                : err == 'chat_closed_perfect'
                    ? strings.chatSendErrorClosedPerfect
                    : '${strings.error}: ${err ?? '?'}',
            style: const TextStyle(fontSize: 15),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.connectionError, style: const TextStyle(fontSize: 15)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancelOrder() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final s = S.lang(appState.language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.cancelOrderTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(s.cancelOrderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.yes),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiClient().cancelOrder(widget.order.id, lang: appState.language);
      MasterLocationService.instance.stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.orderCancelledSuccess, style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {}
  }

  Future<void> _finish() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final s = S.lang(appState.language);
    final isMaster = appState.role == 'master';

    if (isMaster) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.masterConfirmFinish, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DDC84),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(s.yes),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await _doFinish(s, rating: 0, comment: '');
    } else {
      final result = await showDialog<_RatingResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RatingDialog(s: s),
      );
      if (result == null || !mounted) return;
      await _doFinish(s, rating: result.rating, comment: result.comment, withReview: result.rating > 0);
    }
  }

  Future<void> _reportUser(S s, int reportedId) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ReportUserDialog(s: s),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    try {
      await ApiClient().reportUser(reportedId: reportedId, reason: reason);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.reportSubmittedTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: Text(s.reportSubmittedBody, style: const TextStyle(fontSize: 15, height: 1.35)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.reportClose, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.connectionError, style: const TextStyle(fontSize: 15)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _mapFinishError(S s, String? code) {
    switch (code) {
      case 'bad_state':
        return s.finishErrorBadState;
      case 'forbidden':
        return s.finishErrorForbidden;
      case 'db_error':
        return s.finishErrorGeneric;
      default:
        return code != null && code.isNotEmpty ? '${s.error}: $code' : s.connectionError;
    }
  }

  Future<void> _doFinish(S s, {required int rating, required String comment, bool withReview = false}) async {
    if (_finishing) return; // guard against double-tap
    setState(() => _finishing = true);
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final result = await ApiClient().finishOrder(widget.order.id);
      if (result['ok'] != true) {
        if (!mounted) return;
        setState(() => _finishing = false);
        final err = result['error']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapFinishError(s, err), style: const TextStyle(fontSize: 15)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final d = result['data'];
      final bothDone = d is Map && (d['both_done'] == true || d['both_done'] == 1);
      if (bothDone && appState.role == 'master') {
        MasterLocationService.instance.stop();
      }

      if (withReview && widget.order.masterId != null) {
        try {
          final reviewResult = await ApiClient().sendReview(
            masterId: widget.order.masterId!,
            orderId: widget.order.id,
            rating: rating,
            comment: comment,
          );
          if (reviewResult['ok'] == true && mounted) {
            await _loadReview();
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _myDoneLocally = true;
        _finishing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.orderFinishedSuccess, style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _finishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.connectionError, style: const TextStyle(fontSize: 15)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final s = S.lang(appState.language);
    final myId = appState.user?.id ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final infoBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA);
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FA);
    final sentBubble = isDark ? const Color(0xFF2563EB) : const Color(0xFF1CB7FF);
    final receivedBubble = isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FA);
    final receivedText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final systemBg = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final systemText = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final mediaBtnBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final bidsPanelBg = isDark ? const Color(0xFF1A2E1A) : const Color(0xFFF0FFF4);
    final bidsPanelBorder = isDark ? const Color(0xFF2D5A2D) : const Color(0xFF86EFAC);
    final chatClosedPerfect = widget.order.status == 'completed' &&
        _reviewLoaded &&
        _review != null &&
        _review!.rating >= 5;
    final clientChatLocked = appState.role == 'client' &&
        widget.order.status == 'new' &&
        (widget.order.masterId ?? 0) <= 0;
    final messageInputLocked = clientChatLocked || chatClosedPerfect;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.order.displayTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            Text(
              s.orderStatus(widget.order.status),
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (appState.role == 'client' &&
              widget.order.status == 'in_progress' &&
              (widget.order.masterId ?? 0) > 0)
            IconButton(
              icon: Icon(Icons.map_rounded, color: textSecondary, size: 24),
              tooltip: s.masterMapWhere,
              onPressed: () => showMasterLocationMapSheet(
                context,
                orderId: widget.order.id,
                s: s,
                isDark: isDark,
                orderLat: widget.order.clientLat,
                orderLng: widget.order.clientLng,
              ),
            ),
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: textSecondary, size: 24),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderStatusScreen(order: widget.order, s: s)),
            ),
            tooltip: s.orderTimeline,
          ),
          if (widget.order.status == 'new' && appState.role == 'client')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 24),
              onPressed: _cancelOrder,
              tooltip: s.cancelOrderTitle,
            ),
          // Hide finish button if this user already confirmed completion
          if (widget.order.status == 'in_progress') ...[
            Builder(builder: (ctx) {
              final myDone = appState.role == 'master'
                  ? widget.order.masterDone
                  : widget.order.clientDone;
              // _myDoneLocally covers the case when Order object is stale
              // (orders list hasn't polled yet after finish was confirmed)
              return (!_myDoneLocally && myDone == 0)
                  ? IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF3DDC84), size: 28),
                      onPressed: _finishing ? null : _finish,
                      tooltip: appState.role == 'master' ? s.masterConfirmFinish : s.clientConfirmFinish,
                    )
                  : Tooltip(
                      message: 'Аяқтауды күтуде...',
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 24),
                      ),
                    );
            }),
          ],
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'report') {
                final reportedId = appState.role == 'master'
                    ? widget.order.clientId
                    : (widget.order.masterId ?? 0);
                if (reportedId > 0) _reportUser(s, reportedId);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 10),
                    Text(s.reportUser, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Order info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: infoBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.description,
                  style: TextStyle(fontSize: 15, color: textPrimary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 15, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(widget.order.address, style: TextStyle(fontSize: 14, color: textSecondary)),
                    const Spacer(),
                    Text(
                      '${widget.order.price} ₸',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1CB7FF)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Master: низкая оценка — обсудить в чате ─────────────────
          if (appState.role == 'master' &&
              widget.order.status == 'completed' &&
              _reviewLoaded &&
              _review != null &&
              _review!.rating < 5)
            _MasterLowRatingBanner(s: s, isDark: isDark),

          // ── Review banner (client only, completed orders) ───────────
          if (appState.role == 'client' && widget.order.status == 'completed' && _reviewLoaded) ...[
            if (_review != null)
              _ReviewEditBanner(
                review: _review!,
                s: s,
                isDark: isDark,
                onEdit: () => _editReview(s),
              ),
          ],

          // ── Bids panel (client only, new orders) ───────────────
          if (appState.role == 'client' && widget.order.status == 'new') ...[
            if (_bidsLoading && _bids.isEmpty)
              const LinearProgressIndicator(color: Color(0xFF3DDC84), minHeight: 2),
            if (!_bidsLoading && _bids.isEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bidsPanelBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bidsPanelBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 22, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.noBids,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          color: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_bids.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                decoration: BoxDecoration(
                  color: bidsPanelBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bidsPanelBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_rounded, size: 18, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.bidsTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_bids.length}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (int i = 0; i < _bids.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF2D5A2D) : const Color(0xFFD1FAE5)),
                      _BidCard(
                        bid: _bids[i],
                        s: s,
                        isDark: isDark,
                        onAccept: () => _acceptBid(s, _bids[i]),
                        onReject: () => _rejectBid(s, _bids[i]),
                      ),
                    ],
                    const SizedBox(height: 6),
                  ],
                ),
              ),
          ],

          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1CB7FF)))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          s.noMessages,
                          style: TextStyle(fontSize: 16, color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          final isSystem = msg['is_system'] == 1 || msg['is_system'] == '1';
                          final senderId = int.tryParse(msg['sender_id']?.toString() ?? '0') ?? 0;
                          final isMine = senderId == myId;
                          // API aliases message AS body; support both field names
                          final msgText = (msg['body'] ?? msg['message'])?.toString() ?? '';
                          final msgType = msg['msg_type']?.toString() ?? 'text';
                          final rawUrl = msg['file_url']?.toString() ?? '';
                          final fileUrl = resolveUploadUrl(rawUrl);

                          if (isSystem) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: systemBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    msgText,
                                    style: TextStyle(fontSize: 13, color: systemText),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.symmetric(
                                horizontal: msgType == 'image' ? 4 : 14,
                                vertical: msgType == 'image' ? 4 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMine ? sentBubble : receivedBubble,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: msgType == 'image' && fileUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        fileUrl,
                                        width: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      msgText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isMine ? Colors.white : receivedText,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
          ),

          // Input (клиент не пишет, пока заказ «жаңа» и мастер таңдалмаған)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: messageInputLocked
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, color: textSecondary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              chatClosedPerfect ? s.chatClosedPerfectHint : s.chatLockedWaitingMaster,
                              style: TextStyle(fontSize: 14, height: 1.35, color: textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: mediaBtnBg,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.attach_file_rounded, color: textSecondary, size: 20),
                            onPressed: _sending ? null : _sendMedia,
                            tooltip: 'Фото жіберу',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            style: TextStyle(fontSize: 16, color: textPrimary),
                            enabled: !_sending,
                            decoration: InputDecoration(
                              hintText: s.messageHint,
                              hintStyle: TextStyle(color: textSecondary),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _sending ? (isDark ? const Color(0xFF475569) : Colors.grey.shade300) : sentBubble,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                                  onPressed: _sendMessage,
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bid card widget ───────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  final Bid bid;
  final S s;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _BidCard({
    required this.bid,
    required this.s,
    required this.isDark,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cardInner = isDark ? const Color(0xFF1E293B) : Colors.white;
    final nameColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final priceColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Material(
        color: cardInner,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _hexColor(bid.masterAvatarColor),
                    backgroundImage: () {
                      final u = bid.masterAvatarUrl;
                      if (u == null || u.isEmpty) return null;
                      final abs = resolveUploadUrl(u);
                      if (abs.isEmpty) return null;
                      return NetworkImage(abs);
                    }(),
                    child: bid.masterAvatarUrl == null || bid.masterAvatarUrl!.isEmpty
                        ? Text(
                            bid.masterName.isNotEmpty ? bid.masterName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                bid.masterName.isNotEmpty ? bid.masterName : (s.isKz ? 'Шебер' : 'Мастер'),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: nameColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (bid.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bid.amount} ₸',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: priceColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onReject,
                      child: Text(s.rejectBid, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3DDC84),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onAccept,
                      child: Text(s.acceptBid, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF1CB7FF);
    }
  }
}

// ── Report user (full dialog: reason + optional details) ──────────────────────

class _ReportUserDialog extends StatefulWidget {
  final S s;
  const _ReportUserDialog({required this.s});

  @override
  State<_ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<_ReportUserDialog> {
  late final List<String> _reasons;
  int _selected = 0;
  late final TextEditingController _otherCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.s;
    _reasons = [
      s.reportReasonInappropriate,
      s.reportReasonFraud,
      s.reportReasonNoShow,
      s.reportReasonOther,
    ];
    _otherCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isOther = _selected == _reasons.length - 1;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.reportUser, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.reportReasonPick, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            ...List.generate(_reasons.length, (i) {
              return RadioListTile<int>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: i,
                // ignore: deprecated_member_use
                groupValue: _selected,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selected = v ?? 0),
                title: Text(_reasons[i], style: const TextStyle(fontSize: 15)),
              );
            }),
            if (isOther) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _otherCtrl,
                decoration: InputDecoration(
                  hintText: s.reportCommentHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: () {
            var reason = _reasons[_selected];
            if (isOther) {
              final extra = _otherCtrl.text.trim();
              if (extra.isNotEmpty) reason = '$reason: $extra';
            }
            Navigator.pop(context, reason);
          },
          child: Text(s.reportSend, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Rating result ─────────────────────────────────────────────────────────────

class _RatingResult {
  final int rating;
  final String comment;
  const _RatingResult(this.rating, this.comment);
}

// ── Rating dialog ─────────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final S      s;
  final int    initialRating;
  final String initialComment;
  final bool   isEdit;

  const _RatingDialog({
    required this.s,
    this.initialRating  = 0,
    this.initialComment = '',
    this.isEdit         = false,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  late int    _rating;
  late final TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _rating      = widget.initialRating;
    _commentCtrl = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              widget.isEdit ? 'Изменить отзыв' : s.rateTheMaster,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.isEdit ? 'Обновите оценку и комментарий' : s.rateSubtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: filled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Comment
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: s.impressionHint,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 16),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rating > 0 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _rating > 0
                    ? () => Navigator.pop(context, _RatingResult(_rating, _commentCtrl.text.trim()))
                    : null,
                child: Text(
                  widget.isEdit ? 'Сохранить' : s.sendRating,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!widget.isEdit)
              TextButton(
                onPressed: () => Navigator.pop(context, const _RatingResult(0, '')),
                child: Text(s.skipRating, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Master: низкая оценка ─────────────────────────────────────────────────────

class _MasterLowRatingBanner extends StatelessWidget {
  final S s;
  final bool isDark;

  const _MasterLowRatingBanner({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF292524) : const Color(0xFFFFF1F2);
    final border = isDark ? const Color(0xFF57534E) : const Color(0xFFFECDD3);
    final titleC = isDark ? Colors.white : const Color(0xFF881337);
    final subC = isDark ? const Color(0xFF94A3B8) : const Color(0xFF9F1239);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('😞', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.masterLowRatingTitle,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: titleC),
                ),
                const SizedBox(height: 6),
                Text(
                  s.masterLowRatingSubtitle,
                  style: TextStyle(fontSize: 13, height: 1.35, color: subC),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Client review banner ──────────────────────────────────────────────────────

class _ReviewEditBanner extends StatelessWidget {
  final Review review;
  final S s;
  final bool isDark;
  final VoidCallback onEdit;

  const _ReviewEditBanner({
    required this.review,
    required this.s,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final stars = '⭐' * review.rating;
    final canEditReview = review.canEdit && review.rating < 5;
    final timeLabel = review.timeRemainingLabel;
    final commentColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    late final Color bg;
    late final Color borderColor;
    late final Color titleColor;
    if (review.rating >= 5) {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
      titleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    } else if (canEditReview) {
      bg = isDark ? const Color(0xFF422006) : const Color(0xFFFFF7ED);
      borderColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFFBBF24);
      titleColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    } else {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
      titleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(stars, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.reviewClientBannerTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: TextStyle(fontSize: 13, color: commentColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (review.rating >= 5) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.reviewFiveStarsImmutable,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                    ),
                  ),
                ],
                if (canEditReview && timeLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${s.reviewEditDeadlinePrefix}$timeLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canEditReview) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.edit_rounded, size: 15),
              label: Text(s.reviewEditButton, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onPressed: onEdit,
            ),
          ],
        ],
      ),
    );
  }
}
