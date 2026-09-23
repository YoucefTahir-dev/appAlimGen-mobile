import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_client.dart';
import 'package:app_alim_gen_mobile/core/network/session_events.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/clients/data/clients_repository.dart';
import 'package:app_alim_gen_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/data/loading_orders_repository.dart';
import 'package:app_alim_gen_mobile/features/printers/data/printers_repository.dart';
import 'package:app_alim_gen_mobile/features/printers/services/bluetooth_printer_transport.dart';
import 'package:app_alim_gen_mobile/features/printers/services/esc_pos_printer_driver.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_test_service.dart';
import 'package:app_alim_gen_mobile/features/products/data/products_repository.dart';
import 'package:app_alim_gen_mobile/features/stock/data/stock_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);
final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(tokenStorageProvider)),
);
final apiClientProvider = Provider<ApiClient>((ref) {
  final languageCode = ref.watch(localeProvider).languageCode;
  return ApiClient(
    storage: ref.watch(tokenStorageProvider),
    sessionEvents: ref.watch(sessionEventsProvider),
    languageCode: () => languageCode,
  );
});
final errorMapperProvider = Provider<ErrorMapper>((ref) => const ErrorMapper());
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    dio: ref.watch(apiClientProvider).dio,
    session: ref.watch(sessionRepositoryProvider),
    errorMapper: ref.watch(errorMapperProvider),
  ),
);
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final clientsRepositoryProvider = Provider<ClientsRepository>(
  (ref) => ClientsRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final invoicesRepositoryProvider = Provider<InvoicesRepository>(
  (ref) => InvoicesRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final suppliersRepositoryProvider = Provider<SuppliersRepository>(
  (ref) => SuppliersRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final purchasesRepositoryProvider = Provider<PurchasesRepository>(
  (ref) => PurchasesRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final loadingOrdersRepositoryProvider = Provider<LoadingOrdersRepository>(
  (ref) => LoadingOrdersRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => StockRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final operatorStockRepositoryProvider = Provider<OperatorStockRepository>(
  (ref) => OperatorStockRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
    ref.watch(loadingOrdersRepositoryProvider),
  ),
);
final printersRepositoryProvider = Provider<PrintersRepository>(
  (ref) => PrintersRepository(
    ref.watch(apiClientProvider).dio,
    ref.watch(errorMapperProvider),
  ),
);
final printerTestServiceProvider = Provider<PrinterTestService>(
  (ref) =>
      PrinterTestService(BluetoothPrinterTransport(), EscPosPrinterDriver()),
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('fr');
  void select(String code) => state = Locale(code);
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
