/// Error de dominio ya traducido a un mensaje comprensible para el usuario.
/// Los repositorios atrapan excepciones técnicas y las convierten en `Failure`.
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Fallo de red o conectividad.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión. Revisa tu internet.']);
}

/// Credenciales inválidas o sesión no autorizada.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'No pudimos validar tus credenciales.']);
}

/// La operación no está permitida para este usuario (p. ej. editar un partido
/// ajeno). Suele reflejar una política RLS.
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'No tienes permiso para esto.']);
}

/// El recurso solicitado no existe.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontramos lo que buscabas.']);
}

/// Regla de negocio violada (p. ej. solicitar dos veces el mismo partido).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Fallo inesperado no clasificado.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Ocurrió un error inesperado.']);
}
