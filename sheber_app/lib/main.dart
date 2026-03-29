import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api/api_client.dart';
import 'app_navigator.dart';
import 'providers/app_state.dart';
import 'screens/main_shell.dart';
import 'services/push_open_order.dart';
import 'services/fcm_sync.dart';
import 'theme/app_theme.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are shown automatically by FCM on Android
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — works even before google-services.json is placed
  // (will silently skip if file missing during development)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Firebase not configured yet — continue without push
  }

  await ApiClient().init();
  final appState = AppState();
  await appState.loadPreferences();

  ApiClient().onSessionExpired = () {
    appState.logout();
  };

  await appState.tryRestoreSession();

  try {
    await _initFcm(appState);
  } catch (_) {
    // FCM listeners / token registration optional
  }

  runApp(SheberApp(appState: appState));
}

Future<void> _initFcm(AppState appState) async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (appState.isLoggedIn && appState.csrfToken.isNotEmpty) {
    await syncFcmTokenToServer();
  }

  messaging.onTokenRefresh.listen((newToken) {
    if (!appState.isLoggedIn || appState.csrfToken.isEmpty) return;
    ApiClient().registerPushToken(newToken).catchError((_) {});
  });

  // Tap on notification while app in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    openOrderChatFromPushMessage(message);
  });

  // Foreground message handler — show in-app SnackBar when app is open
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body  = message.notification?.body  ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final hasOrderId = message.data.containsKey('order_id') || message.data.containsKey('orderId');

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: hasOrderId
            ? SnackBarAction(
                label: 'Открыть',
                textColor: const Color(0xFF1CB7FF),
                onPressed: () => openOrderChatFromPushMessage(message),
              )
            : null,
      ),
    );
  });
}

class SheberApp extends StatelessWidget {
  final AppState appState;
  const SheberApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        title: 'Sheber.kz',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        theme: sheberLightTheme(),
        darkTheme: sheberDarkTheme(),
        // Стабильный MaterialApp: themeMode не переключаем от AppState — иначе при
        // notifyListeners (drawer, профиль) пересоздаётся всё дерево → framework.dart
        // _dependents.isEmpty. Реальная тема — AnimatedTheme в builder.
        themeMode: ThemeMode.light,
        scrollBehavior: const SheberScrollBehavior(),
        builder: (context, child) {
          return Selector<AppState, bool>(
            selector: (_, s) => s.darkMode,
            shouldRebuild: (a, b) => a != b,
            builder: (context, darkMode, _) {
              return AnimatedTheme(
                duration: SheberTokens.themeSwitch,
                curve: SheberTokens.themeCurve,
                data: darkMode ? sheberDarkTheme() : sheberLightTheme(),
                child: Builder(
                  builder: (inner) => sheberThemeBuilder(inner, child),
                ),
              );
            },
          );
        },
        home: const _AppEntryPoint(),
      ),
    );
  }
}

/// Shows MainShell (guest mode) or LoginScreen depending on context.
/// The app is designed so guests can browse masters without login,
/// and login is only required for creating orders or chatting.
class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  bool _checkedInitialPush = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleColdStartPush());
  }

  Future<void> _handleColdStartPush() async {
    if (_checkedInitialPush) return;
    _checkedInitialPush = true;
    try {
      final msg = await FirebaseMessaging.instance.getInitialMessage();
      if (msg != null && mounted) await openOrderChatFromPushMessage(msg);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
