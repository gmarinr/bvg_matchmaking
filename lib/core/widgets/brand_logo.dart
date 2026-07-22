import 'package:flutter/material.dart';

/// Logo de la marca. Envuelto en un [Hero] con tag fijo `brand-logo` para que
/// la transición entre pantallas que lo muestran (login ↔ registro) sea fluida.
/// El mismo tag debe usarse en origen y destino.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});

  final double size;

  static const String heroTag = 'brand-logo';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Hero(
      tag: heroTag,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.secondary],
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(
          Icons.sports_soccer,
          color: scheme.onPrimary,
          size: size * 0.55,
        ),
      ),
    );
  }
}
