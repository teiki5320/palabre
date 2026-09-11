import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

/// Apparence : système par défaut, clair ou sombre au choix. Rien n'est
/// demandé à l'onboarding, le réglage vit dans Paramètres.
class ThemeModeSetting extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (ref.watch(sharedPrefsProvider).getString(PrefKeys.themeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(ThemeMode mode) async {
    final prefs = ref.read(sharedPrefsProvider);
    if (mode == ThemeMode.system) {
      await prefs.remove(PrefKeys.themeMode);
    } else {
      await prefs.setString(PrefKeys.themeMode, mode.name);
    }
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(ThemeModeSetting.new);
