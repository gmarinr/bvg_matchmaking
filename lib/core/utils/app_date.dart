/// Formato de fechas en español sin depender de inicialización de locale.
class AppDate {
  const AppDate._();

  static const List<String> _dias = [
    'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom', //
  ];
  static const List<String> _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
  ];

  /// Ej: "vie 24 jul · 19:30".
  static String short(DateTime dt) {
    final dia = _dias[dt.weekday - 1];
    final mes = _meses[dt.month - 1];
    return '$dia ${dt.day} $mes · ${_hhmm(dt)}';
  }

  /// Ej: "viernes 24 jul, 19:30" — versión algo más larga para detalle.
  static String medium(DateTime dt) {
    final mes = _meses[dt.month - 1];
    return '${dt.day} $mes ${dt.year} · ${_hhmm(dt)}';
  }

  static String _hhmm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
