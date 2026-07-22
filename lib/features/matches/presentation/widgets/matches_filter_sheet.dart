import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/utils/app_date.dart';
import '../../../../core/utils/labels.dart';
import '../providers/matches_list_providers.dart';

/// Hoja de filtros avanzados: comuna, nivel y fecha desde.
/// El deporte se filtra con los chips de la lista.
class MatchesFilterSheet extends ConsumerStatefulWidget {
  const MatchesFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const MatchesFilterSheet(),
      );

  @override
  ConsumerState<MatchesFilterSheet> createState() => _MatchesFilterSheetState();
}

class _MatchesFilterSheetState extends ConsumerState<MatchesFilterSheet> {
  late final TextEditingController _commune;
  SkillLevel? _skill;
  DateTime? _fromDate;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(matchFilterProvider);
    _commune = TextEditingController(text: filter.commune ?? '');
    _skill = filter.skillLevel;
    _fromDate = filter.fromDate;
  }

  @override
  void dispose() {
    _commune.dispose();
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(matchFilterProvider.notifier);
    notifier.setCommune(_commune.text.trim());
    notifier.setSkill(SkillLevelFilter(_skill));
    notifier.setFromDate(_fromDate);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _commune.clear();
      _skill = null;
      _fromDate = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Text('Comuna', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _commune,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ej: Ñuñoa',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Text('Nivel', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final level in SkillLevel.values)
                ChoiceChip(
                  label: Text(level.label),
                  selected: _skill == level,
                  onSelected: (sel) =>
                      setState(() => _skill = sel ? level : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Desde', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _fromDate == null
                  ? 'Cualquier fecha'
                  : AppDate.medium(_fromDate!),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
