import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';
import 'providers/matches_list_providers.dart';
import 'providers/my_matches_providers.dart';
import 'widgets/match_form_fields.dart';

/// Formulario para crear y publicar un partido (Flujo A).
/// Los campos coinciden con los que muestra el detalle del partido.
class CreateMatchPage extends ConsumerStatefulWidget {
  const CreateMatchPage({super.key});

  @override
  ConsumerState<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends ConsumerState<CreateMatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _commune = TextEditingController();
  final _location = TextEditingController();

  String? _sportId;
  SkillLevel _skill = SkillLevel.intermediate;
  DateTime? _startAt;
  int _maxParticipants = 10;
  int _minParticipants = 4;

  bool _loading = false;
  bool _dateTouched = false;
  bool _sportTouched = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _commune.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final picked = await DateTimeTile.pick(context, current: _startAt);
    if (picked == null || !mounted) return;
    setState(() {
      _dateTouched = true;
      _startAt = picked;
    });
  }

  void _setMax(int value) {
    setState(() {
      _maxParticipants = value;
      if (_minParticipants > _maxParticipants) {
        _minParticipants = _maxParticipants;
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _sportTouched = true;
      _dateTouched = true;
    });
    final formOk = _formKey.currentState!.validate();
    if (_sportId == null || _startAt == null || !formOk) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    final now = DateTime.now();
    final match = Match(
      id: '',
      organizerId: user.id,
      sportId: _sportId!,
      title: _title.text.trim(),
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      startAt: _startAt!,
      commune: _commune.text.trim(),
      locationText: _location.text.trim(),
      skillLevel: _skill,
      minParticipants: _minParticipants,
      maxParticipants: _maxParticipants,
      status: MatchStatus.open,
      recruitmentMode: RecruitmentMode.players,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(matchRepositoryProvider).createMatch(match);
      ref.invalidate(matchesListProvider);
      ref.invalidate(myMatchesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Partido publicado!')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos publicar el partido.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportsAsync = ref.watch(sportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear partido')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const FieldLabel('Deporte'),
              const SizedBox(height: 8),
              sportsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(
                  'No se pudo cargar el catálogo de deportes.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                data: (sports) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sport in sports)
                      ChoiceChip(
                        label: Text(sport.name),
                        selected: _sportId == sport.id,
                        onSelected: (_) => setState(() {
                          _sportId = sport.id;
                          _sportTouched = true;
                        }),
                      ),
                  ],
                ),
              ),
              if (_sportTouched && _sportId == null)
                const FieldError('Elige un deporte'),
              const SizedBox(height: 20),

              const FieldLabel('Título'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ej: Fútbol 7 después del trabajo',
                ),
                maxLength: 80,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ponle un título' : null,
              ),
              const SizedBox(height: 8),

              const FieldLabel('Descripción (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Detalles útiles: cancha, qué llevar, etc.',
                ),
              ),
              const SizedBox(height: 20),

              const FieldLabel('Fecha y hora'),
              const SizedBox(height: 8),
              DateTimeTile(
                value: _startAt,
                hasError: _dateTouched && _startAt == null,
                onTap: _pickDateTime,
              ),
              if (_dateTouched && _startAt == null)
                const FieldError('Elige fecha y hora'),
              const SizedBox(height: 20),

              const FieldLabel('Comuna'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commune,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ej: Ñuñoa',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Indica la comuna' : null,
              ),
              const SizedBox(height: 16),

              const FieldLabel('Lugar'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ej: Cancha Parque Padre Hurtado',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Indica el lugar' : null,
              ),
              const SizedBox(height: 20),

              const FieldLabel('Nivel'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final level in SkillLevel.values)
                    ChoiceChip(
                      label: Text(level.label),
                      selected: _skill == level,
                      onSelected: (_) => setState(() => _skill = level),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              const FieldLabel('Cupos'),
              const SizedBox(height: 8),
              CounterField(
                title: 'Máximo de jugadores',
                subtitle: 'Incluyéndote a ti',
                value: _maxParticipants,
                min: 2,
                max: 30,
                onChanged: _setMax,
              ),
              const SizedBox(height: 12),
              CounterField(
                title: 'Mínimo para confirmar',
                subtitle: 'Cuántos necesitas para jugar',
                value: _minParticipants,
                min: 2,
                max: _maxParticipants,
                onChanged: (v) => setState(() => _minParticipants = v),
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check),
                label: Text(_loading ? 'Publicando…' : 'Publicar partido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
