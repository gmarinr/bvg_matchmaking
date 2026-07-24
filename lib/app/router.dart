import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/sport.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/matches/presentation/create_match_page.dart';
import '../features/matches/presentation/manage_requests_page.dart';
import '../features/matches/presentation/match_detail_page.dart';
import '../features/matches/presentation/sport_matches_page.dart';
import '../features/friendships/presentation/friendships_page.dart';
import '../features/profile/data/profile_providers.dart';
import '../features/profile/domain/profile.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/profile/presentation/onboarding_page.dart';
import '../features/users/presentation/public_profile_page.dart';
import '../features/users/presentation/user_search_page.dart';

/// Rutas nombradas de la app.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String userSearch = '/users/search';

  /// Perfil público de otra persona. `/users/search` se declara antes para que
  /// no sea capturada por este patrón.
  static const String userProfile = '/users/:id';

  static String userProfilePath(String id) => '/users/$id';

  static const String friendships = '/friendships';
  static const String home = '/home';
  static const String createMatch = '/matches/new';

  static const String sportMatches = '/sports/:id/matches';

  static String sportMatchesPath(String id) => '/sports/$id/matches';

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
  final profileRepo = ref.watch(profileRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges()),
    redirect: (context, state) async {
      final loggedIn = authRepo.currentUser != null;
      final loc = state.matchedLocation;
      final atAuthScreen = loc == AppRoutes.login || loc == AppRoutes.register;
      final atOnboarding = loc == AppRoutes.onboarding;

      if (!loggedIn) return atAuthScreen ? null : AppRoutes.login;
      final complete = await _isProfileComplete(
        profileRepo,
        authRepo.currentUser!.id,
      );
      if (!complete) return atOnboarding ? null : AppRoutes.onboarding;
      if (atAuthScreen || atOnboarding) return AppRoutes.home;
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
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.userSearch,
        builder: (context, state) => const UserSearchPage(),
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (context, state) =>
            PublicProfilePage(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.friendships,
        builder: (context, state) => const FriendshipsPage(),
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
        path: AppRoutes.sportMatches,
        builder: (context, state) => SportMatchesPage(
          sportId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.matchDetail,
        builder: (context, state) =>
            MatchDetailPage(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.manageRequests,
        builder: (context, state) =>
            ManageRequestsPage(matchId: state.pathParameters['id']!),
      ),
    ],
  );
});

Future<bool> _isProfileComplete(
  ProfileRepository repository,
  String userId,
) async {
  final results = await Future.wait([
    repository.getProfile(userId),
    repository.getUserSports(userId),
  ]);
  final profile = results[0] as Profile?;
  if (profile == null ||
      profile.displayName.trim().isEmpty ||
      profile.commune.trim().isEmpty ||
      (profile.generalAvailability ?? '').trim().isEmpty) {
    return false;
  }

  return (results[1] as List<UserSport>).isNotEmpty;
}

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
