import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// App-wide configuration constants.
/// Change [serverHost] before building for production.
class AppConfig {
  AppConfig._();

  /// ──────────────────────────────────────────────
  /// CHANGE THIS FOR PRODUCTION
  /// Set to your actual domain, e.g. 'https://exams.example.com'
  /// ──────────────────────────────────────────────
  static const String productionHost = 'http://s.nabuo.org';

  /// Returns the correct API base URL depending on the platform.
  /// - If [productionHost] is set, always use it.
  /// - Otherwise, falls back to localhost (Android Emulator → 10.0.2.2).
  static String get apiBaseUrl {
    if (productionHost.isNotEmpty) {
      return '$productionHost/server/api.php';
    }
    if (kIsWeb) return 'http://localhost/server/api.php';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2/server/api.php';
    } catch (_) {}
    return 'http://localhost/server/api.php';
  }
}


