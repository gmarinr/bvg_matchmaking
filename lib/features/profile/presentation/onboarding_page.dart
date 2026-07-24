import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/sport.dart';
import '../../../core/errors/failures.dart';
import '../../auth/data/auth_providers.dart';
import '../data/profile_providers.dart';
import '../domain/profile.dart';

/// Completa los datos necesarios antes de permitir el acceso al flujo de la
/// aplicacion.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _commune = TextEditingController();
  final _availability = TextEditingController();
  final Map<String, SkillLevel> _selectedSports = {};

  List<Sport>? _sports;
  Profile? _profile;
  bool _loadingData = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _commune.dispose();
    _availability.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentAppUserProvider);
    if (user == null) return;

    try {
      final repository = ref.read(profileRepositoryProvider);
      final results = await Future.wait([
        repository.getProfile(user.id),
        repository.getSports(),
        repository.getUserSports(user.id),
      ]);
      final profile = results[0] as Profile?;
      final sports = results[1] as List<Sport>;
      final userSports = results[2] as List<UserSport>;

      if (!mounted) return;
      _profile = profile;
      _sports = sports;
      _displayName.text = profile?.displayName ?? '';
      _commune.text = profile?.commune ?? '';
      _availability.text = profile?.generalAvailability ?? '';
      _selectedSports
        ..clear()
        ..addEntries(
          userSports.map((sport) => MapEntry(sport.sportId, sport.skillLevel)),
        );
      setState(() => _loadingData = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingData = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSports.isEmpty) {
      setState(() => _error = 'Selecciona al menos un deporte.');
      return;
    }

    final user = ref.read(currentAppUserProvider);
    if (user == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);
      final now = DateTime.now();
      await repository.upsertProfile(
        Profile(
          id: user.id,
          displayName: _displayName.text.trim(),
          commune: _commune.text.trim(),
          createdAt: _profile?.createdAt ?? now,
          updatedAt: now,
          avatarUrl: _profile?.avatarUrl,
          generalAvailability: _availability.text.trim(),
        ),
      );

      final existingSports = await repository.getUserSports(user.id);
      final selectedIds = _selectedSports.keys.toSet();
      await Future.wait([
        ..._selectedSports.entries.map(
          (entry) => repository.setUserSport(
            UserSport(
              userId: user.id,
              sportId: entry.key,
              skillLevel: entry.value,
            ),
          ),
        ),
        ...existingSports
            .where((sport) => !selectedIds.contains(sport.sportId))
            .map(
              (sport) => repository.removeUserSport(
                userId: user.id,
                sportId: sport.sportId,
              ),
            ),
      ]);

      ref.invalidate(profileProvider(user.id));
      ref.invalidate(userSportsProvider(user.id));
      if (mounted) context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null && _sports == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Completa tu perfil')),
        body: Center(child: Text(_error!)),
      );
    }

    final sports = _sports ?? const <Sport>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Conoce personas con tus mismos intereses deportivos.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _displayName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre visible',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _requiredValidator('Ingresa tu nombre'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commune,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Comuna',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: _requiredValidator('Ingresa tu comuna'),
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
                validator: _requiredValidator(
                  'Indica tu disponibilidad general',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Que deportes practicas?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (sports.isEmpty)
                const Text('No hay deportes disponibles en este momento.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sport in sports)
                      FilterChip(
                        label: Text(sport.name),
                        selected: _selectedSports.containsKey(sport.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSports[sport.id] =
                                  SkillLevel.intermediate;
                            } else {
                              _selectedSports.remove(sport.id);
                            }
                            _error = null;
                          });
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              for (final sport in sports)
                if (_selectedSports.containsKey(sport.id)) ...[
                  DropdownButtonFormField<SkillLevel>(
                    value: _selectedSports[sport.id],
                    decoration: InputDecoration(
                      labelText: 'Nivel en ${sport.name}',
                    ),
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
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar y continuar'),
              ),
            ],
          ),
        ),
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
  return 'No pudimos cargar tu perfil. Intenta nuevamente.';
}
