# Palabre — écrans 1A (accueil) et 1D (jeu)

Fiche fournie par le propriétaire le 2026-09-16, issue d'une maquette faite dans
Claude Design (`Palabre propositions.dc.html`, options 1A et 1D). Elle fait
autorité pour `lib/ecrans/theme.dart`, `accueil.dart`, `partie_ecran.dart` et
`carte_glissante.dart`. Le moteur (`lib/moteur/`) et la sauvegarde ne changent pas.

## Décisions du contrôleur, en complément de la fiche

1. **Polices embarquées, pas `google_fonts`.** Le paquet télécharge les polices au
   premier lancement ; le jeu s'interdit tout appel réseau et doit s'afficher juste
   hors connexion. Les cinq `.ttf` (Bricolage Grotesque 700/800, Public Sans
   400/600/700, licence OFL) sont dans `assets/polices/`, déclarés dans
   `pubspec.yaml` sous les familles `Bricolage` et `PublicSans`.
2. **Les flèches ← et → passent par les icônes Material.** Elles n'existent pas
   dans le sous-ensemble latin des deux polices ; en texte, iOS et Android
   substitueraient chacun une police différente. `Icons.west` / `Icons.east`
   à la taille du libellé donnent le même dessin partout. Le signe moins
   typographique − (U+2212) du delta, lui, est bien présent : on le garde.
3. **Le logo compact existe déjà** : `assets/icone/icone.png`, la marque seule,
   carrée, 1024 × 1024. Pas de `logo_marque.png` à produire.
4. **Portraits de parcours** : repris chez OpenArt en 896 × 1200 (le dépôt n'avait
   que des réductions en 478 × 640). Si le cadrage plein écran coupe le front, on
   les regénère plus larges ; on juge sur le simulateur avant de dépenser.

## Ce que le contenu impose déjà

Mesuré sur les 50 cartes du prototype : texte le plus long 110 caractères (limite
150), aucun libellé au-dessus de 18 caractères, aucune carte ne touche plus de
3 jauges, `humeur` toujours renseignée. Les quatre règles de contenu de la fiche
sont donc déjà tenues ; elles restent à inscrire dans `lib/contenu/validation.dart`
pour le contenu à venir.

Les quatre phrases de caractère demandées sont posées dans
`assets/contenu/parcours.json` sous la clé `accroche`.

---

## 0. Fondations partagées

### Couleurs (`lib/ecrans/theme.dart`)

```
nuit      #14131A  fond de tout écran, fond de carte
nuitClair #1C1A23  panneaux, carte suivante, tirette
encre     #080709  bas de dégradé sur les portraits
or        #E9B44C  accent unique : sélection, étiquette, jauge visée
creme     #F6EFE4  texte principal
cremeDoux #E3D9C9  texte secondaire sur image
aplat     #26222E  remplaçant d'un portrait manquant
```

Opacités crème utilisées : .65 (secondaire), .45 (placeholder, tertiaire), .35
(libellé inactif). Traits : blanc à .08 (séparateurs), .14–.18 (bordures, fond
de jauge).

### Typographie

- Titres et libellés forts : **Bricolage Grotesque** (700, 800).
- Texte courant, jauges, boutons : **Public Sans** (400, 600, 700).

| Rôle | Taille | Poids | Autres |
| --- | --- | --- | --- |
| Nom du parcours (1A) | 36 | 800 Bricolage | height 1.02 |
| Titre de section « Qui étiez-vous avant ? » | 11 | 700 | letterSpacing 1.8, or, majuscules |
| Sous-titre parcours | 14 | 400 | crème .65 |
| Nom d'une jauge | 10 | 700 | letterSpacing 1.0, majuscules |
| Delta de jauge (+12 / −12) | 11 | 700 | or |
| « JOUR 12 » | 13 | 700 Bricolage | letterSpacing 2.6 |
| « élection au jour 30 » | 11 | 400 | crème .40 |
| Titre du personnage sur la carte | 11 | 800 | letterSpacing 1.8, or, majuscules |
| Texte de la carte | 18 | 400 | height 1.38, crème |
| Étiquette de réponse | 15 | 800 | letterSpacing 1.8, or, majuscules |
| Libellés rappelés sous la carte | 12 | 600 | letterSpacing 1.0, majuscules |
| Bouton principal | 16 | 700 | nuit sur or |
| Champ « Votre nom » | 16 | 400 | placeholder crème .45 |

