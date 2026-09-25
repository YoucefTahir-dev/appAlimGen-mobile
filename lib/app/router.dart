import 'package:app_alim_gen_mobile/app/splash_screen.dart';
import 'package:app_alim_gen_mobile/core/navigation/forbidden_screen.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/login_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/business_list_screens.dart';
import 'package:app_alim_gen_mobile/features/clients/presentation/clients_screen.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/presentation/loading_orders_screen.dart';
import 'package:app_alim_gen_mobile/features/printers/presentation/printers_screen.dart';
import 'package:app_alim_gen_mobile/features/products/presentation/products_screen.dart';
import 'package:app_alim_gen_mobile/features/profile/presentation/profile_screen.dart';
import 'package:app_alim_gen_mobile/features/stock/presentation/stock_screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/products', builder: (_, _) => const ProductsScreen()),
      GoRoute(path: '/clients', builder: (_, _) => const ClientsScreen()),
      GoRoute(path: '/suppliers', builder: (_, _) => const SuppliersScreen()),
      GoRoute(path: '/sales', builder: (_, _) => const SalesScreen()),
      GoRoute(path: '/purchases', builder: (_, _) => const PurchasesScreen()),
      GoRoute(path: '/invoices', builder: (_, _) => const InvoicesScreen()),
      GoRoute(path: '/payments', builder: (_, _) => const PaymentsScreen()),
      GoRoute(path: '/stock', builder: (_, _) => const StockScreen()),
      GoRoute(
        path: '/operator-stock',
        builder: (_, _) => const OperatorStockScreen(),
      ),
      GoRoute(
        path: '/loading-orders',
        builder: (_, _) => const LoadingOrdersScreen(),
      ),
      GoRoute(path: '/expenses', builder: (_, _) => const ExpensesScreen()),
      GoRoute(path: '/printers', builder: (_, _) => const PrintersScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/forbidden', builder: (_, _) => const ForbiddenScreen()),
    ],
    redirect: (_, state) {
      final atLogin = state.matchedLocation == '/login';
      if (auth.status == AuthStatus.initializing) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return atLogin ? null : '/login';
      }
      if (auth.status == AuthStatus.authenticated) {
        final permissions = PermissionService(
          auth.user?.permissions ?? const <String>{},
        );
        if (atLogin || state.matchedLocation == '/splash') {
          return permissions.landingPath();
        }
        if (!permissions.allowsPath(state.matchedLocation)) {
          return '/forbidden';
        }
      }
      return null;
    },
  );
});
