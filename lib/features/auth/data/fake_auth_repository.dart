import 'dart:async';

import '../domain/auth_repository.dart';

/// Implementación en memoria para desarrollar la UI sin Supabase.
/// Cualquier email/clave con formato válido "inicia sesión".
class FakeAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _current = AppUser(id: 'fake-user-1', email: email);
    _controller.add(_current);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Las cuentas nuevas deben pasar por onboarding; el usuario semilla se
    // reserva para los flujos existentes que comienzan con login.
    _current = AppUser(id: 'fake-new-user', email: email);
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}
