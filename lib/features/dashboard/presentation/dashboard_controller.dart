import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardProvider = FutureProvider<DashboardSummary>(
  (ref) => ref.watch(dashboardRepositoryProvider).load(),
);
