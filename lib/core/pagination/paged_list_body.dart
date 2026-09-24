import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
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
    this.emptyIcon = Icons.inbox_outlined,
  });

  final NotifierProvider<C, PagedListState<T>> provider;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool searchable;
  final IconData emptyIcon;

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
            child: AppSearchField(
              hint: strings.text('searchHint'),
              onChanged: ref.read(widget.provider.notifier).search,
            ),
          )
        : null;

    if (state.isInitialLoading) {
      return Column(
        children: [
          ?search,
          const Expanded(child: LoadingSkeleton()),
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
              child: AppErrorState(
                title: strings.text('loadErrorTitle'),
                message: message,
                retryLabel: strings.retry,
                onRetry: ref.read(widget.provider.notifier).refresh,
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: ref.read(widget.provider.notifier).refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  AppEmptyState(
                    icon: widget.emptyIcon,
                    title: strings.text('emptyTitle'),
                    message: strings.text('emptyMessage'),
                  ),
                ],
              ),
            ),
          ),
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
              itemCount:
                  state.items.length +
                  (state.isLoadingMore || state.error != null ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index < state.items.length) {
                  return widget.itemBuilder(context, state.items[index]);
                }
                if (state.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  );
                }
                return Center(
                  child: TextButton.icon(
                    onPressed: ref.read(widget.provider.notifier).loadMore,
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.retry),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
