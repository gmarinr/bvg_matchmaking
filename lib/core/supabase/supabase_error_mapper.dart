import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';

/// Converts Supabase exceptions into errors safe to show in the UI.
Failure mapSupabaseError(Object error) {
  if (error is Failure) return error;

  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (error.code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return const AuthFailure('Confirma tu correo antes de iniciar sesión.');
    }
    if (error.statusCode == '429' || message.contains('rate limit')) {
      return const AuthFailure(
        'Demasiados intentos. Espera un minuto y vuelve a intentarlo.',
      );
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return const AuthFailure('Este correo ya tiene una cuenta.');
    }
    if (message.contains('invalid login credentials')) {
      return const AuthFailure('El correo o la contraseña no son correctos.');
    }
    return const AuthFailure();
  }

  if (error is PostgrestException) {
    switch (error.code) {
      case '42501':
        return const PermissionFailure();
      case 'PGRST116':
        return const NotFoundFailure();
      case '23505':
        return const ValidationFailure(
          'Esta participación ya existe para el partido.',
        );
      case '23503':
        return const ValidationFailure(
          'El deporte o partido seleccionado ya no existe.',
        );
      case 'P0001':
        return const ValidationFailure(
          'La operación no cumple una regla del partido.',
        );
      default:
        // Código de Postgres que aún no clasificamos. Mostramos el detalle
        // (código + mensaje) para poder diagnosticar el problema del backend.
        debugPrint(
          'Postgrest no mapeado — code: ${error.code}, message: ${error.message}, '
          'details: ${error.details}, hint: ${error.hint}',
        );
        return UnexpectedFailure(
          'Error de base de datos (${error.code}): ${error.message}',
        );
    }
  }

  debugPrint('Error no clasificado: ${error.runtimeType} — $error');
  return UnexpectedFailure('Error inesperado: $error');
}
