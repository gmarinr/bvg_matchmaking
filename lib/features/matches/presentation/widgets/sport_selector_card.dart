import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/domain/sport.dart';
import '../../../../core/utils/sport_emojis.dart';

/// Tarjeta visual para explorar el catálogo de deportes.
class SportSelectorCard extends StatelessWidget {
  const SportSelectorCard({
    super.key,
    required this.sport,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  final Sport sport;
  final bool selected;
  final VoidCallback onTap;

  /// Si es `true`, la tarjeta llena el espacio disponible (para una cuadrícula).
  /// Si es `false`, usa el ancho fijo pensado para el carrusel horizontal.
  final bool expand;

  static String heroTag(String sportId) => 'sport-$sportId';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = selected
        ? '${sport.name}. Seleccionado.'
        : 'Filtrar partidos por ${sport.name}';

    return Hero(
      tag: heroTag(sport.id),
      child: FocusableActionDetector(
        shortcuts: <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: SizedBox(
            width: expand ? null : 104,
            child: Card(
              margin: expand ? EdgeInsets.zero : const EdgeInsets.only(right: 10),
              clipBehavior: Clip.antiAlias,
              color: selected ? scheme.primaryContainer : null,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sportEmoji(sport.id),
                        style: const TextStyle(fontSize: 34),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        sport.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado que recibe la transición Hero desde [SportSelectorCard].
class SportHeroHeader extends StatelessWidget {
  const SportHeroHeader({super.key, required this.sport});

  final Sport sport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Hero(
      tag: SportSelectorCard.heroTag(sport.id),
      child: Material(
        color: Colors.transparent,
        child: Card(
          margin: EdgeInsets.zero,
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Text(sportEmoji(sport.id), style: const TextStyle(fontSize: 42)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    sport.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
