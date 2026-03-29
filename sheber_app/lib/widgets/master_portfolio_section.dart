import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../l10n/app_strings.dart';
import '../utils/upload_url.dart';

/// Portfolio grid for master's own profile — load, upload, delete.
class MasterPortfolioSection extends StatefulWidget {
  final bool isDark;
  final S s;

  const MasterPortfolioSection({super.key, required this.isDark, required this.s});

  @override
  State<MasterPortfolioSection> createState() => _MasterPortfolioSectionState();
}

class _MasterPortfolioSectionState extends State<MasterPortfolioSection> {
  List<Map<String, dynamic>> _photos = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await ApiClient().getOwnPortfolioPhotos();
      if (mounted) setState(() { _photos = photos; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    if (_photos.length >= 12 || _uploading) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await ApiClient().uploadPortfolioPhoto(File(picked.path));
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.s.portfolioUploadSuccess),
          backgroundColor: Colors.green.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {}
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _delete(int photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Фото жою / Удалить фото',
            style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.s.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.s.confirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiClient().deletePortfolioPhoto(photoId);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final addColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1CB7FF), strokeWidth: 2)),
      );
    }

    final canAdd = _photos.length < 12;
    final itemCount = _photos.length + (canAdd ? 1 : 0);

    if (itemCount == 1 && canAdd) {
      return GestureDetector(
        onTap: _uploading ? null : _upload,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: addColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4), width: 2),
          ),
          child: _uploading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF2563EB), size: 26),
                    SizedBox(width: 8),
                    Text('Добавить фото / Фото қосу',
                        style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (canAdd && i == _photos.length) {
          return GestureDetector(
            onTap: _uploading ? null : _upload,
            child: Container(
              decoration: BoxDecoration(
                color: addColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4), width: 2),
              ),
              child: _uploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2))
                  : const Icon(Icons.add_rounded, color: Color(0xFF2563EB), size: 32),
            ),
          );
        }

        final photo = _photos[i];
        final photoId = (photo['id'] as num?)?.toInt() ?? 0;
        final url = resolveUploadUrl(photo['url']?.toString() ?? '');

        return GestureDetector(
          onLongPress: () => _delete(photoId),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                url.isNotEmpty
                    ? Image.network(url, fit: BoxFit.cover,
                        errorBuilder: (context, err, st) => ColoredBox(
                          color: addColor,
                          child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                        ))
                    : ColoredBox(color: addColor,
                        child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8))),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => _delete(photoId),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
