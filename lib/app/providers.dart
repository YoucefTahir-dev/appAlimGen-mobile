import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_client.dart';
import 'package:app_alim_gen_mobile/core/network/session_events.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/dashboard/data/dashboard_repository.dart';
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

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('fr');
  void select(String code) => state = Locale(code);
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
