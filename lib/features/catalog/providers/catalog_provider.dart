import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/catalog_service.dart';
import '../data/digital_book.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) => CatalogService());

class CatalogFilter {
  final String query;
  final String format;

  const CatalogFilter({this.query = '', this.format = ''});

  CatalogFilter copyWith({String? query, String? format}) {
    return CatalogFilter(
      query: query ?? this.query,
      format: format ?? this.format,
    );
  }
}

final catalogFilterProvider = StateProvider<CatalogFilter>((ref) => const CatalogFilter());

final digitalBooksProvider = FutureProvider.autoDispose<List<DigitalBook>>((ref) async {
  final service = ref.watch(catalogServiceProvider);
  final filter = ref.watch(catalogFilterProvider);

  return service.getDigitalBooks(
    query: filter.query,
    format: filter.format,
  );
});

