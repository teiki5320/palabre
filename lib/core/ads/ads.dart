import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/theme.dart';
import '../country/country_providers.dart';

/// Publicité : une seule bannière, annonces non personnalisées, uniquement sur
/// les onglets de référence (Gouvernement, Assemblée). Jamais sur la question
/// de la semaine ni sur « Testez-vous ». Coupure à distance : `app_config`
/// clé `publicite` = `off`.
///
/// Identifiants de blocs injectés à la compilation (`ADMOB_BANNER_ANDROID`,
/// `ADMOB_BANNER_IOS`) ; sans eux, les blocs de test de Google.
class AdsConfig {
  static const bannerAndroid = String.fromEnvironment('ADMOB_BANNER_ANDROID', defaultValue: 'ca-app-pub-3940256099942544/6300978111');
  static const bannerIos = String.fromEnvironment('ADMOB_BANNER_IOS', defaultValue: 'ca-app-pub-3940256099942544/2934735716');

  static String get banner => Platform.isIOS ? bannerIos : bannerAndroid;

  static bool get isTest => banner.startsWith('ca-app-pub-3940256099942544');
}

/// Initialisation du SDK et du consentement (UMP), après le premier rendu.
class AdsService {
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  static Future<void> initialize() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      // Consentement : formulaire Google (UMP) affiché seulement là où la loi
      // l'exige ; les annonces restent non personnalisées dans tous les cas.
      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          } finally {
            if (!completer.isCompleted) completer.complete();
          }
        },
        (_) {
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {});
      await MobileAds.instance.initialize();
      ready.value = true;
    } catch (e) {
      debugPrint('publicité indisponible : $e');
    }
  }
}

/// Bannière ancrée en bas d'un onglet. Ne prend aucune place tant qu'aucune
/// annonce n'est chargée, ou si la publicité est coupée à distance.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _width;

  @override
  void initState() {
    super.initState();
    AdsService.ready.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final w = MediaQuery.sizeOf(context).width.truncate();
    if (w != _width) {
      _width = w;
      _maybeLoad();
    }
  }

  Future<void> _maybeLoad() async {
    if (!mounted || !AdsService.ready.value || _ad != null || _width == null) return;
    // Format ancré standard (~50-60 px de haut), pas le grand format : la bannière reste discrète.
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(Orientation.portrait, _width!) ?? AdSize.banner;
    if (!mounted) return;
    _ad = BannerAd(
      adUnitId: AdsConfig.banner,
      size: size,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    AdsService.ready.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(countryConfigOrFallbackProvider);
    if (config.appConfig['publicite'] == 'off') return const SizedBox.shrink();
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border(top: BorderSide(color: t.border, width: 2))),
      child: SizedBox(width: double.infinity, height: ad.size.height.toDouble(), child: Center(child: SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad)))),
    );
  }
}
