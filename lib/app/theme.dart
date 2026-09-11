import 'package:flutter/material.dart';

/// Palette « Lagune » : un bandeau de couleur forte, des cartes claires qui
/// flottent dessus. Clair par défaut, sombre équivalent. La palette n'est pas
/// dérivée du logo et évite le vert, le jaune et le rouge partisans.
/// La couleur encode (bloc ministériel, groupe parlementaire, parti) ; ici
/// elle structure, elle ne juge pas.
class PalabreTokens extends ThemeExtension<PalabreTokens> {
  const PalabreTokens({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.cardShadow,
  });

  /// Bandeau, onglet actif, liens, bouton principal.
  final Color primary;

  /// Texte sur le bandeau.
  final Color onPrimary;

  /// Fond des pastilles, indicateur d'onglet.
  final Color primarySoft;

  /// Interrupteur « important », mise en avant ponctuelle.
  final Color accent;
  final Color onAccent;

  /// Fond des écrans.
  final Color background;

  /// Cartes.
  final Color card;

  /// Texte principal.
  final Color ink;

  /// Texte secondaire, notes.
  final Color muted;

  /// Séparateurs, bordures de champs.
  final Color line;
  final BoxShadow cardShadow;

  static const light = PalabreTokens(
    primary: Color(0xFF0F7F7C),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFDDF0EE),
    accent: Color(0xFFFF7A1A),
    onAccent: Color(0xFF2B1200),
    background: Color(0xFFEFF6F5),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF0F2B2A),
    muted: Color(0xFF5B7674),
    line: Color(0xFFD8E6E4),
    cardShadow: BoxShadow(offset: Offset(0, 10), blurRadius: 24, color: Color(0x1A0F3C3A)),
  );

  static const dark = PalabreTokens(
    primary: Color(0xFF3ED0CB),
    onPrimary: Color(0xFF05201F),
    primarySoft: Color(0xFF1C3F3D),
    accent: Color(0xFFFF7A1A),
    onAccent: Color(0xFF2B1200),
    background: Color(0xFF0E1D1C),
    card: Color(0xFF173130),
    ink: Color(0xFFEAF6F4),
    muted: Color(0xFF94B3B0),
    line: Color(0xFF264543),
    cardShadow: BoxShadow(offset: Offset(0, 10), blurRadius: 24, color: Color(0x59000000)),
  );

  @override
  PalabreTokens copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? accent,
    Color? onAccent,
    Color? background,
    Color? card,
    Color? ink,
    Color? muted,
    Color? line,
    BoxShadow? cardShadow,
  }) =>
      PalabreTokens(
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        primarySoft: primarySoft ?? this.primarySoft,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        background: background ?? this.background,
        card: card ?? this.card,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        line: line ?? this.line,
        cardShadow: cardShadow ?? this.cardShadow,
      );

  @override
  PalabreTokens lerp(ThemeExtension<PalabreTokens>? other, double t) {
    if (other is! PalabreTokens) return this;
    return PalabreTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      cardShadow: BoxShadow.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

extension PalabreTokensContext on BuildContext {
  PalabreTokens get tokens => Theme.of(this).extension<PalabreTokens>() ?? PalabreTokens.light;
}

/// Deux familles embarquées : Sora pour ce qui se lit de loin (titres,
/// questions, gros chiffres), Manrope pour tout le reste.
class PalabreType {
  static const display = 'Sora';
  static const body = 'Manrope';

  static TextStyle title(Color c) => TextStyle(fontFamily: display, fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.2, color: c);
  static TextStyle question(Color c) => TextStyle(fontFamily: display, fontSize: 19, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.2, color: c);
  static TextStyle cardTitle(Color c) => TextStyle(fontFamily: display, fontSize: 15, fontWeight: FontWeight.w700, height: 1.25, color: c);
  static TextStyle big(Color c) => TextStyle(fontFamily: display, fontSize: 22, fontWeight: FontWeight.w800, color: c, fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle wordmark(Color c) => TextStyle(fontFamily: display, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: c);
  static TextStyle eyebrow(Color c) => TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: c);
  static TextStyle note(Color c) => TextStyle(fontSize: 12, height: 1.4, color: c);
  static TextStyle label(Color c) => TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c);
}

