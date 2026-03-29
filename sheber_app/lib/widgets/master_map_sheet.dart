import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_client.dart';
import '../l10n/app_strings.dart';

/// Нижний лист с картой (OSM): точка заказа [orderLat]/[orderLng] (если есть) + мастер по [orderId], опрос каждые 10 с.
Future<void> showMasterLocationMapSheet(
  BuildContext context, {
  required int orderId,
  required S s,
  required bool isDark,
  double? orderLat,
  double? orderLng,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MasterMapSheetBody(
      orderId: orderId,
      s: s,
      isDark: isDark,
      orderLat: orderLat,
      orderLng: orderLng,
    ),
  );
}

class _MasterMapSheetBody extends StatefulWidget {
  final int orderId;
  final S s;
  final bool isDark;
  final double? orderLat;
  final double? orderLng;

  const _MasterMapSheetBody({
    required this.orderId,
    required this.s,
    required this.isDark,
    this.orderLat,
    this.orderLng,
  });

  @override
  State<_MasterMapSheetBody> createState() => _MasterMapSheetBodyState();
}

class _MasterMapSheetBodyState extends State<_MasterMapSheetBody> {
  Timer? _poll;
  final MapController _mapController = MapController();
  double? _masterLat;
  double? _masterLng;
  String _name = '';
  bool _fresh = false;
  bool _loading = true;

  static const LatLng _kzFallback = LatLng(48.0, 66.9);

  bool _valid(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    return lat.abs() <= 90 && lng.abs() <= 180;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refitMap());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiClient().getMasterLocation(orderId: widget.orderId);
      if (!mounted) return;
      if (raw['ok'] != true) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _refitMap());
        return;
      }
      final d = raw['data'] as Map<String, dynamic>?;
      if (d == null) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _refitMap());
        return;
      }
      final lat = d['lat'];
      final lng = d['lng'];
      setState(() {
        _loading = false;
        _name = d['name']?.toString() ?? '';
        _fresh = d['is_fresh'] == true || d['is_fresh'] == 1;
        if (lat != null && lng != null) {
          _masterLat = (lat as num).toDouble();
          _masterLng = (lng as num).toDouble();
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _refitMap());
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _refitMap());
      }
    }
  }

  void _refitMap() {
    if (!mounted) return;
    final oOk = _valid(widget.orderLat, widget.orderLng);
    final mOk = _valid(_masterLat, _masterLng);
    if (!oOk && !mOk) return;
    final coords = <LatLng>[];
    if (oOk) coords.add(LatLng(widget.orderLat!, widget.orderLng!));
    if (mOk) coords.add(LatLng(_masterLat!, _masterLng!));
    try {
      if (coords.length >= 2) {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: coords,
            padding: const EdgeInsets.all(44),
            maxZoom: 16,
          ),
        );
      } else {
        _mapController.move(coords.single, 15);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.55;
    final card = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final oOk = _valid(widget.orderLat, widget.orderLng);

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF475569) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.s.masterMapTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: text),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_name, style: TextStyle(color: text.withValues(alpha: 0.8), fontSize: 14)),
              ),
            ),
          if (oOk || _valid(_masterLat, _masterLng))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (oOk)
                    _legendRow(
                      color: const Color(0xFFEA580C),
                      label: widget.s.orderMapWorkSite,
                      textColor: text,
                    ),
                  if (_valid(_masterLat, _masterLng))
                    _legendRow(
                      color: const Color(0xFF2563EB),
                      label: widget.s.orderMapMasterPin,
                      textColor: text,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildMap(text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow({required Color color, required String label, required Color textColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.85))),
      ],
    );
  }

  Widget _buildMap(Color textColor) {
    final oOk = _valid(widget.orderLat, widget.orderLng);
    final mOk = _valid(_masterLat, _masterLng);
    final hasAny = oOk || mOk;

    if (_loading && !hasAny) {
      return const ColoredBox(
        color: Color(0xFFE2E8F0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!hasAny) {
      return ColoredBox(
        color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.s.masterMapNoLocation,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withValues(alpha: 0.85), fontSize: 15),
            ),
          ),
        ),
      );
    }

    final initialCenter = oOk
        ? LatLng(widget.orderLat!, widget.orderLng!)
        : (_valid(_masterLat, _masterLng) ? LatLng(_masterLat!, _masterLng!) : _kzFallback);

    final markers = <Marker>[];
    if (oOk) {
      markers.add(
        Marker(
          point: LatLng(widget.orderLat!, widget.orderLng!),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Tooltip(
            message: widget.s.orderMapWorkSite,
            child: const Icon(Icons.home_work_rounded, size: 40, color: Color(0xFFEA580C)),
          ),
        ),
      );
    }
    if (mOk) {
      markers.add(
        Marker(
          point: LatLng(_masterLat!, _masterLng!),
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Tooltip(
            message: widget.s.orderMapMasterPin,
            child: const Icon(Icons.location_pin, size: 48, color: Color(0xFF2563EB)),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sheberkz.Sheber.kz',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (mOk && !_fresh)
          Positioned(
            left: 8,
            right: 8,
            top: 8,
            child: Material(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  widget.s.masterMapStale,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
