import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/labels.dart';
import '../data/user_search_providers.dart';
import '../domain/public_user_profile.dart';

/// Etiqueta Hero compartida entre la tarjeta de amigo y el avatar del perfil,
/// para que la transición al abrir el perfil sea fluida.
String friendAvatarTag(String userId) => 'friend-avatar-$userId';

/// Avatar circular con la inicial del nombre. Se usa idéntico en la tarjeta de
/// amigo y en el perfil para que el Hero tenga el mismo origen y destino.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    required this.radius,
  });

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}

/// Perfil público de otra persona: usuario, comuna y deportes declarados.
/// No expone correo ni datos de autenticación.
class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(publicUserLookupProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Centered(
          icon: Icons.cloud_off_outlined,
          message: _errorMessage(error),
        ),
        data: (profile) => profile == null
            ? const _Centered(
                icon: Icons.person_off_outlined,
                message: 'No encontramos este perfil.',
              )
            : _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final PublicUserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(
          child: Hero(
            tag: friendAvatarTag(profile.id),
            child: InitialAvatar(name: profile.displayName, radius: 48),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            profile.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                profile.commune.isEmpty ? 'Sin comuna' : profile.commune,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Deportes y niveles',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (profile.sports.isEmpty)
          Text(
            'Esta persona aún no registra deportes.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          for (final sport in profile.sports)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(Icons.sports_outlined, color: scheme.primary),
                title: Text(
                  sport.sportName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sport.skillLevel.label,
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar el perfil.';
}
