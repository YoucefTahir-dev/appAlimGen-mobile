import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PagedListBody<T, C extends PagedListController<T>>
    extends ConsumerStatefulWidget {
  const PagedListBody({
    super.key,
    required this.provider,
    required this.itemBuilder,
    this.searchable = false,
  });

  final NotifierProvider<C, PagedListState<T>> provider;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool searchable;

  @override
  ConsumerState<PagedListBody<T, C>> createState() =>
      _PagedListBodyState<T, C>();
}

class _PagedListBodyState<T, C extends PagedListController<T>>
    extends ConsumerState<PagedListBody<T, C>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280) {
      ref.read(widget.provider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(widget.provider);
    final search = widget.searchable
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const Key('module-search'),
              onChanged: ref.read(widget.provider.notifier).search,
              decoration: InputDecoration(
                labelText: strings.text('search'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.query.isEmpty
                    ? null
                    : const Icon(Icons.filter_alt_outlined),
              ),
            ),
          )
        : null;

    if (state.isInitialLoading) {
      return Column(
        children: [
          ?search,
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (state.error != null && state.items.isEmpty) {
      final failure = state.error is AppFailure
          ? state.error! as AppFailure
          : null;
      final message = failure?.kind == FailureKind.permission
          ? strings.text('forbiddenMessage')
          : failure?.message ?? strings.text('apiError');
      return Column(
        children: [
          ?search,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: ref.read(widget.provider.notifier).refresh,
                      child: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return Column(
        children: [
          ?search,
          Expanded(child: Center(child: Text(strings.empty))),
        ],
      );
    }

    return Column(
      children: [
        ?search,
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(widget.provider.notifier).refresh,
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => index == state.items.length
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : widget.itemBuilder(context, state.items[index]),
            ),
          ),
        ),
      ],
    );
  }
}
