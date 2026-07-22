import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente Supabase compartido. Debe inicializarse en `main()` antes de leer
/// este provider (solo cuando hay credenciales configuradas).
///
/// La capa `data/` de cada feature lee este provider para construir sus
/// repositorios reales. La UI nunca lo usa directamente.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
