# Question de la semaine automatique — conception

Date : 2026-09-12. Décisions prises avec le propriétaire : publication automatique, notification par
issue GitHub, exécution dans GitHub Actions le dimanche matin.

## Objectif

Chaque semaine, pour chaque pays actif, trouver un fait d'actualité des huit derniers jours, rédiger une
question de sondage neutre et sourcée, la vérifier, la publier dans Supabase pour une ouverture le
lundi 8 h (heure du pays), et prévenir le propriétaire par une issue GitHub qui lui permet de retirer
une question avant l'ouverture.

Règles du projet qui s'appliquent : aucune opinion, jamais une personne, chaque fait renvoie à sa
source, une absence assumée vaut mieux qu'une question douteuse.

## Déclenchement

- Workflow `question-semaine.yml`, cron `0 7 * * 0` (dimanche 7 h UTC), et `workflow_dispatch` avec
  une entrée `dry_run` (par défaut `false`) et une entrée `semaine` facultative (lundi AAAA-MM-JJ).
- Semaine visée : le lundi qui suit la date d'exécution (le lendemain quand on tourne le dimanche).
- Pays traités : `country.actif = true` et `country_module(module = 'poll', actif = true)`, sans
  sondage déjà présent pour la semaine visée. Relancer le workflow est donc sans effet sur un pays déjà
  servi.
- Secrets GitHub : `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`. `GITHUB_TOKEN`
  sert à ouvrir l'issue.

## Pipeline par pays (script `scripts/question_semaine/run.py`, Python 3.12, dépendance `anthropic`)

1. **Recherche** — un appel à l'API Claude (`claude-opus-5`) avec l'outil de recherche web, prompt
   dérivé de `docs/prompts/recherche-pays.md` § 7 et d'une fiche par pays
   (`scripts/question_semaine/pays.json` : nom, fuseau, médias reconnus, consignes de prudence — par
   exemple, pour le Togo, écarter tout sujet dont une réponse pourrait exposer un répondant). Sortie
   structurée : 3 à 5 sujets `{id, fait, question, contexte, options, sources[{titre,url,date,media}],
   points_d_attention}`.
2. **Contrôles automatiques** (fonctions pures, testées) — un sujet est écarté si :
   - une source ne répond pas en HTTP (GET, délai 15 s, statut < 400) ;
   - une date de source est hors de la fenêtre [lundi visé − 9 jours, jour d'exécution] ;
   - les sources viennent de moins de deux hôtes distincts ;
   - il y a moins de 3 ou plus de 5 options, ou aucune option n'est « Sans avis » ;
   - la question ne se termine pas par « ? » ou dépasse 200 caractères ;
   - la question ou une option contient le nom d'une personne de la table `person` du pays
     (comparaison sans accents ni casse, sur le nom complet et sur « prénom nom » inversé) ;
   - le contexte dépasse 600 caractères.
3. **Relecture** — un second appel à Claude, sans recherche web, reçoit les sujets retenus et, pour
   chaque source, un extrait texte de la page (≤ 4 000 caractères, HTML dépouillé). Il vérifie que
   chaque phrase du contexte est couverte par une source, que la question est neutre (pas de
   justification officielle reprise, pas de mot chargé, options équilibrées), et choisit un sujet ou
   aucun. Sortie structurée : `{choix: id|null, avis: texte, rejets: [{id, motif}]}`.
4. **Publication** — via PostgREST avec la clé service : insertion dans `poll` (country_code, semaine,
   question, contexte, sources), puis `poll_option`, puis `publie = true`. Le trigger existant
   `poll_avant_publication` vérifie les options ; le trigger `poll_avant_insert` calcule ouverture et
   fermeture dans le fuseau du pays. En `dry_run`, rien n'est écrit et le résultat est imprimé.
5. **Rapport** — le script écrit `rapport.md` et `rapport.json` (artefacts du workflow).

Si la recherche ne donne rien de valide ou si la relecture ne choisit rien, le pays reste sans
question cette semaine : le rapport dit pourquoi. Une erreur d'API ou de réseau sur un pays n'empêche
pas les autres ; le job termine en échec si au moins un pays a rencontré une erreur technique.

## Notification

Une issue GitHub par exécution, titre « Question de la semaine du AAAA-MM-JJ », étiquette
`question-semaine`, corps = `rapport.md` :

- pour chaque pays publié : question, options, contexte, sources (liens datés), avis du relecteur,
  et le lien vers le workflow de retrait pré-rempli ;
- pour chaque pays sans question : la raison (aucun sujet valide, rejets du relecteur, erreur) ;
- rappel : les questions ouvrent lundi à 8 h heure locale.

## Retrait

Workflow `retirer-question.yml`, `workflow_dispatch` avec `pays` et `semaine` : passe `publie = false`
sur le sondage visé s'il n'est pas encore ouvert (`now() < ouverture`) ; sinon le job échoue avec un
message clair. Il commente l'issue de la semaine.

## Tests

- `scripts/question_semaine/test_controles.py` (unittest) : chaque règle de contrôle, la fenêtre de
  dates, la détection de nom de personne, le choix de la semaine visée, le rendu du rapport.
- Job CI `question-semaine` qui lance ces tests à chaque push, sans clé API.
- Un mode `--fixture chemin.json` remplace l'appel de recherche par un fichier, pour tester le
  pipeline complet hors ligne (contrôles + rapport), sans relecture ni publication.

## Coûts et limites

- Deux appels par pays et par semaine ; facturation à l'usage sur la console Anthropic.
- Le script ne modifie jamais une question existante ni un sondage ouvert.
- Les textes générés restent en français ; les autres langues de l'app affichent la question en
  français comme aujourd'hui.
