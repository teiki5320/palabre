# Palabre

L'arbre à palabres : on pose une question, chacun donne son avis, et la
discussion s'appuie sur des faits vérifiables. Application mobile Flutter
adossée à Supabase, pour le Sénégal d'abord, extensible à d'autres pays
d'Afrique de l'Ouest.

L'app n'exprime aucune opinion. Elle pose des questions et documente des
faits sourcés.

## État d'avancement

| Étape | Contenu | État |
|---|---|---|
| 1 | Schéma Supabase, RLS, jeu de test | fait |
| 2 | Module sondage de bout en bout (Flutter, RPC, crons) | fait |
| 3 | Module « Testez-vous », détail source par source, contestation | fait (quiz de test, contenu réel à rédiger) |
| 4 | Notification hebdomadaire, partage d'image | fait (Firebase à configurer) |
| 5 | Module gouvernement : grille, curseur temporel, fiche personne | fait (données fictives) |
| 6 | Module assemblée : recherche, fiche député, fiche parti | fait (données fictives) |
| 7 | Cache hors-ligne, poids, sélecteur multi-pays | fait |

## Structure

```
lib/
  main.dart            démarrage : cache local d'abord, réseau après le premier rendu
  app/                 thème sombre plat, navigation à quatre onglets
  core/                configuration pays, profil, cache Drift, Supabase, notifications
  features/poll        question de la semaine, vote, résultats, archive
  features/quiz        Testez-vous : moteur de concordance, détail, partage, contestation
  features/reference   gouvernement (curseur temporel), assemblée, fiches personne et parti
  l10n/                chaînes fr (référence), en, wo
supabase/
  config.toml          configuration locale (auth anonyme activée)
  migrations/          schéma, dans l'ordre d'application
  seed.sql             jeu de données de test, entièrement fictif
  tests/               assertions SQL et stub pour Postgres nu
  functions/           poll-notify : notification hebdomadaire via FCM
scripts/db_check.sh    rejoue tout de zéro sur un Postgres local
ios/ci_scripts/        préparation Xcode Cloud
docs/schema.md         décisions de modélisation
docs/deploiement.md    Supabase, Firebase, dart-defines, Xcode Cloud
```

## Lancer l'app

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
            --dart-define=SUPABASE_ANON_KEY=<clé anon locale>
```

Sans `--dart-define`, l'app démarre en mode « cache seul » et l'indique.
Vérifications : `flutter analyze` et `flutter test`. APK release arm64 mesuré
à 10,1 Mo (contrainte : 15 Mo).

## Vérifier le schéma

Avec la CLI Supabase et Docker :

```sh
supabase start
supabase db reset          # migrations + seed
psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" -f supabase/tests/schema_test.sql
```

Sans Docker, sur un Postgres local (16 ou plus) :

```sh
scripts/db_check.sh
```

Le script recrée une base `palabre_check`, charge un stub minimal du schéma
`auth` et des rôles Supabase, applique les migrations, le seed et les tests.
Sans `pg_cron`, la migration des crons se limite à un avertissement.
