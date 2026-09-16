# Audit du code — Président pour 100 jours

16 septembre 2026, sur `main` à `aed0285`. Aucun fichier du dépôt n'a été modifié.

**État de départ** : `flutter analyze` → *No issues found*. `flutter test` → **204 tests, tous au vert**.

Les tests de preuve sont jetables et vivent hors du dépôt, dans
`/private/tmp/claude-501/-Users-jeanperraudeau-Palabre/b949f525-b723-40a6-a721-62008fa7b30a/scratchpad/` :
`audit_moteur_test.dart`, `audit_ecran_test.dart`, `audit_progression_test.dart`,
`audit_marathon_test.dart`, `audit_paquet_test.dart`. Ils se lancent avec
`flutter test <chemin>` depuis la racine du dépôt.

Récapitulatif : **1 bloquant, 8 importants, 16 mineurs.**

---

## 1. Bogues prouvés

### 1.1 — BLOQUANT — Une carte répétable tirée deux jours de suite fige la partie

`lib/ecrans/partie_ecran.dart:98` — `CarteGlissante(key: ValueKey(carte.id), …)`
`lib/ecrans/carte_glissante.dart:58,123` — `_sorti` passe à `true` au départ de la carte et n'est jamais remis à `false`.

Scénario : le tirage rend deux jours de suite la même carte `repetable`
(`lib/moteur/tirage.dart:10` ne l'exclut pas, et c'est voulu). L'identifiant
ne change pas, donc la clé ne change pas, donc Flutter **réutilise le même
`State`** : il est resté « sorti », `_dx` vaut encore une largeur et demie, et
`_bouge`/`_lache` sortent immédiatement sur `if (_sorti) return`. La carte du
jour 2 est dessinée hors de l'écran et plus aucun geste ne répond. Le jeu est
mort, il faut tuer l'application (la sauvegarde, elle, est bonne).

Preuve : `audit_ecran_test.dart`, test « BOGUE 6 ». La carte du jour 2 est
mesurée en `x = 1339` sur un écran de 800 de large, et un second geste laisse
le compteur sur `JOUR 2`.

Latent aujourd'hui : `assets/contenu/cartes.json` ne contient aucune carte
répétable. Mais le moteur, la validation et deux tests du dépôt
(`test/moteur/tirage_test.dart`, `test/simulation_test.dart`) la déclarent
légitime : un seul `"repetable": true` dans un lot de cartes suffit à
l'activer. Correctif : clé de carte portant aussi le jour
(`ValueKey('${etat.jour}_${carte.id}')`), ou remise à zéro de `_sorti` dans
`didUpdateWidget`.

### 1.2 — IMPORTANT — Le second mandat frappe *moins* fort que le premier

`lib/moteur/partie.dart:72-78` — `effetsReels` = `selonAtout(amplifie(selonRegime(…)))`.

`selonRegime` (ligne 33) n'est **pas** borné : à un bout de l'axe, un effet de
+20 sur une jauge favorisée devient +30. `amplifie` (ligne 13), lui, borne à
±20 — mais seulement quand `mandat > 1`, puisqu'il rend `effets` tel quel au
mandat 1. Résultat : au mandat 1 le joueur encaisse 30 (hors des bornes −20/+20
que la spec annonce et que la validation impose au contenu), et au mandat 2,
censé être plus dur, il n'encaisse plus que 20.

Preuve : `audit_moteur_test.dart`, test « BOGUE 2 » :
`effetsReels(effets: {caisses: 20}, style: 100, mandat: 1)` → **30**,
`mandat: 2` → **20**, `mandat: 3` → **20**.

Ordre d'application, pour répondre à la question posée : régime → mandat →
atout. L'ordre lui-même est cohérent et testé
(`test/moteur/regime_test.dart`, `test/moteur/partie_test.dart`), c'est le
bornage qui est mal placé. Correctif : borner en sortie de `effetsReels`, une
fois pour toutes, plutôt que dans `amplifie`.

### 1.3 — IMPORTANT — Un mandat qui finit avant que la progression ait été lue efface tout

`lib/ecrans/session.dart:124` — `final avant = ref.read(progressionProvider).value ?? Progression.neuve();`

Si personne n'a encore écouté `progressionProvider`, `.value` est `null`, le
bilan repart d'une progression **neuve**, et la ligne 138
(`Sauvegarde.enregistreProgression`) l'écrit sur le disque. Parcours
débloqués, exploits, fins découvertes, compteurs : tout disparaît, sans un
mot.

