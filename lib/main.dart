import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo inicializa Supabase si hay credenciales. Sin ellas, la app corre
  // contra los repositorios en memoria (desarrollo de UI sin backend).
  if (Env.isSupabaseConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // La anon key pública se pasa como publishableKey (naming nuevo del SDK).
      publishableKey: Env.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: MatchMakingApp()));
}
