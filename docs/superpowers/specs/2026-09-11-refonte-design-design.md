# Refonte du design et des parcours — spécification

Date : 11 septembre 2026. Statut : en relecture.

## 1. Pourquoi

La première version TestFlight est jugée plate : sombre partout, hairlines, tout se ressemble. Les quatre parcours (onboarding, question de la semaine, quiz, gouvernement et assemblée) ne sont pas satisfaisants. La refonte reprend le style validé sur les maquettes du 11 septembre : un bandeau de couleur forte en haut de chaque écran, des cartes claires qui flottent dessus, un geste par écran. Inspiration assumée : Elyze (cartes à balayer, couleur franche, ton léger), dans les limites des règles de Palabre.

## 2. Ce qui ne change pas

Les règles du projet restent la loi :

- Le pays est une configuration, jamais une branche de code.
- Aucune opinion : pas de score en points, pas de podium, pas de classement de personnes, jamais d'extrapolation d'une position de parti.
- Aucune table ne relie un utilisateur à une orientation politique. Le quiz reste calculé sur le téléphone et n'est jamais envoyé.
- Chaque fait affiché renvoie à sa source ; une absence assumée vaut mieux qu'une donnée inventée.
- Après chaque changement : `flutter analyze`, `flutter test`, commit, push sur `main`.

Ne changent pas non plus : le modèle de données, les providers Riverpod, les routes go_router, la logique du moteur de quiz (`QuizEngine`), les découpes du sondage, la localisation fr/en/wo, les couleurs sémantiques des blocs ministériels et des groupes parlementaires (elles encodent, elles ne décorent pas).

Hors périmètre de cette spec : le contenu réel (25 affirmations, partis, gouvernement), Firebase, le logo, les variables Xcode Cloud.

## 3. Système visuel

### 3.1 Palette B « Lagune »

Un thème clair par défaut, un mode sombre équivalent. La palette n'est pas dérivée du logo, qui peut encore changer. Elle évite le vert, le jaune et le rouge, couleurs partisanes et du drapeau.

| Jeton | Rôle | Clair | Sombre |
|---|---|---|---|
| `primary` | bandeau, onglet actif, liens, bouton principal | `#0F7F7C` | `#3ED0CB` |
| `onPrimary` | texte sur le bandeau | `#FFFFFF` | `#05201F` |
| `primarySoft` | fond des pastilles, indicateur d'onglet | `#DDF0EE` | `#1C3F3D` |
| `accent` | interrupteur « important », mise en avant ponctuelle | `#FF7A1A` | `#FF7A1A` |
| `onAccent` | texte sur accent | `#2B1200` | `#2B1200` |
| `background` | fond des écrans | `#EFF6F5` | `#0E1D1C` |
| `card` | cartes | `#FFFFFF` | `#173130` |
| `ink` | texte principal | `#0F2B2A` | `#EAF6F4` |
| `muted` | texte secondaire, notes | `#5B7674` | `#94B3B0` |
| `line` | séparateurs, bordures de champs | `#D8E6E4` | `#264543` |
| ombre de carte | `0 10 24 rgba(15,60,58,.10)` | `0 10 24 rgba(0,0,0,.35)` |

Les couleurs de bloc (`BlocColors`) et les couleurs de parti venant des données sont conservées telles quelles et vérifiées lisibles sur les deux fonds.

### 3.2 Typographie

Deux familles, embarquées dans l'app (licence SIL OFL, fichiers dans `assets/fonts/` avec leur licence) pour rester hors-ligne et rapide sur un appareil à 2 Go :

- **Sora** (600, 700, 800) pour le nom de l'app, les titres de bandeau, les questions et affirmations, les gros pourcentages.
- **Manrope** (400, 500, 600, 700) pour tout le reste.

Échelle : titre de bandeau 22, question ou affirmation 19, corps 14, note 12, surtitre 12 en capitales espacées. Chiffres tabulaires pour les pourcentages.

### 3.3 Formes et composants

