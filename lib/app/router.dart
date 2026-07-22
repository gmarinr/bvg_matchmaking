import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/matches/presentation/create_match_page.dart';
import '../features/matches/presentation/manage_requests_page.dart';
import '../features/matches/presentation/match_detail_page.dart';

/// Rutas nombradas de la app.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createMatch = '/matches/new';

  /// Detalle de un partido. `/matches/new` se declara antes para que no
  /// sea capturada por este patrón.
  static const String matchDetail = '/matches/:id';

  static String matchDetailPath(String id) => '/matches/$id';

  /// Gestión de solicitudes del organizador.
  static const String manageRequests = '/matches/:id/requests';

  static String manageRequestsPath(String id) => '/matches/$id/requests';
}

/// Router con guard de autenticación. Sin sesión, todo redirige a login;
/// con sesión, login/registro redirigen a home.
final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges()),
    redirect: (context, state) {
      final loggedIn = authRepo.currentUser != null;
      final loc = state.matchedLocation;
      final atAuthScreen =
          loc == AppRoutes.login || loc == AppRoutes.register;

      if (!loggedIn) return atAuthScreen ? null : AppRoutes.login;
      if (atAuthScreen) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.createMatch,
        builder: (context, state) => const CreateMatchPage(),
      ),
      GoRoute(
        path: AppRoutes.matchDetail,
        builder: (context, state) => MatchDetailPage(
          matchId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.manageRequests,
        builder: (context, state) => ManageRequestsPage(
          matchId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});

/// Adapta un [Stream] a [Listenable] para que go_router reevalúe el guard
/// cada vez que cambia la sesión.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
