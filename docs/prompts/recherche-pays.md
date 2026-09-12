# Prompts de recherche — ajouter un pays à Palabre

Sept prompts, à lancer dans cet ordre (les quatre premiers en parallèle). Chacun produit un fichier JSON
sourcé dans `supabase/prod/sources/<pays>/`, que `scripts/gen_prod_sql.py` transforme en SQL.
Les fichiers du Bénin (`supabase/prod/sources/bj/`) servent d'exemple de format et de niveau d'exigence.

Remplacer avant usage :
- `{PAYS}` : nom du pays (ex. Côte d'Ivoire) ; `{CODE}` : code ISO en minuscules (ex. ci) ;
- `{DATE}` : date du jour (AAAA-MM-JJ) ;
- `{REGIONS}` : liste des régions avec leur code ISO 3166-2 (ex. « AB (Abidjan), BS (Bas-Sassandra)… ») ;
- `{SEMAINE}` : lundi de la semaine visée par la question (AAAA-MM-JJ) ;
- `{BROUILLON}` : dossier de travail pour les téléchargements (PDF, textes extraits).

---

## Règles communes (à coller en tête de chaque prompt)

```
Tu fais une recherche factuelle pour Palabre, une app civique strictement neutre : pas de score,
pas d'opinion, pas de classement de personnes, jamais d'extrapolation de la position d'un parti.
Nous sommes le {DATE}. Pays : {PAYS}.

- Chaque fait a une source (URL) que tu as réellement ouverte et lue. Ne cite rien que tu n'as pas lu.
- Ordre d'autorité des sources : Journal officiel, décision de justice ou décret > site officiel
  (gouvernement, présidence, assemblée, cour constitutionnelle, commission électorale) > agence de presse
  nationale > presse nationale reconnue > presse internationale > Wikipédia en dernier recours.
- Aucune invention. Un champ inconnu vaut null, avec l'explication dans "notes". Une absence assumée
  vaut mieux qu'une donnée inventée. Ne complète jamais une liste avec des noms supposés.
- Orthographe des noms et intitulés : celle du texte officiel. Les variantes vont dans "notes".
- Recoupe les listes avec au moins deux sources et signale toute divergence.
- Télécharge les documents officiels dans {BROUILLON} (curl), extrais le texte (pdftotext -layout) ;
  si un PDF est scanné, lis ses pages en image. Recherches web économes : lis directement les pages.
- Écris un JSON UTF-8 valide, indenté de 2 espaces. Réponds à la fin par un résumé court : ce qui est
  trouvé, la source principale, les trous et divergences.
```

---

## 1. Gouvernement en exercice

```
Objectif : documenter le gouvernement EN EXERCICE (chef du gouvernement, liste complète des membres avec
les intitulés exacts de l'acte de nomination) et tout remaniement depuis sa formation.
Vérifie d'abord le régime : qui dirige le gouvernement (Premier ministre, Président de la République,
Président du Conseil…). Le chef de l'État non membre du gouvernement va dans une note.

Fichier : supabase/prod/sources/{CODE}/government.json
{
  "gouvernement": {"nom", "debut": "AAAA-MM-JJ", "decret_ref", "source_url", "source_titre"},
  "chef_gouvernement": {"nom", "intitule", "date_nomination", "decret_ref", "source_url", "note"},
  "ministres": [{"ordre", "nom", "civilite": "M.|Mme", "intitule",
                 "type": "ministre|ministre_etat|ministre_delegue|secretaire_etat|secretaire_general",
                 "bloc": "regalien|economie|social|infrastructure", "source_url", "reconduit": true|false|null}],
  "remaniements": [{"date", "description", "source_url"}],
  "notes": "divergences, qui est membre du gouvernement selon l'acte, points non vérifiés"
}
"ordre" = ordre protocolaire de l'acte. Le secrétaire général du gouvernement n'est listé (type
secretaire_general) que pour information : il est exclu s'il n'est pas membre.
```

## 2. Assemblée nationale

```
Objectif : documenter l'assemblée élue en exercice : numéro de législature, date d'installation,
président et bureau, groupes parlementaires, liste nominative COMPLÈTE des députés (circonscription,
parti ou liste d'élection, région), et tous les changements depuis l'installation (nominations au
gouvernement et remplacements, démissions, décès, invalidations, élections partielles), datés et sourcés.
Source principale attendue : la décision officielle de proclamation des résultats.
Régions : donne pour chaque circonscription le code ISO 3166-2 de sa région parmi {REGIONS}.
Groupes : ne rattache un député à un groupe que si une liste nominative publiée ou une règle écrite
(règlement intérieur) le permet ; sinon null, et explique pourquoi dans "notes".

Fichier : supabase/prod/sources/{CODE}/assembly.json
{
  "legislature": {"numero", "debut", "sieges_total", "source_url", "source_titre", "source_mandats"},
  "president": {"nom", "date_election", "source_url", "note"},
  "bureau": [{"nom", "fonction", "source_url"}],
  "groupes": [{"nom", "sigle", "sieges", "president", "source_url"}],
  "listes": [{"nom", "sigle", "sieges", "voix_pct"}],
  "circonscriptions": [{"nom", "region_code", "sieges"}],
  "deputes": [{"nom", "circonscription", "region_code", "liste", "groupe", "suppleant",
               "statut": "titulaire_en_exercice|suppleant_en_exercice|sorti", "remplace", "note"}],
  "changements": [{"date", "depute_sortant", "remplacant",
                   "motif": "nomination_gouvernement|demission|deces|invalidation|autre", "description", "source_url"}],
  "sources": [{"titre", "url"}],
  "notes": "ce qui manque, divergences"
}
Dans "deputes", mets toutes les personnes ayant siégé : les sortis ET leurs remplaçants (champ "remplace").
```

## 3. Partis et documents programmatiques

```
Objectif : documenter les partis significatifs (élus à la dernière législative, candidats à la dernière
présidentielle) et rassembler leurs DOCUMENTS PROGRAMMATIQUES ÉCRITS (programme, projet de société,
manifeste, statuts), qui serviront à placer les partis sur les affirmations du quiz.
- Un programme de candidat ou de coalition est une entrée séparée (type "coalition"), reliée aux partis
  qui l'ont investi par une relation "coalition_membre" sourcée. Il n'est jamais attribué à un parti.
- "couleur" : seulement si documentée (charte, logo officiel, infobox Wikipédia) ; sinon null.
- Chaque document : télécharge-le, compte les pages, extrais le texte en .txt (copie web.archive.org si
  le lien est mort) et indique le chemin local.
- Relations autorisées : scission, fusion, renommage, coalition_membre, absorption. Les alliances et
  soutiens simples vont dans "notes".

Fichier : supabase/prod/sources/{CODE}/parties.json
{
  "partis": [{"nom", "sigle", "type": "parti|coalition", "fondation", "dirigeant": {"nom", "titre"},
              "site", "wikipedia", "couleur", "couleur_source", "source_url",
              "resultats": [{"election", "voix_pct", "sieges", "source_url"}],
              "documents": [{"titre", "url", "date", "type", "pages", "texte_local"}], "note"}],
  "relations": [{"de", "vers", "type", "date", "source_url"}],
  "notes": "partis sans document écrit, liens morts, divergences, alliances"
}
```

## 4. Débats publics

```
Objectif : inventaire de 25 à 35 grands DÉBATS PUBLICS des trois dernières années (institutions, justice,
libertés, sécurité, relations régionales, économie, social, décentralisation, foncier, énergie,
environnement), base des affirmations du quiz.
- Chaque débat : au moins deux sources datées d'origines différentes.
- Question neutre, contexte factuel de 2 à 3 phrases, arguments pour et contre attribués à qui les porte.
- "positions_publiques" : uniquement les prises de position EXPLICITES d'un parti ou de ses dirigeants
  officiels, avec citation exacte et URL. Jamais déduites de l'appartenance à la majorité ou à l'opposition.
- "sensibilite" : sujet ayant donné lieu à des arrestations ou restrictions récentes (sourcé), sinon null.

Fichier : supabase/prod/sources/{CODE}/debats.json
{"debats": [{"id", "theme", "question", "contexte", "periode", "arguments_pour": [{"argument", "porte_par", "source_url"}],
  "arguments_contre": [...], "positions_publiques": [{"sigle", "sens": "pour|contre", "citation", "auteur", "date", "source_url"}],
  "sources": [{"titre", "media", "date", "url"}], "sensibilite", "encore_ouvert"}], "notes"}
```

## 5. Engagements écrits (après le prompt 3)

```
Objectif : relever, dans chaque document programmatique téléchargé (liste et chemins dans
supabase/prod/sources/{CODE}/parties.json), chaque engagement ou prise de position explicite qui peut
trancher une affirmation « d'accord / pas d'accord ». Lis chaque document EN ENTIER.
- "extrait" : citation EXACTE, mot pour mot, 1 à 3 phrases (coupe avec […]).
- "resume_neutre" : une phrase neutre, sans interprétation.
- "tranchable" : true seulement si l'extrait permet de dire sans hésiter si l'auteur est pour ou contre
  une mesure précise. Un bilan présenté comme un acquis est relevé en le disant dans le résumé.
- "page" : dans un .txt issu de PDF, page n = nombre de sauts de page (\f) avant le passage + 1 ;
  vérifie avec les numéros imprimés. null pour une page web.
- Vérifie par script que chaque extrait se retrouve dans le texte source (espaces et apostrophes
  normalisés) ; un passage lu sur image porte "lu_sur_image": true.

Fichier : {BROUILLON}/engagements_{CODE}.json
{"documents": [{"cle", "auteur": "sigle exact de parties.json", "titre", "url", "date", "pages"}],
 "engagements": [{"document", "theme", "sujet", "resume_neutre", "extrait", "page", "tranchable"}]}
Termine par ton avis : les textes suffisent-ils à placer au moins deux entrées sur une dizaine d'affirmations ?
```

## 6. Rédaction des affirmations du quiz (après les prompts 4 et 5)

```
À partir de debats.json et des engagements tranchables, rédige 25 affirmations :
- priorité aux sujets où au moins deux entrées ont un engagement écrit ;
- une seule idée, jamais une personne, pas de mot chargé, réponse possible par d'accord ou pas d'accord ;
- équilibre : environ la moitié propose de changer l'existant, l'autre de le garder (champ "sens") ;
- pour chaque affirmation et chaque entrée : "accord" ou "desaccord" seulement avec l'extrait exact, la
  page et l'URL du document ; sinon aucune position (non calculable). Jamais de déduction.
Relis chaque position en confrontant l'extrait à l'affirmation ; retire toute position qui demande
d'interpréter. Si moins d'une dizaine d'affirmations ont deux entrées placées, recommande de ne pas
publier de quiz pour ce pays.
Fichiers : quiz_statements.json et positions.json (format du Bénin).
```

## 7. Question de la semaine — actualité

```
Objectif : trouver 3 à 5 sujets d'ACTUALITÉ rapportés dans les 8 jours précédents, pour la question de la
semaine du lundi {SEMAINE}.
- Un fait précis et daté de la période (décision, loi, annonce, mesure de vie quotidienne), rapporté par
  au moins deux sources datées de la période, d'origines différentes.
- Concerne tout le pays ; un citoyen peut avoir un avis sans connaissances techniques.
- Jamais une question sur une personne, jamais une intention de vote, rien qui puisse exposer un
  répondant (manifestations, affaires judiciaires en cours, critique directe des institutions dans un
  pays où l'expression est restreinte).
- Pour chaque sujet : "fait" (1 phrase datée), "question" (neutre, se termine par « ? »), "contexte"
  (2 à 3 phrases strictement factuelles), "options" (3 ou 4 options équilibrées + « Sans avis »),
  "sources" [{"titre", "url", "date", "media"}], "points_d_attention".
Fichier : {BROUILLON}/actu_{CODE}.json. Termine par ta recommandation motivée.
```
