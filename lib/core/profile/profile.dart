import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../country/country_providers.dart';
import '../prefs/prefs_provider.dart';
import '../supabase/supabase_providers.dart';

/// Profil minimal : pays (obligatoire), tranche d'âge et région (facultatifs).
/// Ces trois champs ne servent qu'aux découpes du sondage.
@immutable
class Profile {
  const Profile({required this.countryCode, this.trancheAge, this.regionId});

  final String countryCode;
  final String? trancheAge;
  final int? regionId;

  Profile copyWith({String? countryCode, String? trancheAge, int? regionId, bool clearAge = false, bool clearRegion = false}) =>
      Profile(
        countryCode: countryCode ?? this.countryCode,
        trancheAge: clearAge ? null : (trancheAge ?? this.trancheAge),
        regionId: clearRegion ? null : (regionId ?? this.regionId),
      );
}

class ProfileNotifier extends Notifier<Profile> {
  @override
  Profile build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final country = ref.watch(selectedCountryProvider);
    final regionId = prefs.getInt(PrefKeys.regionId);
    return Profile(
      countryCode: country,
      trancheAge: prefs.getString(PrefKeys.trancheAge),
      regionId: regionId == 0 ? null : regionId,
    );
  }

  /// Enregistre localement puis pousse vers Supabase (upsert). Le local prime :
  /// hors-ligne, le profil est quand même conservé et synchronisé plus tard.
  Future<void> save(Profile p) async {
    final prefs = ref.read(sharedPrefsProvider);
    await ref.read(selectedCountryProvider.notifier).select(p.countryCode);
    if (p.trancheAge == null) {
      await prefs.remove(PrefKeys.trancheAge);
    } else {
      await prefs.setString(PrefKeys.trancheAge, p.trancheAge!);
    }
    await prefs.setInt(PrefKeys.regionId, p.regionId ?? 0);
    await prefs.setBool(PrefKeys.profileSynced, false);
    state = p;
    await sync();
  }

  Future<void> sync() async {
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getBool(PrefKeys.profileSynced) ?? false) return;
    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    final p = state;
    try {
      await client.from('profile').upsert({
        'user_id': user.id,
        'country_code': p.countryCode,
        'tranche_age': p.trancheAge,
        'region_id': p.regionId,
        'langue': prefs.getString(PrefKeys.locale) ?? 'fr',
      });
      await prefs.setBool(PrefKeys.profileSynced, true);
    } catch (e) {
      debugPrint('Synchronisation du profil différée : $e');
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class OnboardingState extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(PrefKeys.onboardingDone) ?? false;

  Future<void> complete() async {
    await ref.read(sharedPrefsProvider).setBool(PrefKeys.onboardingDone, true);
    state = true;
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingState, bool>(OnboardingState.new);

/// Langue choisie (null = celle du téléphone).
class LocaleSetting extends Notifier<String?> {
  @override
  String? build() => ref.watch(sharedPrefsProvider).getString(PrefKeys.locale);

  Future<void> set(String? code) async {
    final prefs = ref.read(sharedPrefsProvider);
    if (code == null) {
      await prefs.remove(PrefKeys.locale);
    } else {
      await prefs.setString(PrefKeys.locale, code);
    }
    state = code;
  }
}

final localeSettingProvider = NotifierProvider<LocaleSetting, String?>(LocaleSetting.new);

/// Carte « Affiner les résultats » déjà remplie ou refusée.
class ProfilePromptDone extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(PrefKeys.profilePromptDone) ?? false;

  Future<void> complete() async {
    await ref.read(sharedPrefsProvider).setBool(PrefKeys.profilePromptDone, true);
    state = true;
  }
}

final profilePromptDoneProvider = NotifierProvider<ProfilePromptDone, bool>(ProfilePromptDone.new);
