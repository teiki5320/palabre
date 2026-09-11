/// Configuration injectée à la compilation :
///   flutter build ... --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Sans ces valeurs, l'app démarre en mode « cache seul » et l'indique.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Pays proposé par défaut à l'onboarding. Une donnée de configuration,
  /// jamais une branche de code.
  static const defaultCountry =
      String.fromEnvironment('PALABRE_COUNTRY', defaultValue: 'SN');

  /// Domaine de secours si le domaine principal ne répond plus (section 13).
  static const fallbackUrl = String.fromEnvironment('SUPABASE_FALLBACK_URL');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
