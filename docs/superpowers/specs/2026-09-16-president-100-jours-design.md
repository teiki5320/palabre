# Président pour 100 jours — conception

Date : 16 septembre 2026. Titre de travail. Ce document remplace toute conception de Palabre : le dépôt, l'identifiant `sn.palabre.app`, la fiche App Store Connect, Xcode Cloud, la fiche Play Console et la clé de téléversement Android sont réutilisés pour ce jeu.

## 1. En une phrase

Un jeu de cartes à glisser : tu es le Président d'un pays d'Afrique de l'Ouest **imaginaire**, les personnages viennent te voir un par jour, tu décides à gauche ou à droite, et tu tiens cent jours sans qu'aucune de tes quatre jauges ne se vide ni ne déborde.

## 2. Décisions prises

| Sujet | Décision |
|---|---|
| Ton | Fond sérieux, personnages hauts en couleur, événements absurdes de temps en temps |
| Déroulement | Mandats de 100 jours enchaînés ; élection au jour 100 ; la progression reste acquise |
| Public | Afrique francophone d'abord ; Android en priorité, iOS conservé ; français uniquement |
| Argent | Publicité récompensée et interstitielle, plus un achat unique « Sans pub » (1 à 2 €) |
| Serveur | Aucun. Tout est dans l'appli ; sauvegarde sur le téléphone ; réseau seulement pour la pub et l'achat |
| Style | Portraits photoréalistes générés sur OpenArt (Nano Banana 2 Lite, 15 crédits l'image) |
| Jauges | Peuple, Armée, Caisses, Presse |
| Identification | Le joueur choisit un parcours (qui il était avant) et écrit son nom |
| Technique | Flutter, comme Palabre ; pas de moteur de jeu |

Ce qui est hors périmètre pour le lancement : classements, mise à jour du contenu à distance, autres langues, effets visuels lourds.

## 3. Règles du jeu

### Les jauges

Quatre jauges de 0 à 100 : **Peuple** (la rue, les syndicats), **Armée** (la loyauté des militaires), **Caisses** (l'argent de l'État), **Presse** (l'opinion et les médias). Une jauge à **0** ou à **100** met fin au mandat, chacune à sa façon :

| Jauge | À 0 | À 100 |
|---|---|---|
| Peuple | La rue te chasse | Homme providentiel : les autres pouvoirs s'allient contre toi |
| Armée | Coup d'État | L'armée gouverne à ta place |
| Caisses | Faillite, mise sous tutelle | Tu thésaurises, le pays s'arrête, la rue explose |
| Presse | Tu es démoli, tu démissionnes | La presse est ta propagande, plus personne ne t'informe : tu apprends le complot trop tard |

### Une journée, une carte

Un personnage apparaît et dit une phrase. Le joueur glisse la carte à gauche ou à droite. Pendant qu'il la retient à mi-chemin, les jauges que la réponse va modifier s'illuminent, sans indiquer de combien. Chaque réponse modifie une à trois jauges, entre −20 et +20. Chaque carte avance d'un jour.

Pas de bouton « neutre », pas de troisième réponse : deux choix, toujours.

### Le tirage

Les cartes ne sortent pas au hasard. Chaque carte porte des **conditions** : jauge sous ou au-dessus d'un seuil, numéro de mandat minimum, jour minimum ou maximum, parcours du joueur, **drapeaux** posés par des choix précédents. Le moteur pioche parmi les cartes dont les conditions sont remplies, pondérées par un poids, sans montrer deux fois la même carte dans un mandat sauf si elle est marquée « répétable ». Certaines cartes sont **forcées** : elles sortent dès que leurs conditions sont remplies (suite d'une chaîne, cartes de parcours).

### Les chaînes

Une chaîne est une suite de cartes liées, espacées dans le mandat : la rumeur, l'article, le procès. Chaque carte de chaîne indique son rang et un délai minimum avant la suivante. Une chaîne peut se terminer différemment selon les réponses.

### L'élection du jour 100

Au jour 100, le résultat dépend du Peuple et de la Presse : réélu si leur moyenne dépasse 50, avec un écran d'affiche de campagne au portrait du joueur. Réélu, le mandat suivant est plus difficile (effets amplifiés, chaînes plus dures, cartes de second mandat). Battu, c'est une fin honorable.

### Ce qui reste entre deux mandats

Quelle que soit l'issue, on garde : les parcours débloqués, les exploits, les fins découvertes, les personnages rencontrés. Rien du mandat lui-même ne se reporte.

### Les exploits

Un exploit est un titre et une condition vérifiée à la fin d'un mandat. Exemples : tenir cent jours sans jamais faire baisser les Caisses, survivre à trois motions de censure, finir avec les quatre jauges au-dessus de 50, découvrir les huit fins. Les exploits sont exposés dans une collection.

## 4. Le joueur : les parcours

Au premier lancement, et à chaque nouvelle partie, le joueur choisit **qui il était avant** et écrit son nom. Le parcours fixe le portrait, le genre (donc « Madame la Présidente » ou « Monsieur le Président »), les jauges de départ, et débloque cinq à huit cartes personnelles.

Huit parcours à l'écran, quatre ouverts, quatre verrouillés avec la condition affichée :

| Parcours | Genre | Ouverture | Jauges de départ (P / A / C / Pr) |
|---|---|---|---|
| L'ancien général | H | dès le début | 40 / 70 / 50 / 40 |
| La professeure d'université | F | dès le début | 55 / 40 / 45 / 65 |
| La femme d'affaires | F | dès le début | 40 / 45 / 70 / 50 |
| Le syndicaliste | H | dès le début | 70 / 40 / 35 / 55 |
| La fille de l'ancien président | F | être réélu une fois | 50 / 60 / 60 / 35 |
| La star de la musique | H | finir un mandat avec Peuple ≥ 80 | 75 / 35 / 45 / 60 |
| L'ancien putschiste | H | perdre un mandat par Armée = 0 | 35 / 80 / 50 / 30 |
| La technocrate revenue de l'étranger | F | finir un mandat avec Caisses ≥ 80 | 40 / 45 / 65 / 55 |

Les jauges de départ sont un point de départ pour l'équilibrage, pas une règle figée.

## 5. Le contenu

### Fichiers

Quatre fichiers JSON dans `assets/contenu/`, lus au démarrage : `personnages.json`, `cartes.json`, `fins.json`, `exploits.json`. Plus `parcours.json`. Ajouter du contenu, c'est ajouter des entrées, jamais toucher au code.

### Une carte

```json
{
  "id": "general_solde_1",
  "personnage": "general",
  "humeur": "fache",
  "texte": "La solde des hommes a deux mois de retard. Je dis ça, je dis rien.",
  "gauche": { "libelle": "Qu'ils patientent", "effets": { "armee": -15, "caisses": 5 }, "drapeaux": ["solde_impayee"] },
  "droite": { "libelle": "On paie", "effets": { "armee": 10, "caisses": -15 } },
  "conditions": { "mandat_min": 1, "jour_min": 3, "caisses_max": 80 },
  "poids": 3,
  "chaine": null,
  "repetable": false
}
```

Règles d'écriture : texte ≤ 140 caractères ; libellés ≤ 18 caractères ; effets entre −20 et +20 ; un à trois effets par réponse ; le texte doit fonctionner avec un joueur homme ou femme ; les noms de personnes réelles, de partis réels et de pays réels sont interdits. Les gabarits `{nom}` et `{titre}` sont remplacés par le nom du joueur et « Monsieur le Président » ou « Madame la Présidente ».

### Un personnage

Un identifiant, un nom, un titre, et trois images : `neutre`, `content`, `fache`. Les images sont des JPEG en 720 × 960, environ 60 Ko chacune.

### Une fin

La jauge et le bout concernés (ou `election_perdue`, `election_gagnee`), un titre, un texte de deux ou trois phrases, une image. Huit fins de jauge, deux fins d'élection ; d'autres fins spéciales pourront être déclenchées par des drapeaux.

### Volume

| Étape | Cartes | Personnages | Parcours jouables | Fins |
|---|---|---|---|---|
| Prototype | 50 | 4 (un par jauge) | 2, plus 2 grisés | 4 |
| Lancement | 250 à 300 | 10 à 12 | 8 | 15 à 20 |

Les quatre personnages du prototype : le ministre des Finances (Caisses), le général (Armée), la rédactrice en chef (Presse), la marchande du grand marché (Peuple).

### Production des images

Génération sur OpenArt via l'outil intégré, modèle `nano-banana-2-lite`, mode texte vers image, format 3:4. Recette validée : buste, face caméra, lumière chaude venant de la gauche, décor flou derrière, « personne entièrement fictive, visage inventé », sans texte, logo ni drapeau d'un pays réel. Pour les trois humeurs d'un même personnage, on génère d'abord le portrait neutre, puis les variantes en image vers image à partir de ce portrait, pour garder le même visage. Budget : 40 à 60 images pour le lancement, essais compris, sur les crédits déjà payés.

### Relecture et contrôle

Chaque lot de cartes est relu par le propriétaire sur une page HTML schématique, personnage par personnage, chaînes affichées à la suite, effets visibles. Avant tout lot, un contrôle automatique (test Dart sur les fichiers de contenu) vérifie : identifiants uniques ; personnage, humeur, drapeaux et conditions qui existent ; deux réponses ; effets et longueurs dans les bornes ; aucune carte inaccessible (conditions impossibles à remplir) ; chaque chaîne complète et sans trou ; aucun nom interdit.

## 6. Architecture

Flutter, un seul code pour Android et iOS. Pas de serveur, pas de Supabase.

- **`lib/moteur/`** : Dart pur, aucune dépendance d'écran. Modèles (jauges, carte, parcours, état de partie), tirage, application d'une réponse, détection de fin, élection, exploits. Déterministe à graine fixée, pour pouvoir simuler des parties en test.
- **`lib/contenu/`** : chargement et validation des JSON.
- **`lib/ecrans/`** : accueil et choix du parcours, partie, fin de mandat, élection, collection d'exploits, réglages. La carte glissante reprend le geste du quiz de Palabre (archivé sous le tag `palabre-final`) : gauche et droite seulement, seuil à 35 % de la largeur.
- **`lib/sauvegarde/`** : sur le téléphone uniquement : partie en cours, déblocages, exploits, statistiques, achat « Sans pub ».
- **`lib/monetisation/`** : publicité (Google Mobile Ads, annonces non personnalisées) et achat intégré. Sans serveur, il n'y a pas d'interrupteur à distance : couper la publicité passe par une mise à jour de l'appli.
- État : Riverpod, comme Palabre.

Moments publicitaires : une vidéo récompensée proposée à la chute (« revenir trois jours en arrière », une fois par mandat), une interstitielle entre deux mandats, jamais pendant les cartes. L'achat « Sans pub » supprime les interstitielles et garde la vidéo récompensée, qui est un choix du joueur.

## 7. Tests et équilibrage

- Tests unitaires du moteur : tirage, conditions, effets bornés, fins, élection, exploits, chaînes.
- Test de contenu : le contrôle automatique du § 5 tourne dans `flutter test`.
- Tests de widget : le geste de carte, l'illumination des jauges, le choix du parcours, les verrous.
- **Simulation** : un test lance dix mille mandats avec des stratégies simples (toujours à gauche, toujours à droite, au hasard, « garder les jauges au centre ») et vérifie que la durée moyenne d'un mandat se situe entre 35 et 70 jours pour la stratégie au hasard, qu'aucune carte n'est jamais tirée, et qu'aucune fin n'est inatteignable. C'est l'outil d'équilibrage principal.
- Avant chaque commit : `flutter analyze` et `flutter test`. Chaque étape visible est installée sur le téléphone du propriétaire.

## 8. Étapes

1. **Squelette** : projet Flutter neuf dans le dépôt, identifiants repris, CI, build iOS et Android qui passent, sans contenu.
2. **Moteur** : modèles, tirage, fins, élection, simulation, sur un contenu de test.
3. **Prototype jouable** : 50 cartes, 4 personnages, 2 parcours, 4 fins, écrans de partie et de fin, sauvegarde. Installation sur téléphone.
4. **Progression** : parcours verrouillés, exploits, collection, second mandat.
5. **Monétisation** : publicité et achat « Sans pub », page de confidentialité, fiches des stores.
6. **Contenu de lancement** : 250 à 300 cartes par lots relus, 8 parcours, 15 à 20 fins, images.
7. **Test fermé** puis production.

## 9. Risques

- **Ressemblance** avec des personnes réelles : chaque portrait est vérifié avant intégration ; en cas de doute, on regénère.
- **Politique des stores** : pays et personnages imaginaires, aucune référence à un État réel, contenu classé tous publics avec humour léger.
- **Poids** : objectif 25 Mo installés au lancement ; images compressées ; pas de vidéo.
- **Équilibrage** : la simulation réduit le risque, mais seuls de vrais joueurs le règlent ; le test fermé sert à ça.
- **Répétition** : la mesure de référence est « combien de mandats avant de revoir une carte », suivie dans la simulation.
