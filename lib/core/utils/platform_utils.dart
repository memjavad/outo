import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// True on Android/iOS only — used to guard mobile-only APIs
bool get isMobilePlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}

/// True on desktop platforms (Windows, macOS, Linux)
bool get isDesktopPlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  } catch (_) {
    return false;
  }
}


