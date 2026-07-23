/// Configuración por entorno. Se inyecta con `--dart-define` al compilar:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// No se guardan secretos en el repositorio. La anon key es pública por
/// diseño; la seguridad depende de RLS, no de ocultarla.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// `true` cuando hay credenciales para conectar a Supabase. Si es `false`,
  /// la app corre contra repositorios falsos (desarrollo de UI sin backend).
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