Preuve : `audit_progression_test.dart`, test « BOGUE 11 ». Une progression de
2 parcours, 2 exploits et 7 mandats est réduite à un exploit et un mandat.
Le test « VÉRIF 12 » montre que lire le provider d'abord suffit à tout sauver :
c'est bien l'absence de lecture qui détruit.

Aujourd'hui l'accueil (`accueil.dart:158`) observe toujours le provider avant
qu'on puisse jouer, donc le chemin n'est pas atteignable — mais rien ne le
garantit, aucun test ne le protège, et le jour où une partie démarrera depuis
un autre écran (notification, raccourci, écran de fin retravaillé) les joueurs
perdront tout. Correctif : attendre la progression (`await ref.read(progressionProvider.future)`)
ou relire le disque plutôt que de prendre `Progression.neuve()` pour un défaut
acceptable.

### 1.4 — IMPORTANT — Une progression à laquelle il manque un compteur est effacée en entier

`lib/sauvegarde/sauvegarde.dart:154-160` — `progressionDepuisJson` lit les trois
listes avec `?? const []` mais `mandats_joues` et `meilleur_jour` avec un cast
non nullable. Un JSON valide sans ces deux champs lève, `lisProgression`
(ligne 94-99) attrape, **supprime la clé** et rend une progression neuve.

Preuve : `audit_moteur_test.dart`, test « BOGUE 3 ».

C'est exactement le cas « ancien format de sauvegarde » de la question : une
progression écrite par une version antérieure à ces deux compteurs est jetée
avec tous les déblocages, alors que trois champs sur cinq étaient lisibles.
Correctif : `((j['mandats_joues'] as num?) ?? 0).toInt()`, et ne jamais
supprimer ce qui est partiellement lisible.

### 1.5 — IMPORTANT — Les conditions en jours tombent un jour trop tôt

`lib/moteur/condition.dart:102` — `if (b.jour < joursMin) return false;` compare
au jour **non joué**, alors que `fin_ecran.dart:60` affiche `jour - 1` comme
nombre de jours tenus.

Conséquence sur le contenu livré : « Le marathon du pouvoir », dont la
description est « rester en poste jusqu'au dernier jour du mandat, sans jamais
flancher » et la condition `jours_min: 100`, se décroche en **s'effondrant au
99ᵉ jour** — l'écran annonce alors « Vous avez tenu 99 jours » et « Vous avez
débloqué : Le marathon du pouvoir ».

Preuves : `audit_moteur_test.dart` test « BOGUE 4 » (mécanisme) et
`audit_marathon_test.dart` test « BOGUE 4 bis » (sur le contenu réel, avec en
prime la fin `armee_bas`, donc une chute).

### 1.6 — IMPORTANT — Un paquet épuisé fabrique un mandat fantôme, exploits compris

`lib/ecrans/session.dart:102-111` — plus aucune carte jouable ⇒ le mandat est
clos « comme une élection », avec la règle `(peuple + presse) / 2 > 50`.

Trois problèmes en un : l'écran de fin annonce **RÉÉLU** pour ce qui est une
panne de contenu ; le bilan est pris et compte un mandat de plus ; et les
exploits de jauge sont décrochés sur les **jauges de départ**, sans qu'un seul
jour ait été joué.

