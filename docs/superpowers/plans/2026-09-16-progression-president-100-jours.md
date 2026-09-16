# Progression — plan de réalisation

> **Pour les agents :** SOUS-COMPÉTENCE REQUISE : utiliser superpowers:subagent-driven-development ou superpowers:executing-plans, tâche par tâche. Les étapes utilisent des cases à cocher.

**But :** donner une raison de recommencer une partie. Ce qu'on accomplit reste acquis : des parcours se débloquent, des exploits se collectionnent, les fins découvertes se gardent, et une réélection ouvre un second mandat plus dur.

**Architecture :** une classe `Progression` immuable, gardée sur l'appareil à côté de la partie en cours ; des conditions **typées et lues depuis le contenu**, évaluées une seule fois en fin de mandat par une fonction pure `bilan(...)` ; les écrans ne font qu'afficher ce qu'elle rend.

**Pile technique :** identique au prototype — Flutter 3.47, Dart pur pour le moteur, shared_preferences, aucun serveur.

**Spec :** `docs/superpowers/specs/2026-09-16-president-100-jours-design.md` (§ « Ce qui reste entre deux mandats », « Les exploits », « Le joueur : les parcours »)

**Plan précédent :** `docs/superpowers/plans/2026-09-16-prototype-president-100-jours.md` — le prototype est livré, 94 tests au vert.

## Contraintes générales

- Elles sont **toutes** celles du plan du prototype : français partout sans accents dans les identifiants ; quatre jauges `peuple`, `armee`, `caisses`, `presse` de 0 à 100 ; pays et personnages imaginaires ; deux réponses par carte, jamais de chiffre de jauge à l'écran ; aucun appel réseau ; `flutter analyze` sans avertissement et `flutter test` au vert avant chaque commit ; chaque commit se termine par `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- **Le contenu ne code rien.** Une condition de déblocage ou d'exploit s'écrit dans le JSON, jamais dans Dart. Ajouter un exploit ne doit pas demander de toucher au code.
- **La progression ne se perd pas.** Elle survit à une chute, à une désinstallation du jeu en cours de mandat, à une sauvegarde de partie abîmée. Elle est écrite à chaque fin de mandat, jamais pendant.
- **Rien ne se déverrouille en douce.** Un déblocage est annoncé au joueur sur l'écran de fin ; sinon il ne le verra jamais.
- Durée du mandat : `dureeMandatPrototype` vaut 30 et ne change pas dans ce plan.

## Trois décisions déjà prises

1. **Le second mandat est plus dur par amplification des effets** : tous les effets d'une réponse sont multipliés par 1,25 au mandat 2, par 1,5 au mandat 3 et au-delà, arrondis à l'entier le plus proche, et toujours bornés à ±20 avant d'être appliqués. On ne crée pas de cartes propres au second mandat : le mécanisme `mandat_min` existe déjà pour ça et servira au contenu de lancement.
2. **Les conditions sont typées, pas scriptées** : un petit jeu de champs (`jauges_min`, `jauges_max`, `jours_min`, `mandat_min`, `fin`, `drapeaux_requis`, `drapeaux_interdits`) suffit aux huit parcours et aux exploits de la spec. Pas de mini-langage.
3. **Une seule collection, un seul écran** : exploits et fins découvertes vivent dans le même écran, atteint depuis l'accueil. Les fins non découvertes s'y affichent en silhouette, sans leur titre : c'est ce qui donne envie de les chercher.

## Structure des fichiers

```
lib/moteur/
  condition.dart        Condition : lecture JSON et évaluation contre un bilan de fin de mandat
  progression.dart      Progression (immuable) et bilan() : ce qu'un mandat vient de débloquer
lib/contenu/
  chargement.dart       (modifié) charge exploits.json
  validation.dart       (modifié) contrôle les exploits et les conditions typées
lib/sauvegarde/
  sauvegarde.dart       (modifié) lit et écrit la progression, clé « progression »
lib/ecrans/
  session.dart          (modifié) amplification au mandat 2+, bilan en fin de mandat, second mandat
  fin_ecran.dart        (modifié) annonce les exploits gagnés et les parcours débloqués
  accueil.dart          (modifié) parcours débloqués jouables, accès à la collection
  collection_ecran.dart la collection : exploits et fins
assets/contenu/
  exploits.json         les exploits, avec leur condition
  parcours.json         (modifié) chaque parcours verrouillé reçoit sa condition typée

test/moteur/condition_test.dart, test/moteur/progression_test.dart,
test/ecrans/collection_test.dart, test/progression_sauvegarde_test.dart
```

