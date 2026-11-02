import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/api_client.dart';
import 'user_profile.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final SecureStorageService _storage = SecureStorageService();
  final ApiClient _apiClient = ApiClient();

  /// Login native dengan akun SSO login.polibatam.ac.id, tanpa browser.
  /// SIPP meneruskan kredensial ke Keycloak lalu mengembalikan token SIPP.
  /// Endpoint: POST index.php?p=api/digital/auth/login
  Future<UserProfile> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.apiAuthLogin,
        data: {
          'username': username,
          'password': password,
          'device_info': 'Polibatam Library Mobile',
        },
      );

      final data = response.data?['data'];
      final token = data?['token']?.toString();
      if (token == null || token.isEmpty || data['member'] is! Map) {
        throw AuthException('Respons server tidak valid.');
      }

      final profile = UserProfile.fromJson(Map<String, dynamic>.from(data['member']));
      await _storage.saveAccessToken(token);
      await _storage.saveUserProfile(profile.toJsonString());
      return profile;
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
      if (serverMessage != null && serverMessage.isNotEmpty) {
        throw AuthException(serverMessage);
      }
      throw AuthException('Tidak dapat terhubung ke server perpustakaan. Periksa koneksi internet Anda.');
    }
  }

  /// Profil tersimpan, hanya jika token juga tersimpan
  Future<UserProfile?> getCurrentUser() async {
    final token = await _storage.getAccessToken();
    final raw = await _storage.getUserProfile();
    if (token == null || token.isEmpty || raw == null) return null;
    return UserProfile.fromJsonString(raw);
  }

  /// Memperbarui profil dari server. Mengembalikan null jika token sudah tidak berlaku;
  /// melempar error jika server tidak bisa dihubungi (sesi lokal tetap dipakai).
  Future<UserProfile?> refreshProfile() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.apiAuthMe);
      final data = response.data?['data'];
      if (data is! Map) return null;
      final profile = UserProfile.fromJson(Map<String, dynamic>.from(data));
      await _storage.saveUserProfile(profile.toJsonString());
      return profile;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(AppConstants.apiAuthLogout);
    } catch (_) {
      // Tetap hapus sesi lokal walau server tidak bisa dihubungi
    }
    await _storage.clearAll();
  }

  Future<void> clearLocalSession() => _storage.clearAll();
}
