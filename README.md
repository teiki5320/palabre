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
| 2 | Module sondage de bout en bout (Flutter, Edge Functions, crons) | à venir |
| 3 | Module « Testez-vous » | à venir |
| 4 | Notification hebdomadaire, partage d'image | à venir |
| 5 | Module gouvernement | à venir |
| 6 | Module assemblée | à venir |
| 7 | Cache hors-ligne, poids, multi-pays | à venir |

## Structure

```
supabase/
  config.toml          configuration locale (auth anonyme activée)
  migrations/          schéma, dans l'ordre d'application
  seed.sql             jeu de données de test, entièrement fictif
  tests/               assertions SQL et stub pour Postgres nu
scripts/db_check.sh    rejoue tout de zéro sur un Postgres local
docs/schema.md         décisions de modélisation
```

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
