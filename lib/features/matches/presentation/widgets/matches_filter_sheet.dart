import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/utils/app_date.dart';
import '../../../../core/utils/labels.dart';
import '../providers/matches_list_providers.dart';
import '../../../communes/presentation/commune_selector.dart';

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
  String? _communeCode;
  SkillLevel? _skill;
  DateTime? _fromDate;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(matchFilterProvider);
    _communeCode = filter.commune;
    _skill = filter.skillLevel;
    _fromDate = filter.fromDate;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(matchFilterProvider.notifier);
    notifier.setCommune(_communeCode);
    notifier.setSkill(SkillLevelFilter(_skill));
    notifier.setFromDate(_fromDate);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _communeCode = null;
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
          Text(
            'Filtros',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          CommuneSelector(
            value: _communeCode,
            onChanged: (value) => setState(() => _communeCode = value),
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
            style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
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
