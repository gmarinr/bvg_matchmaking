import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/sport.dart';
import '../../../core/errors/failures.dart';
import '../../auth/data/auth_providers.dart';
import '../data/profile_providers.dart';
import '../domain/profile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver tu perfil.'));
    }

    final profile = ref.watch(profileProvider(user.id));
    final sports = ref.watch(sportsProvider);
    final userSports = ref.watch(userSportsProvider(user.id));

    if (profile.isLoading || sports.isLoading || userSports.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = profile.error ?? sports.error ?? userSports.error;
    if (error != null) return Center(child: Text(_errorMessage(error)));

    return ProfileForm(
      userId: user.id,
      profile: profile.value,
      sports: sports.value ?? const [],
      userSports: userSports.value ?? const [],
    );
  }
}

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    required this.userId,
    required this.profile,
    required this.sports,
    required this.userSports,
    super.key,
  });

  final String userId;
  final Profile? profile;
  final List<Sport> sports;
  final List<UserSport> userSports;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  late final TextEditingController _commune;
  late final TextEditingController _availability;
  late final Map<String, SkillLevel> _selectedSports;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(
      text: widget.profile?.displayName ?? '',
    );
    _commune = TextEditingController(text: widget.profile?.commune ?? '');
    _availability = TextEditingController(
      text: widget.profile?.generalAvailability ?? '',
    );
    _selectedSports = {
      for (final sport in widget.userSports) sport.sportId: sport.skillLevel,
    };
  }

  @override
  void dispose() {
    _displayName.dispose();
    _commune.dispose();
    _availability.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSports.isEmpty) {
      _showMessage('Selecciona al menos un deporte.');
      return;
    }

    setState(() => _loading = true);
    final now = DateTime.now();
    final current = widget.profile;
    final profile = Profile(
      id: widget.userId,
      displayName: _displayName.text.trim(),
      commune: _commune.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
      avatarUrl: current?.avatarUrl,
      generalAvailability: _availability.text.trim(),
    );

    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.upsertProfile(profile);

      final selectedIds = _selectedSports.keys.toSet();
      await Future.wait([
        ..._selectedSports.entries.map(
          (entry) => repository.setUserSport(
            UserSport(
              userId: widget.userId,
              sportId: entry.key,
              skillLevel: entry.value,
            ),
          ),
        ),
        ...widget.userSports
            .where((sport) => !selectedIds.contains(sport.sportId))
            .map(
              (sport) => repository.removeUserSport(
                userId: widget.userId,
                sportId: sport.sportId,
              ),
            ),
      ]);

      ref.invalidate(profileProvider(widget.userId));
      ref.invalidate(userSportsProvider(widget.userId));
      if (mounted) _showMessage('Perfil actualizado.');
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyUserId() async {
    await Clipboard.setData(ClipboardData(text: widget.userId));
    if (mounted) _showMessage('ID copiado al portapapeles.');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tu perfil deportivo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Esta información se usará para que otras personas conozcan tu perfil.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu ID de usuario',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          widget.userId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar ID',
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: _copyUserId,
                      ),
                    ],
                  ),
                  Text(
                    'Compártelo solo con personas de confianza.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _displayName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre visible',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _requiredValidator('Completa tu nombre.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _commune,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Comuna',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: _requiredValidator('Completa tu comuna.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _availability,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Disponibilidad general',
              hintText: 'Ej.: tardes de lunes a viernes y sabados AM',
              prefixIcon: Icon(Icons.schedule_outlined),
              alignLabelWithHint: true,
            ),
            validator: _requiredValidator('Completa tu disponibilidad.'),
          ),
          const SizedBox(height: 24),
          Text(
            'Deportes y niveles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sport in widget.sports)
                FilterChip(
                  label: Text(sport.name),
                  selected: _selectedSports.containsKey(sport.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSports[sport.id] = SkillLevel.intermediate;
                      } else {
                        _selectedSports.remove(sport.id);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final sport in widget.sports)
            if (_selectedSports.containsKey(sport.id)) ...[
              DropdownButtonFormField<SkillLevel>(
                value: _selectedSports[sport.id],
                decoration: InputDecoration(labelText: 'Nivel en ${sport.name}'),
                items: [
                  for (final level in SkillLevel.values)
                    DropdownMenuItem(
                      value: level,
                      child: Text(_skillLabel(level)),
                    ),
                ],
                onChanged: (level) {
                  if (level != null) {
                    setState(() => _selectedSports[sport.id] = level);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          if (widget.sports.isEmpty)
            const Text('No hay deportes disponibles en este momento.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}

String? Function(String?) _requiredValidator(String message) => (value) {
      if ((value ?? '').trim().isEmpty) return message;
      return null;
    };

String _skillLabel(SkillLevel level) => switch (level) {
      SkillLevel.beginner => 'Principiante',
      SkillLevel.intermediate => 'Intermedio',
      SkillLevel.advanced => 'Avanzado',
    };

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar la información.';
}
