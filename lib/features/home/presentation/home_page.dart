import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/data/auth_providers.dart';
import '../../matches/presentation/matches_list_page.dart';
import '../../matches/presentation/my_participations_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../users/presentation/user_search_page.dart';

/// Contenedor principal tras iniciar sesión.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 1;

  static const _titles = [
    'Buscar',
    'Partidos',
    'Mis participaciones',
    'Perfil',
  ];

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
        0 => const UserSearchPage(embedded: true),
        1 => MatchesListPage(
          onOpenMatch: (match) =>
              context.push(AppRoutes.matchDetailPath(match.id)),
        ),
        2 => const MyParticipationsPage(),
        _ => const ProfilePage(),
      },
      floatingActionButton: _index == 1
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
            icon: Text('🔎', style: TextStyle(fontSize: 22)),
            selectedIcon: Text('🔎', style: TextStyle(fontSize: 22)),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Text('🏟️', style: TextStyle(fontSize: 22)),
            selectedIcon: Text('🏟️', style: TextStyle(fontSize: 22)),
            label: 'Partidos',
          ),
          NavigationDestination(
            icon: Text('📅', style: TextStyle(fontSize: 22)),
            selectedIcon: Text('📅', style: TextStyle(fontSize: 22)),
            label: 'Mis partidos',
          ),
          NavigationDestination(
            icon: Text('👤', style: TextStyle(fontSize: 22)),
            selectedIcon: Text('👤', style: TextStyle(fontSize: 22)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
