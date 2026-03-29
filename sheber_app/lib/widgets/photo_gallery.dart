import 'package:flutter/material.dart';
import '../utils/upload_url.dart';

/// Fullscreen gallery: swipe pages + pinch-zoom per page.
void openSheberPhotoGallery(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
}) {
  if (imageUrls.isEmpty) return;
  final resolved = imageUrls.map((u) => resolveUploadUrl(u.trim())).where((u) => u.isNotEmpty).toList();
  if (resolved.isEmpty) return;
  var idx = initialIndex.clamp(0, resolved.length - 1);
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _PhotoGalleryPage(
        urls: resolved,
        initialIndex: idx,
      ),
    ),
  );
}

class _PhotoGalleryPage extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _PhotoGalleryPage({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<_PhotoGalleryPage> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1} / ${widget.urls.length}'),
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          return _ZoomableImage(url: widget.urls[i]);
        },
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  final String url;

  const _ZoomableImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
        ),
      ),
    );
  }
}
