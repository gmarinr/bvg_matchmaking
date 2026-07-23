import 'package:bvg_matchmaking/core/supabase/supabase_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('explica que falta confirmar el correo', () {
    final failure = mapSupabaseError(
      const AuthException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      ),
    );

    expect(failure.message, 'Confirma tu correo antes de iniciar sesión.');
  });

  test('explica el límite de envío de correo', () {
    final failure = mapSupabaseError(
      const AuthException(
        'For security purposes, you can only request this after 55 seconds.',
        statusCode: '429',
      ),
    );

    expect(
      failure.message,
      'Demasiados intentos. Espera un minuto y vuelve a intentarlo.',
    );
  });
}