---

### Tâche 1 : Les conditions typées

**Fichiers :** créer `lib/moteur/condition.dart` ; test `test/moteur/condition_test.dart`

**Interfaces :**
- Consomme : `Jauge`, `Jauges`.
- Produit :
  - `class BilanMandat { Jauges jauges; int jour; int mandat; String? finId; Set<String> drapeaux; String parcours; }`
  - `class Condition { Map<Jauge,int> jaugesMin; Map<Jauge,int> jaugesMax; int joursMin; int mandatMin; String? fin; List<String> drapeauxRequis; List<String> drapeauxInterdits; Condition.depuisJson(Map<String,dynamic>?); bool remplie(BilanMandat b); }`

Champs JSON, mêmes noms que les conditions de cartes là où c'est le même sens : `<jauge>_min`, `<jauge>_max`, `jours_min`, `mandat_min`, `fin`, `drapeaux_requis`, `drapeaux_interdits`. Une condition vide est toujours remplie.

- [ ] **Étape 1 : le test qui échoue** — couvre : condition vide remplie ; `peuple_min` satisfait et non satisfait ; `jours_min` ; `mandat_min` ; `fin` exacte et fin différente ; drapeau requis et drapeau interdit ; combinaison de deux champs dont un seul est satisfait (donc non remplie). Écris-le avec un `BilanMandat` fabriqué par une fonction d'aide, comme `etat()` dans `test/moteur/etat_partie_test.dart`.
- [ ] **Étape 2 : l'implémentation.** Reprends la forme de `Conditions.depuisJson` (`lib/moteur/modeles.dart`) : boucle sur `Jauge.values` pour lire `<jauge>_min` / `<jauge>_max`, `(x as num).toInt()`, listes par défaut vides. `remplie` suit la forme de l'extension `ConditionsSurEtat` (`lib/moteur/etat_partie.dart`) : une série de tests qui rendent `false` au premier manquement.
- [ ] **Étape 3 :** `flutter analyze`, `flutter test`, commit.

---

### Tâche 2 : La progression et le bilan de fin de mandat

**Fichiers :** créer `lib/moteur/progression.dart` ; test `test/moteur/progression_test.dart`

**Interfaces :**
- Consomme : `Condition`, `BilanMandat` (tâche 1) ; `Parcours`, `Fin` (modeles.dart) ; `Contenu` (chargement.dart).
- Produit :
  - `class Exploit { String id; String titre; String description; Condition condition; Exploit.depuisJson(Map<String,dynamic>); }`
  - `class Progression { Set<String> parcoursDebloques; Set<String> exploits; Set<String> finsDecouvertes; int mandatsJoues; int meilleurJour; const Progression({...}) ; Progression.neuve(); Progression copie({...}); }`
  - `class Nouveautes { List<Exploit> exploits; List<Parcours> parcours; bool finInedite; bool get rienDeNeuf; }`
  - `({Progression progression, Nouveautes nouveautes}) bilan({required Progression avant, required BilanMandat mandat, required Contenu contenu})`

`bilan` est **pure** : elle ne lit ni n'écrit rien. Elle rend la progression mise à jour et la liste de ce qui vient d'être gagné — un exploit déjà obtenu n'est pas rendu une deuxième fois, un parcours déjà débloqué non plus.

- [ ] **Étape 1 : le test qui échoue.** Couvre : un exploit dont la condition est remplie entre dans la progression et figure dans les nouveautés ; le même exploit au mandat suivant n'est plus une nouveauté ; un parcours verrouillé dont la condition est remplie se débloque et est annoncé ; un parcours sans condition typée ne se débloque jamais par bilan ; la fin atteinte entre dans `finsDecouvertes` et `finInedite` vaut vrai la première fois seulement ; `mandatsJoues` s'incrémente ; `meilleurJour` garde le maximum. Fabrique le `Contenu` avec `Contenu.depuisChaines`, comme dans `test/contenu/validation_test.dart`.
- [ ] **Étape 2 : l'implémentation.** `Progression` immuable, `copie` sur le modèle de `EtatPartie.copie`. Dans `bilan`, parcourir `contenu.exploits` puis `contenu.parcours`, ne retenir que ce qui n'est pas déjà acquis et dont la `Condition` est remplie.
- [ ] **Étape 3 :** analyse, tests, commit.

