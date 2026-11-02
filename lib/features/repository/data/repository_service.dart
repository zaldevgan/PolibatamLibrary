import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import 'repository_item.dart';

/// Satu halaman hasil pencarian DSpace beserta info paginasi.
class RepositoryPage {
  final List<RepositoryItem> items;
  final int page;
  final int totalPages;
  final int totalElements;

  RepositoryPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  bool get hasMore => page + 1 < totalPages;
}

class RepositoryService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.dspaceApiUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'PolibatamLibraryMobile/1.0',
      },
    ),
  );

  /// Mencari karya ilmiah di DSpace 9.2 repository Polibatam.
  /// Endpoint: /server/api/discover/search/objects
  ///
  /// Tanpa kata kunci, urutannya sama dengan "Recent Submissions" di
  /// repository.polibatam.ac.id (berdasarkan tanggal masuk). Dengan kata kunci,
  /// diurutkan berdasarkan relevansi.
  Future<RepositoryPage> searchRepository({
    String query = '',
    int page = 0,
    int size = 20,
  }) async {
    final Map<String, dynamic> qParams = {
      'dsoType': 'ITEM',
      'page': page,
      'size': size,
      'sort': query.isEmpty ? 'dc.date.accessioned,desc' : 'score,desc',
      'embed': 'accessStatus',
    };
    if (query.isNotEmpty) {
      qParams['query'] = query;
    }

    try {
      final response = await _dio.get(
        '/discover/search/objects',
        queryParameters: qParams,
      );

      final searchResult = response.data?['_embedded']?['searchResult'] ?? {};
      final pageInfo = searchResult['page'] ?? {};
      final List objects = searchResult['_embedded']?['objects'] ?? [];

      return RepositoryPage(
        items: objects
            .map((obj) => obj['_embedded']?['indexableObject'])
            .whereType<Map<String, dynamic>>()
            .map(RepositoryItem.fromDSpaceJson)
            .toList(),
        page: (pageInfo['number'] as num?)?.toInt() ?? page,
        totalPages: (pageInfo['totalPages'] as num?)?.toInt() ?? 0,
        totalElements: (pageInfo['totalElements'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  /// Mengambil berkas di bundle ORIGINAL (naskah, lembar pengesahan, dsb.)
  /// lalu memeriksa apakah tiap berkas bisa dibuka tanpa login DSpace.
  /// Endpoint: /server/api/core/items/{uuid}/bundles?embed=bitstreams
  Future<List<RepositoryBitstream>> fetchItemBitstreams(String itemUuid) async {
    if (itemUuid.isEmpty) return [];

    try {
      final res = await _dio.get(
        '/core/items/$itemUuid/bundles',
        queryParameters: {'embed': 'bitstreams'},
      );

      final List bundles = res.data?['_embedded']?['bundles'] ?? [];
      final original = bundles.cast<Map<String, dynamic>>().where(
            (b) => b['name']?.toString().toUpperCase() == 'ORIGINAL',
          );
      if (original.isEmpty) return [];

      final List raw =
          original.first['_embedded']?['bitstreams']?['_embedded']?['bitstreams'] ?? [];
      final files = raw
          .cast<Map<String, dynamic>>()
          .map(RepositoryBitstream.fromJson)
          .toList();

      // Berkas yang dibatasi (restricted/embargo) membalas 401/403
      final access = await Future.wait(files.map((f) => _isAccessible(f.contentUrl)));
      return [
        for (var i = 0; i < files.length; i++) files[i].copyWith(isAccessible: access[i]),
      ];
    } on DioException catch (e) {
      throw Exception(_describeError(e));
    }
  }

  Future<bool> _isAccessible(String contentUrl) async {
    if (contentUrl.isEmpty) return false;
    try {
      final res = await _dio.head(
        contentUrl,
        options: Options(validateStatus: (_) => true),
      );
      final code = res.statusCode ?? 0;
      return code >= 200 && code < 300;
    } catch (_) {
      return false;
    }
  }

  String _describeError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Server repository tidak merespons. Coba lagi beberapa saat.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke repository.polibatam.ac.id. Periksa koneksi internet Anda.';
      default:
        final code = e.response?.statusCode;
        return code != null
            ? 'Repository mengembalikan galat (HTTP $code).'
            : 'Gagal memuat data repository.';
    }
  }
}
