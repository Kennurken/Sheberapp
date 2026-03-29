import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/master.dart';

class AppState extends ChangeNotifier {
  User? _user;
  String _csrfToken = '';
  List<Order> _myOrders = [];
  List<Order> _feedOrders = [];
  List<Master> _masters = [];
  bool _isLoading = false;
  String _selectedCity = '';
  String _language = 'kz'; // 'kz' or 'ru'
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  int _highestTierShown = 0;
  int _professionVersion = 0; // incremented when profession changes → triggers feed reload

  User? get user => _user;
  String get csrfToken => _csrfToken;
  List<Order> get myOrders => _myOrders;
  List<Order> get feedOrders => _feedOrders;
  List<Master> get masters => _masters;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String get role => _user?.role ?? 'client';
  String get selectedCity => _selectedCity;
  String get language => _language;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  int get highestTierShown => _highestTierShown;
  int get professionVersion => _professionVersion;

  void bumpProfessionVersion() {
    _professionVersion++;
    notifyListeners();
  }

  /// Call once at app startup to restore persisted preferences.
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'kz';
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    // Only Кызылорда is active during beta — always override stored value
    _selectedCity = 'Қызылорда';
    await prefs.setString('selected_city', 'Қызылорда');
    _highestTierShown = prefs.getInt('highest_tier_shown') ?? 0;
    notifyListeners();
  }

  void setUser(User? user) {
    _user = user;
    if (user != null) {
      _saveUserCache(user);
    }
    notifyListeners();
  }

  /// Обновить пользователя и кэш без немедленного [notifyListeners].
  /// Нужно при закрытии modal bottom sheet: иначе глобальный rebuild пока overlay
  /// ещё в разборке даёт crash `'_dependents.isEmpty': is not true` в framework.dart.
  void setUserQuiet(User user) {
    _user = user;
    _saveUserCache(user);
  }

  /// Вызвать после [setUserQuiet], когда дерево виджетов готово к глобальному rebuild.
  void flushListeners() => notifyListeners();

  void setCsrfToken(String token) {
    _csrfToken = token;
  }

  void setRole(String role) {
    if (_user != null) {
      _user = _user!.copyWith(role: role);
      _saveUserCache(_user!);
      notifyListeners();
    }
  }

  void setSelectedCity(String city) {
    _selectedCity = city;
    SharedPreferences.getInstance().then((p) => p.setString('selected_city', city));
    notifyListeners();
  }

  void setMyOrders(List<Order> orders) {
    _myOrders = orders;
    notifyListeners();
  }

  void setFeedOrders(List<Order> orders) {
    _feedOrders = orders;
    notifyListeners();
  }

  void setMasters(List<Master> masters) {
    _masters = masters;
    notifyListeners();
  }

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    SharedPreferences.getInstance().then((p) => p.setString('language', lang));
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    SharedPreferences.getInstance().then((p) => p.setBool('dark_mode', _darkMode));
    notifyListeners();
  }

  void setNotifications(bool v) {
    _notificationsEnabled = v;
    SharedPreferences.getInstance().then((p) => p.setBool('notifications', v));
    notifyListeners();
  }

  Future<void> markTierShown(int tier) async {
    _highestTierShown = tier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highest_tier_shown', tier);
  }

  static const _kCachedUser = 'cached_user_v1';

  void _saveUserCache(User u) {
    final map = {
      'id': u.id,
      'name': u.name,
      'role': u.role,
      'phone': u.phone,
      'city': u.city,
      'avatar_url': u.avatarUrl,
      'avatar_color': u.avatarColor,
      'profession': u.profession,
      'bio': u.bio,
      'experience': u.experience,
      'subscription': u.subscription,
      'subscription_expires_at': u.subscriptionExpiresAt?.toIso8601String(),
      'subscription_is_trial': u.subscriptionIsTrial,
    };
    SharedPreferences.getInstance()
        .then((p) => p.setString(_kCachedUser, jsonEncode(map)));
  }

  Future<User?> _loadUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedUser);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return User.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedUser);
  }

  /// Called once at startup — if a valid session cookie exists, restore user.
  /// Falls back to cached user data if server is unreachable.
  Future<void> tryRestoreSession() async {
    try {
      final resp = await ApiClient().getMe();
      if (resp['ok'] == true) {
        final data = resp['data'] as Map<String, dynamic>?;
        if (data != null) {
          final userData = data['user'] as Map<String, dynamic>?;
          if (userData != null) {
            _user = User.fromJson(userData);
            _saveUserCache(_user!);
            final token = data['csrf_token']?.toString() ?? '';
            if (token.isNotEmpty) {
              _csrfToken = token;
              ApiClient().setCsrfToken(token);
            }
            notifyListeners();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[AppState] tryRestoreSession server error: $e');
    }

    final cached = await _loadUserCache();
    if (cached != null) {
      _user = cached;
      notifyListeners();
      debugPrint('[AppState] restored user from local cache: ${cached.name}');
    }
  }

  Future<void> logout() async {
    _user = null;
    _csrfToken = '';
    _myOrders = [];
    _feedOrders = [];
    _masters = [];
    await _clearUserCache();
    try {
      await ApiClient().clearSession();
    } catch (_) {}
    notifyListeners();
  }
}
