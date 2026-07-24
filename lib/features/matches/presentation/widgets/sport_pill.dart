import 'package:flutter/material.dart';

import '../../../../core/utils/sport_emojis.dart';

/// Etiqueta del deporte de un partido.
///
/// Va envuelta en un [Hero] cuyo tag depende del id del partido, de modo que
/// la tarjeta de la lista (origen) y el detalle (destino) compartan el mismo
/// tag y la transición entre ambas vistas sea continua.
class SportPill extends StatelessWidget {
  const SportPill({
    super.key,
    required this.matchId,
    required this.sportId,
    required this.sportName,
  });

  final String matchId;
  final String sportId;
  final String sportName;

  static String heroTag(String matchId) => 'match-sport-$matchId';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Hero(
      tag: heroTag(matchId),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sportEmoji(sportId), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  sportName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
