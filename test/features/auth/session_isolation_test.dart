import 'dart:async';

import 'package:app_alim_gen_mobile/app/app.dart';
import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/app/router.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_auth_service.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_preference_store.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_session_manager.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/login_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/business_list_screens.dart';
import 'package:app_alim_gen_mobile/features/clients/data/clients_repository.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:app_alim_gen_mobile/features/clients/presentation/clients_screen.dart';
import 'package:app_alim_gen_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_filter.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_controller.dart';
import 'package:app_alim_gen_mobile/features/products/data/products_repository.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/features/products/presentation/products_screen.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _userA = UserProfile(
  id: 1,
  username: 'user-a',
  firstName: 'A',
  lastName: '',
  email: '',
  phone: '',
  role: 'Opérateur',
  permissions: {'inventory.view_product'},
);
const _userB = UserProfile(
  id: 2,
  username: 'user-b',
  firstName: 'B',
  lastName: '',
  email: '',
  phone: '',
  role: 'Opérateur',
  permissions: {},
);

PageData<T> _page<T>(T item) =>
    PageData(items: [item], count: 1, hasNext: false);

class _ProductsRepository extends ProductsRepository {
  _ProductsRepository(this.account, this.lateA)
    : super(Dio(), const ErrorMapper());

  final String Function() account;
  final Completer<PageData<ProductSummary>> lateA;
  int calls = 0;

  @override
  Future<PageData<ProductSummary>> fetch({
    required int page,
    String query = '',
  }) {
    calls++;
    if (calls == 2) return lateA.future;
    final owner = account();
    return Future.value(
      _page(
        ProductSummary(
          id: owner == 'A' ? 1 : 2,
          name: 'Produit $owner',
          reference: owner,
          quantity: 1,
          stockStatus: 'normal',
        ),
      ),
    );
  }
}

class _ClientsRepository extends ClientsRepository {
  _ClientsRepository(this.account) : super(Dio(), const ErrorMapper());
  final String Function() account;

  @override
  Future<PageData<ClientSummary>> fetch({
    required int page,
    String query = '',
  }) {
    final owner = account();
    return Future.value(
      _page(
        ClientSummary(
          id: owner == 'A' ? 1 : 2,
          name: 'Client $owner',
          phone: '',
          address: '',
          customerType: 'RETAIL',
        ),
      ),
    );
  }
}

class _SalesRepository extends SalesRepository {
  _SalesRepository(this.account) : super(Dio(), const ErrorMapper());
  final String Function() account;

  @override
  Future<PageData<SaleSummary>> fetch({required int page, String query = ''}) {
    final owner = account();
    return Future.value(
      _page(
        SaleSummary(
          id: owner == 'A' ? 1 : 2,
          number: 'Vente $owner',
          clientId: null,
          date: '',
          total: '1.00',
          paymentStatus: 'paid',
          clientName: 'Client $owner',
        ),
      ),
    );
  }
}

class _DashboardRepository extends DashboardRepository {
  _DashboardRepository(this.account) : super(Dio(), const ErrorMapper());
  final String Function() account;

  @override
  Future<DashboardSummary> load({
    DashboardFilter filter = const DashboardFilter(),
  }) {
    final owner = account();
    return Future.value(
      DashboardSummary(
        revenue: owner == 'A' ? '1.00' : '2.00',
        salesCount: owner == 'A' ? 1 : 2,
        averageBasket: '1.00',
        netProfit: '1.00',
        totalProducts: 1,
        totalClients: 1,
        totalSuppliers: 1,
      ),
    );
  }
}

class _AuthRepository extends AuthRepository {
  _AuthRepository(this.logoutGate)
    : super(dio: Dio(), session: SessionRepository(MemoryTokenStorage()));

  final Completer<void> logoutGate;

  @override
  Future<void> logout() => logoutGate.future;
}

class _AuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_userA);
}

class _BiometricAuth implements BiometricAuthService {
  @override
  Future<BiometricAvailability> availability() async =>
      BiometricAvailability.unsupported;

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async =>
      BiometricAuthResult.unavailable;
}

Future<void> _flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'logout puis connexion B purge les caches A et ignore une réponse A tardive',
    () async {
      var account = 'A';
      final lateA = Completer<PageData<ProductSummary>>();
      final logoutGate = Completer<void>();
      final products = _ProductsRepository(() => account, lateA);
      final storage = MemoryTokenStorage();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_AuthController.new),
          authRepositoryProvider.overrideWithValue(_AuthRepository(logoutGate)),
          biometricSessionManagerProvider.overrideWithValue(
            BiometricSessionManager(
              _BiometricAuth(),
              MemoryBiometricPreferenceStore(),
              storage,
            ),
          ),
          productsRepositoryProvider.overrideWithValue(products),
          clientsRepositoryProvider.overrideWithValue(
            _ClientsRepository(() => account),
          ),
          salesRepositoryProvider.overrideWithValue(
            _SalesRepository(() => account),
          ),
          dashboardRepositoryProvider.overrideWithValue(
            _DashboardRepository(() => account),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(productsProvider, (_, _) {}, fireImmediately: true);
      container.listen(clientsProvider, (_, _) {}, fireImmediately: true);
      container.listen(salesProvider, (_, _) {}, fireImmediately: true);
      container.listen(dashboardProvider, (_, _) {}, fireImmediately: true);
      await _flush();

      expect(container.read(productsProvider).items.single.name, 'Produit A');
      expect(container.read(clientsProvider).items.single.name, 'Client A');
      expect(container.read(salesProvider).items.single.number, 'Vente A');
      expect(container.read(dashboardProvider).value?.salesCount, 1);

      unawaited(container.read(productsProvider.notifier).refresh());
      await _flush();
      expect(products.calls, 2);

      final logout = container.read(authControllerProvider.notifier).logout();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(container.read(productsProvider).items, isEmpty);

      logoutGate.complete();
      await logout;
      account = 'B';
      container.read(authControllerProvider.notifier).completeLogin(_userB);
      await _flush();

      expect(container.read(authControllerProvider).user?.id, _userB.id);
      expect(container.read(productsProvider).items.single.name, 'Produit B');
      expect(container.read(clientsProvider).items.single.name, 'Client B');
      expect(container.read(salesProvider).items.single.number, 'Vente B');
      expect(container.read(dashboardProvider).value?.salesCount, 2);

      lateA.complete(
        _page(
          const ProductSummary(
            id: 1,
            name: 'Produit A tardif',
            reference: 'A',
            quantity: 1,
            stockStatus: 'normal',
          ),
        ),
      );
      await _flush();

      expect(container.read(productsProvider).items.single.name, 'Produit B');
    },
  );

  testWidgets('le retour Android après logout reste sur la connexion', (
    tester,
  ) async {
    var account = 'A';
    final logoutGate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_AuthController.new),
        authRepositoryProvider.overrideWithValue(_AuthRepository(logoutGate)),
        biometricSessionManagerProvider.overrideWithValue(
          BiometricSessionManager(
            _BiometricAuth(),
            MemoryBiometricPreferenceStore(),
            MemoryTokenStorage(),
          ),
        ),
        productsRepositoryProvider.overrideWithValue(
          _ProductsRepository(
            () => account,
            Completer<PageData<ProductSummary>>(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ElAmineApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/products');
    await tester.pumpAndSettle();
    expect(find.byType(ProductsScreen), findsOneWidget);

    final logout = container.read(authControllerProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProductsScreen), findsNothing);

    logoutGate.complete();
    await logout;
    account = 'B';
  });
}