- **Bandeau** : couleur `primary`, coins droits, hauteur selon le contenu. Il porte le nom de l'app ou le titre de l'écran, un surtitre de contexte (statut, date, progression) et, quand l'écran en a un, le contrôle de contexte (curseur temporel, recherche, progression).
- **Cartes** : fond `card`, rayon 18, ombre douce, padding 16, sans bordure. La première carte chevauche le bandeau de 30 px.
- **Boutons** : principal plein `primary`, rayon 12, hauteur 48 ; secondaire contour `line` ; les trois boutons du quiz sont ronds (56 px) sur fond `card`.
- **Pastilles** : fond `primarySoft`, texte `primary`, rayon plein ; sur le bandeau, fond blanc à 18 %, texte `onPrimary`.
- **Barre d'onglets** : fond `card`, indicateur `primarySoft`, icône et libellé actifs en `primary`, quatre onglets inchangés (Question, Testez-vous, Gouvernement, Assemblée).
- **Séparateurs** : `line`, 1 px, uniquement à l'intérieur des cartes.
- Plus d'`AppBar` Material : le bandeau la remplace partout. Le bouton retour et le bouton Paramètres vivent dans le bandeau.

### 3.4 Mode sombre

Réglage dans Paramètres : Système (défaut), Clair, Sombre. Clé de préférence `theme_mode` (`system` / `light` / `dark`). L'app suit le système sans rien demander à l'onboarding.

## 4. Architecture Flutter

Tout reste dans l'arborescence actuelle. Fichiers touchés ou créés :

- `lib/app/theme.dart` : remplace `PalabreTheme.dark()` par `PalabreTheme.light()` et `PalabreTheme.dark()`, tous deux construits depuis un `ThemeExtension<PalabreTokens>` (`primarySoft`, `accent`, `onAccent`, `card`, `ink`, `muted`, `line`, `cardShadow`). Les sous-thèmes Material (boutons, champs, chips, barre d'onglets, feuilles) reçoivent les formes de §3.3. Les polices sont déclarées dans `pubspec.yaml`.
- `lib/app/app.dart` : `theme` clair, `darkTheme` sombre, `themeMode` lu depuis un nouveau `themeModeProvider` (`lib/core/prefs/theme_mode_provider.dart`).
- `lib/core/widgets/band_scaffold.dart` : `BandScaffold` — le squelette commun : bandeau (titre, surtitre, actions, zone de contrôle optionnelle) puis corps défilant dont le premier enfant chevauche le bandeau. Gère le bouton retour quand la route peut revenir.
- `lib/core/widgets/soft_card.dart` : `SoftCard` (carte de §3.3) et `Pill`.
- `lib/core/widgets/widgets.dart` : `PercentBar`, `SourceLink`, `NoticeBanner`, `ErrorRetry`, `PersonAvatar` restylés avec les jetons ; `SectionTitle` devient un titre de section hors carte en `muted` capitales ; `Hairline` supprimé au profit des séparateurs de carte.
- `lib/app/shell.dart` : barre d'onglets restylée, structure inchangée.
- Écrans de `lib/features/**` : réécrits sur `BandScaffold` + `SoftCard` selon §5, providers inchangés.

Chaque écran ne connaît que `BandScaffold`, `SoftCard` et les jetons du thème. Changer la palette se fait dans `theme.dart` seul.

## 5. Parcours écran par écran

### 5.1 Onboarding : un seul écran

Bandeau : « Palabre », puis le principe en une phrase (« Une question par semaine, un test pour comparer vos idées aux partis, la liste de qui gouverne. Rien n'est jugé, tout est sourcé. »). Carte : choix du pays (liste des pays actifs de la configuration, présélection selon la locale de l'appareil quand elle correspond). Bouton « Commencer ». Rien d'autre : plus de deuxième page, plus de formulaire de profil.

Tranche d'âge et région sont demandées plus tard : après le premier vote à une question de la semaine, une carte facultative « Affiner les résultats » apparaît sous les résultats, avec les deux champs et un bouton « Plus tard ». Elle disparaît définitivement une fois remplie ou refusée (clé `profile_prompt_done`). Les deux champs restent modifiables dans Paramètres, comme aujourd'hui.

Ce que ça change dans le code : `OnboardingScreen` perd son `PageView` ; `ProfileForm` reste partagé entre la carte « Affiner » (sans le champ pays) et Paramètres (avec).

### 5.2 Question de la semaine

Bandeau : surtitre = statut (« ouverte jusqu'à dimanche 20 h », « ouvre lundi 8 h », « fermée »), titre = « Semaine du 14 septembre ». Icône Paramètres à droite.

Carte principale, selon le statut :

- **Programmée** : question et options visibles mais grisées, note « Le vote ouvre lundi 8 h ».
- **Ouverte, pas encore voté** : question en Sora 19, options sous forme de lignes sélectionnables (bord `line`, sélection en `primarySoft` + coche), bouton « Voter » actif dès qu'une option est choisie, note « Un seul vote, définitif. Les résultats s'affichent après. ».
- **Ouverte, déjà voté** ou **fermée** : question, puis une barre par option avec pourcentage et nombre de réponses, l'option choisie marquée. Les découpes (par région, par tranche d'âge) restent accessibles par le même sélecteur qu'aujourd'hui, à l'intérieur de la carte.

Deuxième carte, repliée par défaut : « Contexte · 3 sources ». Dépliée : le texte de contexte puis les liens de sources (`SourceLink`), un par ligne.

Section « Semaines précédentes » : titre de section, puis une carte par question passée avec le texte de la question, le nombre de réponses et la barre de l'option la plus choisie avec son libellé. Tap : détail de la question (`/question/:id`), même mise en page que la carte principale à l'état fermé.

Sans serveur ou sans réseau et sans cache : la carte principale affiche le `NoticeBanner` existant, jamais une question inventée.

### 5.3 Testez-vous : accueil

Bandeau : « Testez-vous », surtitre « N affirmations · 5 minutes » (N vient du bundle). Carte : ce que c'est en trois lignes (vous répondez, on compare aux positions déclarées et sourcées des partis, le calcul se fait sur votre téléphone et ne quitte jamais l'appareil), bouton « Commencer ». Si une session est en cours : bouton « Reprendre (7 / 25) » et lien « Recommencer ». Si un résultat existe : deuxième carte « Votre dernier résultat » qui ouvre l'écran de résultat.

