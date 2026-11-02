import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  /// Dipanggil saat server menolak token (HTTP 401), diisi oleh AuthNotifier
  static void Function()? onUnauthorized;

  /// Pesan error yang layak ditampilkan ke pengguna: pesan dari server SIPP
  /// jika ada, selain itu pesan umum sesuai jenis galat.
  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Tidak dapat terhubung ke server perpustakaan. Periksa koneksi internet Anda.';
      }
      final code = error.response?.statusCode;
      return code != null ? 'Server mengembalikan galat (HTTP $code).' : 'Permintaan ke server gagal.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  late final Dio dio;
  final SecureStorageService _storage = SecureStorageService();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.sippBaseUrl}/',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Penyimpanan aman rusak: lanjutkan tanpa token, server akan membalas 401
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Token kedaluwarsa atau dicabut: paksa login ulang
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }
}

