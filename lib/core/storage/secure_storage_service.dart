import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.keyAccessToken);
  }

  Future<void> saveUserProfile(String userJson) async {
    await _storage.write(key: AppConstants.keyUserProfile, value: userJson);
  }

  Future<String?> getUserProfile() async {
    return await _storage.read(key: AppConstants.keyUserProfile);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

