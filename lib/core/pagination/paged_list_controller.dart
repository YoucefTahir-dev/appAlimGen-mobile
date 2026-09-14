import 'dart:async';

import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PagedListController<T> extends Notifier<PagedListState<T>> {
  Timer? _debounce;
  int _generation = 0;
  Future<PageData<T>> fetchPage({required int page, required String query});

  @override
  PagedListState<T> build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(refresh);
    return const PagedListState();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(
      items: [],
      page: 0,
      hasNext: false,
      isInitialLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      final result = await fetchPage(page: 1, query: state.query);
      if (generation != _generation) return;
      state = state.copyWith(
        items: result.items,
        page: 1,
        hasNext: result.hasNext,
        isInitialLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(isInitialLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext || state.isLoadingMore || state.isInitialLoading) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final result = await fetchPage(page: state.page + 1, query: state.query);
      if (generation != _generation) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: state.page + 1,
        hasNext: result.hasNext,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  void search(String value) {
    _debounce?.cancel();
    final query = value.trim();
    state = state.copyWith(query: query);
    _debounce = Timer(const Duration(milliseconds: 300), refresh);
  }
}
