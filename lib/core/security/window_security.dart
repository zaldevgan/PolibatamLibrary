import 'package:flutter/services.dart';

/// Helper native untuk mengatur FLAG_SECURE di Android
/// (Mencegah screenshot & screen recording tanpa memerlukan plugin pihak ketiga)
class WindowSecurity {
  static const MethodChannel _channel = MethodChannel('id.ac.polibatam.library/security');

  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } catch (_) {
      // Ignored if platform doesn't implement or on debug simulator
    }
  }
}

