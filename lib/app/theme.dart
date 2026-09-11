import 'package:flutter/material.dart';

/// Sombre par défaut, surfaces plates, pas d'ombres ni de dégradés, hairlines
/// fines. La couleur encode (bloc ministériel, groupe parlementaire), elle ne
/// décore jamais.
class PalabreTheme {
  static const seed = Color(0xFF9DB4C0);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF111416),
    );
    final hairline = BorderSide(color: scheme.outlineVariant, width: 0.5);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: hairline),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 0.5, space: 0.5),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        side: hairline,
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: hairline,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: hairline),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: hairline),
        isDense: true,
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: hairline),
      ),
      snackBarTheme: const SnackBarThemeData(elevation: 0, behavior: SnackBarBehavior.floating),
      sliderTheme: const SliderThemeData(trackHeight: 2),
    );
  }
}

/// Couleurs d'encodage des blocs ministériels.
class BlocColors {
  static const regalien = Color(0xFF8C9EFF);
  static const economie = Color(0xFFF2B33D);
  static const social = Color(0xFF4FC3A1);
  static const infrastructure = Color(0xFFE0705A);
  static const autre = Color(0xFF9E9E9E);

  static Color of(String? bloc) => switch (bloc) {
        'regalien' => regalien,
        'economie' => economie,
        'social' => social,
        'infrastructure' => infrastructure,
        _ => autre,
      };
}

Color? parseHexColor(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}