---

### Tâche 3 : Charger et contrôler les exploits et les conditions

**Fichiers :** modifier `lib/contenu/chargement.dart`, `lib/contenu/validation.dart` ; créer `assets/contenu/exploits.json` ; modifier `assets/contenu/parcours.json` ; tests dans `test/contenu/validation_test.dart`

- [ ] **Étape 1 : le test qui échoue.** Ajoute à `validation_test.dart` : deux exploits de même identifiant sont signalés ; un exploit sans titre ou sans condition est signalé ; une condition qui ne peut jamais être remplie (`peuple_min` supérieur à `peuple_max`, ou `jours_min` supérieur à la durée du mandat) est signalée ; une condition citant une fin qui n'existe pas dans `fins.json` est signalée ; un parcours verrouillé **sans condition typée** est signalé, parce qu'il resterait verrouillé pour toujours ; un mot interdit dans le titre ou la description d'un exploit est signalé.
- [ ] **Étape 2 : le chargement.** `Contenu` reçoit `List<Exploit> exploits` ; `depuisChaines` prend un paramètre nommé `exploits` avec `''` par défaut valant liste vide **pour ne pas casser les appels existants des tests**, et `depuisAssets` lit `assets/contenu/exploits.json`. Déclare le fichier dans `pubspec.yaml` s'il ne l'est pas déjà par le dossier.
- [ ] **Étape 3 : le contrôle**, dans `valide`, sur le modèle des règles existantes, messages de la même forme (`exploit <id> : …`, `parcours <id> : …`).
- [ ] **Étape 4 : le contenu.** Écris `assets/contenu/exploits.json` — huit exploits, chacun avec `id`, `titre`, `description` et `condition` :
  - tenir jusqu'à l'élection (`jours_min` 30) ;
  - être réélu (`fin` `election_gagnee`) ;
  - finir avec les quatre jauges au-dessus de 50 ;
  - finir avec les caisses au-dessus de 80 ;
  - finir avec le peuple au-dessus de 80 ;
  - se faire renverser par l'armée (`fin` `armee_bas`) ;
  - publier l'affaire des 4×4 (`drapeaux_requis` `rumeur_4x4`, et `drapeaux_interdits` `photo_etouffee`) ;
  - atteindre un deuxième mandat (`mandat_min` 2).
  Puis donne leur condition typée aux deux parcours verrouillés de `parcours.json`, à côté de leur texte : `musicienne` → `peuple_min` 80 ; `putschiste` → `fin` `armee_bas`. Le texte affiché ne change pas.
- [ ] **Étape 5 :** `flutter test test/contenu/`, analyse, commit.

---

### Tâche 4 : Garder la progression sur l'appareil

**Fichiers :** modifier `lib/sauvegarde/sauvegarde.dart` ; test `test/progression_sauvegarde_test.dart`

**Interfaces :** `static Future<void> enregistreProgression(Progression p)`, `static Future<Progression> lisProgression()` (rend `Progression.neuve()` quand il n'y a rien ou que c'est illisible), plus `Map<String,dynamic> progressionVersJson(Progression)` et `Progression progressionDepuisJson(Map<String,dynamic>)`. Clé `progression`, distincte de `partie_en_cours`.

- [ ] **Étape 1 : le test qui échoue** : sans rien d'enregistré on obtient une progression neuve ; un aller-retour complet conserve les quatre ensembles et les deux compteurs ; une valeur illisible rend une progression neuve **sans effacer la partie en cours** ; effacer la partie en cours ne touche pas à la progression.
- [ ] **Étape 2 : l'implémentation**, exactement sur le modèle des méthodes existantes, `try/catch` compris : une progression qu'on n'arrive pas à lire ne doit jamais empêcher de jouer.
- [ ] **Étape 3 :** analyse, tests, commit.

---

### Tâche 5 : Brancher la progression dans la partie

**Fichiers :** modifier `lib/ecrans/session.dart` ; tests dans `test/ecrans/partie_ecran_test.dart` et un nouveau `test/ecrans/session_progression_test.dart`

