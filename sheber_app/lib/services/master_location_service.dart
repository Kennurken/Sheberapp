import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/api_client.dart';

/// Периодическая отправка координат мастера (каждые 30 с) для активного заказа.
class MasterLocationService {
  MasterLocationService._();
  static final MasterLocationService instance = MasterLocationService._();

  Timer? _timer;
  int? _orderId;

  /// Текущий отслеживаемый заказ (если есть).
  int? get activeOrderId => _orderId;

  Future<bool> ensurePermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    return status.isGranted;
  }

  /// Запуск трекинга для заказа [orderId]. Предыдущий таймер отменяется.
  void startTracking(int orderId) {
    if (orderId <= 0) return;
    stop();
    _orderId = orderId;
    unawaited(_tick());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _orderId = null;
  }

  Future<void> _tick() async {
    final oid = _orderId;
    if (oid == null) return;

    try {
      if (!await ensurePermission()) return;

      final order = await ApiClient().getOrderById(oid);
      if (order == null || order.status != 'in_progress') {
        stop();
        return;
      }

      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 25),
        ),
      );

      await ApiClient().updateLocation(pos.latitude, pos.longitude);
    } catch (_) {}
  }
}
