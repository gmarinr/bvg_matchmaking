import 'package:flutter/material.dart';

/// Identidad visual de Match Making: paleta "cancha".
///
/// Verde pasto como color base, acompañado de blanco levemente azulado y un
/// acento ámbar de alto contraste (par complementario verde/ámbar) para los
/// llamados a la acción. Soporta claro y oscuro.
///
/// Tipografía prevista: Barlow Condensed (títulos) / Barlow (cuerpo). Se
/// incorpora vía `google_fonts` cuando se apruebe la dependencia; por ahora
/// se usa la tipografía por defecto de Material para no anticipar paquetes.
class AppTheme {
  const AppTheme._();

  // --- Verdes de pasto ---
  static const Color _grass = Color(0xFF15803D); // green 700 (primario)
  static const Color _grassLight = Color(0xFF22C55E); // green 500 (secundario)
  static const Color _grassBright = Color(0xFF4ADE80); // green 400 (dark mode)
  static const Color _grassDeep = Color(0xFF052E16); // green 950 (texto/on)

  // --- Acento ámbar de alto contraste ---
  static const Color _amber = Color(0xFFF59E0B); // amber 500
  static const Color _amberSoft = Color(0xFFFBBF24); // amber 400 (dark mode)
  static const Color _amberInk = Color(0xFF422006); // texto sobre ámbar

  // --- Neutros ---
  static const Color _error = Color(0xFFDC2626);
  static const Color _bluishWhite = Color(0xFFF4F8FB); // fondo claro azulado
  static const Color _ink = Color(0xFF0F172A); // texto sobre claro
  static const Color _darkSurface = Color(0xFF0B141B); // superficie oscura

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: _grass,
      brightness: brightness,
    );

    final ColorScheme scheme = isLight
        ? base.copyWith(
            primary: _grass,
            onPrimary: Colors.white,
            secondary: _grassLight,
            onSecondary: _grassDeep,
            tertiary: _amber,
            onTertiary: _amberInk,
            error: _error,
            onError: Colors.white,
            surface: Colors.white,
            onSurface: _ink,
          )
        : base.copyWith(
            primary: _grassBright,
            onPrimary: _grassDeep,
            secondary: _grassLight,
            onSecondary: _grassDeep,
            tertiary: _amberSoft,
            onTertiary: _amberInk,
            error: _error,
            onError: Colors.white,
            surface: _darkSurface,
          );

    final Color scaffoldBg = isLight ? _bluishWhite : const Color(0xFF060D12);
    const double radius = 14;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