Preuve : `audit_ecran_test.dart`, test « BOGUE 9 » : `demarre()` sur un paquet
dont la seule carte exige `jour_min: 50` rend aussitôt `terminee`,
`electionGagnee`, `jour: 1` (l'écran dira « Vous avez tenu 0 jours ») et
l'exploit « caisses ≥ 80 ».

Mesure rassurante sur le contenu livré (`audit_paquet_test.dart`) : sur
**16 000 mandats** (10 parcours × 4 stratégies × 400), aucun `paquetEpuise`.
296 cartes pour 100 jours suffisent largement. Le risque est donc celui d'un
contenu futur plus conditionné, pas d'aujourd'hui.

### 1.7 — IMPORTANT — `mandatSuivant()` peut enchaîner les mandats sans qu'on joue

`lib/ecrans/session.dart:84-96`. La garde `s.denouement?.type != electionGagnee`
protège bien contre le double appel ordinaire (le mandat 2 démarre, le
dénouement disparaît). Mais si le mandat qui démarre se termine aussitôt (cas
1.6), le nouveau dénouement est de nouveau `electionGagnee` et un second appui
part au mandat 3, un troisième au mandat 4 — chacun comptant un mandat de plus
et décrochant « La longévité du pouvoir ».

Preuve : `audit_ecran_test.dart`, test « BOGUE 10 » : mandat 2, 3, 4 en trois
appels, zéro carte jouée.

### 1.8 — IMPORTANT — Rien ne borne le nom du joueur

`lib/ecrans/accueil.dart:390-394` — `TextField` sans `maxLength`, sans
`inputFormatters`. Le nom part tel quel dans `EtatPartie.nomJoueur`, dans la
sauvegarde, et dans le texte des cartes via `habille`
(`session.dart:148`).

Preuve : `audit_ecran_test.dart`, test « BOGUE 7 » : un nom de 200 caractères
arrive intact sur la carte. Il n'y a ni `maxLines` ni `overflow` sur le texte de
carte (`partie_ecran.dart:221`) : le bloc de texte monte et se fait couper par
le `ClipRRect`, le portrait disparaît sous le texte.

C'est aussi ce qui rend la mesure de `validation.dart:19-20` fausse : elle
mesure les textes contre `_nomLePlusLong = 'Rakotobearison'` (14 caractères),
ce qui n'engage que les joueurs qui veulent bien. Correctif : `maxLength` à 20
ou 24 sur le champ, et la validation reste juste.

### 1.9 — MINEUR — Un nom contenant `{titre}` est resubstitué

`lib/ecrans/session.dart:148` — `texte.replaceAll('{nom}', nom).replaceAll('{titre}', titre)`.
Un joueur nommé `{titre}` voit « Bonjour Madame la Présidente. » là où la carte
disait `{nom}`. Preuve : `audit_ecran_test.dart`, test « BOGUE 8 ». Sans
gravité, mais une seule passe de remplacement l'éviterait.

### 1.10 — MINEUR — `depuisJson` ne borne ni ne vérifie rien

`lib/sauvegarde/sauvegarde.dart:124-144`. Une sauvegarde au bon **format** mais
aux valeurs absurdes est acceptée telle quelle : `peuple: 900`, `jour: -5`,
`style: 4000`, `parcours` inexistant. Preuve : `audit_moteur_test.dart`, test
« BOGUE 5 ». Le moteur répond par une chute immédiate — donc, combiné à 1.3
et 1.6, un fichier de préférences trafiqué donne un mandat terminé d'office,
avec bilan pris. Correctif : `clamp(0, 100)` sur les jauges, `jour >= 1`,
`mandat >= 1`, et refuser la sauvegarde dont le parcours n'existe plus (auquel
cas `mandatSuivant`, `session.dart:87`, déréférence un `!` sur `null`).

### 1.11 — MINEUR — Un effet écrit à 0 devient −1

`lib/moteur/partie.dart:49` et `partie.dart:65` : le garde-fou « un effet ne
disparaît jamais » transforme `0` en `−1` (car `e.value > 0` est faux).
Preuve : `audit_moteur_test.dart`, « VÉRIF 6 ». Inoffensif aujourd'hui, la
validation refusant les effets nuls (`validation.dart:83`), mais le garde-fou
devrait laisser passer zéro.

### 1.12 — Déjà corrigé pendant l'audit

Le déblocage par `fin: election_gagnee` ne tombait que dans la fourchette de
régime 31–71, les variantes `election_gagnee_franche` et `election_gagnee_seul`
ne débloquant ni les deux parcours ni l'exploit « Un second serment ». Corrigé
par `aed0285` (notion de famille de fin) pendant que cet audit tournait ;
vérifié ici (`audit_famille_test.dart`) : à style 20 comme à style 80, les
déblocages tombent de nouveau.

Reste une fragilité **mineure** : `BilanMandat` (`condition.dart:8-16`) accepte
un `finId` sans `finFamille`, et le bogue revient en silence chez qui oublie le
second. Passer la `Fin` et calculer `famille` dans le constructeur rendrait
l'oubli impossible.

---

## 2. Bogues probables, non prouvés

- **Redémarrer l'application retire une carte au sort.** `session.dart:112`
  enregistre l'état *avant* la réponse, et `reprend` (ligne 60) réamorce
  `Random` sur l'horloge. Une carte qu'on n'aime pas se change donc en tuant
  l'application. Certain par lecture, non mesuré côté joueur ; sans gravité
  tant que le joueur ne voit pas les effets avant de glisser, mais la graine
  mériterait d'être persistée avec la partie. *Mineur.*