Ce que la session doit faire en plus :
- exposer la progression courante (chargée au démarrage de l'application) et les `Nouveautes` du mandat qui vient de finir ;
- **amplifier les effets au-delà du premier mandat** : au moment d'appliquer une réponse, multiplier chaque effet par 1,25 au mandat 2, 1,5 au mandat 3 et plus, arrondir à l'entier le plus proche, borner à ±20 ;
- appeler `bilan(...)` **une seule fois**, au moment où le mandat se termine, enregistrer la progression, et garder les nouveautés pour l'écran de fin ;
- proposer d'enchaîner un second mandat après une réélection : `mandatSuivant()` repart au jour 1, mandat + 1, jauges remises au départ du parcours, drapeaux et cartes vues remis à zéro.

- [ ] **Étape 1 : les tests qui échouent.** Au moins : un effet de −12 devient −15 au mandat 2 ; le bilan n'est calculé qu'une fois, même si l'écran se reconstruit ; après une réélection, `mandatSuivant()` rend un état au jour 1 du mandat 2 avec les jauges de départ du parcours ; les nouveautés sont vides quand rien n'a été gagné.
- [ ] **Étape 2 : l'implémentation.** L'amplification est une fonction pure dans `lib/moteur/partie.dart` — `Map<Jauge,int> amplifie(Map<Jauge,int> effets, int mandat)` — testée à part, et `repond` reçoit le mandat depuis l'état. Garde `repond` compatible avec ses tests existants (mandat 1 = aucun changement).
- [ ] **Étape 3 :** analyse, suite complète, commit.

---

### Tâche 6 : L'écran de fin annonce ce qu'on a gagné

**Fichiers :** modifier `lib/ecrans/fin_ecran.dart` ; tests dans `test/ecrans/fin_ecran_test.dart`

Sous le texte de la fin et les jours tenus, une zone « Vous avez débloqué » : un exploit par ligne avec son titre et sa description, et un parcours débloqué par ligne avec son nom. Rien du tout quand il n'y a rien, sans espace vide laissé. Après une réélection, un second bouton « Continuer, deuxième mandat » à côté de « Reprendre ses fonctions ».

- [ ] **Étape 1 : les tests qui échouent** : un exploit gagné s'affiche ; deux exploits s'affichent tous les deux ; rien ne s'affiche quand il n'y a aucune nouveauté ; le bouton de second mandat n'apparaît qu'après une réélection et appelle `mandatSuivant()`.
- [ ] **Étape 2 : l'implémentation**, en suivant le motif de test du fichier (`ProviderContainer` monté à la main, session préparée avant le premier rendu).
- [ ] **Étape 3 :** analyse, tests, commit.

---

### Tâche 7 : La collection

**Fichiers :** créer `lib/ecrans/collection_ecran.dart` ; modifier `lib/ecrans/accueil.dart` ; test `test/ecrans/collection_test.dart`

L'écran liste les exploits — obtenus en clair avec leur description, les autres en grisé avec leur seule description comme indice — puis les fins : titre en clair si découverte, sinon une ligne « Fin inconnue » avec la jauge concernée. En bas, une ligne de comptage : « 3 exploits sur 8 · 2 fins sur 10 ». L'accueil y mène par un bouton discret, et n'affiche plus comme verrouillés les parcours que la progression a débloqués.

- [ ] **Étape 1 : les tests qui échouent** : un exploit obtenu apparaît avec son titre, un exploit non obtenu n'affiche pas son titre ; une fin découverte affiche son titre, une fin inconnue ne le montre pas ; le comptage est juste ; depuis l'accueil, un parcours débloqué par la progression est sélectionnable.
- [ ] **Étape 2 : l'implémentation.** L'accueil lit la progression au même endroit qu'il relit la sauvegarde (`_relisSauvegarde`), pour qu'un retour de partie mette la liste à jour.
- [ ] **Étape 3 :** analyse, suite complète, commit, **et une installation sur le simulateur** pour vérifier de l'œil : gagner un exploit, le voir annoncé, le retrouver dans la collection.

---

## Ce que ce plan ne couvre pas

Les quatre parcours restants de la spec et leurs cartes personnelles, les portraits des parcours, la publicité et l'achat « Sans pub », les 250 à 300 cartes du lancement, la durée de mandat à 100 jours.
