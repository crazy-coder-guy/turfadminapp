import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/documents_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/turfs/presentation/screens/court_form_screen.dart';
import '../../features/turfs/presentation/screens/operating_hours_screen.dart';
import '../../features/turfs/presentation/screens/pricing_rules_screen.dart';
import '../../features/turfs/presentation/screens/create_turf_screen.dart';
import '../../features/turfs/presentation/screens/turf_detail_screen.dart';
import '../../features/turfs/presentation/screens/turf_list_screen.dart';
import 'go_router_refresh_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      switch (authState.status) {
        case AuthStatus.bootstrapping:
          return isSplash ? null : '/splash';
        case AuthStatus.unauthenticated:
          return isAuthRoute ? null : '/login';
        case AuthStatus.authenticated:
          return (isSplash || isAuthRoute) ? '/dashboard' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/turfs',
                builder: (context, state) => const TurfListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const CreateTurfScreen(),
                  ),
                  GoRoute(
                    path: ':turfId',
                    builder: (context, state) =>
                        TurfDetailScreen(turfId: state.pathParameters['turfId']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) =>
                            CreateTurfScreen(turfId: state.pathParameters['turfId']),
                      ),
                      GoRoute(
                        path: 'courts/new',
                        builder: (context, state) =>
                            CourtFormScreen(turfId: state.pathParameters['turfId']!),
                      ),
                      GoRoute(
                        path: 'courts/:courtId',
                        builder: (context, state) => CourtFormScreen(
                          turfId: state.pathParameters['turfId']!,
                          courtId: state.pathParameters['courtId'],
                        ),
                        routes: [
                          GoRoute(
                            path: 'operating-hours',
                            builder: (context, state) => OperatingHoursScreen(
                              turfId: state.pathParameters['turfId']!,
                              courtId: state.pathParameters['courtId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'pricing',
                            builder: (context, state) => PricingRulesScreen(
                              turfId: state.pathParameters['turfId']!,
                              courtId: state.pathParameters['courtId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'documents',
                    builder: (context, state) => const DocumentsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
