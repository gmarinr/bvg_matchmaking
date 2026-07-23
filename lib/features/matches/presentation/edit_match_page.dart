import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';
import 'providers/match_detail_providers.dart';
import 'providers/matches_list_providers.dart';
import 'providers/my_matches_providers.dart';
import 'widgets/match_form_fields.dart';

/// Edición de un partido publicado (Flujo C). Ofrece los mismos campos que la
/// creación; solo el organizador puede abrirla.
class EditMatchPage extends ConsumerWidget {
  const EditMatchPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar partido')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar el partido',
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(matchDetailProvider(matchId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
        data: (match) {
          if (match == null) {
            return const _Message(
              icon: Icons.search_off,
              title: 'Este partido ya no está disponible',
            );
          }
          if (user == null || match.organizerId != user.id) {
            return const _Message(
              icon: Icons.lock_outline,
              title: 'Solo el organizador puede editar este partido',
            );
          }
          if (match.status == MatchStatus.completed ||
              match.status == MatchStatus.cancelled) {
            return _Message(
              icon: Icons.lock_clock,
              title: match.status == MatchStatus.completed
                  ? 'Un partido finalizado ya no se puede editar'
                  : 'Un partido cancelado ya no se puede editar',
            );
          }
          return _EditForm(match: match);
        },
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.match});

  final Match match;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _commune;
  late final TextEditingController _location;

  late SkillLevel _skill;
  late DateTime _startAt;
  late int _maxParticipants;
  late int _minParticipants;

  bool _loading = false;

  Match get _match => widget.match;

  /// Los cupos ya ocupados marcan el piso: no se puede reducir el máximo por
  /// debajo de la gente que ya está aceptada.
  int get _maxFloor =>
      _match.acceptedCount < 2 ? 2 : _match.acceptedCount;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _match.title);
    _description = TextEditingController(text: _match.description ?? '');
    _commune = TextEditingController(text: _match.commune);
    _location = TextEditingController(text: _match.locationText);
    _skill = _match.skillLevel;
    _startAt = _match.startAt;
    _maxParticipants = _match.maxParticipants;
    _minParticipants = _match.minParticipants;
  }

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
    setState(() => _startAt = picked);
  }

  void _setMax(int value) {
    setState(() {
      _maxParticipants = value;
      if (_minParticipants > _maxParticipants) {
        _minParticipants = _maxParticipants;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final updated = _match.copyWith(
      title: _title.text.trim(),
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      startAt: _startAt,
      commune: _commune.text.trim(),
      locationText: _location.text.trim(),
      skillLevel: _skill,
      minParticipants: _minParticipants,
      maxParticipants: _maxParticipants,
      // Si el nuevo máximo vuelve a dejar cupos libres, el partido reabre.
      status: _match.status == MatchStatus.full &&
              _match.acceptedCount < _maxParticipants
          ? MatchStatus.open
          : _match.status,
    );

    try {
      await ref.read(matchRepositoryProvider).updateMatch(updated);
      ref.invalidate(matchDetailProvider(_match.id));
      ref.invalidate(matchesListProvider);
      ref.invalidate(myMatchesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partido actualizado.')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos guardar los cambios.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportName =
        ref.watch(sportsByIdProvider)[_match.sportId]?.name ?? 'Deporte';

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const FieldLabel('Deporte'),
            const SizedBox(height: 8),
            _ReadOnlyTile(
              icon: Icons.sports_soccer_outlined,
              value: sportName,
              hint: 'El deporte no se cambia una vez publicado el partido.',
            ),
            const SizedBox(height: 20),

            const FieldLabel('Título'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
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
              hasError: false,
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 20),

            const FieldLabel('Comuna'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commune,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
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
              subtitle: _match.acceptedCount > 0
                  ? 'Ya hay ${_match.acceptedCount} aceptados'
                  : 'Incluyéndote a ti',
              value: _maxParticipants,
              min: _maxFloor,
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
            const SizedBox(height: 12),
            Text(
              'Los participantes ya aceptados mantienen su cupo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_loading ? 'Guardando…' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({
    required this.icon,
    required this.value,
    required this.hint,
  });

  final IconData icon;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

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
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