class PalabreTheme {
  static ThemeData light() => _build(PalabreTokens.light, Brightness.light);
  static ThemeData dark() => _build(PalabreTokens.dark, Brightness.dark);

  static ThemeData _build(PalabreTokens t, Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: t.primary,
      onPrimary: t.onPrimary,
      primaryContainer: t.primarySoft,
      onPrimaryContainer: t.primary,
      secondary: t.primary,
      onSecondary: t.onPrimary,
      secondaryContainer: t.primarySoft,
      onSecondaryContainer: t.primary,
      tertiary: t.accent,
      onTertiary: t.onAccent,
      error: isDark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
      onError: isDark ? const Color(0xFF601410) : Colors.white,
      surface: t.card,
      onSurface: t.ink,
      onSurfaceVariant: t.muted,
      outline: t.muted,
      outlineVariant: t.line,
      surfaceContainerHighest: t.background,
      surfaceContainerHigh: t.background,
      surfaceContainer: t.card,
      surfaceContainerLow: t.card,
      surfaceContainerLowest: t.card,
      inverseSurface: t.ink,
      onInverseSurface: t.card,
      shadow: Colors.black,
      scrim: Colors.black,
    );
    final line = BorderSide(color: t.line, width: 1);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b, fontFamily: PalabreType.body);
    final text = base.textTheme.apply(bodyColor: t.ink, displayColor: t.ink).copyWith(
          headlineSmall: PalabreType.title(t.ink),
          titleLarge: PalabreType.cardTitle(t.ink).copyWith(fontSize: 17),
          titleMedium: TextStyle(fontFamily: PalabreType.body, fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
          bodyLarge: TextStyle(fontFamily: PalabreType.body, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4, color: t.ink),
          bodyMedium: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: t.ink),
          bodySmall: TextStyle(fontFamily: PalabreType.body, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, color: t.muted),
          labelLarge: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w700, color: t.ink),
        );
    return base.copyWith(
      textTheme: text,
      extensions: [t],
      scaffoldBackgroundColor: t.background,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: t.line,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        centerTitle: false,
        titleTextStyle: PalabreType.title(t.ink).copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.primarySoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? t.primary : t.muted, size: 24),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: PalabreType.body,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: s.contains(WidgetState.selected) ? t.primary : t.muted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        side: BorderSide.none,
        backgroundColor: t.primarySoft,
        selectedColor: t.primary,
        labelStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 12.5, fontWeight: FontWeight.w700, color: t.primary),
        secondaryLabelStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 12.5, fontWeight: FontWeight.w700, color: t.onPrimary),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: t.primary,
          foregroundColor: t.onPrimary,
          disabledBackgroundColor: t.line,
          disabledForegroundColor: t.muted,
          textStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          side: line,
          textStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primary,
          textStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: line),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: line),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.primary, width: 1.5)),
        labelStyle: TextStyle(color: t.muted, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: t.muted),
      ),
      listTileTheme: ListTileThemeData(contentPadding: const EdgeInsets.symmetric(horizontal: 16), iconColor: t.muted, textColor: t.ink),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : t.card),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accent : t.line),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.primary : t.muted)),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.ink,
        contentTextStyle: TextStyle(fontFamily: PalabreType.body, color: t.card, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      sliderTheme: const SliderThemeData(trackHeight: 4),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.primary, linearTrackColor: t.line),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: t.primary,
        collapsedIconColor: t.muted,
        textColor: t.ink,
        collapsedTextColor: t.ink,
      ),
    );
  }
}

/// Couleurs d'encodage des blocs ministériels. Elles encodent, elles ne
/// décorent pas ; identiques en clair et en sombre, vérifiées lisibles sur les
/// deux fonds.
class BlocColors {
  static const regalien = Color(0xFF5C6BC0);
  static const economie = Color(0xFFD99A2B);
  static const social = Color(0xFF2E9E8F);
  static const infrastructure = Color(0xFFD9654F);
  static const autre = Color(0xFF8A9396);

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
