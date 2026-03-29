import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/categories.dart';

class CreateOrderScreen extends StatefulWidget {
  final int? initialCategoryId;
  const CreateOrderScreen({super.key, this.initialCategoryId});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  final List<File> _photos = [];
  final _picker = ImagePicker();
  bool _loadingGps = false;

  // Yandex address autocomplete
  List<String> _addressSuggestions = [];
  bool _showSuggestions = false;
  final _addressFocusNode = FocusNode();
  Timer? _geocodeTimer;
  LatLng? _mapPoint;
  bool _geocodeLoading = false;
  String? _lastGeocodedAddress;
  /// Запрос, по которому последний раз завершился геокод (успех или нет).
  String? _lastFinishedGeocodeQuery;

  Future<void> _onAddressChanged(String text) async {
    if (text.length < 3) {
      _geocodeTimer?.cancel();
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
        if (text.trim().length < 5) {
          _mapPoint = null;
          _geocodeLoading = false;
          _lastGeocodedAddress = null;
          _lastFinishedGeocodeQuery = null;
        }
      });
      return;
    }
    final suggestions = await ApiClient().suggestAddress(text);
    if (!mounted) return;
    setState(() {
      _addressSuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
    _scheduleGeocode(text.trim());
  }

  void _scheduleGeocode(String trimmed) {
    if (trimmed.length < 5) return;
    _geocodeTimer?.cancel();
    _geocodeTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_addressController.text.trim() != trimmed) return;
      unawaited(_runGeocode(trimmed));
    });
  }

  Future<void> _runGeocode(String address) async {
    if (!mounted || address.length < 5) return;
    if (address == _lastGeocodedAddress && _mapPoint != null) return;
    setState(() => _geocodeLoading = true);
    final res = await ApiClient().geocodeAddress(address);
    if (!mounted) return;
    setState(() {
      _geocodeLoading = false;
      _lastFinishedGeocodeQuery = address;
      if (res == null) {
        _mapPoint = null;
        _lastGeocodedAddress = null;
      } else {
        _mapPoint = LatLng(res.lat, res.lng);
        _lastGeocodedAddress = address;
      }
    });
  }

  void _selectAddress(String address) {
    _addressController.text = address;
    setState(() { _showSuggestions = false; _addressSuggestions = []; });
    _addressFocusNode.unfocus();
    _geocodeTimer?.cancel();
    final t = address.trim();
    if (t.length >= 5) {
      unawaited(_runGeocode(t));
    } else {
      setState(() {
        _mapPoint = null;
        _lastGeocodedAddress = null;
        _lastFinishedGeocodeQuery = null;
        _geocodeLoading = false;
      });
    }
  }

  int _selectedCategoryIdx = 7; // defaults to "Басқа / Другое"

  @override
  void initState() {
    super.initState();
    _addressController.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.initialCategoryId != null) {
      final idx = kAppCategories.indexWhere((c) => c.id == widget.initialCategoryId);
      if (idx >= 0) _selectedCategoryIdx = idx;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectGpsLocation());
  }

  Future<void> _detectGpsLocation() async {
    if (!mounted) return;
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
    if (!mounted) return;
    setState(() => _loadingGps = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final address = await ApiClient().reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (address.isNotEmpty) {
        _addressController.text = address;
        setState(() {
          _mapPoint = LatLng(pos.latitude, pos.longitude);
          _lastGeocodedAddress = address;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingGps = false);
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked == null) return;
    setState(() => _photos.add(File(picked.path)));
  }

  Future<void> _submit() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final s = S.lang(appState.language);
    if (_descController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      _showError(s.errFillAllFields);
      return;
    }
    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (price < 500) {
      _showError(s.errOrderMinBudget);
      return;
    }
    if (price > 5000000) {
      _showError(s.isKz ? 'Бюджет тым жоғары (макс. 5 000 000₸)' : 'Бюджет слишком большой (макс. 5 000 000₸)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cat = kAppCategories[_selectedCategoryIdx];
      final result = await ApiClient().createOrder(
        serviceTitle: cat.nameKz,
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        price: price,
        categoryId: cat.id,
        photoFiles: _photos,
        clientLat: _mapPoint?.latitude,
        clientLng: _mapPoint?.longitude,
      );

      if (!mounted) return;
      if (result['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.isKz ? 'Тапсырыс жасалды! Шебер күтіңіз.' : 'Заказ создан! Ожидайте мастера.',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        _showError(result['error']?.toString() ?? s.errServerError);
      }
    } catch (e) {
      debugPrint('[createOrder] ERROR: $e');
      String msg = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        debugPrint('[createOrder] SERVER RESPONSE: $data');
        if (data is Map && data['error'] != null) {
          msg = 'error: ${data['error']}';
        } else if (data != null) {
          msg = data.toString();
        }
      }
      if (mounted) _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _geocodeTimer?.cancel();
    _descController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = S.lang(appState.language);
    final lang = appState.language;
    final isDark = appState.darkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final borderMuted = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.newOrder,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category
            _buildLabel(s.category, isDark),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedCategoryIdx,
                  isExpanded: true,
                  dropdownColor: cardColor,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1CB7FF)),
                  style: TextStyle(fontSize: 16, color: textColor),
                  items: List.generate(kAppCategories.length, (i) => DropdownMenuItem(
                    value: i,
                    child: Row(
                      children: [
                        Icon(kAppCategories[i].icon, size: 18, color: kAppCategories[i].color),
                        const SizedBox(width: 10),
                        Text(kAppCategories[i].name(lang)),
                      ],
                    ),
                  )),
                  onChanged: (v) => setState(() => _selectedCategoryIdx = v!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description
            _buildLabel(s.describeIssue, isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descController,
              hint: s.isKz
                  ? 'Мысалы: Асүйдегі кран ағады, ауыстыру керек...'
                  : 'Например: течёт кран на кухне, нужна замена...',
              maxLines: 4,
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // Address with Yandex autocomplete
            _buildLabel(s.address, isDark),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _addressController,
                  focusNode: _addressFocusNode,
                  style: TextStyle(fontSize: 16, color: textColor),
                  onChanged: _onAddressChanged,
                  decoration: InputDecoration(
                    hintText: s.isKz ? 'Қала, көше, үй, пәтер' : 'Город, улица, дом, квартира',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF1CB7FF)),
                    suffixIcon: _loadingGps
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1CB7FF)),
                            ),
                          )
                        : _addressController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                onPressed: () {
                                  _geocodeTimer?.cancel();
                                  _addressController.clear();
                                  setState(() {
                                    _showSuggestions = false;
                                    _mapPoint = null;
                                    _lastGeocodedAddress = null;
                                    _lastFinishedGeocodeQuery = null;
                                    _geocodeLoading = false;
                                  });
                                },
                              )
                            : null,
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF1CB7FF), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderMuted),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: _addressSuggestions.map((addr) => InkWell(
                        onTap: () => _selectAddress(addr),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF1CB7FF)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(addr, style: TextStyle(fontSize: 14, color: textColor))),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                _buildLabel(s.orderMapPreview, isDark),
                const SizedBox(height: 8),
                _buildAddressMiniMap(s, isDark, borderMuted, textColor),
              ],
            ),

            const SizedBox(height: 20),

            // Budget
            _buildLabel(s.budget, isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _priceController,
              hint: s.isKz ? '500 ₸ бастап' : 'от 500 ₸',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // Photos
            _buildLabel(s.isKz ? 'Фото (міндетті емес)' : 'Фото (необязательно)', isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                ..._photos.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(e.value, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(e.key)),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (_photos.length < 3)
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderMuted, width: 1.5),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF1CB7FF), size: 28),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : Text(s.submitOrder, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressMiniMap(
    S s,
    bool isDark,
    Color borderMuted,
    Color textColor,
  ) {
    final addrLen = _addressController.text.trim().length;
    final placeholderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    if (_geocodeLoading && _mapPoint == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderMuted),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 12),
              Text(
                s.orderGeocodingLoading,
                style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      );
    }

    if (_mapPoint != null) {
      final center = _mapPoint!;
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: borderMuted),
            borderRadius: BorderRadius.circular(14),
          ),
          child: FlutterMap(
            key: ValueKey<String>('${center.latitude}_${center.longitude}'),
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sheberkz.Sheber.kz',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(Icons.location_pin, size: 44, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final trimmed = _addressController.text.trim();
    final showNotFound = addrLen >= 5 &&
        !_geocodeLoading &&
        _mapPoint == null &&
        _lastFinishedGeocodeQuery == trimmed;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderMuted),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            showNotFound ? s.orderGeocodeNotFound : s.orderGeocodingHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.82), height: 1.35),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final fillColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: TextStyle(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade500),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1CB7FF)) : null,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CB7FF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
