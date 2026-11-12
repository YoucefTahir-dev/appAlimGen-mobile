import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/session/session_boundary.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/data/loading_orders_repository.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/presentation/loading_orders_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

LoadingOrderSummary _order(int id) => LoadingOrderSummary(
  id: id,
  number: 'SYNTHETIC-$id',
  operatorName: 'Synthetic operator',
  status: 'in_progress',
  createdAt: '2026-11-12T10:30:00Z',
  lines: const [],
);

class _Orders extends LoadingOrdersRepository {
  _Orders() : super(Dio(), const ErrorMapper());
  final requests = <(int, String, String?)>[];
  final cancelTokens = <CancelToken?>[];
  int keys = 0;
  bool failNext = false;
  Completer<LoadingOrderSummary>? next;

  @override
  String newKey() => 'synthetic-intent-${++keys}';

  Future<LoadingOrderSummary> _submit(
    int id,
    String action,
    String? key,
    CancelToken? cancelToken,
  ) {
    requests.add((id, action, key));
    cancelTokens.add(cancelToken);
    final pending = next;
    next = null;
    if (pending != null) return pending.future;
    if (failNext) {
      failNext = false;
      return Future.error(
        const AppFailure(
          kind: FailureKind.timeout,
          code: 'SYNTHETIC_TIMEOUT',
          message: 'Synthetic timeout',
        ),
      );
    }
    return Future.value(_order(id));
  }

  @override
  Future<LoadingOrderSummary> validateLoadingOrder(
    int id,
    String key, {
    CancelToken? cancelToken,
  }) => _submit(id, 'validate', key, cancelToken);
  @override
  Future<LoadingOrderSummary> closeLoadingOrder(
    int id,
    String key, {
    CancelToken? cancelToken,
  }) => _submit(id, 'close', key, cancelToken);
  @override
  Future<LoadingOrderSummary> cancelLoadingOrder(
    int id, {
    CancelToken? cancelToken,
  }) => _submit(id, 'cancel', null, cancelToken);
}

const _screenUser = UserProfile(
  id: 1,
  username: 'synthetic-session-A',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'test',
  permissions: {
    'inventory.view_loadingorder',
    'inventory.delete_loadingorder',
    'inventory.validate_loadingorder',
    'inventory.close_loadingorder',
  },
);

class _ScreenAuth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_screenUser);
}

class _ScreenOrders extends LoadingOrdersController {
  _ScreenOrders(this.order);
  final LoadingOrderSummary order;

  @override
  PagedListState<LoadingOrderSummary> build() =>
      PagedListState(isInitialLoading: false, items: [order]);
}

Future<ProviderContainer> _openAction(
  WidgetTester tester,
  _Orders repository,
  LoadingOrderAction action,
) async {
  final order = LoadingOrderSummary(
    id: 7,
    number: 'SYNTHETIC-7',
    operatorName: 'Synthetic operator',
    status: action == LoadingOrderAction.close ? 'in_progress' : 'draft',
    createdAt: '2026-11-12T10:30:00Z',
    lines: const [],
  );
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_ScreenAuth.new),
      loadingOrdersRepositoryProvider.overrideWithValue(repository),
      loadingOrdersProvider.overrideWith(() => _ScreenOrders(order)),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LoadingOrdersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('SYNTHETIC-7'));
  await tester.pumpAndSettle();
  final label = switch (action) {
    LoadingOrderAction.validate => 'Valider',
    LoadingOrderAction.cancel => 'Annuler le bon',
    LoadingOrderAction.close => 'Clôturer',
  };
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  return container;
}

