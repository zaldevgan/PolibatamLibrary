import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import 'digital_loan.dart';

class LoansService {
  final ApiClient _client = ApiClient();

  Future<List<DigitalLoanItem>> getMemberLoans(String memberId) async {
    try {
      final response = await _client.dio.get('${AppConstants.apiDigitalLoans}/$memberId');
      if (response.statusCode == 200 && response.data != null) {
        dynamic resData = response.data;
        if (resData is String) {
          try {
            resData = jsonDecode(resData);
          } catch (_) {}
        }
        if (resData is Map && resData['data'] is List) {
          final List raw = resData['data'];
          return raw.map((item) => DigitalLoanItem.fromJson(item)).toList();
        }
      }
    } catch (e) {
      throw Exception(ApiClient.errorMessage(e));
    }
    return [];
  }

  Future<bool> returnLoan(int loanId, String memberId) async {
    try {
      final response = await _client.dio.post(
        AppConstants.apiDigitalReturn,
        data: {'loan_id': loanId, 'member_id': memberId},
      );
      dynamic resData = response.data;
      if (resData is String) {
        try {
          resData = jsonDecode(resData);
        } catch (_) {}
      }
      return resData is Map && (resData['status'] == 'success' || resData['success'] == true);
    } catch (_) {
      return false;
    }
  }
}


