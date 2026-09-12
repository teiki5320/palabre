# Déploiement

## 1. Supabase

```sh
supabase link --project-ref <ref>
supabase db push                      # migrations 0001 → 0009
supabase functions deploy poll-notify
```

Extensions à activer sur le projet (Dashboard → Database → Extensions) :
`pg_cron`, `pg_net`. Les migrations les détectent et n'installent les crons
que si elles sont présentes.

Secrets Vault (Dashboard → Settings → Vault), lus par le cron horaire qui
appelle l'Edge Function :

| Nom | Valeur |
|---|---|
| `project_url` | `https://<ref>.supabase.co` |
| `service_role_key` | la clé de service du projet |

Puis rejouer la migration `0009` (ou exécuter son bloc `do $$` final) pour
planifier `palabre_poll_notify` une fois les secrets présents.

Secret de l'Edge Function :

```sh
supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
```

Auth : activer **Anonymous sign-ins** (Authentication → Providers).

Le seed est réservé au développement local : ne jamais le charger sur le
projet de production. Les données de production se chargent avec les
scripts de `supabase/prod/` :

```sh
psql "$DATABASE_URL" -f supabase/prod/01_configuration.sql   # pays, régions, modules
# puis une copie remplie de 02_question_modele.sql par question de la semaine
```

L'URL `DATABASE_URL` se lit dans le tableau de bord : Connect → Session
pooler.

## 2. Firebase (notification hebdomadaire)

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=<projet-firebase> --platforms=android,ios
```

Cela remplace `lib/firebase_options.dart`. Tant que le fichier contient les
marqueurs d'origine, l'app démarre sans Firebase et le module notification
est simplement désactivé.

iOS : activer *Push Notifications* et *Background Modes → Remote
notifications* dans Xcode, et déposer la clé APNs dans la console Firebase.

## 3. Build Flutter

Toute la configuration passe par des `--dart-define` :

```sh
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<clé publique> \
  --dart-define=PALABRE_COUNTRY=SN
```

Sans `SUPABASE_URL`, l'app tourne en mode « cache seul » et l'affiche.

Poids : les bibliothèques natives sont compressées dans l'APK
(`useLegacyPackaging` dans `android/app/build.gradle.kts`) et le code Dart
est obfusqué. Le workflow CI échoue si un APK par architecture dépasse
15 Mo. Conserver `build/symbols` pour dé-obfusquer les rapports de plantage.

## 3 bis. Android — Google Play

- Clé de téléversement : `android/app/upload-keystore.jks` + `android/key.properties` (ignorés par git),
  mot de passe dans le trousseau macOS « Palabre Android upload keystore ». Sans ces fichiers (CI),
  la release est signée avec la clé de debug.
- Bundle signé pour la Play Console :

```sh
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=SUPABASE_URL=https://kigaejkyzpehkoujzlyf.supabase.co \
  --dart-define=SUPABASE_ANON_KEY="$(supabase projects api-keys --project-ref kigaejkyzpehkoujzlyf -o json | python3 -c 'import sys,json;print(next(k["api_key"] for k in json.load(sys.stdin) if k["name"]=="anon"))')"
```

  Fichier : `build/app/outputs/bundle/release/app-release.aab`. Incrémenter `version: x.y.z+N` dans
  pubspec.yaml avant chaque envoi (N = versionCode).
- Fiche, sécurité des données, classification : `docs/play-store.md`. Politique de confidentialité
  publiée par GitHub Pages depuis `docs/site/` : https://teiki5320.github.io/palabre/site/confidentialite.html
- Émulateur local : AVD `palabre` (Pixel 7, Android 16) — `flutter run -d emulator-5554 --dart-define=…`.

## 4. Xcode Cloud et TestFlight

Le dépôt contient `ios/ci_scripts/ci_post_clone.sh`, exécuté
automatiquement par Xcode Cloud après le clone. Il installe Flutter, génère
les fichiers Dart, prépare la configuration iOS et installe les pods.

Dans le workflow Xcode Cloud :

1. Produit : `Runner` (schéma `Runner`, workspace `ios/Runner.xcworkspace`).
2. Variables d'environnement : `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
   éventuellement `FLUTTER_VERSION` (branche ou tag Flutter, défaut `stable`).
3. Action *Archive* avec distribution TestFlight.

Identifiant de bundle : `sn.palabre.app` (modifiable dans Xcode, penser à
répercuter dans `lib/firebase_options.dart` après `flutterfire configure`).

## 5. Domaine de secours

`app_config.domaine_secours` est lu au démarrage. La bascule effective se
fait par `--dart-define=SUPABASE_FALLBACK_URL=` à la compilation : l'app
tente le domaine principal, puis le secours. À décider hors code.

## 6. Suspendre un module dans un pays

```sql
update country_module set actif = false, motif = 'Période électorale'
where country_code = 'SN' and module = 'poll';
```

Effet immédiat au prochain lancement de l'app, sans mise à jour.
