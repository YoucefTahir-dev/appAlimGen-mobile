import 'package:app_alim_gen_mobile/app/splash_screen.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/login_screen.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app_alim_gen_mobile/features/profile/presentation/profile_screen.dart';
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
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
    redirect: (_, state) {
      final atLogin = state.matchedLocation == '/login';
      if (auth.status == AuthStatus.restoring) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }
      if (auth.status == AuthStatus.unauthenticated ||
          auth.status == AuthStatus.submitting) {
        return atLogin ? null : '/login';
      }
      if (auth.status == AuthStatus.authenticated &&
          (atLogin || state.matchedLocation == '/splash')) {
        return '/dashboard';
      }
      return null;
    },
  );
});