### Formes

- Rayon des boutons et du champ : 14. Hauteur : bouton 56, champ 52.
- Rayon d'une carte de jeu : 24. Vignettes de parcours : 10. Étiquette : 8.
- Marge latérale d'écran : 22. Le contenu ne touche jamais les bords.
- Pas d'élévation Material : les ombres sont explicites
  (`BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 60, offset: Offset(0, 30))`
  sur la carte active).

### Thème

`ThemeData(useMaterial3: true, brightness: dark, colorSchemeSeed: or,
scaffoldBackgroundColor: nuit)` plus un `textTheme` construit sur Public Sans.
Tint de surface Material désactivé sur les cartes et panneaux.

---

## 1. Accueil — « Galerie » (1A)

### Rôle

Choisir qui l'on était (parcours), donner son nom, prendre ses fonctions, ou
reprendre une partie. Un seul portrait plein cadre à la fois ; on glisse
horizontalement entre les quatre parcours.

### Structure (écran 390 × 844 de référence)

1. **Portrait plein cadre** : `PageView` horizontal, `viewportFraction: 1`, une
   page par parcours dans l'ordre de `parcours.json`. Image
   `assets/images/parcours/{id}.jpg`, `BoxFit.cover`, `Alignment(0, -0.6)`,
   68 % de la hauteur. Par-dessus, un dégradé vertical : nuit .55 → transparent
   à 22 % → transparent à 42 % → nuit opaque à 66 %.
2. **Barre haute** (padding 60, 26, 0, 26) : logo hauteur 44 à gauche ; compteur
   « 2 / 4 » à droite (11, 700, letterSpacing 1.8, or).
3. **Bloc identité** (aligné en bas de la zone image, gap 6) : surtitre
   « QUI ÉTIEZ-VOUS AVANT ? » ; nom du parcours (36 / 800 Bricolage), 2 lignes
   max, ellipsis ; sous-titre `parcours.titre` + « · » + la phrase de caractère,
   14, crème .65.
4. **Jauges de départ** : 4 colonnes égales, gap 10. Chaque colonne : nom
   (10/700, crème .60) puis barre 4 px, rayon 2, fond blanc .16, remplissage
   crème à `depart.valeur(j)/100`. La jauge **la plus haute** est en or.
5. **Vignettes des parcours** : rangée, gap 10, 52 × 64, rayon 10,
   `Alignment(0, -0.5)`. Vignette courante : bordure or 2 px avec écart 2.
   Autres ouvertes : opacité .70. Taper une vignette anime le `PageView`.
6. **Formulaire** (gap 10, padding-top 6) : champ « Votre nom » (52, bordure
   blanc .18, fond blanc .04) puis bouton or « Prendre mes fonctions » (56). Si
   une sauvegarde existe, un bouton contour or « Reprendre le jour N » (48) se
   place au-dessus du champ.
7. Padding bas 30 (+ safe area).

Sur un écran de moins de 740 de haut, le nom passe à 30 et la zone image à 60 %.

### Parcours verrouillé

- Portrait en niveaux de gris et opacité .55.
- Le nom garde sa taille ; le sous-titre devient `condition_deblocage` précédé
  d'une icône `Icons.lock_outline` 16 or.
- Les jauges de départ restent visibles en crème .35, aucune en or.
- Vignette grise, opacité .40, cadenas centré (14, or).
- Bouton « Prendre mes fonctions » désactivé (or .35, texte nuit .60). Le nom
  saisi est conservé quand on change de page.

### États et transitions

| Événement | Animation |
| --- | --- |
| Changement de page | Défilement natif du `PageView` ; bloc identité + jauges en `AnimatedSwitcher` 220 ms `easeOut`, fondu + translation verticale 8 px. Le compteur change sans animation. |
| Vignette sélectionnée | `AnimatedContainer` 180 ms sur la bordure et l'opacité. |
| Bouton activé / désactivé | `AnimatedOpacity` 160 ms. |
| Retour sur l'accueil après une partie | relire la sauvegarde, pas d'animation. |