void main() {
  late _Orders repository;
  late ProviderContainer container;
  setUp(() {
    repository = _Orders();
    container = ProviderContainer(
      overrides: [
        loadingOrdersRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'validation and close preserve their keys after an uncertain failure',
    () async {
      final controller = container.read(loadingOrderActionProvider.notifier);
      for (final action in [controller.validateOrder, controller.closeOrder]) {
        repository.failNext = true;
        await expectLater(action(7), throwsA(isA<AppFailure>()));
        expect(container.read(loadingOrderActionProvider).isLoading, isFalse);
        final failedKey = repository.requests.last.$3;
        await action(7);
        expect(repository.requests.last.$3, failedKey);
      }
      expect(repository.requests[0].$3, isNot(repository.requests[2].$3));
    },
  );

  test(
    'successful retries retain the key, other actions and documents do not share it',
    () async {
      final controller = container.read(loadingOrderActionProvider.notifier);
      await controller.validateOrder(7);
      await controller.validateOrder(7);
      await controller.closeOrder(7);
      await controller.validateOrder(8);
      expect(repository.requests[0].$3, repository.requests[1].$3);
      expect({
        repository.requests[0].$3,
        repository.requests[2].$3,
        repository.requests[3].$3,
      }, hasLength(3));
    },
  );

  test(
    're-entrant taps do not create another request or another key',
    () async {
      final pending = Completer<LoadingOrderSummary>();
      repository.next = pending;
      final controller = container.read(loadingOrderActionProvider.notifier);
      final running = controller.validateOrder(7);
      await expectLater(
        controller.closeOrder(8),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'ACTION_IN_PROGRESS'),
        ),
      );
      expect(repository.requests, hasLength(1));
      expect(repository.keys, 1);
      pending.complete(_order(7));
      await running;
      expect(container.read(loadingOrderActionProvider).isLoading, isFalse);
    },
  );

  test(
    'rotating the authenticated session clears old intention keys',
    () async {
      await container
          .read(loadingOrderActionProvider.notifier)
          .validateOrder(7);
      final oldKey = repository.requests.last.$3;
      container.read(sessionEpochProvider.notifier).rotate();
      container.read(loadingOrderActionProvider);
      await container
          .read(loadingOrderActionProvider.notifier)
          .validateOrder(7);
      expect(repository.requests.last.$3, isNot(oldKey));
      expect(repository.cancelTokens.first!.isCancelled, isTrue);
      expect(repository.cancelTokens.last!.isCancelled, isFalse);
    },
  );

  test(
    'an old completion cannot clear the busy state of the new session',
    () async {
      final oldPending = Completer<LoadingOrderSummary>();
      repository.next = oldPending;
      final oldRun = container
          .read(loadingOrderActionProvider.notifier)
          .validateOrder(7);
      final oldResult = expectLater(
        oldRun,
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'SESSION_CHANGED'),
        ),
      );
      container.read(sessionEpochProvider.notifier).rotate();
      container.read(loadingOrderActionProvider);
      final nextPending = Completer<LoadingOrderSummary>();
      repository.next = nextPending;
      final nextRun = container
          .read(loadingOrderActionProvider.notifier)
          .closeOrder(8);
      oldPending.complete(_order(7));
      await oldResult;
      expect(
        container
            .read(loadingOrderActionProvider)
            .isRunning(8, LoadingOrderAction.close),
        isTrue,
      );
      nextPending.complete(_order(8));
      await nextRun;
      expect(container.read(loadingOrderActionProvider).isLoading, isFalse);
    },
  );

  test('cancel does not pretend to opt in to a keyed server action', () async {
    await container.read(loadingOrderActionProvider.notifier).cancelOrder(7);
    expect(repository.requests.single, (7, 'cancel', null));
    expect(repository.keys, 0);
  });

  for (final action in LoadingOrderAction.values) {
    testWidgets(
      '${action.name}: a current-session confirmation still completes normally',
      (tester) async {
        final screenContainer = await _openAction(tester, repository, action);
        final initial = screenContainer
            .read(loadingOrdersProvider)
            .items
            .single;
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();
        expect(repository.requests, hasLength(1));
        expect(repository.requests.single.$2, action.name);
        expect(repository.cancelTokens.single!.isCancelled, isFalse);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          screenContainer.read(loadingOrdersProvider).items.single,
          isNot(same(initial)),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${action.name}: a confirmation opened in A cannot submit in B',
      (tester) async {
        final screenContainer = await _openAction(tester, repository, action);
        screenContainer.read(sessionEpochProvider.notifier).rotate();
        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();
        expect(repository.requests, isEmpty);
        expect(repository.keys, 0);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    for (final fail in [false, true]) {
      testWidgets(
        '${action.name}: late ${fail ? 'error' : 'success'} from A stays out of B',
        (tester) async {
          final screenContainer = await _openAction(tester, repository, action);
          final initial = screenContainer
              .read(loadingOrdersProvider)
              .items
              .single;
          final pending = Completer<LoadingOrderSummary>();
          repository.next = pending;
          await tester.tap(find.text('Confirmer'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(repository.requests, hasLength(1));
          screenContainer.read(sessionEpochProvider.notifier).rotate();
          screenContainer.read(loadingOrderActionProvider);
          expect(repository.cancelTokens.single!.isCancelled, isTrue);
          if (fail) {
            pending.completeError(
              const AppFailure(
                kind: FailureKind.timeout,
                code: 'SYNTHETIC_PRIVATE_ERROR_A',
                message: 'Private failure belonging to A',
              ),
            );
          } else {
            pending.complete(_order(7));
          }
          await tester.pumpAndSettle();
          expect(repository.requests, hasLength(1));
          expect(find.byType(SnackBar), findsNothing);
          expect(find.text('Private failure belonging to A'), findsNothing);
          expect(
            screenContainer.read(loadingOrdersProvider).items.single,
            same(initial),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
