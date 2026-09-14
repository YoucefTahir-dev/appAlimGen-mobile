import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_filter.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardFilterController extends Notifier<DashboardFilter> {
  @override
  DashboardFilter build() => const DashboardFilter();

  void selectPeriod(String period) {
    state = DashboardFilter(period: period);
  }

  void selectCustom(DateTime startDate, DateTime endDate) {
    state = DashboardFilter(
      period: 'custom',
      startDate: startDate,
      endDate: endDate,
    );
  }
}

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterController, DashboardFilter>(
      DashboardFilterController.new,
    );

final dashboardProvider = FutureProvider<DashboardSummary>((ref) {
  final filter = ref.watch(dashboardFilterProvider);
  return ref.watch(dashboardRepositoryProvider).load(filter: filter);
});
