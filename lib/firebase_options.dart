// Remplacer ce fichier par celui généré par `flutterfire configure`.
// Tant que les valeurs ci-dessous sont des marqueurs, l'app démarre sans
// Firebase et la notification hebdomadaire est simplement désactivée.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const String _placeholder = 'REMPLACER';

  static bool get isConfigured => currentPlatform.apiKey != _placeholder;

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    iosBundleId: 'sn.palabre.app',
  );
}
