import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository_service.dart';
import '../data/repository_item.dart';

final repositoryServiceProvider = Provider<RepositoryService>((ref) => RepositoryService());

class RepositoryListState {
  final String query;
  final List<RepositoryItem> items;
  final int page;
  final int totalElements;
  final bool hasMore;
  final bool isLoading; // memuat halaman pertama
  final bool isLoadingMore; // memuat halaman berikutnya
  final String? errorMessage;

  const RepositoryListState({
    this.query = '',
    this.items = const [],
    this.page = 0,
    this.totalElements = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  RepositoryListState copyWith({
    String? query,
    List<RepositoryItem>? items,
    int? page,
    int? totalElements,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return RepositoryListState(
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      totalElements: totalElements ?? this.totalElements,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }
}

class RepositoryListNotifier extends StateNotifier<RepositoryListState> {
  final RepositoryService _service;
  int _requestId = 0;

  RepositoryListNotifier(this._service) : super(const RepositoryListState()) {
    search('');
  }

  Future<void> search(String query) async {
    final requestId = ++_requestId;
    state = RepositoryListState(query: query, isLoading: true);
    try {
      final result = await _service.searchRepository(query: query);
      if (requestId != _requestId) return; // pencarian lama, abaikan
      state = state.copyWith(
        items: result.items,
        page: result.page,
        totalElements: result.totalElements,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, errorMessage: _clean(e));
    }
  }

  Future<void> refresh() => search(state.query);

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final requestId = _requestId;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _service.searchRepository(
        query: state.query,
        page: state.page + 1,
      );
      if (requestId != _requestId) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        totalElements: result.totalElements,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoadingMore: false, errorMessage: _clean(e));
    }
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}

final repositoryListProvider =
    StateNotifierProvider<RepositoryListNotifier, RepositoryListState>((ref) {
  return RepositoryListNotifier(ref.watch(repositoryServiceProvider));
});
