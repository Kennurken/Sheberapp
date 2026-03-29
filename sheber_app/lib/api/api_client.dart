import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'dart:ui' show VoidCallback;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import '../models/order.dart';
import '../models/master.dart';
import '../models/bid.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  late CookieJar cookieJar;
  String _csrfToken = '';

  final String baseUrl = kProdBaseUrl;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
      },
    ));
  }

  /// Callback invoked when a 401 response is received (session expired).
  /// Set by the app entry point to trigger logout + navigation.
  VoidCallback? onSessionExpired;

  Future<void> init() async {
    if (!kIsWeb) {
      final appDocDir = await getApplicationDocumentsDirectory();
      cookieJar = PersistCookieJar(
        ignoreExpires: true,
        storage: FileStorage("${appDocDir.path}/.cookies/"),
      );
      dio.interceptors.add(CookieManager(cookieJar));
    } else {
      cookieJar = CookieJar();
    }

    // Log network/API failures in debug; forward 401 to session handler
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, ErrorInterceptorHandler handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ${e.requestOptions.uri} → ${e.type.name}: ${e.message}',
          );
        }
        if (e.response?.statusCode == 401) {
          onSessionExpired?.call();
        }
        handler.next(e);
      },
    ));
  }

  /// Clear persistent cookies on logout.
  Future<void> clearSession() async {
    _csrfToken = '';
    try {
      await cookieJar.deleteAll();
    } catch (_) {}
  }

  // ---------- URL HELPER ----------
  String absoluteUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl/$path';
  }

  // ---------- CSRF ----------
  void setCsrfToken(String token) {
    _csrfToken = token;
  }

  Map<String, String> get _csrfHeaders =>
      _csrfToken.isNotEmpty ? {'X-CSRF-TOKEN': _csrfToken} : {};

  // ---------- AUTH ----------
  Future<Map<String, dynamic>> sendCode(String phone) async {
    final resp = await dio.post(
      '/api/mobile_auth.php?action=send_code',
      data: {'phone': phone},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyCode(String phone, String code) async {
    final resp = await dio.post(
      '/api/mobile_auth.php?action=verify_code',
      data: {'phone': phone, 'code': code},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final resp = await dio.post(
      '/api/mobile_auth.php?action=me',
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- ROLE ----------
  Future<Map<String, dynamic>> switchRole(String targetRole, {String profession = ''}) async {
    final resp = await dio.post(
      '/api/role_switch.php',
      data: {
        'target_role': targetRole,
        'profession': profession,
        'csrf_token': _csrfToken,
      },
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- ORDERS ----------
  Future<Map<String, dynamic>> createOrder({
    required String serviceTitle,
    required String description,
    required String address,
    required int price,
    int categoryId = 0,
    List<File> photoFiles = const [],
    double? clientLat,
    double? clientLng,
  }) async {
    final map = <String, dynamic>{
      'service_title': serviceTitle,
      'description': description,
      'address': address,
      'price': price,
      'category_id': categoryId,
      'csrf_token': _csrfToken,
    };
    if (clientLat != null && clientLng != null) {
      map['client_lat'] = clientLat.toString();
      map['client_lng'] = clientLng.toString();
    }

    // Attach photo files as multipart
    if (photoFiles.isNotEmpty) {
      final multipartFiles = <MultipartFile>[];
      for (final f in photoFiles) {
        final ext = f.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        multipartFiles.add(await MultipartFile.fromFile(
          f.path,
          contentType: MediaType('image', ext),
        ));
      }
      map['photos'] = multipartFiles;
    }

    final formData = FormData.fromMap(map);
    final resp = await dio.post(
      '/api/orders_create.php',
      data: formData,
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Order>> getOrdersFeed({String city = ''}) async {
    final resp = await dio.get('/api/orders_feed.php',
        queryParameters: city.isNotEmpty ? {'city': city} : null);
    final data = resp.data as Map<String, dynamic>;
    if (kDebugMode) {
      debugPrint('[feed] orders=${(data['data'] as List?)?.length}');
    }
    if (data['ok'] == true && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Order>> getMyOrders() async {
    final resp = await dio.get('/api/orders_list.php');
    final data = resp.data as Map<String, dynamic>;
    if (data['ok'] == true && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Single order for chat / push deep link (`order_get.php`).
  Future<Order?> getOrderById(int orderId) async {
    if (orderId <= 0) return null;
    try {
      final resp = await dio.get('/api/order_get.php?order_id=$orderId');
      final data = resp.data as Map<String, dynamic>;
      if (data['ok'] == true && data['data'] is Map<String, dynamic>) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    final resp = await dio.post(
      '/api/orders_accept.php',
      data: {
        'order_id': orderId,
        'csrf_token': _csrfToken,
      },
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> finishOrder(int orderId) async {
    final resp = await dio.post(
      '/api/order_finish.php',
      data: {
        'order_id': orderId,
        'csrf_token': _csrfToken,
      },
      options: Options(
        headers: _csrfHeaders,
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'ok': false, 'error': 'bad_response'};
  }

  // ---------- MESSAGES ----------
  Future<List<Map<String, dynamic>>> getMessages(int orderId) async {
    final resp = await dio.get('/api/messages_list.php?order_id=$orderId');
    final data = resp.data as Map<String, dynamic>;
    if (kDebugMode) {
      debugPrint('[api] getMessages raw: ok=${data['ok']}, dataType=${data['data']?.runtimeType}');
    }
    if (data['ok'] == true) {
      // API returns { ok: true, data: { me: uid, messages: [...], other: {...} } }
      final inner = data['data'];
      List<dynamic>? msgs;
      if (inner is Map) {
        msgs = inner['messages'] as List?;
        if (kDebugMode) {
          debugPrint('[api] getMessages Map, count=${msgs?.length}, me=${inner['me']}');
        }
      } else if (inner is List) {
        msgs = inner; // legacy fallback
        if (kDebugMode) {
          debugPrint('[api] getMessages List legacy, count=${msgs.length}');
        }
      } else if (kDebugMode) {
        debugPrint('[api] getMessages unexpected inner: ${inner.runtimeType}');
      }
      if (msgs != null) {
        return msgs.whereType<Map<String, dynamic>>().toList();
      }
    } else if (kDebugMode) {
      debugPrint('[api] getMessages FAILED: error=${data['error']}');
    }
    return [];
  }

  Future<Map<String, dynamic>> sendMessage(int orderId, String text) async {
    final resp = await dio.post(
      '/api/messages_send.php',
      data: {
        'order_id': orderId,
        'message': text,
        'csrf_token': _csrfToken,
      },
      options: Options(
        headers: _csrfHeaders,
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'ok': false, 'error': 'bad_response'};
  }

  Future<Map<String, dynamic>> sendMediaMessage(int orderId, String filePath) async {
    final formData = FormData.fromMap({
      'order_id': orderId,
      'csrf_token': _csrfToken,
      'file': await MultipartFile.fromFile(filePath),
    });
    final resp = await dio.post(
      '/api/message_upload.php',
      data: formData,
      options: Options(
        headers: _csrfHeaders,
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'ok': false, 'error': 'bad_response'};
  }

  // ---------- MASTERS ----------
  Future<List<Master>> getMasters(
    String city, {
    bool allCities = false,
    String query = '',
    int offset = 0,
    int limit = 20,
    int? categoryId,
    double minRating = 0,
  }) async {
    final params = <String, dynamic>{
      if (allCities) 'all_cities': 1 else 'city': city,
      'limit': limit < 1 ? 20 : (limit > 100 ? 100 : limit),
      'offset': offset < 0 ? 0 : offset,
      if (query.isNotEmpty) 'q': query,
      'category_id': ?categoryId,
      'min_rating': ?(minRating > 0 ? minRating : null),
    };
    final resp = await dio.get('/api/masters_list.php', queryParameters: params);
    final data = resp.data as Map<String, dynamic>;
    if (data['ok'] == true && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Master.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> sendReview({
    required int masterId,
    required int orderId,
    required int rating,
    required String comment,
  }) async {
    final resp = await dio.post(
      '/api/reviews_send.php',
      data: {
        'master_id' : masterId,
        'order_id'  : orderId,
        'rating'    : rating,
        'comment'   : comment,
        'csrf_token': _csrfToken,
      },
      options: Options(
        headers: _csrfHeaders,
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'ok': false, 'error': 'bad_response'};
  }

  /// Fetch review for an order (includes can_edit, editable_until)
  Future<Map<String, dynamic>> getReview(int orderId) async {
    final resp = await dio.get(
      '/api/review_get.php',
      queryParameters: {'order_id': orderId},
      options: Options(validateStatus: (s) => s != null && s < 600),
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'ok': false, 'error': 'bad_response'};
  }

  // ---------- PROFILE ----------
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async {
    fields['csrf_token'] = _csrfToken;
    final resp = await dio.post(
      '/api/profile_update.php',
      data: fields,
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  /// GET — задан ли пароль для входа по email (SMS-сессия достаточна).
  Future<Map<String, dynamic>> getPasswordStatus() async {
    final resp = await dio.get('/api/password_status.php');
    return resp.data as Map<String, dynamic>;
  }

  /// Смена или первая установка пароля (требуется активная сессия).
  Future<Map<String, dynamic>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    final data = <String, dynamic>{
      'new_password': newPassword,
      'csrf_token': _csrfToken,
    };
    if (currentPassword != null && currentPassword.isNotEmpty) {
      data['current_password'] = currentPassword;
    }
    final resp = await dio.post(
      '/api/password_change.php',
      data: data,
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- AVATAR ----------
  /// Upload profile photo — uses /api/avatar_upload.php (field name: 'avatar')
  Future<Map<String, dynamic>> uploadAvatar(File file) async {
    final ext = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType('image', ext),
      ),
      'csrf_token': _csrfToken,
    });
    final resp = await dio.post(
      '/api/avatar_upload.php',
      data: formData,
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- MASTER REVIEWS ----------
  Future<List<Map<String, dynamic>>> getMasterReviews(int masterId) async {
    try {
      final resp = await dio.get(
        '/api/master_reviews.php',
        queryParameters: {'master_id': masterId},
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['ok'] == true && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data'] as List);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[getMasterReviews] error: $e');
    }
    return [];
  }

  // ---------- PHOTOS ----------
  Future<String> uploadPhoto(File file) async {
    final ext = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType('image', ext),
      ),
      'csrf_token': _csrfToken,
    });
    final resp = await dio.post(
      '/api/photo_upload.php',
      data: formData,
      options: Options(headers: _csrfHeaders),
    );
    final body = resp.data as Map<String, dynamic>;
    final data = body['data'];
    if (data == null || data is! Map) {
      throw Exception(body['error']?.toString() ?? 'upload_failed');
    }
    final url = (data['url'] ?? '').toString();
    return absoluteUrl(url);
  }

  // ---------- CANCEL ----------
  Future<Map<String, dynamic>> cancelOrder(int orderId, {String lang = 'kz'}) async {
    final resp = await dio.post(
      '/api/orders_cancel.php',
      data: {
        'order_id': orderId,
        'lang': lang,
        'csrf_token': _csrfToken,
      },
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- BIDS ----------
  Future<Map<String, dynamic>> submitBid(int orderId, int amount) async {
    final resp = await dio.post(
      '/api/orders_bid.php',
      data: {'order_id': orderId, 'amount': amount, 'csrf_token': _csrfToken},
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> respondBid(int bidId, String action) async {
    final resp = await dio.post(
      '/api/orders_bid_respond.php',
      data: {'bid_id': bidId, 'action': action, 'csrf_token': _csrfToken},
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Bid>> getBids(int orderId) async {
    final resp = await dio.get('/api/orders_bids_list.php?order_id=$orderId');
    final data = resp.data as Map<String, dynamic>;
    if (data['ok'] == true && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Bid.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<int> getUnreadNotifications() async {
    try {
      final resp = await dio.get(
        '/api/notifications_list.php',
        options: Options(validateStatus: (s) => s != null && s < 600),
      );
      final raw = resp.data;
      if (raw is! Map) return 0;
      final data = Map<String, dynamic>.from(raw);
      if (data['ok'] != true && data['ok'] != 1) return 0;
      final u = data['unread'];
      if (u is int) return u;
      if (u is num) return u.toInt();
      return 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[getUnreadNotifications] error: $e');
      return 0;
    }
  }

  // ---------- PUSH TOKENS ----------
  Future<void> registerPushToken(String token) async {
    try {
      await dio.post(
        '/api/push_register.php',
        data: {'token': token, 'platform': 'android', 'csrf_token': _csrfToken},
        options: Options(headers: _csrfHeaders),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[registerPushToken] error: $e');
    }
  }

  // ---------- REVIEW UPDATE ----------
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int rating,
    required String comment,
  }) async {
    final resp = await dio.post(
      '/api/review_update.php',
      data: {
        'review_id': reviewId,
        'rating': rating,
        'comment': comment,
        'csrf_token': _csrfToken,
      },
      options: Options(
        headers: _csrfHeaders,
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'ok': false, 'error': 'bad_response'};
  }

  // ---------- YANDEX ADDRESS SUGGEST ----------
  Future<List<String>> suggestAddress(String query) async {
    if (query.length < 3) return [];
    try {
      final resp = await dio.get(
        'https://suggest-maps.yandex.ru/suggest-geo',
        queryParameters: {
          'text': query,
          'lang': 'ru_KZ',
          'results': '6',
          'bbox': '60.09,43.18,66.98,48.73', // Kazakhstan bbox
          'type': 'geo',
        },
      );
      final data = resp.data;
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((r) {
              final title = (r['title'] as Map?)?['text']?.toString() ?? '';
              final subtitle = (r['subtitle'] as Map?)?['text']?.toString();
              return subtitle != null ? '$title, $subtitle' : title;
            })
            .where((s) => s.isNotEmpty)
            .toList()
            .cast<String>();
      }
    } catch (_) {}
    return [];
  }

  /// Геокодирование адреса через Nominatim (OSM). Возвращает координаты в границах Казахстана или null.
  /// User-Agent обязателен по политике Nominatim; не вызывать чаще ~1 раз/с с одного устройства.
  Future<({double lat, double lng})?> geocodeAddress(String address) async {
    final q = address.trim();
    if (q.length < 5) return null;
    try {
      final resp = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: <String, dynamic>{
          'q': '$q, Kazakhstan',
          'format': 'json',
          'limit': 1,
          'countrycodes': 'kz',
        },
        options: Options(
          headers: <String, dynamic>{
            'User-Agent': 'SheberKZ/1.0 (Flutter; +https://kmaruk4u.beget.tech/)',
          },
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final data = resp.data;
      if (data is! List || data.isEmpty) return null;
      final m = data.first;
      if (m is! Map) return null;
      final lat = double.tryParse(m['lat']?.toString() ?? '');
      final lng = double.tryParse(m['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;
      if (!_coordRoughlyKazakhstan(lat, lng)) return null;
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  static bool _coordRoughlyKazakhstan(double lat, double lng) {
    return lat >= 40.2 && lat <= 55.5 && lng >= 46.0 && lng <= 87.5;
  }

  /// Reverse geocode coordinates to address (Nominatim OSM).
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final resp = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: <String, dynamic>{
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'ru',
          'zoom': 16,
        },
        options: Options(
          headers: <String, dynamic>{
            'User-Agent': 'SheberKZ/1.0 (Flutter; +https://kmaruk4u.beget.tech/)',
          },
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final data = resp.data as Map<String, dynamic>?;
      if (data == null) return '';
      final addr = data['address'] as Map<String, dynamic>?;
      if (addr == null) return data['display_name']?.toString() ?? '';
      final parts = <String>[];
      final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '';
      final road = addr['road'] ?? addr['pedestrian'] ?? '';
      final house = addr['house_number'] ?? '';
      if (city.toString().isNotEmpty) parts.add(city.toString());
      if (road.toString().isNotEmpty) parts.add(road.toString());
      if (house.toString().isNotEmpty) parts.add(house.toString());
      return parts.isNotEmpty ? parts.join(', ') : (data['display_name']?.toString() ?? '');
    } catch (_) {
      return '';
    }
  }

  // ---------- REPORTS ----------
  Future<Map<String, dynamic>> reportUser({
    required int reportedId,
    required String reason,
  }) async {
    final resp = await dio.post(
      '/api/report_user.php',
      data: {
        'reported_id': reportedId,
        'reason': reason,
        'csrf_token': _csrfToken,
      },
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- EMAIL AUTH ----------
  Future<Map<String, dynamic>> emailLogin(String email, String password) async {
    final resp = await dio.post(
      '/api/email_auth.php?action=login',
      data: {'email': email, 'password': password},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> emailRegister(String name, String email, String password, {String role = 'client'}) async {
    final resp = await dio.post(
      '/api/email_auth.php?action=register',
      data: {'name': name, 'email': email, 'password': password, 'role': role},
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- SUPPORT ----------
  Future<Map<String, dynamic>> sendSupportMessage(String message) async {
    final resp = await dio.post(
      '/api/support_send.php',
      data: {
        'message': message,
        'csrf_token': _csrfToken,
      },
      options: Options(
        headers: _csrfHeaders,
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    final raw = resp.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'ok': false, 'error': 'bad_response'};
  }

  Future<List<Map<String, dynamic>>> getSupportMessages({int since = 0}) async {
    final resp = await dio.get(
      '/api/support_messages.php',
      queryParameters: {'since': since},
      options: Options(validateStatus: (s) => s != null && s < 600),
    );
    final raw = resp.data;
    if (raw is! Map) return [];
    final data = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
    if (data['ok'] == true && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  // ---------- GPS LOCATION ----------
  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    final resp = await dio.post(
      '/api/location_update.php',
      data: {'lat': lat, 'lng': lng, 'csrf_token': _csrfToken},
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMasterLocation({int? masterId, int? orderId}) async {
    final params = <String, dynamic>{};
    if (masterId != null) params['master_id'] = masterId;
    if (orderId != null) params['order_id'] = orderId;
    final resp = await dio.get('/api/location_get.php', queryParameters: params);
    return resp.data as Map<String, dynamic>;
  }

  // ---------- MASTER PROFILE (FULL) ----------
  Future<Map<String, dynamic>> getMasterProfile(int masterId) async {
    final resp = await dio.get('/api/master_profile.php', queryParameters: {'master_id': masterId});
    return resp.data as Map<String, dynamic>;
  }

  // ---------- PORTFOLIO ----------
  Future<List<Map<String, dynamic>>> getOwnPortfolioPhotos() async {
    final resp = await dio.get('/api/portfolio_photos.php');
    final data = resp.data as Map<String, dynamic>;
    if (data['ok'] == true && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> uploadPortfolioPhoto(File file, {String caption = ''}) async {
    final path = file.path.toLowerCase();
    final ext = path.endsWith('.png') ? 'png' : path.endsWith('.webp') ? 'webp' : 'jpg';
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path, contentType: MediaType('image', ext)),
      'caption': caption,
      'csrf_token': _csrfToken,
    });
    final resp = await dio.post(
      '/api/portfolio_photos.php',
      data: formData,
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deletePortfolioPhoto(int photoId) async {
    final resp = await dio.delete(
      '/api/portfolio_photos.php',
      data: 'photo_id=$photoId',
      options: Options(
        headers: {..._csrfHeaders, 'Content-Type': 'application/x-www-form-urlencoded',
                   'X-CSRF-TOKEN': _csrfToken},
      ),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ---------- SUBSCRIPTIONS ----------
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final resp = await dio.get('/api/subscription_status.php');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> buySubscription(int planId) async {
    final resp = await dio.post(
      '/api/subscription_buy.php',
      data: {'plan_id': planId, 'csrf_token': _csrfToken},
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    final resp = await dio.post(
      '/api/subscription_cancel.php',
      data: {'csrf_token': _csrfToken},
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resumeSubscription() async {
    final resp = await dio.post(
      '/api/subscription_resume.php',
      data: {'csrf_token': _csrfToken},
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changeSubscription(int newPlanId) async {
    final resp = await dio.post(
      '/api/subscription_change.php',
      data: {'new_plan_id': newPlanId, 'csrf_token': _csrfToken},
      options: Options(headers: _csrfHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }
}