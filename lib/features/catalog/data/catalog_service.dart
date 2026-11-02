import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import 'digital_book.dart';

class CatalogService {
  final ApiClient _client = ApiClient();

  Future<List<DigitalBook>> getDigitalBooks({
    String query = '',
    String format = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        AppConstants.apiDigitalBooks,
        queryParameters: {
          if (query.isNotEmpty) 'q': query,
          if (format.isNotEmpty) 'format': format,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic resData = response.data;
        if (resData is String) {
          try {
            resData = jsonDecode(resData);
          } catch (_) {}
        }

        if (resData is Map && resData['data'] != null) {
          final List raw = resData['data'];
          return raw.map((item) => DigitalBook.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('[CatalogService] getDigitalBooks error: $e');
      throw Exception(ApiClient.errorMessage(e));
    }
    return [];
  }

  Future<DigitalBook?> getBookDetail(int bookId) async {
    try {
      final detailUrl = '${AppConstants.apiDigitalBooks}/$bookId';
      final response = await _client.dio.get(detailUrl);
      if (response.statusCode == 200 && response.data != null) {
        dynamic resData = response.data;
        if (resData is String) {
          try {
            resData = jsonDecode(resData);
          } catch (_) {}
        }
        if (resData is Map && resData['data'] != null) {
          return DigitalBook.fromJson(resData['data']);
        }
      }
    } catch (e) {
      debugPrint('[CatalogService] getBookDetail error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> borrowBook({
    required int bookId,
    required String memberId,
    required String memberName,
  }) async {
    try {
      final response = await _client.dio.post(
        AppConstants.apiDigitalBorrow,
        data: {
          'book_id': bookId,
          'member_id': memberId,
          'member_name': memberName,
        },
      );
      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'status': 'success', 'data': data};
    } catch (e) {
      return {'status': 'error', 'message': ApiClient.errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> reserveBook({
    required int bookId,
    required String memberId,
    required String memberName,
  }) async {
    try {
      final response = await _client.dio.post(
        AppConstants.apiDigitalReserve,
        data: {
          'book_id': bookId,
          'member_id': memberId,
          'member_name': memberName,
        },
      );
      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'status': 'success', 'data': data};
    } catch (e) {
      return {'status': 'error', 'message': ApiClient.errorMessage(e)};
    }
  }
}
