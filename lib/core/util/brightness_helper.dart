import 'package:flutter/services.dart';

class BrightnessHelper {
  static const MethodChannel _channel = MethodChannel('id.ac.polibatam.library/brightness');

  /// Memaksimalkan kecerahan layar ke 100% agar barcode & QR code dapat dipindai oleh alat scanner
  static Future<void> setMaxBrightness() async {
    try {
      await _channel.invokeMethod('setMaxBrightness');
    } catch (_) {}
  }

  /// Mengembalikan kecerahan layar ke pengaturan normal sistem pengguna
  static Future<void> resetBrightness() async {
    try {
      await _channel.invokeMethod('resetBrightness');
    } catch (_) {}
  }
}

