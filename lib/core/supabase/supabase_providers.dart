import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Client Supabase, ou null si l'app n'est pas configurée (mode cache seul).
final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => Env.isConfigured ? Supabase.instance.client : null,
);

/// Démarrage : initialise Supabase et ouvre une session anonyme sans bloquer
/// le premier rendu. L'e-mail est optionnel et pourra être lié plus tard.
class AuthBootstrap {
  static Future<void> initialize() async {
    if (!Env.isConfigured) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
  }

  /// À appeler après runApp : ne retarde pas l'affichage.
  static Future<void> ensureSession() async {
    if (!Env.isConfigured) return;
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return;
    try {
      await auth.signInAnonymously();
    } catch (e) {
      debugPrint('Session anonyme impossible : $e');
    }
  }
}

/// Identifiant de session courant (null hors-ligne ou avant connexion).
final sessionUserIdProvider = StreamProvider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream.value(null);
  final controller = StreamController<String?>();
  controller.add(client.auth.currentUser?.id);
  final sub = client.auth.onAuthStateChange
      .listen((s) => controller.add(s.session?.user.id));
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});
