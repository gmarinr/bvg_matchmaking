import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/failures.dart';
import '../../auth/data/auth_providers.dart';
import '../../users/data/user_search_providers.dart';
import '../../users/presentation/public_profile_page.dart';
import '../data/friendship_providers.dart';
import '../domain/friendship.dart';

class FriendshipsPage extends ConsumerWidget {
  const FriendshipsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver tus solicitudes.')),
      );
    }

    final received = ref.watch(receivedFriendshipsProvider(user.id));
    final sent = ref.watch(sentFriendshipsProvider(user.id));
    final accepted = ref.watch(acceptedFriendshipsProvider(user.id));
    final loading = received.isLoading || sent.isLoading || accepted.isLoading;
    final error = received.error ?? sent.error ?? accepted.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes y amigos')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(_errorMessage(error)))
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Recibidas'),
                      Tab(text: 'Enviadas'),
                      Tab(text: 'Amigos'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _FriendshipList(
                          items: received.value ?? const [],
                          type: _FriendshipListType.received,
                          currentUserId: user.id,
                        ),
                        _FriendshipList(
                          items: sent.value ?? const [],
                          type: _FriendshipListType.sent,
                          currentUserId: user.id,
                        ),
                        _FriendshipList(
                          items: accepted.value ?? const [],
                          type: _FriendshipListType.accepted,
                          currentUserId: user.id,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

enum _FriendshipListType { received, sent, accepted }

class _FriendshipList extends StatelessWidget {
  const _FriendshipList({
    required this.items,
    required this.type,
    required this.currentUserId,
  });

  final List<Friendship> items;
  final _FriendshipListType type;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 140),
          Center(child: Text(_emptyMessage(type))),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friendship = items[index];
        if (type == _FriendshipListType.accepted) {
          return _FriendCard(
            friendship: friendship,
            currentUserId: currentUserId,
          );
        }
        return _FriendshipTile(
          friendship: friendship,
          type: type,
          currentUserId: currentUserId,
        );
      },
    );
  }
}

/// Identifica al otro usuario de una amistad respecto del usuario actual.
String _otherUserId(Friendship friendship, String currentUserId) =>
    friendship.requesterId == currentUserId
    ? friendship.addresseeId
    : friendship.requesterId;

/// Tarjeta de un amigo: avatar a la izquierda, usuario al centro y un botón
/// redondo para eliminar la amistad a la derecha. Al presionarla se abre el
/// perfil de la persona.
class _FriendCard extends ConsumerStatefulWidget {
  const _FriendCard({required this.friendship, required this.currentUserId});

  final Friendship friendship;
  final String currentUserId;

  @override
  ConsumerState<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends ConsumerState<_FriendCard> {
  bool _loading = false;

  String get _friendId =>
      _otherUserId(widget.friendship, widget.currentUserId);

  Future<void> _confirmRemove(String friendName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar amistad'),
        content: Text('Dejarás de ser amigo de $friendName.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _remove();
  }

  Future<void> _remove() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(friendshipRepositoryProvider)
          .removeFriendship(widget.friendship.id);
      ref.invalidate(receivedFriendshipsProvider(widget.currentUserId));
      ref.invalidate(sentFriendshipsProvider(widget.currentUserId));
      ref.invalidate(acceptedFriendshipsProvider(widget.currentUserId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profileAsync = ref.watch(publicUserLookupProvider(_friendId));
    final name = profileAsync.when(
      loading: () => 'Cargando…',
      error: (_, _) => 'Usuario',
      data: (profile) => profile?.displayName ?? 'Usuario',
    );
    final commune = profileAsync.valueOrNull?.commune;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.userProfilePath(_friendId)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Hero(
                tag: friendAvatarTag(_friendId),
                child: InitialAvatar(name: name, radius: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (commune != null && commune.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        commune,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton.filledTonal(
                      tooltip: 'Eliminar amistad',
                      onPressed: () => _confirmRemove(name),
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        foregroundColor: scheme.error,
                        backgroundColor: scheme.errorContainer,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendshipTile extends ConsumerStatefulWidget {
  const _FriendshipTile({
    required this.friendship,
    required this.type,
    required this.currentUserId,
  });

  final Friendship friendship;
  final _FriendshipListType type;
  final String currentUserId;

  @override
  ConsumerState<_FriendshipTile> createState() => _FriendshipTileState();
}

class _FriendshipTileState extends ConsumerState<_FriendshipTile> {
  bool _loading = false;

  Future<void> _runAction() async {
    setState(() => _loading = true);
    try {
      final repository = ref.read(friendshipRepositoryProvider);
      final action = switch (widget.type) {
        _FriendshipListType.received =>
          repository.acceptRequest(widget.friendship.id),
        _FriendshipListType.sent =>
          repository.cancelRequest(widget.friendship.id),
        _FriendshipListType.accepted =>
          repository.removeFriendship(widget.friendship.id),
      };
      await action;
      _invalidateLists();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(friendshipRepositoryProvider)
          .rejectRequest(widget.friendship.id);
      _invalidateLists();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _invalidateLists() {
    ref.invalidate(receivedFriendshipsProvider(widget.currentUserId));
    ref.invalidate(sentFriendshipsProvider(widget.currentUserId));
    ref.invalidate(acceptedFriendshipsProvider(widget.currentUserId));
  }

  @override
  Widget build(BuildContext context) {
    final otherUserId = _otherUserId(widget.friendship, widget.currentUserId);
    final displayNameAsync = ref.watch(publicUserLookupProvider(otherUserId));
    final displayName = displayNameAsync.when(
      loading: () => 'Cargando usuario...',
      error: (_, _) => 'Usuario',
      data: (profile) => profile?.displayName ?? 'Usuario',
    );
    final title = switch (widget.type) {
      _FriendshipListType.received => 'Solicitud recibida a $displayName',
      _FriendshipListType.sent => 'Solicitud enviada a $displayName',
      _FriendshipListType.accepted => 'Amistad con $displayName',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const SizedBox(height: 4),
            if (widget.type == _FriendshipListType.received)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading ? null : _runAction,
                      child: const Text('Aceptar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _reject,
                      child: const Text('Rechazar'),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton(
                onPressed: _loading ? null : _runAction,
                child: Text(
                  widget.type == _FriendshipListType.sent
                      ? 'Cancelar solicitud'
                      : 'Eliminar amistad',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _emptyMessage(_FriendshipListType type) => switch (type) {
      _FriendshipListType.received => 'No tienes solicitudes recibidas.',
      _FriendshipListType.sent => 'No tienes solicitudes enviadas.',
      _FriendshipListType.accepted => 'Aún no tienes amigos.',
    };

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos actualizar tus solicitudes.';
}
