import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/data/auth_providers.dart';
import '../../matches/presentation/matches_list_page.dart';
import '../../matches/presentation/my_matches_page.dart';
import '../../profile/presentation/profile_page.dart';

/// Contenedor principal tras iniciar sesión. Bottom navigation con las tres
/// zonas del MVP: buscar partidos, mis partidos y perfil.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  static const _titles = ['Partidos', 'Mis participaciones', 'Perfil'];

  void _openMatch(String id) => context.push(AppRoutes.matchDetailPath(id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: switch (_index) {
        0 => MatchesListPage(
            onOpenMatch: (match) => _openMatch(match.id),
          ),
        1 => MyMatchesPage(
            onOpenMatch: (match) => _openMatch(match.id),
          ),
        _ => const ProfilePage(),
      },
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.createMatch),
              icon: const Icon(Icons.add),
              label: const Text('Crear partido'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Mis partidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
