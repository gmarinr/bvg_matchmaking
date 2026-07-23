import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/sport.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/profile_providers.dart';
import '../../domain/profile.dart';

/// Perfil del usuario de la sesión. `null` si todavía no lo ha creado.
final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});

/// Deportes y niveles declarados por el usuario de la sesión.
final myUserSportsProvider =
    FutureProvider.autoDispose<List<UserSport>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const [];
  return ref.watch(profileRepositoryProvider).getUserSports(user.id);
});