- **Le `Random` d'une partie n'est pas reproductible**, et c'est voulu :
  `graine` n'est fournie qu'en test (`session.dart:53,60`). Conforme à la
  spec (« déterministe à graine fixée »). Rien à corriger.
- **Course entre `Sauvegarde.efface()` (session.dart:121) et
  `Sauvegarde.enregistre()` (ligne 112)**, tous deux lancés sans `await`. Les
  deux suivent la même chaîne d'attentes, donc l'ordre FIFO des microtâches
  les sérialise correctement dans la pratique ; je n'ai pas trouvé
  d'ordonnancement qui les inverse, mais rien dans le code ne le garantit non
  plus. *Mineur.*
- **Deux chaînes qui partagent un drapeau** : sans effet, les drapeaux étant
  globaux au mandat et l'avancement par chaîne. Deux chaînes qui partageraient
  un **identifiant** sont bien attrapées par le contrôle de rangs
  (`validation.dart:198-204`). En revanche, une chaîne dont le maillon 2 exige
  un drapeau que seul le maillon 3 pose n'est détectée par rien : la chaîne
  s'arrête au milieu, sans erreur. *Mineur, test de contenu manquant.*
- **Régime à exactement 50** : `selonRegime` rend les effets inchangés
  (`partie.dart:35`), c'est le neutre documenté. **Élection à moyenne exactement
  50** : perdue (`moyenne > 50`), conforme à la spec (« dépasse 50 »), et la
  règle est écrite deux fois — `denouement.dart:35` et `session.dart:106` —
  avec la même valeur. À garder synchronisées ou, mieux, à factoriser.

---

## 3. Divergences moteur / écran

**Les chiffres, eux, ne divergent pas.** `partie_ecran.dart:68-73` et
`session.dart:67-72` appellent tous deux `effetsReels` avec le même `style`, le
même `mandat` et le même atout, tirés du même `session.etat` — et `repond`
applique le régime *avant* de déplacer l'axe, comme l'aperçu. Le côté répondu
est le même que le côté annoncé : `carte_glissante.dart:99` et `:121` lisent
tous deux le signe de `_dx`. C'est la partie la mieux tenue du code.

Trois écarts d'affichage subsistent :

- **MINEUR** — `partie_ecran.dart:462` borne la barre fantôme
  (`(valeur + effet).clamp(0, 100)`) mais `partie_ecran.dart:540` affiche le
  chiffre brut. À 95 de peuple, une réponse à +20 dessine un fantôme de 5 points
  et écrit « +20 ». Les deux moitiés du même widget se contredisent.
- **MINEUR** — conséquence de 1.2 : au mandat 1, à un bout de l'axe, le delta
  affiché peut dire « +30 », au-delà des bornes annoncées par la spec.
- **MINEUR** — l'aperçu s'éteint dès le départ de la carte
  (`carte_glissante.dart:124`, `_annonce(null)`), donc les jauges redeviennent
  ternes pendant les 260 ms de sortie. Volontaire, mais c'est le moment où le
  joueur cherche justement à vérifier ce qu'il vient de faire.

---

## 4. Persistance

Ce qui marche : deux clés indépendantes, chaque méthode avale ses erreurs, une
sauvegarde illisible est jetée sans bloquer la partie, `style` est bien
sauvegardé et relu avec un défaut (`sauvegarde.dart:138`) — les tests
`test/sauvegarde_test.dart` et `test/progression_sauvegarde_test.dart` le
couvrent.

- **IMPORTANT** — la progression partielle est détruite au lieu d'être réparée :
  voir 1.4.
- **IMPORTANT** — la progression peut être écrasée par une progression neuve :
  voir 1.3.
- **MINEUR** — les valeurs relues ne sont pas bornées : voir 1.10.
- **MINEUR** — **l'atout n'a pas à être sauvegardé** (il se relit du contenu par
  `parcours`), et c'est le bon choix : il suit les rééquilibrages. En revanche
  **rien n'identifie la version du contenu** : une partie reprise après une mise
  à jour peut citer dans `vues` et `chaines_rang` des cartes qui n'existent
  plus, et repartir sur des jauges de départ modifiées au mandat suivant. Rien
  ne plante, mais une chaîne entamée peut rester coincée à mi-parcours.
- **MINEUR** — ce qui n'est pas persisté et devrait l'être : **la graine du
  tirage** (voir §2) et **la carte du jour**. Tuer l'application pendant la
  sortie d'une carte est en revanche propre : `whenComplete` sur un
  `TickerFuture` annulé ne se déclenche pas, la réponse n'est donc jamais
  appliquée à moitié, et l'état enregistré est bien celui d'avant la carte.
