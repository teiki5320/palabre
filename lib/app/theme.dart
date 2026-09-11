import 'package:flutter/material.dart';

/// Style « affiche » : fond uni, bords nets de 2 px dans la couleur d'encre,
/// ombres portées dures (décalage sans flou), une seule couleur d'action.
/// Clair « Sable & indigo », sombre « Nuit lagune ». La couleur encode (bloc
/// ministériel, groupe, parti) ; ici elle structure, elle ne juge pas.
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
    required this.track,
    required this.border,
    required this.hardShadow,
    required this.disabled,
    required this.quiz,
    required this.onQuiz,
    required this.government,
    required this.onGovernment,
    required this.assembly,
    required this.onAssembly,
  });

  /// Couleur de section de l'onglet Question, wordmark, éléments choisis.
  final Color primary;
  final Color onPrimary;

  /// Pastilles douces.
  final Color primarySoft;

  /// La seule couleur d'action : Voter, Partager, Important.
  final Color accent;
  final Color onAccent;

  /// Fond de tous les écrans, y compris l'en-tête.
  final Color background;

  /// Cartes et barre de navigation.
  final Color card;

  /// Texte principal, bords, ombres dures en clair.
  final Color ink;

  /// Texte secondaire.
  final Color muted;

  /// Séparateurs fins internes.
  final Color line;

  /// Piste des barres de pourcentage.
  final Color track;

  /// Bords de 2 px.
  final Color border;

  /// Couleur de l'ombre dure par défaut (clair : encre).
  final Color hardShadow;

  /// Bord et texte désactivés (« Sans avis », « non calculable »).
  final Color disabled;

  /// Couleurs de section des autres onglets.
  final Color quiz, onQuiz, government, onGovernment, assembly, onAssembly;

  /// Ombre dure : décalage sans flou.
  static BoxShadow hard(Color c, [double d = 4]) => BoxShadow(offset: Offset(d, d), blurRadius: 0, color: c);

  BoxShadow get cardShadow => hard(hardShadow);

  static const light = PalabreTokens(
    primary: Color(0xFF33357F),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE4E4F5),
    accent: Color(0xFFFF7A1A),
    onAccent: Color(0xFF2B1200),
    background: Color(0xFFF5EFE4),
    card: Color(0xFFFFFDF8),
    ink: Color(0xFF1E1B3A),
    muted: Color(0xFF6E6A80),
    line: Color(0xFFDCD5C4),
    track: Color(0xFFE6DFCF),
    border: Color(0xFF1E1B3A),
    hardShadow: Color(0xFF1E1B3A),
    disabled: Color(0xFFC9C2B2),
    quiz: Color(0xFF33357F),
    onQuiz: Color(0xFFFFFFFF),
    government: Color(0xFF33357F),
    onGovernment: Color(0xFFFFFFFF),
    assembly: Color(0xFF33357F),
    onAssembly: Color(0xFFFFFFFF),
  );

  static const dark = PalabreTokens(
    primary: Color(0xFF3ED0CB),
    onPrimary: Color(0xFF0C1E22),
    primarySoft: Color(0xFF1C3F3D),
    accent: Color(0xFFFF7A1A),
    onAccent: Color(0xFF2B1200),
    background: Color(0xFF0C1E22),
    card: Color(0xFF14313A),
    ink: Color(0xFFEAF6F4),
    muted: Color(0xFF9DBBB8),
    line: Color(0xFF2D4F50),
    track: Color(0xFF24484C),
    border: Color(0xFFEAF6F4),
    hardShadow: Color(0xFF3ED0CB),
    disabled: Color(0xFF3A5C60),
    quiz: Color(0xFFC08BF0),
    onQuiz: Color(0xFF1E0A33),
    government: Color(0xFF8FB4C8),
    onGovernment: Color(0xFF0E1B22),
    assembly: Color(0xFF7FB3E6),
    onAssembly: Color(0xFF071A2B),
  );

  bool get isDark => background.computeLuminance() < 0.2;

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
    Color? track,
    Color? border,
    Color? hardShadow,
    Color? disabled,
    Color? quiz,
    Color? onQuiz,
    Color? government,
    Color? onGovernment,
    Color? assembly,
    Color? onAssembly,
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
        track: track ?? this.track,
        border: border ?? this.border,
        hardShadow: hardShadow ?? this.hardShadow,
        disabled: disabled ?? this.disabled,
        quiz: quiz ?? this.quiz,
        onQuiz: onQuiz ?? this.onQuiz,
        government: government ?? this.government,
        onGovernment: onGovernment ?? this.onGovernment,
        assembly: assembly ?? this.assembly,
        onAssembly: onAssembly ?? this.onAssembly,
      );

  @override
  PalabreTokens lerp(ThemeExtension<PalabreTokens>? other, double t) {
    if (other is! PalabreTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PalabreTokens(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      background: l(background, other.background),
      card: l(card, other.card),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      track: l(track, other.track),
      border: l(border, other.border),
      hardShadow: l(hardShadow, other.hardShadow),
      disabled: l(disabled, other.disabled),
      quiz: l(quiz, other.quiz),
      onQuiz: l(onQuiz, other.onQuiz),
      government: l(government, other.government),
      onGovernment: l(onGovernment, other.onGovernment),
      assembly: l(assembly, other.assembly),
      onAssembly: l(onAssembly, other.onAssembly),
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

  /// Question de la semaine, titres d'écran.
  static TextStyle poster(Color c, {bool long = false}) =>
      TextStyle(fontFamily: display, fontSize: long ? 28 : 34, fontWeight: FontWeight.w800, height: long ? 1.15 : 1.1, letterSpacing: long ? -0.8 : -1, color: c);
  static TextStyle title(Color c) => TextStyle(fontFamily: display, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.6, color: c);
  static TextStyle question(Color c) => TextStyle(fontFamily: display, fontSize: 27, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.6, color: c);
  static TextStyle cardTitle(Color c) => TextStyle(fontFamily: display, fontSize: 16, fontWeight: FontWeight.w700, height: 1.25, color: c);
  static TextStyle big(Color c) => TextStyle(fontFamily: display, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, color: c, fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle wordmark(Color c) => TextStyle(fontFamily: display, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: c);
  static TextStyle eyebrow(Color c) => TextStyle(fontFamily: body, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: c);
  static TextStyle label(Color c) => TextStyle(fontFamily: body, fontSize: 16, fontWeight: FontWeight.w800, color: c);
  static TextStyle note(Color c) => TextStyle(fontFamily: body, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: c);
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
      secondary: t.accent,
      onSecondary: t.onAccent,
      secondaryContainer: t.primarySoft,
      onSecondaryContainer: t.primary,
      tertiary: t.accent,
      onTertiary: t.onAccent,
      error: isDark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
      onError: isDark ? const Color(0xFF601410) : Colors.white,
      surface: t.card,
      onSurface: t.ink,
      onSurfaceVariant: t.muted,
      outline: t.border,
      outlineVariant: t.line,
      surfaceContainerHighest: t.background,
      surfaceContainerHigh: t.background,
      surfaceContainer: t.card,
      surfaceContainerLow: t.card,
      surfaceContainerLowest: t.card,
      inverseSurface: t.ink,
      onInverseSurface: t.card,
      shadow: t.hardShadow,
      scrim: Colors.black,
    );
    final border = BorderSide(color: t.border, width: 2);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b, fontFamily: PalabreType.body);
    final text = base.textTheme.apply(bodyColor: t.ink, displayColor: t.ink).copyWith(
          headlineSmall: PalabreType.title(t.ink),
          titleLarge: PalabreType.cardTitle(t.ink).copyWith(fontSize: 18),
          titleMedium: TextStyle(fontFamily: PalabreType.body, fontSize: 15, fontWeight: FontWeight.w700, color: t.ink),
          bodyLarge: TextStyle(fontFamily: PalabreType.body, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4, color: t.ink),
          bodyMedium: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: t.ink),
          bodySmall: TextStyle(fontFamily: PalabreType.body, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, color: t.muted),
          labelLarge: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w800, color: t.ink),
        );
    return base.copyWith(
      textTheme: text,
      extensions: [t],
      scaffoldBackgroundColor: t.background,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: t.border,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.primary,
        centerTitle: false,
        titleTextStyle: PalabreType.title(t.ink).copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: border),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1.5, space: 1.5),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? t.primary : t.muted, size: 24),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: PalabreType.body,
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w700,
            color: s.contains(WidgetState.selected) ? t.primary : t.muted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        side: BorderSide(color: t.border, width: 1.5),
        backgroundColor: Colors.transparent,
        selectedColor: t.primary,
        labelStyle: PalabreType.eyebrow(t.ink),
        secondaryLabelStyle: PalabreType.eyebrow(t.onPrimary),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: t.background,
          disabledForegroundColor: t.disabled,
          side: border,
          textStyle: TextStyle(fontFamily: PalabreType.display, fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size.fromHeight(56),
        ).copyWith(side: WidgetStateProperty.resolveWith((s) => BorderSide(color: s.contains(WidgetState.disabled) ? t.disabled : t.border, width: 2))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          backgroundColor: t.card,
          side: border,
          textStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size.fromHeight(54),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primary,
          textStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: border),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: border),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: t.primary, width: 2)),
        labelStyle: TextStyle(color: t.muted, fontWeight: FontWeight.w700),
        hintStyle: TextStyle(color: t.muted, fontWeight: FontWeight.w500),
      ),
      listTileTheme: ListTileThemeData(contentPadding: const EdgeInsets.symmetric(horizontal: 16), iconColor: t.muted, textColor: t.ink),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.onAccent : t.card),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accent : t.track),
        trackOutlineColor: WidgetStatePropertyAll(t.border),
        trackOutlineWidth: const WidgetStatePropertyAll(2),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.primary : t.border)),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), side: border),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: border),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: border),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.ink,
        contentTextStyle: TextStyle(fontFamily: PalabreType.body, color: t.card, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      sliderTheme: const SliderThemeData(trackHeight: 6),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.primary, linearTrackColor: t.track),
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
/// décorent pas ; identiques en clair et en sombre.
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
