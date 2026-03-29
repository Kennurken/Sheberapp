import '../config/app_config.dart';

/// Normalizes image/upload paths from the API to absolute HTTPS URLs.
String resolveUploadUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';

  if (t.startsWith('https://')) return t;

  if (t.startsWith('http://')) {
    // Prefer HTTPS for known production hosts (ATS / mixed content).
    if (t.startsWith('http://kmaruk4u.beget.tech') ||
        t.startsWith('http://sheberkz.duckdns.org')) {
      return 'https://${t.substring('http://'.length)}';
    }
    return t;
  }

  var path = t.startsWith('/') ? t.substring(1) : t;
  while (path.startsWith('/')) {
    path = path.substring(1);
  }
  return '$kProdBaseUrl/$path';
}
