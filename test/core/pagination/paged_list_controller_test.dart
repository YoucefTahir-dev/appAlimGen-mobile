import 'dart:async';

import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _StringListController extends PagedListController<String> {
  @override
  Future<PageData<String>> fetchPage({
    required int page,
    required String query,
  }) async =>
      const PageData(items: ['Fournisseur test'], count: 1, hasNext: false);
}

final _stringListProvider =
    NotifierProvider<_StringListController, PagedListState<String>>(
      _StringListController.new,
    );

void main() {
  test('keeps the item type when the first API page is loaded', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final loaded = Completer<void>();
    final subscription = container.listen(_stringListProvider, (_, next) {
      if (next.items.isNotEmpty && !loaded.isCompleted) {
        loaded.complete();
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await loaded.future.timeout(const Duration(seconds: 1));

    expect(container.read(_stringListProvider).items, ['Fournisseur test']);
  });
}
