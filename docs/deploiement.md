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
projet de production.

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
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<clé publique> \
  --dart-define=PALABRE_COUNTRY=SN
```

Sans `SUPABASE_URL`, l'app tourne en mode « cache seul » et l'affiche.

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
