import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';
import 'providers/matches_list_providers.dart';

/// Formulario para crear y publicar un partido (Flujo A).
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
    final now = DateTime.now();
    final base = _startAt ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Fecha del partido',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Hora del partido',
    );
    if (time == null || !mounted) return;

    setState(() {
      _dateTouched = true;
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
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
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
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
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Partido publicado.')));
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        // Mostramos el motivo real (p. ej. permiso RLS o error de Postgres) en
        // vez de un genérico, para poder diagnosticar fallos del backend.
        final message = e is Failure
            ? e.message
            : 'No pudimos publicar el partido.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
              _Label('Deporte'),
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
                _FieldError('Elige un deporte'),
              const SizedBox(height: 20),
              _Label('Título'),
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
              _Label('Descripción (opcional)'),
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
              _Label('Fecha y hora'),
              const SizedBox(height: 8),
              _DateTimeTile(
                value: _startAt,
                hasError: _dateTouched && _startAt == null,
                onTap: _pickDateTime,
              ),
              if (_dateTouched && _startAt == null)
                _FieldError('Elige fecha y hora'),
              const SizedBox(height: 20),
              _Label('Comuna'),
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
              _Label('Lugar'),
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
              _Label('Nivel'),
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
              _Label('Cupos'),
              const SizedBox(height: 8),
              _Counter(
                title: 'Máximo de jugadores',
                subtitle: 'Incluyéndote a ti',
                value: _maxParticipants,
                min: 2,
                max: 30,
                onChanged: _setMax,
              ),
              const SizedBox(height: 12),
              _Counter(
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
                label: Text(_loading ? 'Publicando...' : 'Publicar partido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.value,
    required this.hasError,
    required this.onTap,
  });

  final DateTime? value;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = hasError ? scheme.error : scheme.outlineVariant;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.event_outlined, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value == null
                      ? 'Selecciona fecha y hora'
                      : AppDate.medium(value!),
                  style: TextStyle(
                    color: value == null
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                    fontWeight: value == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
