import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/api_client.dart';

/// Registers the current FCM device token with the API (needs session + CSRF).
Future<void> syncFcmTokenToServer() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await ApiClient().registerPushToken(token);
  } catch (_) {}
}