- `intro_vue` répond « déjà vue » quand le stockage est
  indisponible (`sauvegarde.dart:65`) : bon réflexe, documenté.
- L'achat « Sans pub » de la spec n'est pas encore persisté, mais
  `lib/monetisation/` n'existe pas non plus : hors périmètre à ce stade.

---

## 5. Performance et fuites

- **IMPORTANT — les portraits.** Les 33 portraits de personnages et les 10
  portraits de parcours sont des JPEG **896 × 1200**, soit **4,3 Mo décodés
  chacun** : 142 Mo pour les seuls personnages, 196 Mo pour l'ensemble des
  images. Le cache image de Flutter est plafonné à 100 Mio : au fil des cartes
  il évince et redécode en boucle, ce qui sur un téléphone d'entrée de gamme
  Android se voit (saccade à l'apparition d'une carte) et se sent (pression
  GC). Aucun des six `Image.asset` du projet ne passe `cacheWidth`
  (`partie_ecran.dart:195`, `accueil.dart:455,491,766`, `fin_ecran.dart:68`,
  `intro_ecran.dart:66`). Le cas le plus criant est la vignette de parcours
  (`accueil.dart:766`) : elle décode 896 × 1200 pour afficher 52 × 64.
  Correctif : `cacheWidth` proportionné à l'usage. Les fichiers eux-mêmes sont
  légers (3,1 Mo au total), l'objectif des 25 Mo installés est tenu.
- **MINEUR** — aucun `precacheImage` : le portrait de la carte suivante n'est
  décodé qu'au moment où elle arrive, juste après la sortie de la précédente.
- **MINEUR** — `_LigneJauges` (`partie_ecran.dart:392`) : l'`AnimatedBuilder`
  n'utilise pas son paramètre `child`, donc les quatre `_Jauge` — chacune avec
  son `LayoutBuilder` et ses deux `AnimatedContainer` — sont reconstruites à
  chaque image du battement, c'est-à-dire en continu dès qu'une jauge passe
  sous 15 ou au-dessus de 85, soit une bonne partie d'un mandat tendu. La
  pulsation ne sert qu'à l'opacité d'une couleur : un `AnimatedBuilder` autour
  du seul remplissage, ou une `ValueListenableBuilder` par jauge, suffirait.
- **MINEUR** — le `LayoutBuilder` de chaque jauge (`partie_ecran.dart:458`) et
  celui de l'axe (`:272`) sont corrects sur le principe (ils convertissent une
  valeur 0–100 en pixels), mais ils créent un `relayoutBoundary` par jauge
  reconstruit à chaque image du fait du point précédent. Une
  `FractionallySizedBox` ou un `Align(widthFactor:)` s'en passerait.
- **Rien à redire sur les disposals** : `_doublure`, `_battement`, `_anim`,
  `_nom`, `_page` (accueil et intro), `_defilement` sont tous disposés, et le
  battement s'arrête quand plus aucune jauge n'est au bord
  (`partie_ecran.dart:361-368`). Je n'ai trouvé aucune fuite.

---

## 6. Code mort et restes

- **MINEUR** — `outils/apercu_logos.dart` : reste de session, et il pointe en
  dur (`ligne 9`) vers un répertoire de travail d'une session Claude qui
  n'existe plus. À supprimer.
- **MINEUR** — `lib/contenu/validation.dart:241-245` : `clesFins` est construit
  puis jamais lu. Cinq lignes mortes.
- **MINEUR** — `lib/app.dart:13` : `title: 'Palabre'`. C'est le nom que le
  sélecteur de tâches d'Android affiche.
- **MINEUR** — `Couleurs.trait` (`theme.dart:29`) n'est utilisé nulle part.
  `Textes.rappel` ne l'est qu'une fois, avec un `copyWith` qui remplace sa
  couleur (`intro_ecran.dart:74`) : le style ne sert donc à rien de ce qu'il
  déclare.
- **MINEUR** — `Contenu.exploits` porte encore un défaut `const []` justifié
  par « ne pas casser les appels existants » (`chargement.dart:23`) ; tous les
  appels de production passent désormais les exploits.
- Ce qui n'est **pas** du code mort, malgré les apparences :
  `outils/relecture.dart` et `outils/fusionne_lots.py` sont des outils de
  production de contenu, documentés en tête de fichier et hors de `test/`.
  `Jauges.milieu` et `Strategie.toujoursDroite` servent aux tests.

