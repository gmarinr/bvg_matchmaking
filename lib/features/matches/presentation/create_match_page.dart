import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/failures.dart';
import '../../auth/data/auth_providers.dart';
import '../../profile/data/profile_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';

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
  final _minParticipants = TextEditingController(text: '2');
  final _maxParticipants = TextEditingController(text: '10');

  DateTime _startAt = DateTime.now().add(const Duration(days: 1));
  SkillLevel _skillLevel = SkillLevel.beginner;
  String? _sportId;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _commune.dispose();
    _location.dispose();
    _minParticipants.dispose();
    _maxParticipants.dispose();
    super.dispose();
  }

  Future<void> _pickStartAt() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _startAt,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (time == null) return;

    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentAppUserProvider);
    final min = int.tryParse(_minParticipants.text.trim());
    final max = int.tryParse(_maxParticipants.text.trim());
    if (user == null || _sportId == null || min == null || max == null) return;
    if (max < min) {
      _showError('La capacidad máxima debe ser mayor o igual al mínimo.');
      return;
    }

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
      startAt: _startAt,
      commune: _commune.text.trim(),
      locationText: _location.text.trim(),
      skillLevel: _skillLevel,
      minParticipants: min,
      maxParticipants: max,
      status: MatchStatus.open,
      recruitmentMode: RecruitmentMode.players,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(matchRepositoryProvider).createMatch(match);
      ref.invalidate(matchesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final sports = ref.watch(sportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear partido')),
      body: sports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(_errorMessage(error))),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No hay deportes disponibles.'));
          }
          _sportId ??= items.first.id;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: _required('Ingresa un título'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sportId,
                  decoration: const InputDecoration(labelText: 'Deporte'),
                  items: [
                    for (final sport in items)
                      DropdownMenuItem(
                        value: sport.id,
                        child: Text(sport.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _sportId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SkillLevel>(
                  initialValue: _skillLevel,
                  decoration: const InputDecoration(labelText: 'Nivel'),
                  items: [
                    for (final level in SkillLevel.values)
                      DropdownMenuItem(value: level, child: Text(level.wire)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _skillLevel = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commune,
                  decoration: const InputDecoration(labelText: 'Comuna'),
                  validator: _required('Ingresa una comuna'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Lugar'),
                  validator: _required('Ingresa un lugar'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha y hora'),
                  subtitle: Text(
                    _startAt.toLocal().toString().substring(0, 16),
                  ),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: _pickStartAt,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minParticipants,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mínimo'),
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxParticipants,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Máximo'),
                        validator: _positiveNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publicar partido'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? Function(String?) _required(String message) => (value) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  };

  String? _positiveNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 1 ? 'Ingresa un número válido' : null;
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos completar la operación.';
}
