import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../net/cached_notifier.dart';
import '../prefs/prefs_provider.dart';
import '../supabase/supabase_providers.dart';
import 'country_models.dart';

class CountryConfigNotifier extends CachedNotifier<CountryConfig> {
  @override
  String get cacheKey => 'country_config';

  @override
  Future<CountryConfig> fetchRemote() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) throw const NotConfiguredException();
    final results = await Future.wait([
      client.from('country').select().order('nom', ascending: true),
      client.from('region').select().order('nom', ascending: true),
      client.from('country_module').select(),
      client.from('app_config').select(),
    ]);
    final appConfig = <String, String>{
      for (final row in results[3]) row['cle'] as String: row['valeur'] as String,
    };
    return CountryConfig(
      countries: results[0].map(Country.fromJson).toList(),
      regions: results[1].map(Region.fromJson).toList(),
      modules: results[2].map(CountryModule.fromJson).toList(),
      appConfig: appConfig,
    );
  }

  @override
  CountryConfig decode(Map<String, dynamic> json) => CountryConfig.fromJson(json);

  @override
  Map<String, dynamic> encode(CountryConfig value) => value.toJson();
}

final countryConfigProvider =
    AsyncNotifierProvider<CountryConfigNotifier, CountryConfig>(CountryConfigNotifier.new);

/// Configuration disponible immédiatement : la vraie si chargée, sinon un repli.
final countryConfigOrFallbackProvider = Provider<CountryConfig>((ref) {
  final code = ref.watch(selectedCountryProvider);
  return ref.watch(countryConfigProvider).value ?? CountryConfig.fallback(code);
});

/// Pays sélectionné, persistant. Le cœur du code ne connaît pas le Sénégal :
/// il ne connaît que ce code.
class SelectedCountry extends Notifier<String> {
  @override
  String build() =>
      ref.watch(sharedPrefsProvider).getString(PrefKeys.country) ?? Env.defaultCountry;

  Future<void> select(String code) async {
    await ref.read(sharedPrefsProvider).setString(PrefKeys.country, code);
    state = code;
  }
}

final selectedCountryProvider = NotifierProvider<SelectedCountry, String>(SelectedCountry.new);

final selectedCountryInfoProvider = Provider<Country>((ref) {
  final code = ref.watch(selectedCountryProvider);
  return ref.watch(countryConfigOrFallbackProvider).country(code) ??
      Country(code: code, nom: code, fuseau: 'UTC', langue: 'fr', actif: true);
});

/// Interrupteur de module pour le pays courant (section 13).
final moduleStateProvider = Provider.family<CountryModule?, AppModule>((ref, m) {
  final code = ref.watch(selectedCountryProvider);
  return ref.watch(countryConfigOrFallbackProvider).module(code, m);
});
