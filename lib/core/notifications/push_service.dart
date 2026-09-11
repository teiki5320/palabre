import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../country/country_providers.dart';
import '../prefs/prefs_provider.dart';
import '../supabase/supabase_providers.dart';

/// Une seule notification hebdomadaire : l'ouverture de la question du lundi,
/// et un rappel le samedi pour ceux qui n'ont pas voté. Rien d'autre.
///
/// Le côté app se limite à enregistrer le jeton FCM avec le pays et la
/// langue ; l'envoi est fait par l'Edge Function poll-notify.
class PushService {
  static bool get available => DefaultFirebaseOptions.isConfigured;

  static Future<void> initialize(ProviderContainer container) async {
    if (!available) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: false, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await messaging.setForegroundNotificationPresentationOptions(alert: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) await _register(container, token);
      messaging.onTokenRefresh.listen((t) => _register(container, t));
      container.listen(selectedCountryProvider, (_, _) async {
        final t = await messaging.getToken();
        if (t != null) await _register(container, t);
      });
    } catch (e) {
      debugPrint('Notifications indisponibles : $e');
    }
  }

  static Future<void> _register(ProviderContainer container, String token) async {
    final client = container.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    final prefs = container.read(sharedPrefsProvider);
    try {
      await client.from('device_token').upsert({
        'token': token,
        'user_id': user.id,
        'country_code': container.read(selectedCountryProvider),
        'langue': prefs.getString(PrefKeys.locale) ?? 'fr',
        'plateforme': Platform.isIOS ? 'ios' : 'android',
        'maj': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Jeton non enregistré : $e');
    }
  }
}
