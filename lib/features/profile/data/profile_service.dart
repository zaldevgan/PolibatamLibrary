import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import 'member_summary.dart';

class ProfileService {
  final ApiClient _client = ApiClient();

  /// Mengambil data ringkasan keanggotaan SLiMS lengkap
  /// (Profil, Statistik, Buku Dipinjam, Riwayat Pinjam, dan Rincian Denda)
  Future<MemberSummary?> getMemberSummary(String memberId) async {
    try {
      final response = await _client.dio.get('${AppConstants.apiMemberSummary}/$memberId');
      if (response.statusCode == 200 && response.data != null) {
        dynamic resData = response.data;
        if (resData is String) {
          try {
            resData = jsonDecode(resData);
          } catch (_) {}
        }
        if (resData is Map && resData['status'] == 'success' && resData['data'] is Map) {
          return MemberSummary.fromJson(resData['data']);
        }
      }
    } catch (e) {
      throw Exception(ApiClient.errorMessage(e));
    }
    return null;
  }
}