Le geste horizontal appartient au `PageView` ; le champ texte ne l'intercepte
pas (il est hors de la zone image).

### Phrases de caractère

Dans `parcours.json`, clé `accroche` (≤ 60 caractères), lue par
`Parcours.depuisJson` :

- general_parcours : « L'armée vous suit, la presse se méfie. »
- professeure : « Le pays vous lit, l'armée vous ignore. »
- musicienne : « Le peuple vous adore, la caserne vous attend. »
- putschiste : « La caserne est à vous, personne d'autre. »

### Composants

```
AccueilEcran        conserve _nom, _choisi, _enCours ; _choisi devient l'index de page
_PortraitParcours   image + dégradé + gris si verrouillé
_IdentiteParcours   surtitre, nom, sous-titre ou condition
_JaugesDepart       4 barres, la plus haute en or
_VignettesParcours  rangée 52×64, onTap(index)
```

---

## 2. Écran de jeu — « Carte portrait » (1D)

### Rôle

Une carte par jour. Le geste horizontal est la seule réponse. Pendant le geste,
le joueur voit ce que la réponse coûtera avant de lâcher.

### Structure

1. **Jauges** (padding 56, 22, 0, 22 ; 4 colonnes, gap 10). Chaque colonne,
   centrée : nom (10/700), barre, delta.
   - Repos : barre 6 px, fond blanc .14, remplissage crème. Nom crème .60.
     Delta invisible mais sa hauteur est réservée, pour que rien ne saute.
   - Jauge **concernée** : barre 8 px, nom et remplissage or, delta affiché
     (« +12 » / « −12 », 11/700 or, signe −). Un **fantôme** or .45 de 4 px
     couvre la portion gagnée ou perdue : effet négatif, de `valeur+effet` à
     `valeur` ; effet positif, de `valeur` à `valeur+effet` (borné 0–100). Pour
     un effet négatif, une marque verticale or 2 × 14 px au niveau actuel.
   - Transition repos ↔ concernée : `AnimatedContainer` 160 ms `easeOut` sur
     hauteur et couleurs ; delta en `AnimatedOpacity` 160 ms.
2. **Jour** : rangée centrée, gap 8, padding 16, 0, 6 : « JOUR 12 » puis
   « élection au jour 30 » (crème .40). Après le jour 30 : « second mandat ».
3. **Zone carte** (`Expanded`, padding 12, 22, 24, 22, `clipBehavior:
   Clip.hardEdge` pour que la carte sortante ne dépasse pas les jauges).
   - **Carte suivante** derrière : même rectangle, fond nuitClair, bordure
     blanc .06, `scale .96` + `translateY 10`. C'est un aplat : on ne révèle
     pas le prochain personnage.
   - **Carte active** : rayon 24, fond nuit, ombre noire .6 / blur 60 /
     offset (0, 30). Portrait `personnage.image(humeur)` en `BoxFit.cover`,
     `Alignment(0, -0.35)`. Bas : dégradé transparent → encre .95 à 55 %,
     padding 120, 20, 24, 20, gap 8 : titre du personnage (majuscules, or)
     puis texte de la carte (18, height 1.38), déjà passé par `habille()`.
   - **Étiquette** : coin haut du côté vers lequel on glisse (top 18, left ou
     right 18), padding 8 × 14, bordure or 3, rayon 8, fond noir .55, texte or
     majuscules. Rotation inverse de la carte pour rester droite.
4. **Libellés rappelés** (padding 0, 30, 34, 30 ; `spaceBetween`) : « ← LES
   ROUTES » à gauche, « LES BOURSES → » à droite. Repos : crème .35 des deux
   côtés. Geste : le côté visé passe or, l'autre reste .35.
   `AnimatedDefaultTextStyle` 160 ms.

### Geste

Conserver `seuil = 0.35` et `seuilIntention = 0.08` de la largeur. Changements :

- Rotation : `angle = part * 0.18` rad, pivot au bas de la carte
  (`Alignment(0, 1.2)`), type « carte en main ».
