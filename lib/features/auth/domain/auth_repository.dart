/// Usuario autenticado, expuesto a la UI sin filtrar tipos de Supabase.
class AppUser {
  const AppUser({required this.id, required this.email});

  final String id;
  final String email;
}

/// Contrato de autenticación. La implementación real (Supabase Auth) vive en
/// `data/`. La UI y los providers dependen solo de esta interfaz.
abstract interface class AuthRepository {
  /// Emite el usuario actual cada vez que cambia la sesión (login/logout).
  Stream<AppUser?> authStateChanges();

  /// Usuario actual sin esperar el stream, o `null` si no hay sesión.
  AppUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({required String email, required String password});

  Future<void> signOut();
}
