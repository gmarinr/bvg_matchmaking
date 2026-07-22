import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';

/// Converts Supabase exceptions into errors safe to show in the UI.
Failure mapSupabaseError(Object error) {
  if (error is Failure) return error;

  if (error is AuthException) {
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
        return const UnexpectedFailure();
    }
  }

  return const UnexpectedFailure();
}