- Translation : `dx` brut jusqu'au seuil, puis résistance (`dx * 0.6` au-delà).
- Retour au centre : 220 ms `easeOut`.
- Sortie : 260 ms `easeIn` vers `±1.5 × largeur`, puis `onReponse`.
- Pendant la sortie, la **carte suivante** monte de `scale .96 / translateY 10`
  à `scale 1 / translateY 0` en 260 ms `easeOut`. Elle ne se remplit du nouveau
  portrait qu'après `onReponse`.
- Retour haptique léger (`HapticFeedback.selectionClick`) au franchissement de
  `seuilIntention` et à la réponse.

### Effets affichés pendant le geste

`PartieEcran` connaît déjà `reponse` (côté pressenti) :

```dart
_LigneJauges(jauges: etat.jauges, effets: reponse?.effets ?? const {})
// concernées = effets.keys ; delta = effets[j] ; fantôme calculé dans le widget
```

### Alerte jauge proche d'un extrême

Une jauge est en alerte si `valeur <= 15` ou `valeur >= 85`.

- Repos : remplissage en or à .70, nom en or, pulsation d'opacité .70 ↔ 1 sur
  1 400 ms `easeInOut` en boucle (un seul `AnimationController` pour la ligne).
- Si le geste l'aggrave : fantôme et delta en crème sur pastille or (2 × 6 px,
  rayon 4), barre à 10 px — le danger prime sur l'information.
- Aucune couleur rouge : la palette reste or / crème / nuit.

### États à couvrir

| État | Carte | Jauges | Libellés |
| --- | --- | --- | --- |
| Repos | centrée, angle 0, doublure derrière | 6 px crème ; alerte en or pulsé | crème .35 des deux côtés |
| Geste gauche (part ≥ .08) | translatée, angle négatif, étiquette en haut à droite | concernées or 8 px + fantôme + delta | gauche en or |
| Geste droite | symétrique, étiquette en haut à gauche | idem | droite en or |
| Lâché avant seuil | retour 220 ms | retour au repos 160 ms | retour au repos |
| Lâché après seuil | sort 260 ms, doublure monte | figées jusqu'à `onReponse`, puis `AnimatedContainer` 300 ms vers les nouvelles valeurs | retour au repos |
| Nouvelle carte | apparaît sans animation propre | — | nouveaux libellés |

### Règles de contenu

À inscrire dans `outils/relecture.dart` et `lib/contenu/validation.dart` :

- `texte` : 2 phrases au plus, ≤ 150 caractères après `habille()` avec le titre
  le plus long (« Madame la Présidente »).
- `libelle` : ≤ 18 caractères.
- `humeur` : toujours renseignée dans le JSON ; chaque personnage a ses trois
  images, aucun repli silencieux.
- Une carte ne touche pas plus de 3 jauges.

---

## 3. Assets

- `assets/icone/icone.png` sert de logo compact (1024 × 1024).
- Portraits de parcours : 4 `.jpg` en 896 × 1200. À regénérer plus larges si le
  cadrage plein écran coupe le front.
- Portraits de personnages : 12 `.jpg` en place.
- Polices : `assets/polices/`, cinq `.ttf` OFL.
- Aucune icône dessinée nécessaire.

## 4. Tests widget

- `accueil_test.dart` : glisser sur un parcours verrouillé désactive le bouton ;
  taper une vignette change la page ; le nom saisi survit au changement de page ;
  « Reprendre le jour N » n'apparaît que si `Sauvegarde.lis()` rend un état.
- `partie_ecran_test.dart` : à part ≥ .08 vers la droite, les jauges des effets
  de `carte.droite` sont concernées (hauteur 8, delta affiché) ; à part < .08,
  aucune ; une jauge à 12 porte l'état alerte.
- `carte_glissante_test.dart` : garder les tests existants ; ajouter la
  résistance au-delà du seuil.

## 5. Ordre de mise en œuvre

1. `theme.dart` + polices.
2. `_LigneJauges` avec effets, fantôme, delta, alerte.
3. `CarteGlissante` : pivot, résistance, haptique, progression pour la doublure.
4. `PartieEcran` : doublure, libellés rappelés, ligne « JOUR ».
5. `AccueilEcran` en `PageView` + vignettes + accroches JSON.
6. Tests.
