import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/labels.dart';
import '../data/user_search_providers.dart';
import '../domain/public_user_profile.dart';
import '../domain/uuid_validator.dart';

class UserSearchPage extends ConsumerStatefulWidget {
  const UserSearchPage({this.embedded = false, super.key});

  final bool embedded;

  @override
  ConsumerState<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends ConsumerState<UserSearchPage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = TextEditingController();
  String? _searchedId;

  @override
  void dispose() {
    _uuid.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _searchedId = _uuid.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final searchedId = _searchedId;
    final content = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Busca una persona usando su UUID exacto.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'No se pueden buscar nombres ni listar usuarios. El resultado solo muestra información pública mínima.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _uuid,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'UUID del usuario',
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Ingresa un UUID.';
                if (!isValidUuid(input)) return 'Ingresa un UUID válido.';
                return null;
              },
              onFieldSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search),
            label: const Text('Buscar'),
          ),
          const SizedBox(height: 24),
          if (searchedId == null)
            const _InitialSearchState()
          else
            _LookupResult(userId: searchedId),
        ],
      );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar usuario')),
      body: content,
    );
  }
}

class _LookupResult extends ConsumerWidget {
  const _LookupResult({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(publicUserLookupProvider(userId));
    return result.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(_errorMessage(error)),
      data: (profile) => profile == null
          ? const _EmptySearchState()
          : _PublicProfileCard(profile: profile),
    );
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos buscar el usuario. Intenta nuevamente.';
}

class _PublicProfileCard extends StatelessWidget {
  const _PublicProfileCard({required this.profile});

  final PublicUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('UUID: ${profile.id}'),
            Text('Comuna: ${profile.commune}'),
            const SizedBox(height: 16),
            Text(
              'Deportes y niveles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final sport in profile.sports)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.sports_outlined),
                title: Text(sport.sportName),
                trailing: Text(sport.skillLevel.label),
              ),
            if (profile.sports.isEmpty)
              const Text('Esta persona aún no registra deportes.'),
          ],
        ),
      ),
    );
  }
}

class _InitialSearchState extends StatelessWidget {
  const _InitialSearchState();

  @override
  Widget build(BuildContext context) => const Text(
    'Pega aquí el UUID que la otra persona compartió contigo.',
  );
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) => const Text(
    'No encontramos un usuario con ese UUID.',
  );
}
