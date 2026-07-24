import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/commune_providers.dart';
import '../domain/commune.dart';

class CommuneSelector extends ConsumerWidget {
  const CommuneSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communes = ref.watch(communesProvider);
    return communes.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(labelText: 'Comuna'),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const InputDecorator(
        decoration: InputDecoration(labelText: 'Comuna'),
        child: Text('No se pudo cargar el catálogo de comunas.'),
      ),
      data: (items) {
        final selected = items.where((item) => item.code == value).firstOrNull;
        return Autocomplete<Commune>(
          initialValue: TextEditingValue(text: selected?.name ?? ''),
          displayStringForOption: (commune) => commune.name,
          optionsBuilder: (text) {
            final query = _normalize(text.text);
            if (query.isEmpty) return items;
            return items.where(
              (commune) => _normalize(commune.name).contains(query),
            );
          },
          onSelected: (commune) => onChanged(commune.code),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              key: const ValueKey('commune-selector-input'),
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Comuna',
                hintText: 'Escribe para buscar',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: (text) {
                if (text != selected?.name) onChanged(null);
              },
              validator: (_) => value == null ? 'Indica la comuna' : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final commune = options.elementAt(index);
                    return ListTile(
                      title: Text(commune.name),
                      subtitle: Text('${commune.province} · ${commune.region}'),
                      onTap: () => onSelected(commune),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u')
    .replaceAll('ñ', 'n');