### 5.4 Testez-vous : une affirmation par carte

Bandeau : « Testez-vous » avec, à droite, la progression « 7 / 25 » en pastille et une barre fine de progression sous le titre ; surtitre « Glissez la carte, ou touchez un bouton ». Bouton retour à gauche = revenir à l'affirmation précédente (ne perd pas la réponse), fermer = retour à l'accueil du quiz, session conservée.

Corps : une pile de cartes. La carte du dessus porte le thème en pastille et l'affirmation en Sora 19. Deux cartes suivantes dépassent légèrement derrière, décalées et réduites, pour signaler la pile.

Gestes et boutons, strictement équivalents :

- glisser à droite = **D'accord** ; à gauche = **Pas d'accord** ; la carte s'incline en suivant le doigt, un libellé « D'accord » ou « Pas d'accord » apparaît en surimpression selon le sens ; seuil 35 % de la largeur, sinon retour élastique ;
- trois boutons ronds sous la pile : ✕ Pas d'accord, 〜 Neutre, ✓ D'accord, avec libellé sous chaque bouton ;
- ligne « Important pour moi » avec interrupteur `accent` et compteur « 2 sur 5 marquées, elles comptent double » ; désactivé à 5 avec un message ;
- lien texte « Passer cette affirmation » = `Answer.passer`.

Répondre déclenche une animation de sortie de 250 ms, un léger retour haptique, puis la carte suivante monte. Après la 25e, navigation vers le résultat. Les réponses sont enregistrées dans la session existante (`QuizSessionNotifier`) au fil de l'eau, donc une fermeture d'app ne perd rien.

Accessibilité : les boutons suffisent, le balayage est un raccourci ; les cartes sont annoncées avec leur numéro ; réduction des animations respectée si le système la demande.

### 5.5 Testez-vous : résultat

Bandeau : « Votre concordance », surtitre « 25 réponses · calculé sur votre téléphone », titre « Tous les partis, du plus proche au plus éloigné ».

Carte principale : une ligne par parti, tous les partis, dans l'ordre déjà produit par `QuizEngine.compute` : bande verticale de la couleur du parti, nom, « 22 positions comparées · 3 sans position », gros pourcentage à droite, barre `PercentBar` dessous. Pas de numéro de rang, pas de médaille, pas de mise en avant du premier autre que sa place dans la liste, pas de ligne « votre parti ». Les partis non calculables sont en fin de liste avec « non calculable » à la place du pourcentage.

Note sous la carte : « Un parti sans position sur une affirmation n'est jamais deviné : il apparaît « n'a pas pris position ». Chaque position renvoie à sa source. »

Deux actions : « Détail par affirmation » (ouvre la liste affirmation par affirmation, votre réponse contre la position de chaque parti avec son niveau de source et son lien, et le bouton de contestation existant) et « Partager » (la `ShareCard` existante, redessinée avec le bandeau et la liste complète des pourcentages, sans podium).

### 5.6 Gouvernement

Bandeau : « Gouvernement », surtitre « Au 11 septembre 2026 · aujourd'hui », puis le curseur temporel dans le bandeau : piste claire, curseur `onPrimary`, un point par remaniement (les dates de composition du bundle), libellés de bornes aux extrémités, aide « Faites glisser pour remonter le temps ». Le curseur s'aimante sur les points.

