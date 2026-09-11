class Country {
  const Country({
    required this.code,
    required this.nom,
    required this.fuseau,
    required this.langue,
    required this.actif,
  });

  final String code;
  final String nom;
  final String fuseau;
  final String langue;
  final bool actif;

  factory Country.fromJson(Map<String, dynamic> j) => Country(
        code: j['code'] as String,
        nom: j['nom'] as String,
        fuseau: (j['fuseau'] as String?) ?? 'UTC',
        langue: (j['langue'] as String?) ?? 'fr',
        actif: (j['actif'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'code': code, 'nom': nom, 'fuseau': fuseau, 'langue': langue, 'actif': actif};
}

class Region {
  const Region({required this.id, required this.countryCode, required this.code, required this.nom});

  final int id;
  final String countryCode;
  final String code;
  final String nom;

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: (j['id'] as num).toInt(),
        countryCode: j['country_code'] as String,
        code: j['code'] as String,
        nom: j['nom'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'country_code': countryCode, 'code': code, 'nom': nom};
}

enum AppModule { poll, quiz, government, assembly }

class CountryModule {
  const CountryModule({required this.countryCode, required this.module, required this.actif, this.motif});

  final String countryCode;
  final String module;
  final bool actif;
  final String? motif;

  factory CountryModule.fromJson(Map<String, dynamic> j) => CountryModule(
        countryCode: j['country_code'] as String,
        module: j['module'] as String,
        actif: (j['actif'] as bool?) ?? true,
        motif: j['motif'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'country_code': countryCode, 'module': module, 'actif': actif, 'motif': motif};
}

/// Tout ce que l'app sait des pays : lu une fois, mis en cache.
class CountryConfig {
  const CountryConfig({required this.countries, required this.regions, required this.modules, this.appConfig = const {}});

  final List<Country> countries;
  final List<Region> regions;
  final List<CountryModule> modules;
  final Map<String, String> appConfig;

  Country? country(String code) {
    for (final c in countries) {
      if (c.code == code) return c;
    }
    return null;
  }

  List<Region> regionsOf(String code) =>
      regions.where((r) => r.countryCode == code).toList()..sort((a, b) => a.nom.compareTo(b.nom));

  Region? region(int? id) {
    if (id == null) return null;
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  CountryModule? module(String code, AppModule m) {
    for (final cm in modules) {
      if (cm.countryCode == code && cm.module == m.name) return cm;
    }
    return null;
  }

  /// Un module absent de la table est actif : l'interrupteur ne sert qu'à suspendre.
  bool isActive(String code, AppModule m) => module(code, m)?.actif ?? true;

  factory CountryConfig.fromJson(Map<String, dynamic> j) => CountryConfig(
        countries: (j['countries'] as List).cast<Map<String, dynamic>>().map(Country.fromJson).toList(),
        regions: (j['regions'] as List).cast<Map<String, dynamic>>().map(Region.fromJson).toList(),
        modules: (j['modules'] as List).cast<Map<String, dynamic>>().map(CountryModule.fromJson).toList(),
        appConfig: ((j['app_config'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
      );

  Map<String, dynamic> toJson() => {
        'countries': countries.map((c) => c.toJson()).toList(),
        'regions': regions.map((r) => r.toJson()).toList(),
        'modules': modules.map((m) => m.toJson()).toList(),
        'app_config': appConfig,
      };

  /// Repli quand ni réseau ni cache : le pays par défaut, sans régions.
  static CountryConfig fallback(String code) => CountryConfig(
        countries: [Country(code: code, nom: code, fuseau: 'UTC', langue: 'fr', actif: true)],
        regions: const [],
        modules: const [],
      );
}

const ageBrackets = ['18-24', '25-34', '35-44', '45-54', '55-64', '65+'];
