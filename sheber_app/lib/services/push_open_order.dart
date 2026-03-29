import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../app_navigator.dart';
import '../l10n/app_strings.dart';
import '../providers/app_state.dart';
import '../screens/order_chat_screen.dart';

int? _parseOrderId(RemoteMessage message) {
  final d = message.data;
  final raw = d['order_id'] ?? d['orderId'];
  if (raw == null) return null;
  return int.tryParse(raw.toString());
}

/// Opens [OrderChatScreen] when push payload contains `order_id` / `orderId`.
Future<void> openOrderChatFromPushMessage(RemoteMessage message) async {
  final orderId = _parseOrderId(message);
  if (orderId == null || orderId <= 0) return;

  final nav = rootNavigatorKey.currentState;
  final ctx = rootNavigatorKey.currentContext;
  if (nav == null || ctx == null) return;

  final order = await ApiClient().getOrderById(orderId);
  if (!ctx.mounted) return;

  if (order == null) {
    var lang = 'ru';
    try {
      lang = Provider.of<AppState>(ctx, listen: false).language;
    } catch (_) {}
    final msg = S.lang(lang).pushOrderOpenError;
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(content: Text(msg)));
    return;
  }

  nav.push(
    MaterialPageRoute<void>(builder: (_) => OrderChatScreen(order: order)),
  );
}