Corps : une carte d'en-tête (nom du gouvernement, « depuis le 5 avril 2025 », couverture « 5 des 25 portefeuilles renseignés · Décret n° 2025-412 » avec lien source), puis une carte par bloc : titre du bloc avec sa pastille de couleur, grille de portraits (avatar, nom, portefeuille), le chef du gouvernement seul dans sa carte en premier. Tap sur un portrait : fiche personne.

### 5.7 Assemblée

Bandeau : « Assemblée », surtitre « N députés · législature X » (valeurs issues du bundle), champ de recherche sur le bandeau (fond blanc 18 %), puis les filtres existants (groupe, région) en pastilles de bandeau.

Corps : liste groupée par groupe parlementaire, une carte par groupe avec son titre coloré, une ligne par député (avatar, nom, circonscription). Quand un filtre ou une recherche est actif, la liste reste groupée mais ne montre que les groupes qui ont des résultats. Tap : fiche personne.

### 5.8 Fiches et détails

Fiche personne, fiche parti, détail d'une question passée : mêmes `BandScaffold` + `SoftCard`. Le bandeau porte le nom et un sous-titre (fonction, ou sigle), le corps les cartes déjà présentes (mandats, sources, positions du parti avec sources). Aucun contenu nouveau.

Paramètres : ajoute la section « Apparence » (Système / Clair / Sombre) au-dessus de la langue ; le profil (pays, âge, région) et les mentions restent.

## 6. Données et préférences

Aucune migration Supabase, aucune requête nouvelle. Deux clés `SharedPreferences` ajoutées à `PrefKeys` : `theme_mode`, `profile_prompt_done`. Rien de ce qui touche au quiz ne quitte le téléphone, comme avant.

## 7. Localisation

`app_fr.arb` reste le modèle. Toutes les chaînes nouvelles (onboarding, notes, libellés des gestes, apparence, « non calculable », « Affiner les résultats ») sont ajoutées en français, anglais et wolof dans le même commit. Les chaînes devenues inutiles (deuxième page d'onboarding) sont retirées des trois fichiers.

## 8. Tests

Tous existants maintenus et adaptés :

- `app_smoke_test.dart` : l'onboarding tient sur un écran ; « Commencer » enregistre `onboarding_done` et le pays, puis l'onglet Question affiche le bandeau « serveur non configuré ».
- `quiz_engine_test.dart` : inchangé, le moteur ne bouge pas.

Nouveaux tests de widgets :

- thème : `PalabreTheme.light()` et `dark()` exposent `PalabreTokens` et les jetons de §3.1 ; `themeModeProvider` lit et écrit `theme_mode`.
- quiz : un balayage à droite au-delà du seuil enregistre `Answer.accord`, un balayage court ramène la carte ; le bouton ✕ enregistre `Answer.desaccord` ; l'interrupteur « important » se bloque à 5.
- résultat : avec un bundle de test, tous les partis sont listés dans l'ordre du moteur, aucun texte de rang (« 1er », « #1 », médaille) n'apparaît, un parti non calculable affiche « non calculable ».
- question : l'état programmé n'affiche pas de bouton « Voter » actif ; la carte « Affiner les résultats » n'apparaît qu'après un vote et disparaît après « Plus tard ».

Vérification manuelle sur simulateur iPhone 17 en clair et en sombre, puis TestFlight sur iPad.

## 9. Découpage pour le plan d'implémentation

Neuf étapes, chacune se terminant par `flutter analyze`, `flutter test`, commit, push :

1. Polices embarquées, jetons, `PalabreTheme.light()/dark()`, `themeModeProvider`, réglage Apparence dans Paramètres.
2. `BandScaffold`, `SoftCard`, `Pill`, restylage de `widgets.dart`, barre d'onglets.
3. Onboarding sur un écran + carte « Affiner les résultats » après le premier vote.
4. Question de la semaine (carte principale par statut, contexte repliable, archive) et détail d'une question.
5. Accueil du quiz.
6. Cartes à balayer.
7. Résultat et partage.
8. Gouvernement (curseur dans le bandeau, cartes par bloc).
9. Assemblée, fiches personne et parti, nettoyage des chaînes et widgets inutilisés.

Version : `version` dans `pubspec.yaml` incrémentée à la fin de l'étape 9 ; le numéro de build reste géré par Xcode Cloud.
