import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injecté au démarrage (voir main.dart).
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider doit être surchargé'),
);

class PrefKeys {
  static const onboardingDone = 'onboarding_done';
  static const country = 'country';
  static const trancheAge = 'tranche_age';
  static const regionId = 'region_id';
  static const locale = 'locale';
  static const profileSynced = 'profile_synced';
  static const themeMode = 'theme_mode';
  static const profilePromptDone = 'profile_prompt_done';
}