---

## 7. Tests manquants

Le filet est déjà large (204 tests, moteur, contenu, écrans et simulation). Ce
qui manque, par ordre d'utilité :

1. **`SessionNotifier` n'est testé que par la bande.** Aucun test n'appelle
   `_prochaine` sur un paquet épuisé (§1.6), ni `mandatSuivant` deux fois
   (§1.7), ni `_termine` sans progression chargée (§1.3). Les trois bogues les
   plus coûteux du rapport vivent dans ces vingt lignes.
2. **Aucune simulation ne joue un second mandat.** `simule`
   (`simulation.dart:53`) crée toujours un `EtatPartie` au mandat 1 : le
   facteur ×1,25 / ×1,5, qui change tout l'équilibrage, n'est éprouvé que par
   des tests unitaires sur `amplifie`, jamais sur une partie entière. C'est
   ainsi que 1.2 a pu passer.
3. **La stratégie « équilibrée » ment au moteur.** `_versLeCentre`
   (`simulation.dart:92-97`) choisit son côté sur `r.effets` **brut**, sans
   régime, sans mandat, sans atout. Les tests d'équilibrage du contenu
   (`contenu_reel_test.dart:71`) mesurent donc un joueur qui ne voit pas ce que
   l'écran montre. À faire passer par `effetsReels`.
4. **Aucun test ne compare l'aperçu à ce qui est appliqué.** C'est pourtant la
   promesse centrale (`partie.dart:68-71`). Un test qui pencherait la carte,
   lirait les deltas affichés, relâcherait et vérifierait les jauges du
   lendemain verrouillerait §3 pour de bon.
5. **Sauvegardes déviantes** : `test/sauvegarde_test.dart:47` n'éprouve que du
   non-JSON. Manquent : JSON valide avec champ manquant, valeurs hors bornes,
   parcours inexistant (§1.10), progression sans compteur (§1.4).
6. **Contenu** : aucune vérification qu'un maillon de chaîne est atteignable
   (drapeau posé par un maillon *ultérieur*), ni que les jauges de départ d'un
   parcours sont entre 1 et 99 — un parcours à 100 de peuple ferait chuter au
   premier jour.
7. **Tests faibles** : `test/app_test.dart` monte un `MaterialApp` fabriqué sur
   place et cherche son propre `Text` ; il n'importe rien du projet et ne
   pourrait pas échouer. `test/simulation_test.dart:48` (« à graine égale, les
   mesures sont identiques ») ne compare que `joursMoyens` : deux séries
   différentes de même moyenne passeraient.

---

## 8. Ce qui est bien fait, et qu'il ne faut pas toucher

- **Le moteur est du Dart pur, immuable et sans dépendance d'écran.**
  `EtatPartie.copie`, `Jauges.applique`, `repond` qui rend un état neuf : c'est
  ce qui rend la simulation possible, et la simulation est ce qui tient
  l'équilibrage. Ne pas y introduire d'état mutable.
- **`effetsReels` est le point de passage unique** de l'aperçu et de
  l'application. C'est exactement la bonne forme ; c'est le bornage à
  l'intérieur d'`amplifie` qu'il faut déplacer, pas l'architecture.
- **Le bilan est calculé à un seul endroit**, `_termine` (`session.dart:120`),
  jamais depuis un `build`. Le commentaire qui explique pourquoi vaut de l'or,
  et la garde de `mandatSuivant` (« un écran mal écrit peut appeler cette
  méthode ») est la bonne façon de se défendre des écrans.
- **`bilan()` ne partage jamais un ensemble mutable** avec la progression
  d'avant (`progression.dart:119`), et un test le vérifie.
- **La validation de contenu est sévère et bien pensée** : la mesure du texte
  *habillé*, la normalisation `_mots` qui neutralise traits d'union et
  apostrophes, le refus d'une condition d'exploit vide, la détection des fins
  qui se disputent un cas sans que le régime les départage. C'est ce qui permet
  d'ajouter des cartes sans lire le code.
- **Tous les contrôleurs d'animation sont disposés**, et le battement des
  jauges ne tourne que quand une jauge est au bord.
- **Les commentaires expliquent le *pourquoi*** (l'atout qui amortit dans les
  deux sens, l'axe qui ne s'amplifie pas d'un mandat à l'autre, la carte
  d'ouverture qui ne revient pas). C'est rare et c'est précieux : la moitié de
  cet audit s'est appuyée dessus.
