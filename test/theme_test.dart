import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/app/theme.dart';
import 'package:palabre/core/prefs/prefs_provider.dart';
import 'package:palabre/core/prefs/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('les deux thèmes exposent les jetons Lagune', () {
    final light = PalabreTheme.light().extension<PalabreTokens>()!;
    final dark = PalabreTheme.dark().extension<PalabreTokens>()!;
    expect(light.primary, const Color(0xFF33357F));
    expect(light.accent, const Color(0xFFFF7A1A));
    expect(light.background, const Color(0xFFF5EFE4));
    expect(light.border, light.ink);
    expect(light.cardShadow.blurRadius, 0);
    expect(dark.primary, const Color(0xFF3ED0CB));
    expect(dark.card, const Color(0xFF14313A));
    expect(dark.quiz, const Color(0xFFC08BF0));
    expect(PalabreTheme.light().colorScheme.primary, light.primary);
    expect(PalabreTheme.light().scaffoldBackgroundColor, light.background);
    expect(PalabreTheme.light().textTheme.bodyMedium!.fontFamily, PalabreType.body);
    expect(PalabreTheme.dark().colorScheme.brightness, Brightness.dark);
  });

  test("le mode d'apparence est lu et écrit dans les préférences", () async {
    SharedPreferences.setMockInitialValues({PrefKeys.themeMode: 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await container.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString(PrefKeys.themeMode), 'light');
    await container.read(themeModeProvider.notifier).set(ThemeMode.system);
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(prefs.getString(PrefKeys.themeMode), isNull);
  });
}
