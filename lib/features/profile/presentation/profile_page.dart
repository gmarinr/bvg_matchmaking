import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../auth/data/auth_providers.dart';
import '../data/profile_providers.dart';
import '../domain/profile.dart';
import '../../communes/data/commune_providers.dart';
import '../../communes/presentation/commune_selector.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver tu perfil.'));
    }

    final profile = ref.watch(profileProvider(user.id));
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(_errorMessage(error))),
      data: (value) => ProfileForm(userId: user.id, profile: value),
    );
  }
}

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({required this.userId, required this.profile, super.key});

  final String userId;
  final Profile? profile;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  late final TextEditingController _displayName;
  String? _communeCode;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(
      text: widget.profile?.displayName ?? '',
    );
    _communeCode = widget.profile?.communeCode;
  }

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final commune = ref
        .read(communesProvider)
        .valueOrNull
        ?.where((item) => item.code == _communeCode)
        .firstOrNull;
    if (_displayName.text.trim().isEmpty || commune == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa tu nombre y comuna.')),
      );
      return;
    }

    setState(() => _loading = true);
    final now = DateTime.now();
    final current = widget.profile;
    final profile = Profile(
      id: widget.userId,
      displayName: _displayName.text.trim(),
      commune: commune.name,
      communeCode: commune.code,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
      avatarUrl: current?.avatarUrl,
      generalAvailability: current?.generalAvailability,
    );

    try {
      await ref.read(profileRepositoryProvider).upsertProfile(profile);
      ref.invalidate(profileProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil guardado.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tu perfil deportivo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _displayName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre visible',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        CommuneSelector(
          value: _communeCode,
          onChanged: (value) => setState(() => _communeCode = value),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar perfil'),
        ),
      ],
    );
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar la información.';
}
