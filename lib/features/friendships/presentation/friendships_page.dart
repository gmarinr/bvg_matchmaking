import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../auth/data/auth_providers.dart';
import '../../users/data/user_search_providers.dart';
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
      itemBuilder: (context, index) => _FriendshipTile(
        friendship: items[index],
        type: type,
        currentUserId: currentUserId,
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
    final otherUserId = widget.friendship.requesterId == widget.currentUserId
        ? widget.friendship.addresseeId
        : widget.friendship.requesterId;
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
