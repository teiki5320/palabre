# Prototype « Président pour 100 jours » — plan de réalisation

> **Pour les agents :** SOUS-COMPÉTENCE REQUISE : utiliser superpowers:subagent-driven-development (recommandé) ou superpowers:executing-plans pour réaliser ce plan tâche par tâche. Les étapes utilisent des cases à cocher (`- [ ]`).

**But :** livrer un prototype jouable sur téléphone — 50 cartes, 4 personnages, 2 parcours jouables et 2 grisés, 4 fins, une partie complète du choix du parcours jusqu'à l'écran de fin, sauvegardée sur l'appareil.

**Architecture :** un moteur en Dart pur, sans écran et déterministe à graine fixée, qui pioche la carte suivante et applique les réponses ; le contenu dans des fichiers JSON livrés avec l'appli ; des écrans Flutter qui ne font qu'afficher l'état du moteur. Aucun serveur.

**Pile technique :** Flutter 3.47.3 / Dart 3.13.3, Riverpod 3, shared_preferences. Pas de moteur de jeu, pas de génération de code, pas de Supabase.

**Spec :** `docs/superpowers/specs/2026-09-16-president-100-jours-design.md`

## Contraintes générales

- Pays, personnages et institutions **imaginaires**. Aucun nom de personne, de parti ou de pays réel, nulle part, y compris dans les commentaires et les identifiants.
- Identifiant d'application : `sn.palabre.app` sur les deux plateformes (fiche App Store Connect et Play Console réutilisées).
- Nom de paquet Dart : `president`. Les imports s'écrivent donc `package:president/...`.
- Tout le code, les commentaires, les noms de fichiers et les identifiants JSON sont **en français**, sans accents dans les identifiants (`armee`, pas `armée`).
- Quatre jauges, dans cet ordre partout : `peuple`, `armee`, `caisses`, `presse`. Valeurs entières de 0 à 100. Une jauge à 0 **ou** à 100 met fin au mandat.
- Effets d'une réponse : de −20 à +20, une à trois jauges par réponse.
- Texte d'une carte : 140 caractères au plus. Libellé d'une réponse : 18 caractères au plus.
- **Durée du mandat du prototype : 30 jours**, pas 100. Avec 50 cartes non répétables, 100 jours viderait le paquet. La constante `dureeMandat` passera à 100 quand le contenu du lancement sera écrit.
- Deux réponses par carte, jamais trois. Pas de bouton : le geste est le seul moyen de répondre.
- Aucun appel réseau dans ce plan. La publicité et l'achat intégré font l'objet d'un plan séparé.
- Avant chaque commit : `flutter analyze` (zéro avertissement) puis `flutter test` (tout au vert).
- Chaque commit se termine par la ligne `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- Ne jamais réactiver Swift Package Manager dans le projet iOS.

## Ce que ce plan ne couvre pas

Étapes 4 à 7 de la spec, qui feront l'objet de plans distincts : parcours verrouillés à débloquer, exploits et collection, second mandat plus difficile, publicité et achat « Sans pub », les 250 à 300 cartes du lancement, les fiches des stores.

## Structure des fichiers

```
pubspec.yaml                        dépendances et déclaration des assets
analysis_options.yaml               règles d'analyse
.github/workflows/ci.yml            analyse + tests à chaque poussée
ios/ci_scripts/ci_post_clone.sh     préparation Xcode Cloud

lib/
  main.dart                         point d'entrée, ProviderScope
  app.dart                          MaterialApp, thème, navigation
  moteur/
    jauges.dart                     Jauge, Jauges (application des effets, détection d'extrême)
    modeles.dart                    Reponse, Conditions, Chaine, Carte, Personnage, Parcours, Fin
    etat_partie.dart                EtatPartie (jauges, jour, mandat, drapeaux, cartes vues, chaînes)
    tirage.dart                     choisitCarte : filtrage, chaînes forcées, tirage pondéré
    partie.dart                     repond : applique une réponse et renvoie le nouvel état
    denouement.dart                 chute et élection : quelle fin, et pourquoi
  contenu/
    chargement.dart                 lecture des JSON depuis les assets
    validation.dart                 contrôle du contenu, utilisé par les tests
  ecrans/
    accueil.dart                    choix du parcours et saisie du nom
    partie_ecran.dart               la partie : jauges, carte, jour
    carte_glissante.dart            le geste (gauche / droite)
    fin_ecran.dart                  la fin de mandat
  sauvegarde/
    sauvegarde.dart                 shared_preferences : partie en cours, nom, parcours

assets/contenu/personnages.json
assets/contenu/parcours.json
assets/contenu/cartes.json
assets/contenu/fins.json
assets/images/personnages/*.jpg
assets/images/fins/*.jpg

test/
  moteur/jauges_test.dart
  moteur/modeles_test.dart
  moteur/etat_partie_test.dart
  moteur/tirage_test.dart
  moteur/partie_test.dart
  moteur/denouement_test.dart
  contenu/validation_test.dart
  contenu/contenu_reel_test.dart    le contrôle appliqué au contenu livré
  simulation_test.dart              dix mille mandats, mesures d'équilibrage
  ecrans/carte_glissante_test.dart
  ecrans/partie_ecran_test.dart
  ecrans/accueil_test.dart
  sauvegarde_test.dart
```

---

### Tâche 1 : Squelette Flutter, identifiants, intégration continue

**Fichiers :**
- Créer : tout le projet Flutter à la racine du dépôt (`lib/`, `ios/`, `android/`, `test/`, `pubspec.yaml`)
- Créer : `.github/workflows/ci.yml`, `ios/ci_scripts/ci_post_clone.sh`
- Modifier : `android/app/build.gradle.kts`, `ios/Runner.xcodeproj/project.pbxproj`, `.gitignore`

**Interfaces :**
- Consomme : rien, le dépôt est vide.
- Produit : un projet qui compile, `flutter analyze` et `flutter test` au vert, l'identifiant `sn.palabre.app` sur les deux plateformes.

- [ ] **Étape 1 : Créer le projet**

```bash
cd /Users/jeanperraudeau/Palabre
flutter create --org sn.palabre --project-name president --platforms=ios,android .
```

- [ ] **Étape 2 : Régler l'identifiant d'application**

L'organisation donne `sn.palabre.president` ; la fiche des stores attend `sn.palabre.app`. On change l'identifiant publié, sans toucher au `namespace` Android ni au paquet Kotlin, qui n'ont pas besoin d'être identiques.

```bash
cd /Users/jeanperraudeau/Palabre
sed -i '' 's/applicationId = "sn.palabre.president"/applicationId = "sn.palabre.app"/' android/app/build.gradle.kts
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = sn.palabre.president;/PRODUCT_BUNDLE_IDENTIFIER = sn.palabre.app;/g' ios/Runner.xcodeproj/project.pbxproj
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = sn.palabre.president.RunnerTests;/PRODUCT_BUNDLE_IDENTIFIER = sn.palabre.app.RunnerTests;/g' ios/Runner.xcodeproj/project.pbxproj
grep -n 'applicationId' android/app/build.gradle.kts
grep -n 'PRODUCT_BUNDLE_IDENTIFIER' ios/Runner.xcodeproj/project.pbxproj | head -3
```

Attendu : `applicationId = "sn.palabre.app"` et trois lignes `sn.palabre.app` côté iOS.

- [ ] **Étape 3 : Écrire le pubspec**

Remplacer `pubspec.yaml` par :

```yaml
name: president
description: "Président pour 100 jours — jeu de cartes à glisser."
publish_to: none
version: 0.1.0+1

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.0.0
  shared_preferences: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/contenu/
    - assets/images/personnages/
    - assets/images/fins/
```

```bash
mkdir -p assets/contenu assets/images/personnages assets/images/fins
printf '[]' > assets/contenu/cartes.json
printf '[]' > assets/contenu/personnages.json
printf '[]' > assets/contenu/parcours.json
printf '[]' > assets/contenu/fins.json
flutter pub get
```

- [ ] **Étape 4 : Remplacer le test d'exemple**

`flutter create` laisse un test qui s'appuie sur le compteur d'exemple. Le remplacer :

```bash
cat > test/app_test.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('l application demarre', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Président'))));
    expect(find.text('Président'), findsOneWidget);
  });
}
EOF
```

- [ ] **Étape 5 : Point d'entrée minimal**

```bash
cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(const ProviderScope(child: AppPresident()));
}
EOF

cat > lib/app.dart << 'EOF'
import 'package:flutter/material.dart';

/// Coquille de l'application. La navigation sera ajoutée avec les écrans.
class AppPresident extends StatelessWidget {
  const AppPresident({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Président pour 100 jours',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFE9B44C), brightness: Brightness.dark),
      home: const Scaffold(body: Center(child: Text('Président'))),
    );
  }
}
EOF
```

- [ ] **Étape 6 : Vérifier que tout passe**

```bash
flutter analyze && flutter test
```

Attendu : « No issues found! » puis un test au vert.

- [ ] **Étape 7 : Intégration continue GitHub**

```bash
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  analyse-et-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.47.3'
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
EOF
```

- [ ] **Étape 8 : Script Xcode Cloud**

Celui de Palabre installait Supabase, la traduction et la génération de code : plus rien de tout ça ici.

```bash
mkdir -p ios/ci_scripts
cat > ios/ci_scripts/ci_post_clone.sh << 'EOF'
#!/bin/sh
# Xcode Cloud — préparation d'un projet Flutter sans génération de code.
set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.3}"
FLUTTER_DIR="$HOME/flutter"

echo "▸ Flutter $FLUTTER_VERSION"
git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version
flutter precache --ios

cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "▸ Dépendances"
flutter pub get

echo "▸ Configuration iOS"
flutter build ios --release --no-codesign --config-only --build-number="${CI_BUILD_NUMBER:-1}"

echo "▸ CocoaPods"
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods >/dev/null 2>&1 || true
cd ios
pod install
EOF
chmod +x ios/ci_scripts/ci_post_clone.sh
```

- [ ] **Étape 9 : Compléter le .gitignore**

`flutter create` a pu écraser le nôtre. Vérifier que les deux lignes de session y sont :

```bash
grep -q '^\.superpowers/' .gitignore || printf '\n# Outils de session\n.superpowers/\n.claude/\n' >> .gitignore
grep -q '^android/key.properties' .gitignore || printf 'android/key.properties\n*.jks\n' >> .gitignore
tail -6 .gitignore
```

- [ ] **Étape 10 : Commit**

```bash
git add -A
git commit -m "Squelette Flutter, identifiants sn.palabre.app, CI

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 2 : Les jauges

**Fichiers :**
- Créer : `lib/moteur/jauges.dart`
- Test : `test/moteur/jauges_test.dart`

**Interfaces :**
- Consomme : rien.
- Produit : `enum Jauge { peuple, armee, caisses, presse }` ; `class Jauges` avec `const Jauges({required int peuple, required int armee, required int caisses, required int presse})`, `static const Jauges milieu`, `int valeur(Jauge)`, `Jauges applique(Map<Jauge, int> effets)`, `Jauge? extreme()`.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
mkdir -p test/moteur
cat > test/moteur/jauges_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/jauges.dart';

void main() {
  test('applique additionne les effets', () {
    final j = Jauges.milieu.applique({Jauge.armee: 10, Jauge.caisses: -15});
    expect(j.armee, 60);
    expect(j.caisses, 35);
    expect(j.peuple, 50);
    expect(j.presse, 50);
  });

  test('applique borne entre 0 et 100', () {
    final basse = const Jauges(peuple: 5, armee: 95, caisses: 50, presse: 50)
        .applique({Jauge.peuple: -20, Jauge.armee: 20});
    expect(basse.peuple, 0);
    expect(basse.armee, 100);
  });

  test('extreme signale la premiere jauge a bout, dans l ordre', () {
    expect(Jauges.milieu.extreme(), isNull);
    expect(const Jauges(peuple: 0, armee: 50, caisses: 50, presse: 50).extreme(), Jauge.peuple);
    expect(const Jauges(peuple: 50, armee: 50, caisses: 100, presse: 0).extreme(), Jauge.caisses);
  });

  test('valeur lit la bonne jauge', () {
    const j = Jauges(peuple: 1, armee: 2, caisses: 3, presse: 4);
    expect(j.valeur(Jauge.presse), 4);
  });
}
EOF
flutter test test/moteur/jauges_test.dart
```

Attendu : ÉCHEC, `lib/moteur/jauges.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
mkdir -p lib/moteur
cat > lib/moteur/jauges.dart << 'EOF'
/// Les quatre jauges du mandat, toujours dans cet ordre.
enum Jauge { peuple, armee, caisses, presse }

/// Un état des quatre jauges. Immuable : appliquer des effets rend un
/// nouvel objet, ce qui rend le moteur facile à tester et à rejouer.
class Jauges {
  const Jauges({required this.peuple, required this.armee, required this.caisses, required this.presse});

  final int peuple;
  final int armee;
  final int caisses;
  final int presse;

  static const milieu = Jauges(peuple: 50, armee: 50, caisses: 50, presse: 50);

  int valeur(Jauge j) => switch (j) {
        Jauge.peuple => peuple,
        Jauge.armee => armee,
        Jauge.caisses => caisses,
        Jauge.presse => presse,
      };

  /// Additionne les effets et borne chaque jauge entre 0 et 100.
  Jauges applique(Map<Jauge, int> effets) {
    int v(Jauge j) => (valeur(j) + (effets[j] ?? 0)).clamp(0, 100);
    return Jauges(
      peuple: v(Jauge.peuple),
      armee: v(Jauge.armee),
      caisses: v(Jauge.caisses),
      presse: v(Jauge.presse),
    );
  }

  /// La première jauge arrivée à un bout, ou null si le mandat continue.
  Jauge? extreme() {
    for (final j in Jauge.values) {
      final v = valeur(j);
      if (v <= 0 || v >= 100) return j;
    }
    return null;
  }

  @override
  String toString() => 'Jauges(P$peuple A$armee C$caisses Pr$presse)';
}
EOF
flutter test test/moteur/jauges_test.dart
```

Attendu : quatre tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/moteur/jauges.dart test/moteur/jauges_test.dart
git commit -m "Moteur : les quatre jauges

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 3 : Les modèles de contenu et leur lecture JSON

**Fichiers :**
- Créer : `lib/moteur/modeles.dart`
- Test : `test/moteur/modeles_test.dart`

**Interfaces :**
- Consomme : `Jauge`, `Jauges` (tâche 2).
- Produit :
  - `enum Humeur { neutre, content, fache }`
  - `class Reponse { String libelle; Map<Jauge,int> effets; List<String> drapeaux; Reponse.depuisJson(Map<String,dynamic>) }`
  - `class Chaine { String id; int rang; int delaiMin; }`
  - `class Conditions { int mandatMin, jourMin, jourMax; Map<Jauge,int> minimums, maximums; List<String> drapeauxRequis, drapeauxInterdits, parcours; Conditions.depuisJson(Map<String,dynamic>?) }`
  - `class Carte { String id, personnage, texte; Humeur humeur; Reponse gauche, droite; Conditions conditions; int poids; Chaine? chaine; bool repetable; Carte.depuisJson(Map<String,dynamic>) }`
  - `class Personnage { String id, nom, titre; }`
  - `class Parcours { String id, nom, titre; bool femme; Jauges depart; String? conditionDeblocage; }`
  - `class Fin { String id; Jauge? jauge; bool versLeHaut; String titre, texte, image; }`

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/moteur/modeles_test.dart << 'EOF'
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';

void main() {
  test('une carte se lit depuis son JSON', () {
    final j = jsonDecode('''
    {
      "id": "general_solde_1",
      "personnage": "general",
      "humeur": "fache",
      "texte": "La solde a deux mois de retard.",
      "gauche": { "libelle": "Qu ils patientent", "effets": { "armee": -15, "caisses": 5 }, "drapeaux": ["solde_impayee"] },
      "droite": { "libelle": "On paie", "effets": { "armee": 10, "caisses": -15 } },
      "conditions": { "jour_min": 3, "caisses_max": 80 },
      "poids": 3,
      "chaine": { "id": "solde", "rang": 1, "delai_min": 4 }
    }
    ''') as Map<String, dynamic>;

    final c = Carte.depuisJson(j);
    expect(c.id, 'general_solde_1');
    expect(c.humeur, Humeur.fache);
    expect(c.gauche.effets[Jauge.armee], -15);
    expect(c.gauche.drapeaux, ['solde_impayee']);
    expect(c.droite.drapeaux, isEmpty);
    expect(c.conditions.jourMin, 3);
    expect(c.conditions.maximums[Jauge.caisses], 80);
    expect(c.poids, 3);
    expect(c.chaine!.rang, 1);
    expect(c.chaine!.delaiMin, 4);
    expect(c.repetable, isFalse);
  });

  test('les champs absents prennent leur valeur par defaut', () {
    final c = Carte.depuisJson(jsonDecode('''
    {
      "id": "x", "personnage": "p", "humeur": "neutre", "texte": "t",
      "gauche": { "libelle": "a", "effets": { "peuple": 1 } },
      "droite": { "libelle": "b", "effets": { "peuple": -1 } }
    }
    ''') as Map<String, dynamic>);
    expect(c.poids, 1);
    expect(c.chaine, isNull);
    expect(c.conditions.mandatMin, 1);
    expect(c.conditions.jourMin, 1);
    expect(c.conditions.parcours, isEmpty);
  });

  test('un parcours se lit depuis son JSON', () {
    final p = Parcours.depuisJson(jsonDecode('''
    {
      "id": "general", "nom": "L ancien general", "titre": "Monsieur le President",
      "femme": false, "depart": { "peuple": 40, "armee": 70, "caisses": 50, "presse": 40 }
    }
    ''') as Map<String, dynamic>);
    expect(p.depart.armee, 70);
    expect(p.femme, isFalse);
    expect(p.conditionDeblocage, isNull);
  });

  test('une fin se lit depuis son JSON', () {
    final f = Fin.depuisJson(jsonDecode('''
    { "id": "armee_bas", "jauge": "armee", "vers_le_haut": false, "titre": "Le palais est pris",
      "texte": "Les blindes sont entres a l aube.", "image": "fins/coup.jpg" }
    ''') as Map<String, dynamic>);
    expect(f.jauge, Jauge.armee);
    expect(f.versLeHaut, isFalse);
  });
}
EOF
flutter test test/moteur/modeles_test.dart
```

Attendu : ÉCHEC, `modeles.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/moteur/modeles.dart << 'EOF'
import 'jauges.dart';

/// Les trois expressions disponibles pour chaque personnage.
enum Humeur { neutre, content, fache }

Map<Jauge, int> _effets(Map<String, dynamic>? source) => {
      for (final e in (source ?? const <String, dynamic>{}).entries)
        Jauge.values.byName(e.key): (e.value as num).toInt(),
    };

List<String> _textes(dynamic source) => ((source as List?) ?? const []).cast<String>();

/// Une des deux réponses possibles à une carte.
class Reponse {
  const Reponse({required this.libelle, required this.effets, this.drapeaux = const []});

  final String libelle;
  final Map<Jauge, int> effets;

  /// Marques posées dans la partie, que d'autres cartes pourront exiger.
  final List<String> drapeaux;

  factory Reponse.depuisJson(Map<String, dynamic> j) => Reponse(
        libelle: j['libelle'] as String,
        effets: _effets(j['effets'] as Map<String, dynamic>?),
        drapeaux: _textes(j['drapeaux']),
      );
}

/// Place d'une carte dans une suite d'événements liés.
class Chaine {
  const Chaine({required this.id, required this.rang, this.delaiMin = 0});

  final String id;
  final int rang;

  /// Nombre de jours minimum depuis la carte précédente de la chaîne.
  final int delaiMin;

  factory Chaine.depuisJson(Map<String, dynamic> j) => Chaine(
        id: j['id'] as String,
        rang: (j['rang'] as num).toInt(),
        delaiMin: ((j['delai_min'] as num?) ?? 0).toInt(),
      );
}

/// Ce qui doit être vrai pour qu'une carte puisse sortir.
class Conditions {
  const Conditions({
    this.mandatMin = 1,
    this.jourMin = 1,
    this.jourMax = 9999,
    this.minimums = const {},
    this.maximums = const {},
    this.drapeauxRequis = const [],
    this.drapeauxInterdits = const [],
    this.parcours = const [],
  });

  final int mandatMin;
  final int jourMin;
  final int jourMax;

  /// Jauge -> valeur plancher, la carte ne sort que si la jauge est au-dessus.
  final Map<Jauge, int> minimums;

  /// Jauge -> valeur plafond, la carte ne sort que si la jauge est en dessous.
  final Map<Jauge, int> maximums;

  final List<String> drapeauxRequis;
  final List<String> drapeauxInterdits;

  /// Parcours autorisés ; vide signifie « tous ».
  final List<String> parcours;

  factory Conditions.depuisJson(Map<String, dynamic>? j) {
    if (j == null) return const Conditions();
    final minimums = <Jauge, int>{};
    final maximums = <Jauge, int>{};
    for (final jauge in Jauge.values) {
      final min = j['${jauge.name}_min'] as num?;
      final max = j['${jauge.name}_max'] as num?;
      if (min != null) minimums[jauge] = min.toInt();
      if (max != null) maximums[jauge] = max.toInt();
    }
    return Conditions(
      mandatMin: ((j['mandat_min'] as num?) ?? 1).toInt(),
      jourMin: ((j['jour_min'] as num?) ?? 1).toInt(),
      jourMax: ((j['jour_max'] as num?) ?? 9999).toInt(),
      minimums: minimums,
      maximums: maximums,
      drapeauxRequis: _textes(j['drapeaux_requis']),
      drapeauxInterdits: _textes(j['drapeaux_interdits']),
      parcours: _textes(j['parcours']),
    );
  }
}

/// Une carte : un personnage, une phrase, deux réponses.
class Carte {
  const Carte({
    required this.id,
    required this.personnage,
    required this.humeur,
    required this.texte,
    required this.gauche,
    required this.droite,
    this.conditions = const Conditions(),
    this.poids = 1,
    this.chaine,
    this.repetable = false,
  });

  final String id;
  final String personnage;
  final Humeur humeur;
  final String texte;
  final Reponse gauche;
  final Reponse droite;
  final Conditions conditions;

  /// Poids du tirage : une carte de poids 3 sort trois fois plus souvent.
  final int poids;
  final Chaine? chaine;
  final bool repetable;

  factory Carte.depuisJson(Map<String, dynamic> j) => Carte(
        id: j['id'] as String,
        personnage: j['personnage'] as String,
        humeur: Humeur.values.byName((j['humeur'] as String?) ?? 'neutre'),
        texte: j['texte'] as String,
        gauche: Reponse.depuisJson(j['gauche'] as Map<String, dynamic>),
        droite: Reponse.depuisJson(j['droite'] as Map<String, dynamic>),
        conditions: Conditions.depuisJson(j['conditions'] as Map<String, dynamic>?),
        poids: ((j['poids'] as num?) ?? 1).toInt(),
        chaine: j['chaine'] == null ? null : Chaine.depuisJson(j['chaine'] as Map<String, dynamic>),
        repetable: (j['repetable'] as bool?) ?? false,
      );
}

/// Quelqu'un qui vient voir le Président.
class Personnage {
  const Personnage({required this.id, required this.nom, required this.titre});

  final String id;
  final String nom;
  final String titre;

  factory Personnage.depuisJson(Map<String, dynamic> j) => Personnage(
        id: j['id'] as String,
        nom: j['nom'] as String,
        titre: j['titre'] as String,
      );

  /// Chemin de l'image pour une humeur donnée.
  String image(Humeur h) => 'assets/images/personnages/${id}_${h.name}.jpg';
}

/// Qui le joueur était avant d'être élu.
class Parcours {
  const Parcours({
    required this.id,
    required this.nom,
    required this.titre,
    required this.femme,
    required this.depart,
    this.conditionDeblocage,
  });

  final String id;
  final String nom;

  /// « Monsieur le Président » ou « Madame la Présidente ».
  final String titre;
  final bool femme;
  final Jauges depart;

  /// Texte affiché sur un parcours verrouillé ; null si ouvert dès le début.
  final String? conditionDeblocage;

  factory Parcours.depuisJson(Map<String, dynamic> j) {
    final d = j['depart'] as Map<String, dynamic>;
    return Parcours(
      id: j['id'] as String,
      nom: j['nom'] as String,
      titre: j['titre'] as String,
      femme: j['femme'] as bool,
      depart: Jauges(
        peuple: (d['peuple'] as num).toInt(),
        armee: (d['armee'] as num).toInt(),
        caisses: (d['caisses'] as num).toInt(),
        presse: (d['presse'] as num).toInt(),
      ),
      conditionDeblocage: j['condition_deblocage'] as String?,
    );
  }

  bool get ouvertDesLeDebut => conditionDeblocage == null;
}

/// Comment un mandat se termine.
class Fin {
  const Fin({
    required this.id,
    required this.jauge,
    required this.versLeHaut,
    required this.titre,
    required this.texte,
    required this.image,
  });

  /// La jauge fautive, ou null pour les fins d'élection.
  final Jauge? jauge;

  /// true si la jauge a débordé, false si elle s'est vidée.
  final bool versLeHaut;
  final String id;
  final String titre;
  final String texte;
  final String image;

  factory Fin.depuisJson(Map<String, dynamic> j) => Fin(
        id: j['id'] as String,
        jauge: j['jauge'] == null ? null : Jauge.values.byName(j['jauge'] as String),
        versLeHaut: (j['vers_le_haut'] as bool?) ?? false,
        titre: j['titre'] as String,
        texte: j['texte'] as String,
        image: j['image'] as String,
      );
}
EOF
flutter test test/moteur/modeles_test.dart
```

Attendu : quatre tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/moteur/modeles.dart test/moteur/modeles_test.dart
git commit -m "Moteur : modeles de contenu et lecture JSON

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 4 : L'état d'une partie et l'évaluation des conditions

**Fichiers :**
- Créer : `lib/moteur/etat_partie.dart`
- Test : `test/moteur/etat_partie_test.dart`

**Interfaces :**
- Consomme : `Jauges`, `Jauge` (tâche 2) ; `Conditions`, `Chaine` (tâche 3).
- Produit :
  - `class EtatPartie` avec `const EtatPartie({required String parcours, required String nomJoueur, required Jauges jauges, int jour = 1, int mandat = 1, Set<String> drapeaux = const {}, Set<String> vues = const {}, Map<String,int> chainesRang = const {}, Map<String,int> chainesJour = const {}})` et `EtatPartie copie({Jauges? jauges, int? jour, int? mandat, Set<String>? drapeaux, Set<String>? vues, Map<String,int>? chainesRang, Map<String,int>? chainesJour})`.
  - `extension ConditionsSurEtat on Conditions { bool satisfaites(EtatPartie etat) }`

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/moteur/etat_partie_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';

EtatPartie etat({
  Jauges? jauges,
  int jour = 5,
  int mandat = 1,
  Set<String> drapeaux = const {},
  String parcours = 'general',
}) =>
    EtatPartie(
      parcours: parcours,
      nomJoueur: 'Awa',
      jauges: jauges ?? Jauges.milieu,
      jour: jour,
      mandat: mandat,
      drapeaux: drapeaux,
    );

void main() {
  test('sans condition, la carte peut sortir', () {
    expect(const Conditions().satisfaites(etat()), isTrue);
  });

  test('le jour minimum et maximum sont respectes', () {
    expect(const Conditions(jourMin: 6).satisfaites(etat(jour: 5)), isFalse);
    expect(const Conditions(jourMin: 5).satisfaites(etat(jour: 5)), isTrue);
    expect(const Conditions(jourMax: 4).satisfaites(etat(jour: 5)), isFalse);
  });

  test('le mandat minimum est respecte', () {
    expect(const Conditions(mandatMin: 2).satisfaites(etat(mandat: 1)), isFalse);
    expect(const Conditions(mandatMin: 2).satisfaites(etat(mandat: 2)), isTrue);
  });

  test('les planchers et plafonds de jauges sont respectes', () {
    final pauvre = etat(jauges: const Jauges(peuple: 50, armee: 50, caisses: 20, presse: 50));
    expect(const Conditions(maximums: {Jauge.caisses: 30}).satisfaites(pauvre), isTrue);
    expect(const Conditions(maximums: {Jauge.caisses: 10}).satisfaites(pauvre), isFalse);
    expect(const Conditions(minimums: {Jauge.caisses: 30}).satisfaites(pauvre), isFalse);
    expect(const Conditions(minimums: {Jauge.caisses: 10}).satisfaites(pauvre), isTrue);
  });

  test('les drapeaux requis et interdits sont respectes', () {
    final avec = etat(drapeaux: {'solde_impayee'});
    expect(const Conditions(drapeauxRequis: ['solde_impayee']).satisfaites(avec), isTrue);
    expect(const Conditions(drapeauxRequis: ['solde_impayee']).satisfaites(etat()), isFalse);
    expect(const Conditions(drapeauxInterdits: ['solde_impayee']).satisfaites(avec), isFalse);
  });

  test('le parcours filtre les cartes personnelles', () {
    expect(const Conditions(parcours: ['general']).satisfaites(etat(parcours: 'general')), isTrue);
    expect(const Conditions(parcours: ['general']).satisfaites(etat(parcours: 'professeure')), isFalse);
    expect(const Conditions().satisfaites(etat(parcours: 'professeure')), isTrue);
  });

  test('copie ne change que ce qu on lui donne', () {
    final e = etat();
    final f = e.copie(jour: 9, drapeaux: {'x'});
    expect(f.jour, 9);
    expect(f.drapeaux, {'x'});
    expect(f.mandat, e.mandat);
    expect(f.nomJoueur, 'Awa');
    expect(e.jour, 5, reason: 'l etat d origine reste intact');
  });
}
EOF
flutter test test/moteur/etat_partie_test.dart
```

Attendu : ÉCHEC, `etat_partie.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/moteur/etat_partie.dart << 'EOF'
import 'jauges.dart';
import 'modeles.dart';

/// Tout ce qui décrit un mandat en cours. Immuable : chaque réponse rend un
/// nouvel état, ce qui permet de rejouer et de tester une partie pas à pas.
class EtatPartie {
  const EtatPartie({
    required this.parcours,
    required this.nomJoueur,
    required this.jauges,
    this.jour = 1,
    this.mandat = 1,
    this.drapeaux = const {},
    this.vues = const {},
    this.chainesRang = const {},
    this.chainesJour = const {},
  });

  final String parcours;
  final String nomJoueur;
  final Jauges jauges;
  final int jour;
  final int mandat;

  /// Marques laissées par les réponses précédentes.
  final Set<String> drapeaux;

  /// Identifiants des cartes déjà sorties dans ce mandat.
  final Set<String> vues;

  /// Chaîne -> dernier rang joué.
  final Map<String, int> chainesRang;

  /// Chaîne -> jour du dernier rang joué.
  final Map<String, int> chainesJour;

  EtatPartie copie({
    Jauges? jauges,
    int? jour,
    int? mandat,
    Set<String>? drapeaux,
    Set<String>? vues,
    Map<String, int>? chainesRang,
    Map<String, int>? chainesJour,
  }) =>
      EtatPartie(
        parcours: parcours,
        nomJoueur: nomJoueur,
        jauges: jauges ?? this.jauges,
        jour: jour ?? this.jour,
        mandat: mandat ?? this.mandat,
        drapeaux: drapeaux ?? this.drapeaux,
        vues: vues ?? this.vues,
        chainesRang: chainesRang ?? this.chainesRang,
        chainesJour: chainesJour ?? this.chainesJour,
      );
}

/// Évaluation des conditions d'une carte contre l'état courant.
extension ConditionsSurEtat on Conditions {
  bool satisfaites(EtatPartie etat) {
    if (etat.mandat < mandatMin) return false;
    if (etat.jour < jourMin || etat.jour > jourMax) return false;
    for (final e in minimums.entries) {
      if (etat.jauges.valeur(e.key) < e.value) return false;
    }
    for (final e in maximums.entries) {
      if (etat.jauges.valeur(e.key) > e.value) return false;
    }
    for (final d in drapeauxRequis) {
      if (!etat.drapeaux.contains(d)) return false;
    }
    for (final d in drapeauxInterdits) {
      if (etat.drapeaux.contains(d)) return false;
    }
    if (parcours.isNotEmpty && !parcours.contains(etat.parcours)) return false;
    return true;
  }
}
EOF
flutter test test/moteur/etat_partie_test.dart
```

Attendu : sept tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/moteur/etat_partie.dart test/moteur/etat_partie_test.dart
git commit -m "Moteur : etat de partie et evaluation des conditions

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 5 : Le tirage

**Fichiers :**
- Créer : `lib/moteur/tirage.dart`
- Test : `test/moteur/tirage_test.dart`

**Interfaces :**
- Consomme : `Carte`, `Chaine` (tâche 3) ; `EtatPartie`, `ConditionsSurEtat` (tâche 4).
- Produit : `Carte? choisitCarte({required List<Carte> paquet, required EtatPartie etat, required Random alea})`. Renvoie `null` quand aucune carte n'est jouable, ce qui termine le mandat faute de contenu.

Règles, dans l'ordre : on écarte les cartes déjà vues et non répétables, celles dont les conditions ne sont pas remplies, et les maillons de chaîne qui ne sont pas le suivant attendu ou dont le délai n'est pas écoulé. S'il reste des maillons de chaîne, le tirage se fait parmi eux seulement : une histoire commencée passe avant une carte ordinaire. Sinon, tirage au hasard pondéré par le poids.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/moteur/tirage_test.dart << 'EOF'
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/tirage.dart';

Carte carte(String id, {Conditions? conditions, int poids = 1, Chaine? chaine, bool repetable = false}) => Carte(
      id: id,
      personnage: 'general',
      humeur: Humeur.neutre,
      texte: 'texte',
      gauche: const Reponse(libelle: 'non', effets: {Jauge.armee: -5}),
      droite: const Reponse(libelle: 'oui', effets: {Jauge.armee: 5}),
      conditions: conditions ?? const Conditions(),
      poids: poids,
      chaine: chaine,
      repetable: repetable,
    );

EtatPartie etat({int jour = 5, Set<String> vues = const {}, Map<String, int> rangs = const {}, Map<String, int> jours = const {}}) =>
    EtatPartie(
      parcours: 'general',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      jour: jour,
      vues: vues,
      chainesRang: rangs,
      chainesJour: jours,
    );

void main() {
  test('une carte deja vue ne ressort pas', () {
    final tiree = choisitCarte(paquet: [carte('a'), carte('b')], etat: etat(vues: {'a'}), alea: Random(1));
    expect(tiree!.id, 'b');
  });

  test('une carte repetable peut ressortir', () {
    final tiree = choisitCarte(paquet: [carte('a', repetable: true)], etat: etat(vues: {'a'}), alea: Random(1));
    expect(tiree!.id, 'a');
  });

  test('une carte dont les conditions ne sont pas remplies est ecartee', () {
    final tiree = choisitCarte(
      paquet: [carte('tot', conditions: const Conditions(jourMin: 99)), carte('ok')],
      etat: etat(),
      alea: Random(1),
    );
    expect(tiree!.id, 'ok');
  });

  test('le paquet epuise rend null', () {
    expect(choisitCarte(paquet: [carte('a')], etat: etat(vues: {'a'}), alea: Random(1)), isNull);
  });

  test('le maillon suivant d une chaine passe avant une carte ordinaire', () {
    final paquet = [
      carte('ordinaire', poids: 50),
      carte('suite', chaine: const Chaine(id: 'solde', rang: 2)),
    ];
    final tiree = choisitCarte(paquet: paquet, etat: etat(rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tiree!.id, 'suite');
  });

  test('un maillon hors sequence est ecarte', () {
    final paquet = [
      carte('ordinaire'),
      carte('trop_loin', chaine: const Chaine(id: 'solde', rang: 3)),
    ];
    final tiree = choisitCarte(paquet: paquet, etat: etat(rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tiree!.id, 'ordinaire');
  });

  test('un maillon dont le delai n est pas ecoule attend', () {
    final paquet = [
      carte('ordinaire'),
      carte('suite', chaine: const Chaine(id: 'solde', rang: 2, delaiMin: 4)),
    ];
    final tot = choisitCarte(paquet: paquet, etat: etat(jour: 3, rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tot!.id, 'ordinaire');
    final tard = choisitCarte(paquet: paquet, etat: etat(jour: 5, rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tard!.id, 'suite');
  });

  test('le poids augmente la frequence', () {
    final paquet = [carte('rare', poids: 1, repetable: true), carte('courante', poids: 9, repetable: true)];
    final alea = Random(42);
    var courante = 0;
    for (var i = 0; i < 1000; i++) {
      if (choisitCarte(paquet: paquet, etat: etat(), alea: alea)!.id == 'courante') courante++;
    }
    expect(courante, greaterThan(820));
    expect(courante, lessThan(980));
  });

  test('a graine egale, le tirage est identique', () {
    final paquet = [carte('a', repetable: true), carte('b', repetable: true), carte('c', repetable: true)];
    List<String> serie(int graine) {
      final alea = Random(graine);
      return [for (var i = 0; i < 20; i++) choisitCarte(paquet: paquet, etat: etat(), alea: alea)!.id];
    }

    expect(serie(3), serie(3));
  });
}
EOF
flutter test test/moteur/tirage_test.dart
```

Attendu : ÉCHEC, `tirage.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/moteur/tirage.dart << 'EOF'
import 'dart:math';

import 'etat_partie.dart';
import 'modeles.dart';

/// Choisit la carte du jour, ou null si plus rien n'est jouable.
Carte? choisitCarte({required List<Carte> paquet, required EtatPartie etat, required Random alea}) {
  final jouables = <Carte>[];
  for (final c in paquet) {
    if (!c.repetable && etat.vues.contains(c.id)) continue;
    if (!c.conditions.satisfaites(etat)) continue;
    final ch = c.chaine;
    if (ch != null) {
      final rangAtteint = etat.chainesRang[ch.id] ?? 0;
      if (ch.rang != rangAtteint + 1) continue;
      final dernierJour = etat.chainesJour[ch.id];
      if (dernierJour != null && etat.jour - dernierJour < ch.delaiMin) continue;
    }
    jouables.add(c);
  }
  if (jouables.isEmpty) return null;

  // Une histoire commencée passe avant une situation ordinaire.
  final maillons = jouables.where((c) => c.chaine != null).toList();
  return _tirePondere(maillons.isNotEmpty ? maillons : jouables, alea);
}

Carte _tirePondere(List<Carte> cartes, Random alea) {
  final total = cartes.fold<int>(0, (s, c) => s + (c.poids < 1 ? 1 : c.poids));
  var seuil = alea.nextInt(total);
  for (final c in cartes) {
    seuil -= c.poids < 1 ? 1 : c.poids;
    if (seuil < 0) return c;
  }
  return cartes.last;
}
EOF
flutter test test/moteur/tirage_test.dart
```

Attendu : neuf tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/moteur/tirage.dart test/moteur/tirage_test.dart
git commit -m "Moteur : tirage des cartes, chaines prioritaires

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 6 : Répondre à une carte

**Fichiers :**
- Créer : `lib/moteur/partie.dart`
- Test : `test/moteur/partie_test.dart`

**Interfaces :**
- Consomme : `Carte`, `Reponse` (tâche 3) ; `EtatPartie` (tâche 4).
- Produit : `enum Cote { gauche, droite }` ; `EtatPartie repond({required EtatPartie etat, required Carte carte, required Cote cote})`.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/moteur/partie_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';

final carteSolde = Carte(
  id: 'general_solde_1',
  personnage: 'general',
  humeur: Humeur.fache,
  texte: 'La solde a deux mois de retard.',
  gauche: const Reponse(libelle: 'Patientez', effets: {Jauge.armee: -15, Jauge.caisses: 5}, drapeaux: ['solde_impayee']),
  droite: const Reponse(libelle: 'On paie', effets: {Jauge.armee: 10, Jauge.caisses: -15}),
  chaine: const Chaine(id: 'solde', rang: 1),
);

EtatPartie depart() => const EtatPartie(parcours: 'general', nomJoueur: 'Awa', jauges: Jauges.milieu);

void main() {
  test('la reponse de gauche applique ses effets et pose ses drapeaux', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.gauche);
    expect(e.jauges.armee, 35);
    expect(e.jauges.caisses, 55);
    expect(e.drapeaux, contains('solde_impayee'));
  });

  test('la reponse de droite applique ses propres effets', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.droite);
    expect(e.jauges.armee, 60);
    expect(e.jauges.caisses, 35);
    expect(e.drapeaux, isEmpty);
  });

  test('le jour avance et la carte est retenue comme vue', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.droite);
    expect(e.jour, 2);
    expect(e.vues, contains('general_solde_1'));
  });

  test('la chaine memorise son rang et son jour', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.droite);
    expect(e.chainesRang['solde'], 1);
    expect(e.chainesJour['solde'], 1);
  });

  test('l etat d origine n est pas modifie', () {
    final avant = depart();
    repond(etat: avant, carte: carteSolde, cote: Cote.gauche);
    expect(avant.jour, 1);
    expect(avant.jauges.armee, 50);
    expect(avant.drapeaux, isEmpty);
  });
}
EOF
flutter test test/moteur/partie_test.dart
```

Attendu : ÉCHEC, `partie.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/moteur/partie.dart << 'EOF'
import 'etat_partie.dart';
import 'modeles.dart';

/// Le côté vers lequel le joueur a glissé la carte.
enum Cote { gauche, droite }

/// Applique une réponse et rend l'état du lendemain.
EtatPartie repond({required EtatPartie etat, required Carte carte, required Cote cote}) {
  final reponse = cote == Cote.gauche ? carte.gauche : carte.droite;

  final drapeaux = {...etat.drapeaux, ...reponse.drapeaux};
  final vues = {...etat.vues, carte.id};

  final chainesRang = {...etat.chainesRang};
  final chainesJour = {...etat.chainesJour};
  final ch = carte.chaine;
  if (ch != null) {
    chainesRang[ch.id] = ch.rang;
    chainesJour[ch.id] = etat.jour;
  }

  return etat.copie(
    jauges: etat.jauges.applique(reponse.effets),
    jour: etat.jour + 1,
    drapeaux: drapeaux,
    vues: vues,
    chainesRang: chainesRang,
    chainesJour: chainesJour,
  );
}
EOF
flutter test test/moteur/partie_test.dart
```

Attendu : cinq tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/moteur/partie.dart test/moteur/partie_test.dart
git commit -m "Moteur : application d une reponse

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 7 : La chute et l'élection

**Fichiers :**
- Créer : `lib/moteur/denouement.dart`
- Test : `test/moteur/denouement_test.dart`

**Interfaces :**
- Consomme : `Jauge`, `Jauges` (tâche 2) ; `Fin` (tâche 3) ; `EtatPartie` (tâche 4).
- Produit :
  - `const int dureeMandatPrototype = 30;`
  - `enum TypeDenouement { chute, electionGagnee, electionPerdue }`
  - `class Denouement { final TypeDenouement type; final Jauge? jauge; final bool versLeHaut; }`
  - `Denouement? evalue(EtatPartie etat, {int duree = dureeMandatPrototype})`
  - `Fin? choisitFin(Denouement d, List<Fin> fins)`

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/moteur/denouement_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';

EtatPartie etat(Jauges j, {int jour = 5}) =>
    EtatPartie(parcours: 'general', nomJoueur: 'Awa', jauges: j, jour: jour);

const fins = [
  Fin(id: 'armee_bas', jauge: Jauge.armee, versLeHaut: false, titre: 'Coup d Etat', texte: 't', image: 'i'),
  Fin(id: 'armee_haut', jauge: Jauge.armee, versLeHaut: true, titre: 'L armee gouverne', texte: 't', image: 'i'),
  Fin(id: 'election_gagnee', jauge: null, versLeHaut: true, titre: 'Reelu', texte: 't', image: 'i'),
  Fin(id: 'election_perdue', jauge: null, versLeHaut: false, titre: 'Battu', texte: 't', image: 'i'),
];

void main() {
  test('tant que tout va bien, il n y a pas de denouement', () {
    expect(evalue(etat(Jauges.milieu)), isNull);
  });

  test('une jauge vide fait chuter', () {
    final d = evalue(etat(const Jauges(peuple: 50, armee: 0, caisses: 50, presse: 50)))!;
    expect(d.type, TypeDenouement.chute);
    expect(d.jauge, Jauge.armee);
    expect(d.versLeHaut, isFalse);
  });

  test('une jauge pleine fait chuter aussi', () {
    final d = evalue(etat(const Jauges(peuple: 50, armee: 100, caisses: 50, presse: 50)))!;
    expect(d.type, TypeDenouement.chute);
    expect(d.jauge, Jauge.armee);
    expect(d.versLeHaut, isTrue);
  });

  test('au dela de la duree, l election est gagnee si peuple et presse depassent 50', () {
    final d = evalue(etat(const Jauges(peuple: 60, armee: 50, caisses: 50, presse: 45), jour: 31))!;
    expect(d.type, TypeDenouement.electionGagnee);
  });

  test('au dela de la duree, l election est perdue si la moyenne est trop basse', () {
    final d = evalue(etat(const Jauges(peuple: 40, armee: 50, caisses: 50, presse: 45), jour: 31))!;
    expect(d.type, TypeDenouement.electionPerdue);
  });

  test('la chute passe avant l election', () {
    final d = evalue(etat(const Jauges(peuple: 0, armee: 50, caisses: 50, presse: 90), jour: 31))!;
    expect(d.type, TypeDenouement.chute);
  });

  test('choisitFin trouve la fin correspondante', () {
    final chute = evalue(etat(const Jauges(peuple: 50, armee: 100, caisses: 50, presse: 50)))!;
    expect(choisitFin(chute, fins)!.id, 'armee_haut');

    final gagnee = evalue(etat(const Jauges(peuple: 80, armee: 50, caisses: 50, presse: 80), jour: 31))!;
    expect(choisitFin(gagnee, fins)!.id, 'election_gagnee');
  });

  test('choisitFin rend null si la fin manque au contenu', () {
    final chute = evalue(etat(const Jauges(peuple: 0, armee: 50, caisses: 50, presse: 50)))!;
    expect(choisitFin(chute, fins), isNull);
  });
}
EOF
flutter test test/moteur/denouement_test.dart
```

Attendu : ÉCHEC, `denouement.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/moteur/denouement.dart << 'EOF'
import 'etat_partie.dart';
import 'jauges.dart';
import 'modeles.dart';

/// Durée d'un mandat dans le prototype. Le lancement passera à 100, quand il
/// y aura assez de cartes pour tenir cent jours sans se répéter.
const int dureeMandatPrototype = 30;

enum TypeDenouement { chute, electionGagnee, electionPerdue }

/// Pourquoi et comment le mandat s'arrête.
class Denouement {
  const Denouement({required this.type, this.jauge, this.versLeHaut = false});

  final TypeDenouement type;

  /// La jauge fautive en cas de chute, null pour une élection.
  final Jauge? jauge;

  /// true si la jauge a débordé, false si elle s'est vidée.
  final bool versLeHaut;
}

/// Rend le dénouement si le mandat s'arrête, null s'il continue.
Denouement? evalue(EtatPartie etat, {int duree = dureeMandatPrototype}) {
  final fautive = etat.jauges.extreme();
  if (fautive != null) {
    return Denouement(
      type: TypeDenouement.chute,
      jauge: fautive,
      versLeHaut: etat.jauges.valeur(fautive) >= 100,
    );
  }
  if (etat.jour > duree) {
    final moyenne = (etat.jauges.peuple + etat.jauges.presse) / 2;
    return Denouement(type: moyenne > 50 ? TypeDenouement.electionGagnee : TypeDenouement.electionPerdue);
  }
  return null;
}

/// La fin écrite qui correspond au dénouement, ou null si le contenu ne la
/// fournit pas encore.
Fin? choisitFin(Denouement d, List<Fin> fins) {
  for (final f in fins) {
    switch (d.type) {
      case TypeDenouement.chute:
        if (f.jauge == d.jauge && f.versLeHaut == d.versLeHaut) return f;
      case TypeDenouement.electionGagnee:
        if (f.jauge == null && f.versLeHaut) return f;
      case TypeDenouement.electionPerdue:
        if (f.jauge == null && !f.versLeHaut) return f;
    }
  }
  return null;
}
EOF
flutter test test/moteur/denouement_test.dart
```

Attendu : huit tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/moteur/denouement.dart test/moteur/denouement_test.dart
git commit -m "Moteur : chute, election et choix de la fin

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 8 : Charger le contenu et le contrôler

**Fichiers :**
- Créer : `lib/contenu/chargement.dart`, `lib/contenu/validation.dart`
- Test : `test/contenu/validation_test.dart`

**Interfaces :**
- Consomme : tous les modèles de la tâche 3.
- Produit :
  - `class Contenu { List<Carte> cartes; Map<String,Personnage> personnages; List<Parcours> parcours; List<Fin> fins; static Contenu depuisChaines({required String cartes, required String personnages, required String parcours, required String fins}); static Future<Contenu> depuisAssets(AssetBundle bundle); }`
  - `List<String> valide(Contenu contenu)` — la liste des problèmes, vide si tout va bien.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
mkdir -p test/contenu
cat > test/contenu/validation_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';

const personnages = '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]';
const parcours = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
    '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}}]';
const fins = '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
    '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';

String carte({
  String id = 'a',
  String personnage = 'general',
  String texte = 'Une phrase courte.',
  String libelleGauche = 'Non',
  String effetsGauche = '{"armee":-10}',
  String extra = '',
}) =>
    '{"id":"$id","personnage":"$personnage","humeur":"neutre","texte":"$texte",'
    '"gauche":{"libelle":"$libelleGauche","effets":$effetsGauche},'
    '"droite":{"libelle":"Oui","effets":{"armee":10}}$extra}';

Contenu contenuAvec(String cartes) =>
    Contenu.depuisChaines(cartes: '[$cartes]', personnages: personnages, parcours: parcours, fins: fins);

void main() {
  test('un contenu correct ne remonte aucun probleme', () {
    expect(valide(contenuAvec(carte())), isEmpty);
  });

  test('deux cartes avec le meme identifiant', () {
    expect(valide(contenuAvec('${carte(id: 'a')},${carte(id: 'a')}')).join(), contains('identifiant'));
  });

  test('un personnage inconnu', () {
    expect(valide(contenuAvec(carte(personnage: 'fantome'))).join(), contains('personnage'));
  });

  test('un texte trop long', () {
    expect(valide(contenuAvec(carte(texte: 'x' * 141))).join(), contains('140'));
  });

  test('un libelle trop long', () {
    expect(valide(contenuAvec(carte(libelleGauche: 'x' * 19))).join(), contains('18'));
  });

  test('un effet hors bornes', () {
    expect(valide(contenuAvec(carte(effetsGauche: '{"armee":-30}'))).join(), contains('20'));
  });

  test('une reponse sans effet', () {
    expect(valide(contenuAvec(carte(effetsGauche: '{}'))).join(), contains('effet'));
  });

  test('un drapeau exige que personne ne pose', () {
    final c = carte(extra: ',"conditions":{"drapeaux_requis":["jamais_pose"]}');
    expect(valide(contenuAvec(c)).join(), contains('jamais_pose'));
  });

  test('une chaine a trou', () {
    final un = carte(id: 'c1', extra: ',"chaine":{"id":"affaire","rang":1}');
    final trois = carte(id: 'c3', extra: ',"chaine":{"id":"affaire","rang":3}');
    expect(valide(contenuAvec('$un,$trois')).join(), contains('affaire'));
  });

  test('des conditions impossibles', () {
    final c = carte(extra: ',"conditions":{"jour_min":10,"jour_max":4}');
    expect(valide(contenuAvec(c)).join(), contains('impossible'));
  });

  test('un pays reel dans le texte', () {
    expect(valide(contenuAvec(carte(texte: 'Le Senegal nous observe.'))).join(), contains('interdit'));
  });

  test('un parcours inconnu dans les conditions', () {
    final c = carte(extra: ',"conditions":{"parcours":["pilote"]}');
    expect(valide(contenuAvec(c)).join(), contains('pilote'));
  });
}
EOF
flutter test test/contenu/validation_test.dart
```

Attendu : ÉCHEC, les fichiers de contenu n'existent pas.

- [ ] **Étape 2 : Écrire le chargement**

```bash
mkdir -p lib/contenu
cat > lib/contenu/chargement.dart << 'EOF'
import 'dart:convert';

import 'package:flutter/services.dart';

import '../moteur/modeles.dart';

/// Tout le contenu du jeu, lu une fois au démarrage.
class Contenu {
  const Contenu({
    required this.cartes,
    required this.personnages,
    required this.parcours,
    required this.fins,
  });

  final List<Carte> cartes;
  final Map<String, Personnage> personnages;
  final List<Parcours> parcours;
  final List<Fin> fins;

  static List<Map<String, dynamic>> _liste(String source) =>
      (jsonDecode(source) as List).cast<Map<String, dynamic>>();

  static Contenu depuisChaines({
    required String cartes,
    required String personnages,
    required String parcours,
    required String fins,
  }) {
    final gens = [for (final j in _liste(personnages)) Personnage.depuisJson(j)];
    return Contenu(
      cartes: [for (final j in _liste(cartes)) Carte.depuisJson(j)],
      personnages: {for (final p in gens) p.id: p},
      parcours: [for (final j in _liste(parcours)) Parcours.depuisJson(j)],
      fins: [for (final j in _liste(fins)) Fin.depuisJson(j)],
    );
  }

  static Future<Contenu> depuisAssets(AssetBundle bundle) async {
    Future<String> lis(String nom) => bundle.loadString('assets/contenu/$nom.json');
    return depuisChaines(
      cartes: await lis('cartes'),
      personnages: await lis('personnages'),
      parcours: await lis('parcours'),
      fins: await lis('fins'),
    );
  }

  Parcours? parcoursParId(String id) {
    for (final p in parcours) {
      if (p.id == id) return p;
    }
    return null;
  }
}
EOF
```

- [ ] **Étape 3 : Écrire le contrôle**

```bash
cat > lib/contenu/validation.dart << 'EOF'
import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import 'chargement.dart';

/// Mots qui n'ont rien à faire dans un jeu situé dans un pays imaginaire.
const _interdits = [
  'senegal', 'benin', 'cote d ivoire', 'ivoirien', 'togo', 'mali', 'niger', 'nigeria',
  'ghana', 'burkina', 'guinee', 'cameroun', 'tchad', 'france', 'francais', 'paris',
  'fmi', 'banque mondiale', 'onu', 'union africaine', 'cedeao', 'union europeenne',
];

String _sansAccents(String s) {
  const avec = 'àâäéèêëîïôöùûüç';
  const sans = 'aaaeeeeiioouuuc';
  var r = s.toLowerCase();
  for (var i = 0; i < avec.length; i++) {
    r = r.replaceAll(avec[i], sans[i]);
  }
  return r.replaceAll(RegExp(r"[^a-z0-9 ]"), ' ');
}

/// Passe tout le contenu en revue et rend la liste des problèmes trouvés.
/// Une liste vide signifie que le contenu est livrable.
List<String> valide(Contenu c) {
  final problemes = <String>[];

  final vus = <String>{};
  final drapeauxPoses = <String>{};
  final idsParcours = {for (final p in c.parcours) p.id};

  for (final carte in c.cartes) {
    for (final r in [carte.gauche, carte.droite]) {
      drapeauxPoses.addAll(r.drapeaux);
    }
  }

  for (final carte in c.cartes) {
    final ou = 'carte ${carte.id}';

    if (!vus.add(carte.id)) problemes.add('$ou : identifiant en double');
    if (!c.personnages.containsKey(carte.personnage)) {
      problemes.add('$ou : personnage inconnu « ${carte.personnage} »');
    }
    if (carte.texte.length > 140) problemes.add('$ou : texte de ${carte.texte.length} caractères, 140 au plus');
    if (carte.poids < 1) problemes.add('$ou : poids inférieur à 1');

    for (final r in [carte.gauche, carte.droite]) {
      if (r.libelle.length > 18) problemes.add('$ou : libellé « ${r.libelle} » de ${r.libelle.length} caractères, 18 au plus');
      if (r.effets.isEmpty) problemes.add('$ou : une réponse sans effet');
      if (r.effets.length > 3) problemes.add('$ou : une réponse touche ${r.effets.length} jauges, 3 au plus');
      for (final e in r.effets.entries) {
        if (e.value == 0) problemes.add('$ou : effet nul sur ${e.key.name}');
        if (e.value < -20 || e.value > 20) problemes.add('$ou : effet ${e.value} hors des bornes −20 à 20');
      }
    }

    final cond = carte.conditions;
    if (cond.jourMin > cond.jourMax) problemes.add('$ou : conditions impossibles, jour_min après jour_max');
    for (final j in Jauge.values) {
      final min = cond.minimums[j];
      final max = cond.maximums[j];
      if (min != null && max != null && min > max) {
        problemes.add('$ou : conditions impossibles sur ${j.name}');
      }
    }
    for (final d in cond.drapeauxRequis) {
      if (!drapeauxPoses.contains(d)) problemes.add('$ou : exige le drapeau « $d » que personne ne pose');
    }
    for (final p in cond.parcours) {
      if (!idsParcours.contains(p)) problemes.add('$ou : parcours inconnu « $p »');
    }

    final texte = _sansAccents('${carte.texte} ${carte.gauche.libelle} ${carte.droite.libelle}');
    for (final mot in _interdits) {
      if (texte.contains(mot)) problemes.add('$ou : mot interdit « $mot »');
    }
  }

  // Les chaînes doivent aller de 1 à n, sans trou ni doublon.
  final rangs = <String, List<int>>{};
  for (final carte in c.cartes) {
    final ch = carte.chaine;
    if (ch != null) rangs.putIfAbsent(ch.id, () => []).add(ch.rang);
  }
  for (final e in rangs.entries) {
    final attendus = [for (var i = 1; i <= e.value.length; i++) i];
    final tries = [...e.value]..sort();
    if (!_memeListe(tries, attendus)) {
      problemes.add('chaîne ${e.key} : rangs ${tries.join(", ")}, attendus ${attendus.join(", ")}');
    }
  }

  // Le joueur doit pouvoir gagner et perdre une élection.
  final aGagnee = c.fins.any((f) => f.jauge == null && f.versLeHaut);
  final aPerdue = c.fins.any((f) => f.jauge == null && !f.versLeHaut);
  if (!aGagnee) problemes.add('fins : il manque la fin d élection gagnée');
  if (!aPerdue) problemes.add('fins : il manque la fin d élection perdue');

  final clesFins = <String>{};
  for (final f in c.fins) {
    final cle = '${f.jauge?.name ?? "election"}_${f.versLeHaut}';
    if (!clesFins.add(cle)) problemes.add('fins : deux fins pour le même cas « $cle »');
  }

  if (c.parcours.where((p) => p.ouvertDesLeDebut).isEmpty) {
    problemes.add('parcours : aucun parcours ouvert dès le début');
  }

  return problemes;
}

bool _memeListe(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
EOF
flutter test test/contenu/validation_test.dart
```

Attendu : douze tests au vert.

- [ ] **Étape 4 : Commit**

```bash
flutter analyze && flutter test
git add lib/contenu test/contenu
git commit -m "Contenu : chargement et controle automatique

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 9 : La simulation d'équilibrage

**Fichiers :**
- Créer : `lib/moteur/simulation.dart`
- Test : `test/simulation_test.dart`

**Interfaces :**
- Consomme : `Contenu` (tâche 8) ; `EtatPartie`, `choisitCarte`, `repond`, `evalue` (tâches 4 à 7).
- Produit :
  - `enum Strategie { toujoursGauche, toujoursDroite, auHasard, equilibree }`
  - `class Mesures { int parties; double joursMoyens; Map<String,int> denouements; Set<String> cartesJamaisVues; }`
  - `Mesures simule({required Contenu contenu, required String parcours, required Strategie strategie, int parties = 1000, int graine = 1, int duree = dureeMandatPrototype})`

C'est l'outil d'équilibrage : il dit combien de jours tient un joueur, quelles fins sortent, et quelles cartes ne sortent jamais.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/simulation_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/simulation.dart';

/// Un paquet de dix cartes équilibrées, assez pour éprouver la mécanique
/// sans dépendre du contenu réel, qui est écrit plus tard.
Contenu paquetDEssai() {
  final cartes = [
    for (var i = 0; i < 10; i++)
      '{"id":"c$i","personnage":"general","humeur":"neutre","texte":"Situation $i",'
          '"gauche":{"libelle":"Non","effets":{"peuple":-6,"caisses":6}},'
          '"droite":{"libelle":"Oui","effets":{"peuple":6,"caisses":-6}},"repetable":true}'
  ].join(',');
  return Contenu.depuisChaines(
    cartes: '[$cartes]',
    personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
    parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
        '"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
    fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
        '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
  );
}

void main() {
  final contenu = paquetDEssai();

  test('toute partie se termine', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 200);
    expect(m.parties, 200);
    expect(m.denouements.values.fold<int>(0, (s, v) => s + v), 200);
  });

  test('glisser toujours du meme cote fait chuter vite', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.toujoursGauche, parties: 50);
    expect(m.joursMoyens, lessThan(15));
  });

  test('jouer au centre permet d atteindre l election', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.equilibree, parties: 50);
    expect(m.denouements.keys.any((k) => k.startsWith('election')), isTrue);
  });

  test('les cartes jamais tirees sont signalees', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 200);
    expect(m.cartesJamaisVues, isEmpty);
  });

  test('a graine egale, les mesures sont identiques', () {
    final a = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 100, graine: 5);
    final b = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 100, graine: 5);
    expect(a.joursMoyens, b.joursMoyens);
  });
}
EOF
flutter test test/simulation_test.dart
```

Attendu : ÉCHEC, `simulation.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/moteur/simulation.dart << 'EOF'
import 'dart:math';

import '../contenu/chargement.dart';
import 'denouement.dart';
import 'etat_partie.dart';
import 'jauges.dart';
import 'modeles.dart';
import 'partie.dart';
import 'tirage.dart';

/// Façons de jouer, pour éprouver l'équilibrage sans joueur humain.
enum Strategie { toujoursGauche, toujoursDroite, auHasard, equilibree }

/// Ce que la simulation mesure.
class Mesures {
  const Mesures({
    required this.parties,
    required this.joursMoyens,
    required this.denouements,
    required this.cartesJamaisVues,
  });

  final int parties;

  /// Durée moyenne d'un mandat, en jours.
  final double joursMoyens;

  /// Nom du dénouement -> nombre de parties qui s'y terminent.
  final Map<String, int> denouements;

  /// Cartes qu'aucune partie n'a tirées : du contenu écrit pour rien.
  final Set<String> cartesJamaisVues;
}

/// Joue un grand nombre de mandats et rend les mesures.
Mesures simule({
  required Contenu contenu,
  required String parcours,
  required Strategie strategie,
  int parties = 1000,
  int graine = 1,
  int duree = dureeMandatPrototype,
}) {
  final alea = Random(graine);
  final depart = contenu.parcoursParId(parcours);
  if (depart == null) throw ArgumentError('parcours inconnu : $parcours');

  final denouements = <String, int>{};
  final vuesPartout = <String>{};
  var totalJours = 0;

  for (var p = 0; p < parties; p++) {
    var etat = EtatPartie(parcours: parcours, nomJoueur: 'Test', jauges: depart.depart);
    while (true) {
      final fin = evalue(etat, duree: duree);
      if (fin != null) {
        denouements.update(fin.type.name, (v) => v + 1, ifAbsent: () => 1);
        break;
      }
      final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
      if (carte == null) {
        denouements.update('paquetEpuise', (v) => v + 1, ifAbsent: () => 1);
        break;
      }
      vuesPartout.add(carte.id);
      etat = repond(etat: etat, carte: carte, cote: _choisit(strategie, etat, carte, alea));
    }
    totalJours += etat.jour - 1;
  }

  return Mesures(
    parties: parties,
    joursMoyens: totalJours / parties,
    denouements: denouements,
    cartesJamaisVues: {for (final c in contenu.cartes) c.id}..removeAll(vuesPartout),
  );
}

Cote _choisit(Strategie s, EtatPartie etat, Carte carte, Random alea) => switch (s) {
      Strategie.toujoursGauche => Cote.gauche,
      Strategie.toujoursDroite => Cote.droite,
      Strategie.auHasard => alea.nextBool() ? Cote.gauche : Cote.droite,
      Strategie.equilibree => _versLeCentre(etat, carte),
    };

/// Joue le côté qui laisse les jauges le plus près du centre.
Cote _versLeCentre(EtatPartie etat, Carte carte) {
  int ecart(Reponse r) {
    final apres = etat.jauges.applique(r.effets);
    return Jauge.values.fold(0, (s, j) => s + (apres.valeur(j) - 50).abs());
  }

  return ecart(carte.gauche) <= ecart(carte.droite) ? Cote.gauche : Cote.droite;
}
EOF
flutter test test/simulation_test.dart
```

Attendu : cinq tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/moteur/simulation.dart test/simulation_test.dart
git commit -m "Moteur : simulation d equilibrage

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 10 : La carte qui glisse

**Fichiers :**
- Créer : `lib/ecrans/carte_glissante.dart`
- Test : `test/ecrans/carte_glissante_test.dart`

**Interfaces :**
- Consomme : `Cote` (tâche 6).
- Produit : `class CarteGlissante extends StatefulWidget` avec `const CarteGlissante({required Key key, required Widget enfant, required ValueChanged<Cote> onReponse, required ValueChanged<Cote?> onIntention, String libelleGauche, String libelleDroite})`, et `static const double seuil = 0.35`.

`onIntention` prévient l'écran du côté vers lequel le joueur penche, pour illuminer les jauges concernées ; `null` quand il revient au centre.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
mkdir -p test/ecrans
cat > test/ecrans/carte_glissante_test.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/ecrans/carte_glissante.dart';
import 'package:president/moteur/partie.dart';

void main() {
  Future<void> montre(WidgetTester tester, List<Cote> reponses, List<Cote?> intentions) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 400,
            child: CarteGlissante(
              key: const ValueKey('carte'),
              onReponse: reponses.add,
              onIntention: intentions.add,
              libelleGauche: 'Non',
              libelleDroite: 'Oui',
              enfant: const Text('La solde a du retard'),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('glisser franchement a droite repond droite', (tester) async {
    final reponses = <Cote>[];
    await montre(tester, reponses, []);
    await tester.drag(find.text('La solde a du retard'), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(reponses, [Cote.droite]);
  });

  testWidgets('glisser franchement a gauche repond gauche', (tester) async {
    final reponses = <Cote>[];
    await montre(tester, reponses, []);
    await tester.drag(find.text('La solde a du retard'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(reponses, [Cote.gauche]);
  });

  testWidgets('un petit mouvement ne repond pas et la carte revient', (tester) async {
    final reponses = <Cote>[];
    await montre(tester, reponses, []);
    await tester.drag(find.text('La solde a du retard'), const Offset(30, 0));
    await tester.pumpAndSettle();
    expect(reponses, isEmpty);
  });

  testWidgets('pencher annonce l intention puis l annule au retour', (tester) async {
    final intentions = <Cote?>[];
    await montre(tester, [], intentions);
    final geste = await tester.startGesture(tester.getCenter(find.text('La solde a du retard')));
    await geste.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(intentions.last, Cote.droite);
    await geste.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(intentions.last, isNull);
    await geste.up();
    await tester.pumpAndSettle();
  });

  testWidgets('les libelles apparaissent pendant le geste', (tester) async {
    await montre(tester, [], []);
    final geste = await tester.startGesture(tester.getCenter(find.text('La solde a du retard')));
    await geste.moveBy(const Offset(80, 0));
    await tester.pump();
    expect(find.text('Oui'), findsOneWidget);
    await geste.up();
    await tester.pumpAndSettle();
  });
}
EOF
flutter test test/ecrans/carte_glissante_test.dart
```

Attendu : ÉCHEC, `carte_glissante.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
mkdir -p lib/ecrans
cat > lib/ecrans/carte_glissante.dart << 'EOF'
import 'package:flutter/material.dart';

import '../moteur/partie.dart';

/// Une carte que l'on fait glisser à gauche ou à droite. Le geste est le seul
/// moyen de répondre : il n'y a pas de bouton.
class CarteGlissante extends StatefulWidget {
  const CarteGlissante({
    required Key key,
    required this.enfant,
    required this.onReponse,
    required this.onIntention,
    required this.libelleGauche,
    required this.libelleDroite,
  }) : super(key: key);

  final Widget enfant;

  /// Appelé une seule fois, quand le geste vaut réponse.
  final ValueChanged<Cote> onReponse;

  /// Appelé pendant le geste : le côté pressenti, ou null au centre.
  final ValueChanged<Cote?> onIntention;

  final String libelleGauche;
  final String libelleDroite;

  /// Fraction de la largeur au-delà de laquelle le geste vaut réponse.
  static const double seuil = 0.35;

  /// Fraction à partir de laquelle on annonce l'intention.
  static const double seuilIntention = 0.08;

  @override
  State<CarteGlissante> createState() => _CarteGlissanteState();
}

class _CarteGlissanteState extends State<CarteGlissante> with SingleTickerProviderStateMixin {
  double _dx = 0;
  double _largeur = 300;
  Cote? _intention;
  bool _sorti = false;

  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
        ..addListener(() {
          final t = _retour;
          if (t != null) setState(() => _dx = t.value);
        });
  Animation<double>? _retour;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _annonce(Cote? c) {
    if (c == _intention) return;
    _intention = c;
    widget.onIntention(c);
  }

  void _bouge(DragUpdateDetails d) {
    if (_sorti) return;
    setState(() => _dx += d.delta.dx);
    final part = _dx.abs() / _largeur;
    if (part < CarteGlissante.seuilIntention) {
      _annonce(null);
    } else {
      _annonce(_dx > 0 ? Cote.droite : Cote.gauche);
    }
  }

  void _lache(DragEndDetails d) {
    if (_sorti) return;
    final part = _dx.abs() / _largeur;
    if (part >= CarteGlissante.seuil) {
      final cote = _dx > 0 ? Cote.droite : Cote.gauche;
      _sorti = true;
      _annonce(null);
      _retour = Tween<double>(begin: _dx, end: _dx > 0 ? _largeur * 1.5 : -_largeur * 1.5)
          .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
      _anim.forward(from: 0).whenComplete(() => widget.onReponse(cote));
      return;
    }
    _annonce(null);
    _retour = Tween<double>(begin: _dx, end: 0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _largeur = c.maxWidth;
      final part = (_dx / _largeur).clamp(-1.0, 1.0);
      final visible = _dx.abs() / _largeur >= CarteGlissante.seuilIntention;
      return GestureDetector(
        onPanUpdate: _bouge,
        onPanEnd: _lache,
        child: Transform.translate(
          offset: Offset(_dx, 0),
          child: Transform.rotate(
            angle: part * 0.18,
            child: Stack(
              children: [
                Positioned.fill(child: widget.enfant),
                if (visible)
                  Positioned(
                    top: 18,
                    left: _dx > 0 ? 18 : null,
                    right: _dx > 0 ? null : 18,
                    child: _Etiquette(texte: _dx > 0 ? widget.libelleDroite : widget.libelleGauche),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9B44C), width: 3),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black54,
      ),
      child: Text(
        texte,
        style: const TextStyle(color: Color(0xFFE9B44C), fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }
}
EOF
flutter test test/ecrans/carte_glissante_test.dart
```

Attendu : cinq tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/ecrans/carte_glissante.dart test/ecrans/carte_glissante_test.dart
git commit -m "Ecrans : la carte qui glisse a gauche ou a droite

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 11 : La session et l'écran de partie

**Fichiers :**
- Créer : `lib/ecrans/session.dart`, `lib/ecrans/partie_ecran.dart`
- Test : `test/ecrans/partie_ecran_test.dart`

**Interfaces :**
- Consomme : `Contenu` (tâche 8), le moteur (tâches 4 à 7), `CarteGlissante` (tâche 10).
- Produit :
  - `final contenuProvider = FutureProvider<Contenu>(...)`
  - `class Session { EtatPartie etat; Carte? carte; Denouement? denouement; Fin? fin; }`
  - `class SessionNotifier extends Notifier<Session?>` avec `void demarre({required Parcours parcours, required String nom, int graine})`, `void repondA(Cote cote)`, `void arrete()`
  - `final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new)`
  - `class PartieEcran extends ConsumerStatefulWidget`

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/ecrans/partie_ecran_test.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/partie_ecran.dart';
import 'package:president/ecrans/session.dart';

Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '['
          '{"id":"c1","personnage":"general","humeur":"neutre","texte":"{nom}, la solde a du retard.",'
          '"gauche":{"libelle":"Patientez","effets":{"armee":-10}},'
          '"droite":{"libelle":"On paie","effets":{"armee":10,"caisses":-10}}},'
          '{"id":"c2","personnage":"general","humeur":"neutre","texte":"Les casernes murmurent.",'
          '"gauche":{"libelle":"Ignorer","effets":{"armee":-5}},'
          '"droite":{"libelle":"Ecouter","effets":{"armee":5}}}'
          ']',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );

Future<void> lance(WidgetTester tester) async {
  final contenu = contenuDEssai();
  await tester.pumpWidget(ProviderScope(
    overrides: [contenuProvider.overrideWith((ref) => contenu)],
    child: MaterialApp(
      home: Consumer(builder: (context, ref, _) {
        return TextButton(
          onPressed: () {
            ref.read(sessionProvider.notifier).demarre(
                  parcours: contenu.parcours.first,
                  nom: 'Awa',
                  graine: 1,
                );
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartieEcran()));
          },
          child: const Text('commencer'),
        );
      }),
    ),
  ));
  await tester.pump();
  await tester.tap(find.text('commencer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la partie affiche le jour, les jauges et une carte', (tester) async {
    await lance(tester);
    expect(find.text('Jour 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('jauge_armee')), findsOneWidget);
    expect(find.textContaining('solde'), findsOneWidget);
  });

  testWidgets('repondre avance au jour suivant et change de carte', (tester) async {
    await lance(tester);
    await tester.drag(find.textContaining('solde'), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Jour 2'), findsOneWidget);
    expect(find.textContaining('casernes'), findsOneWidget);
  });

  testWidgets('le nom du joueur remplace le gabarit', (tester) async {
    await lance(tester);
    expect(find.textContaining('Awa'), findsWidgets);
  });
}
EOF
flutter test test/ecrans/partie_ecran_test.dart
```

Attendu : ÉCHEC, `session.dart` et `partie_ecran.dart` n'existent pas.

- [ ] **Étape 2 : Écrire la session**

```bash
cat > lib/ecrans/session.dart << 'EOF'
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contenu/chargement.dart';
import '../moteur/denouement.dart';
import '../moteur/etat_partie.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart';
import '../moteur/tirage.dart';

/// Le contenu du jeu, lu une seule fois au lancement.
final contenuProvider = FutureProvider<Contenu>((ref) => Contenu.depuisAssets(rootBundle));

/// Ce que l'écran a besoin de savoir : où en est la partie, quelle carte est
/// devant le joueur, et comment le mandat s'est terminé le cas échéant.
class Session {
  const Session({required this.etat, this.carte, this.denouement, this.fin});

  final EtatPartie etat;
  final Carte? carte;
  final Denouement? denouement;
  final Fin? fin;

  bool get terminee => denouement != null;
}

class SessionNotifier extends Notifier<Session?> {
  late Random _alea;

  @override
  Session? build() => null;

  Contenu get _contenu => ref.read(contenuProvider).requireValue;

  /// Commence un mandat. La graine rend la partie reproductible en test.
  void demarre({required Parcours parcours, required String nom, int? graine}) {
    _alea = Random(graine ?? DateTime.now().millisecondsSinceEpoch);
    final etat = EtatPartie(parcours: parcours.id, nomJoueur: nom, jauges: parcours.depart);
    state = _prochaine(etat);
  }

  /// Reprend une partie enregistrée.
  void reprend(EtatPartie etat, {int? graine}) {
    _alea = Random(graine ?? DateTime.now().millisecondsSinceEpoch);
    state = _prochaine(etat);
  }

  void repondA(Cote cote) {
    final s = state;
    if (s == null || s.carte == null || s.terminee) return;
    state = _prochaine(repond(etat: s.etat, carte: s.carte!, cote: cote));
  }

  void arrete() => state = null;

  /// Calcule l'état affichable : dénouement s'il y en a un, sinon la carte du jour.
  Session _prochaine(EtatPartie etat) {
    final d = evalue(etat);
    if (d != null) {
      return Session(etat: etat, denouement: d, fin: choisitFin(d, _contenu.fins));
    }
    final carte = choisitCarte(paquet: _contenu.cartes, etat: etat, alea: _alea);
    if (carte == null) {
      // Plus aucune carte jouable : on clôt le mandat comme une élection.
      final faute = Denouement(
        type: (etat.jauges.peuple + etat.jauges.presse) / 2 > 50
            ? TypeDenouement.electionGagnee
            : TypeDenouement.electionPerdue,
      );
      return Session(etat: etat, denouement: faute, fin: choisitFin(faute, _contenu.fins));
    }
    return Session(etat: etat, carte: carte);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// Remplace les gabarits d'un texte de carte par le nom et le titre du joueur.
String habille(String texte, {required String nom, required String titre}) =>
    texte.replaceAll('{nom}', nom).replaceAll('{titre}', titre);
EOF
```

- [ ] **Étape 3 : Écrire l'écran**

```bash
cat > lib/ecrans/partie_ecran.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart';
import 'carte_glissante.dart';
import 'fin_ecran.dart';
import 'session.dart';

/// L'écran de jeu : les jauges en haut, la carte du jour au milieu.
class PartieEcran extends ConsumerStatefulWidget {
  const PartieEcran({super.key});

  @override
  ConsumerState<PartieEcran> createState() => _PartieEcranState();
}

class _PartieEcranState extends ConsumerState<PartieEcran> {
  Cote? _intention;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const Scaffold(body: SizedBox.shrink());
    if (session.terminee) return const FinEcran();

    final contenu = ref.watch(contenuProvider).requireValue;
    final carte = session.carte!;
    final personnage = contenu.personnages[carte.personnage];
    final parcours = contenu.parcoursParId(session.etat.parcours);
    final titre = parcours?.titre ?? 'Monsieur le Président';
    final reponse = _intention == Cote.gauche ? carte.gauche : (_intention == Cote.droite ? carte.droite : null);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _LigneJauges(jauges: session.etat.jauges, concernees: reponse?.effets.keys.toSet() ?? const {}),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Jour ${session.etat.jour}',
                  style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: CarteGlissante(
                    key: ValueKey(carte.id),
                    libelleGauche: carte.gauche.libelle,
                    libelleDroite: carte.droite.libelle,
                    onIntention: (c) => setState(() => _intention = c),
                    onReponse: (c) {
                      setState(() => _intention = null);
                      ref.read(sessionProvider.notifier).repondA(c);
                    },
                    enfant: _Carte(
                      personnage: personnage,
                      humeur: carte.humeur,
                      texte: habille(carte.texte, nom: session.etat.nomJoueur, titre: titre),
                      nomJoueur: session.etat.nomJoueur,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.personnage, required this.humeur, required this.texte, required this.nomJoueur});

  final Personnage? personnage;
  final Humeur humeur;
  final String texte;
  final String nomJoueur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: const Color(0xFF14131A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (personnage != null)
              Image.asset(
                personnage!.image(humeur),
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.35),
                // Tant que les portraits ne sont pas générés, un aplat suffit.
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF26222E)),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 34, 18, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xF2080709)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (personnage?.titre ?? '').toUpperCase(),
                      style: const TextStyle(color: Color(0xFFE9B44C), fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(texte, style: const TextStyle(color: Color(0xFFF6EFE4), fontSize: 17, height: 1.35)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneJauges extends StatelessWidget {
  const _LigneJauges({required this.jauges, required this.concernees});

  final Jauges jauges;
  final Set<Jauge> concernees;

  static const _noms = {
    Jauge.peuple: 'Peuple',
    Jauge.armee: 'Armée',
    Jauge.caisses: 'Caisses',
    Jauge.presse: 'Presse',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final j in Jauge.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  key: ValueKey('jauge_${j.name}'),
                  children: [
                    Text(
                      _noms[j]!,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w700,
                        color: concernees.contains(j) ? const Color(0xFFE9B44C) : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: jauges.valeur(j) / 100,
                        minHeight: concernees.contains(j) ? 9 : 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(
                          concernees.contains(j) ? const Color(0xFFE9B44C) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
EOF
```

- [ ] **Étape 4 : Vérifier**

L'écran importe `fin_ecran.dart`, écrit à la tâche suivante. Créer d'abord une version minimale pour que tout compile :

```bash
cat > lib/ecrans/fin_ecran.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran de fin de mandat. Étoffé à la tâche 12.
class FinEcran extends ConsumerWidget {
  const FinEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Scaffold(body: Center(child: Text('Fin du mandat')));
}
EOF
flutter test test/ecrans/partie_ecran_test.dart
```

Attendu : trois tests au vert.

- [ ] **Étape 5 : Commit**

```bash
flutter analyze && flutter test
git add lib/ecrans test/ecrans/partie_ecran_test.dart
git commit -m "Ecrans : session de jeu et ecran de partie

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 12 : L'écran de fin

**Fichiers :**
- Modifier : `lib/ecrans/fin_ecran.dart`
- Test : `test/ecrans/fin_ecran_test.dart`

**Interfaces :**
- Consomme : `Session`, `sessionProvider`, `contenuProvider` (tâche 11) ; `Denouement`, `Fin`.
- Produit : `class FinEcran extends ConsumerWidget` qui affiche le titre, le texte et l'image de la fin, le nombre de jours tenus, et un bouton « Reprendre ses fonctions » qui vide la session et revient à l'accueil.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/ecrans/fin_ecran_test.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/fin_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';

Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '[]',
      personnages: '[]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
      fins: '[{"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Le palais est pris",'
          '"texte":"Les blindes sont entres a l aube.","image":"fins/coup.jpg"},'
          '{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );

const etatChute = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 50, armee: 0, caisses: 50, presse: 50),
  jour: 12,
);

/// Le conteneur est monté à la main : on prépare la session AVANT le premier
/// rendu, car on n appelle jamais un notifier pendant un build.
Future<ProviderContainer> montre(WidgetTester tester) async {
  final contenu = contenuDEssai();
  final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
  addTearDown(container.dispose);
  await container.read(contenuProvider.future);
  container.read(sessionProvider.notifier).reprend(etatChute, graine: 1);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: FinEcran()),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('la fin montre son titre, son texte et les jours tenus', (tester) async {
    await montre(tester);
    expect(find.text('Le palais est pris'), findsOneWidget);
    expect(find.textContaining('blindes'), findsOneWidget);
    expect(find.textContaining('11 jours'), findsOneWidget);
  });

  testWidgets('reprendre ses fonctions vide la session', (tester) async {
    final container = await montre(tester);
    await tester.tap(find.text('Reprendre ses fonctions'));
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider), isNull);
  });
}
EOF
flutter test test/ecrans/fin_ecran_test.dart
```

Attendu : ÉCHEC, l'écran minimal n'affiche que « Fin du mandat ».

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/ecrans/fin_ecran.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/denouement.dart';
import 'session.dart';

/// Ce qu'on voit quand le mandat s'arrête : la fin écrite, les jours tenus,
/// et l'invitation à recommencer.
class FinEcran extends ConsumerWidget {
  const FinEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.terminee) return const Scaffold(body: SizedBox.shrink());

    final fin = session.fin;
    final jours = session.etat.jour - 1;
    final gagnee = session.denouement!.type == TypeDenouement.electionGagnee;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (fin != null)
            Image.asset(
              'assets/images/${fin.image}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1620)),
            )
          else
            Container(color: const Color(0xFF1A1620)),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gagnee ? 'RÉÉLU' : 'FIN DU MANDAT',
                    style: const TextStyle(color: Color(0xFFE9B44C), letterSpacing: 2.5, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fin?.titre ?? 'Le mandat s arrête',
                    style: const TextStyle(color: Colors.white, fontSize: 30, height: 1.1, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fin?.texte ?? '',
                    style: const TextStyle(color: Color(0xFFE3D9C9), fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Vous avez tenu $jours jours.',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ref.read(sessionProvider.notifier).arrete();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('Reprendre ses fonctions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
EOF
flutter test test/ecrans/fin_ecran_test.dart
```

Attendu : deux tests au vert.

- [ ] **Étape 3 : Commit**

```bash
flutter analyze && flutter test
git add lib/ecrans/fin_ecran.dart test/ecrans/fin_ecran_test.dart
git commit -m "Ecrans : fin de mandat

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 13 : L'accueil et le choix du parcours

**Fichiers :**
- Créer : `lib/ecrans/accueil.dart`
- Modifier : `lib/app.dart`
- Test : `test/ecrans/accueil_test.dart`

**Interfaces :**
- Consomme : `contenuProvider`, `sessionProvider` (tâche 11) ; `Parcours` (tâche 3).
- Produit : `class AccueilEcran extends ConsumerStatefulWidget`. Les parcours ouverts sont sélectionnables ; les verrouillés sont grisés et affichent leur condition. Le bouton « Prendre mes fonctions » ne s'active qu'avec un nom et un parcours choisi.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/ecrans/accueil_test.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/accueil.dart';
import 'package:president/ecrans/session.dart';

Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '[{"id":"c1","personnage":"general","humeur":"neutre","texte":"La solde a du retard.",'
          '"gauche":{"libelle":"Patientez","effets":{"armee":-10}},'
          '"droite":{"libelle":"On paie","effets":{"armee":10}}}]',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '['
          '{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
          '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}},'
          '{"id":"professeure","nom":"La professeure d universite","titre":"Madame la Presidente","femme":true,'
          '"depart":{"peuple":55,"armee":40,"caisses":45,"presse":65}},'
          '{"id":"putschiste","nom":"L ancien putschiste","titre":"Monsieur le President","femme":false,'
          '"depart":{"peuple":35,"armee":80,"caisses":50,"presse":30},'
          '"condition_deblocage":"Se faire renverser par l armee"}'
          ']',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );

Future<void> montre(WidgetTester tester) async {
  final contenu = contenuDEssai();
  await tester.pumpWidget(ProviderScope(
    overrides: [contenuProvider.overrideWith((ref) => contenu)],
    child: const MaterialApp(home: AccueilEcran()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('les parcours ouverts et verrouilles sont distingues', (tester) async {
    await montre(tester);
    expect(find.text('L ancien general'), findsOneWidget);
    expect(find.text('La professeure d universite'), findsOneWidget);
    expect(find.text('Se faire renverser par l armee'), findsOneWidget);
  });

  testWidgets('le bouton reste inactif sans nom ni parcours', (tester) async {
    await montre(tester);
    final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
    expect(bouton.onPressed, isNull);
  });

  testWidgets('un parcours verrouille ne peut pas etre choisi', (tester) async {
    await montre(tester);
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.tap(find.text('L ancien putschiste'));
    await tester.pump();
    final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
    expect(bouton.onPressed, isNull);
  });

  testWidgets('choisir un parcours et un nom active le bouton', (tester) async {
    await montre(tester);
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.tap(find.text('La professeure d universite'));
    await tester.pump();
    final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
    expect(bouton.onPressed, isNotNull);
  });
}
EOF
flutter test test/ecrans/accueil_test.dart
```

Attendu : ÉCHEC, `accueil.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
cat > lib/ecrans/accueil.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/modeles.dart';
import 'partie_ecran.dart';
import 'session.dart';

/// Premier écran : qui étiez-vous avant, et comment vous appelez-vous.
class AccueilEcran extends ConsumerStatefulWidget {
  const AccueilEcran({super.key});

  @override
  ConsumerState<AccueilEcran> createState() => _AccueilEcranState();
}

class _AccueilEcranState extends ConsumerState<AccueilEcran> {
  final _nom = TextEditingController();
  String? _choisi;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenu = ref.watch(contenuProvider);

    return Scaffold(
      body: SafeArea(
        child: contenu.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Contenu illisible : $e')),
          data: (c) {
            final parcours = c.parcours;
            final pret = _choisi != null && _nom.text.trim().isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 22, 22, 6),
                  child: Text('Président pour 100 jours',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text('Qui étiez-vous avant ?', style: TextStyle(color: Colors.white70)),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: parcours.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CarteParcours(
                      parcours: parcours[i],
                      choisi: _choisi == parcours[i].id,
                      onTap: () => setState(() {
                        _choisi = parcours[i].ouvertDesLeDebut ? parcours[i].id : null;
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nom,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Votre nom',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: !pret
                              ? null
                              : () {
                                  final p = c.parcoursParId(_choisi!)!;
                                  ref.read(sessionProvider.notifier).demarre(parcours: p, nom: _nom.text.trim());
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const PartieEcran()),
                                  );
                                },
                          child: const Text('Prendre mes fonctions'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CarteParcours extends StatelessWidget {
  const _CarteParcours({required this.parcours, required this.choisi, required this.onTap});

  final Parcours parcours;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verrouille = !parcours.ouvertDesLeDebut;
    return Opacity(
      opacity: verrouille ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: choisi ? const Color(0xFFE9B44C) : Colors.white24, width: choisi ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parcours.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    if (verrouille)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(parcours.conditionDeblocage!,
                            style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                      ),
                  ],
                ),
              ),
              if (verrouille) const Icon(Icons.lock_outline, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
EOF
```

- [ ] **Étape 3 : Brancher l'accueil comme écran d'ouverture**

```bash
cat > lib/app.dart << 'EOF'
import 'package:flutter/material.dart';

import 'ecrans/accueil.dart';

/// L'application : un thème sombre, et l'accueil pour commencer.
class AppPresident extends StatelessWidget {
  const AppPresident({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Président pour 100 jours',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFE9B44C), brightness: Brightness.dark),
      home: const AccueilEcran(),
    );
  }
}
EOF
flutter test test/ecrans/accueil_test.dart
```

Attendu : quatre tests au vert.

- [ ] **Étape 4 : Commit**

```bash
flutter analyze && flutter test
git add lib/ecrans/accueil.dart lib/app.dart test/ecrans/accueil_test.dart
git commit -m "Ecrans : accueil et choix du parcours

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 14 : La sauvegarde sur l'appareil

**Fichiers :**
- Créer : `lib/sauvegarde/sauvegarde.dart`
- Modifier : `lib/ecrans/session.dart` (enregistrer à chaque réponse), `lib/ecrans/accueil.dart` (proposer de reprendre)
- Test : `test/sauvegarde_test.dart`

**Interfaces :**
- Consomme : `EtatPartie` (tâche 4).
- Produit : `class Sauvegarde { static Future<void> enregistre(EtatPartie etat); static Future<EtatPartie?> lis(); static Future<void> efface(); }`, plus `Map<String,dynamic> versJson(EtatPartie)` et `EtatPartie depuisJson(Map<String,dynamic>)`.

- [ ] **Étape 1 : Écrire le test qui échoue**

```bash
cat > test/sauvegarde_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/sauvegarde/sauvegarde.dart';
import 'package:shared_preferences/shared_preferences.dart';

const etat = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 44, armee: 61, caisses: 38, presse: 52),
  jour: 7,
  mandat: 2,
  drapeaux: {'solde_impayee'},
  vues: {'c1', 'c2'},
  chainesRang: {'affaire': 2},
  chainesJour: {'affaire': 5},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sans partie enregistree, la lecture rend null', () async {
    expect(await Sauvegarde.lis(), isNull);
  });

  test('une partie enregistree se relit a l identique', () async {
    await Sauvegarde.enregistre(etat);
    final relu = (await Sauvegarde.lis())!;
    expect(relu.parcours, etat.parcours);
    expect(relu.nomJoueur, 'Awa');
    expect(relu.jauges.peuple, 44);
    expect(relu.jauges.presse, 52);
    expect(relu.jour, 7);
    expect(relu.mandat, 2);
    expect(relu.drapeaux, {'solde_impayee'});
    expect(relu.vues, {'c1', 'c2'});
    expect(relu.chainesRang['affaire'], 2);
    expect(relu.chainesJour['affaire'], 5);
  });

  test('effacer supprime la partie', () async {
    await Sauvegarde.enregistre(etat);
    await Sauvegarde.efface();
    expect(await Sauvegarde.lis(), isNull);
  });

  test('une sauvegarde illisible est ignoree plutot que de faire planter', () async {
    SharedPreferences.setMockInitialValues({'partie_en_cours': 'ceci n est pas du json'});
    expect(await Sauvegarde.lis(), isNull);
  });
}
EOF
flutter test test/sauvegarde_test.dart
```

Attendu : ÉCHEC, `sauvegarde.dart` n'existe pas.

- [ ] **Étape 2 : Écrire l'implémentation**

```bash
mkdir -p lib/sauvegarde
cat > lib/sauvegarde/sauvegarde.dart << 'EOF'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../moteur/etat_partie.dart';
import '../moteur/jauges.dart';

/// La partie en cours, gardée sur l'appareil. Rien ne part sur le réseau.
class Sauvegarde {
  static const _cle = 'partie_en_cours';

  static Future<void> enregistre(EtatPartie etat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, jsonEncode(versJson(etat)));
  }

  /// Rend la partie enregistrée, ou null s'il n'y en a pas ou si elle est
  /// illisible — une sauvegarde abîmée ne doit jamais empêcher de jouer.
  static Future<EtatPartie?> lis() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString(_cle);
    if (brut == null) return null;
    try {
      return depuisJson(jsonDecode(brut) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_cle);
      return null;
    }
  }

  static Future<void> efface() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cle);
  }
}

Map<String, dynamic> versJson(EtatPartie e) => {
      'parcours': e.parcours,
      'nom': e.nomJoueur,
      'jauges': {
        'peuple': e.jauges.peuple,
        'armee': e.jauges.armee,
        'caisses': e.jauges.caisses,
        'presse': e.jauges.presse,
      },
      'jour': e.jour,
      'mandat': e.mandat,
      'drapeaux': e.drapeaux.toList(),
      'vues': e.vues.toList(),
      'chaines_rang': e.chainesRang,
      'chaines_jour': e.chainesJour,
    };

EtatPartie depuisJson(Map<String, dynamic> j) {
  final g = j['jauges'] as Map<String, dynamic>;
  return EtatPartie(
    parcours: j['parcours'] as String,
    nomJoueur: j['nom'] as String,
    jauges: Jauges(
      peuple: (g['peuple'] as num).toInt(),
      armee: (g['armee'] as num).toInt(),
      caisses: (g['caisses'] as num).toInt(),
      presse: (g['presse'] as num).toInt(),
    ),
    jour: (j['jour'] as num).toInt(),
    mandat: (j['mandat'] as num).toInt(),
    drapeaux: ((j['drapeaux'] as List?) ?? const []).cast<String>().toSet(),
    vues: ((j['vues'] as List?) ?? const []).cast<String>().toSet(),
    chainesRang: ((j['chaines_rang'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
    chainesJour: ((j['chaines_jour'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
  );
}
EOF
flutter test test/sauvegarde_test.dart
```

Attendu : quatre tests au vert.

- [ ] **Étape 3 : Enregistrer à chaque réponse**

Dans `lib/ecrans/session.dart`, ajouter l'import `import '../sauvegarde/sauvegarde.dart';` puis, à la fin de `_prochaine`, avant chaque `return` :

```dart
  Session _prochaine(EtatPartie etat) {
    final d = evalue(etat);
    if (d != null) {
      Sauvegarde.efface(); // le mandat est fini, il n'y a plus rien à reprendre
      return Session(etat: etat, denouement: d, fin: choisitFin(d, _contenu.fins));
    }
    final carte = choisitCarte(paquet: _contenu.cartes, etat: etat, alea: _alea);
    if (carte == null) {
      Sauvegarde.efface();
      final faute = Denouement(
        type: (etat.jauges.peuple + etat.jauges.presse) / 2 > 50
            ? TypeDenouement.electionGagnee
            : TypeDenouement.electionPerdue,
      );
      return Session(etat: etat, denouement: faute, fin: choisitFin(faute, _contenu.fins));
    }
    Sauvegarde.enregistre(etat);
    return Session(etat: etat, carte: carte);
  }
```

- [ ] **Étape 4 : Proposer de reprendre**

Dans `lib/ecrans/accueil.dart`, ajouter les imports `import '../moteur/etat_partie.dart';` et `import '../sauvegarde/sauvegarde.dart';`, puis, dans `_AccueilEcranState` :

```dart
  EtatPartie? _enCours;

  @override
  void initState() {
    super.initState();
    Sauvegarde.lis().then((e) {
      if (mounted) setState(() => _enCours = e);
    });
  }
```

et, juste au-dessus du `TextField`, le bouton de reprise :

```dart
                      if (_enCours != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(sessionProvider.notifier).reprend(_enCours!);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PartieEcran()),
                                );
                              },
                              child: Text('Reprendre le jour ${_enCours!.jour}'),
                            ),
                          ),
                        ),
```

- [ ] **Étape 5 : Vérifier et commettre**

```bash
flutter analyze && flutter test
git add lib/sauvegarde lib/ecrans/session.dart lib/ecrans/accueil.dart test/sauvegarde_test.dart
git commit -m "Sauvegarde de la partie en cours sur l appareil

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 15 : Les images

**Fichiers :**
- Créer : `assets/images/personnages/*.jpg` (4 portraits), `assets/images/fins/*.jpg` (4 fins)

**Interfaces :**
- Consomme : `Personnage.image(Humeur)` (tâche 3) qui attend `assets/images/personnages/<id>_<humeur>.jpg`.
- Produit : les huit fichiers attendus par le prototype.

**À faire par Claude dans la session principale**, avec l'outil OpenArt : un sous-agent n'y a pas accès. Modèle `nano-banana-2-lite`, mode `text2image`, format `3:4`, 15 crédits l'image. Le prototype n'a besoin que de l'humeur `neutre` ; `content` et `fache` viendront avec le contenu de lancement.

Recette de prompt, à reprendre mot pour mot en changeant seulement la description du personnage :

> Photorealistic character portrait for a mobile card game. **[description]**. Upper body, facing the camera, framed from the chest up, centred. Warm cinematic key light from the left, soft shadow on the right, shallow depth of field. Background: **[décor]**, deliberately out of focus so the face reads clearly on a small phone screen. Rich saturated colour, crisp detail on the face, subtle film grain. Entirely fictional person, invented face, not resembling any real public figure. No text, no logo, no watermark, no flag or emblem of a real country.

Les quatre personnages :

| Fichier | Description | Décor |
|---|---|---|
| `ministre_neutre.jpg` | homme d'une cinquantaine d'années, costume bleu nuit, cravate rouge, lunettes cerclées d'or baissées sur le nez, sourire gêné | bureau présidentiel, boiseries sombres |
| `general_neutre.jpg` | homme d'une soixantaine d'années, uniforme vert olive, rubans de décorations, lunettes noires, béret rouge, bras croisés | cour de caserne au crépuscule |
| `redactrice_neutre.jpg` | femme d'une quarantaine d'années, chemisier blanc, carnet à la main, regard direct et sceptique | salle de rédaction, écrans flous |
| `marchande_neutre.jpg` | femme d'une cinquantaine d'années, pagne coloré et foulard assorti, mains sur les hanches, air décidé | grand marché en plein air |

Les quatre fins : `fins/coup.jpg` (blindés à l'aube devant un palais), `fins/rue.jpg` (foule dense dans une avenue), `fins/faillite.jpg` (guichet de banque fermé, file d'attente), `fins/urne.jpg` (bureau de vote, urne transparente). Même recette, sans personnage reconnaissable au premier plan.

- [ ] **Étape 1 : Générer les huit images** avec l'outil OpenArt, une par une, en vérifiant chaque résultat avant de l'accepter.
- [ ] **Étape 2 : Vérifier qu'aucun visage ne ressemble à une personne réelle.** Au moindre doute, régénérer.
- [ ] **Étape 3 : Réduire et convertir** en JPEG 720 × 960, qualité 82, environ 60 Ko :

```bash
cd /Users/jeanperraudeau/Palabre
for f in assets/images/personnages/*.jpg assets/images/fins/*.jpg; do
  sips -Z 960 "$f" --setProperty formatOptions 82 >/dev/null
  ls -lh "$f"
done
```

- [ ] **Étape 4 : Commit**

```bash
git add assets/images
git commit -m "Images : quatre personnages et quatre fins

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Tâche 16 : Les cinquante cartes

**Fichiers :**
- Modifier : `assets/contenu/personnages.json`, `assets/contenu/parcours.json`, `assets/contenu/cartes.json`, `assets/contenu/fins.json`
- Créer : `test/contenu/contenu_reel_test.dart`, `outils/relecture.dart`

**Interfaces :**
- Consomme : `valide` (tâche 8), `simule` (tâche 9).
- Produit : le contenu du prototype — 4 personnages, 4 parcours (2 ouverts, 2 verrouillés), 50 cartes dont 3 chaînes, 4 fins.

**Écrit par Claude dans la session principale, par lots de 25 cartes relus par le propriétaire.** Chaque carte respecte les contraintes générales de ce plan, et le contrôle automatique doit rester silencieux.

- [ ] **Étape 1 : Écrire les personnages, les parcours et les fins**

```bash
cd /Users/jeanperraudeau/Palabre
cat > assets/contenu/personnages.json << 'EOF'
[
  {"id":"ministre","nom":"Le ministre des Finances","titre":"Ministre des Finances"},
  {"id":"general","nom":"Le général","titre":"Chef d'état-major"},
  {"id":"redactrice","nom":"La rédactrice en chef","titre":"Rédactrice en chef"},
  {"id":"marchande","nom":"La marchande","titre":"Présidente des commerçantes"}
]
EOF
cat > assets/contenu/parcours.json << 'EOF'
[
  {"id":"general_parcours","nom":"L'ancien général","titre":"Monsieur le Président","femme":false,
   "depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}},
  {"id":"professeure","nom":"La professeure d'université","titre":"Madame la Présidente","femme":true,
   "depart":{"peuple":55,"armee":40,"caisses":45,"presse":65}},
  {"id":"musicienne","nom":"La star de la musique","titre":"Madame la Présidente","femme":true,
   "depart":{"peuple":75,"armee":35,"caisses":45,"presse":60},
   "condition_deblocage":"Finir un mandat avec le peuple au-dessus de 80"},
  {"id":"putschiste","nom":"L'ancien putschiste","titre":"Monsieur le Président","femme":false,
   "depart":{"peuple":35,"armee":80,"caisses":50,"presse":30},
   "condition_deblocage":"Se faire renverser par l'armée"}
]
EOF
cat > assets/contenu/fins.json << 'EOF'
[
  {"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Le palais est pris",
   "texte":"Les blindés sont entrés à l'aube. On vous a laissé prendre un avion, et vos affaires suivront.",
   "image":"fins/coup.jpg"},
  {"id":"peuple_bas","jauge":"peuple","vers_le_haut":false,"titre":"L'avenue a tranché",
   "texte":"Trois semaines de marches, puis une nuit de klaxons. Vous avez signé votre départ à quatre heures du matin.",
   "image":"fins/rue.jpg"},
  {"id":"caisses_bas","jauge":"caisses","vers_le_haut":false,"titre":"Les guichets sont fermés",
   "texte":"Les salaires n'ont pas pu partir. Ce sont vos partenaires, désormais, qui écrivent le budget.",
   "image":"fins/faillite.jpg"},
  {"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Réélu",
   "texte":"Les affiches sont déjà collées sur les murs. Le prochain mandat sera plus difficile que celui-ci.",
   "image":"fins/urne.jpg"},
  {"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu dans les urnes",
   "texte":"Vous avez appelé votre successeur avant les résultats officiels. Cela vous fera une belle sortie.",
   "image":"fins/urne.jpg"}
]
EOF
```

- [ ] **Étape 2 : Écrire le test qui échoue sur le contenu réel**

```bash
cat > test/contenu/contenu_reel_test.dart << 'EOF'
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';
import 'package:president/moteur/simulation.dart';

Contenu contenuLivre() {
  String lis(String nom) => File('assets/contenu/$nom.json').readAsStringSync();
  return Contenu.depuisChaines(
    cartes: lis('cartes'),
    personnages: lis('personnages'),
    parcours: lis('parcours'),
    fins: lis('fins'),
  );
}

void main() {
  final contenu = contenuLivre();

  test('le contenu livre passe le controle', () {
    expect(valide(contenu), isEmpty, reason: valide(contenu).join('\n'));
  });

  test('le prototype contient bien cinquante cartes', () {
    expect(contenu.cartes.length, greaterThanOrEqualTo(50));
  });

  test('deux parcours sont ouverts et deux sont verrouilles', () {
    expect(contenu.parcours.where((p) => p.ouvertDesLeDebut).length, 2);
    expect(contenu.parcours.where((p) => !p.ouvertDesLeDebut).length, 2);
  });

  test('un mandat joue au hasard dure entre dix et vingt-deux jours', () {
    for (final p in contenu.parcours.where((p) => p.ouvertDesLeDebut)) {
      final m = simule(contenu: contenu, parcours: p.id, strategie: Strategie.auHasard, parties: 2000);
      expect(m.joursMoyens, greaterThan(10), reason: '${p.id} : mandats trop courts');
      expect(m.joursMoyens, lessThan(22), reason: '${p.id} : mandats trop longs');
    }
  });

  test('aucune carte n est ecrite pour rien', () {
    final m = simule(
      contenu: contenu,
      parcours: 'general_parcours',
      strategie: Strategie.auHasard,
      parties: 5000,
    );
    final ailleurs = simule(
      contenu: contenu,
      parcours: 'professeure',
      strategie: Strategie.equilibree,
      parties: 5000,
    );
    final jamais = m.cartesJamaisVues.intersection(ailleurs.cartesJamaisVues);
    expect(jamais, isEmpty, reason: 'cartes jamais tirées : ${jamais.join(", ")}');
  });

  test('un joueur prudent atteint l election', () {
    final m = simule(contenu: contenu, parcours: 'professeure', strategie: Strategie.equilibree, parties: 2000);
    expect(m.denouements.keys.any((k) => k.startsWith('election')), isTrue,
        reason: 'aucun mandat ne va au bout : les cartes sont trop dures');
  });
}
EOF
flutter test test/contenu/contenu_reel_test.dart
```

Attendu : ÉCHEC, `cartes.json` est encore vide.

- [ ] **Étape 3 : Écrire les cartes, par lots de 25**

Répartition visée sur les 50 cartes :

| Personnage | Cartes | Rôle |
|---|---|---|
| ministre | 14 | les caisses, les bailleurs, les marchés publics |
| general | 13 | la solde, les casernes, la frontière |
| redactrice | 12 | les enquêtes, la censure, l'image |
| marchande | 11 | les prix, le marché, la rue |

Dont **trois chaînes** de trois cartes : l'affaire des 4×4 (rumeur, article, procès ou étouffement), la solde impayée (menace, grogne, mutinerie ou paiement), la pénurie de riz (première alerte, file d'attente, émeute ou importation d'urgence). Et **six cartes de parcours** : trois pour `general_parcours`, trois pour `professeure`.

Exemple d'une carte livrable, à recopier comme gabarit — un maillon de chaîne avec un drapeau :

```json
{
  "id": "redactrice_4x4_2",
  "personnage": "redactrice",
  "humeur": "content",
  "texte": "{titre}, mon journal a la photo du 4×4 de l'État devant la boîte de nuit. On publie ?",
  "gauche": { "libelle": "Retenez-la", "effets": { "presse": -12, "peuple": 4 }, "drapeaux": ["photo_etouffee"] },
  "droite": { "libelle": "Publiez", "effets": { "presse": 10, "peuple": 6, "armee": -4 } },
  "conditions": { "jour_min": 6, "drapeaux_requis": ["rumeur_4x4"] },
  "poids": 2,
  "chaine": { "id": "affaire_4x4", "rang": 2, "delai_min": 4 }
}
```

Écrire le premier lot de 25 cartes dans `assets/contenu/cartes.json`, puis :

```bash
flutter test test/contenu/contenu_reel_test.dart -n 'controle'
```

Corriger jusqu'à ce que le contrôle soit silencieux, puis écrire le second lot de 25.

- [ ] **Étape 4 : Page de relecture**

```bash
mkdir -p outils
cat > outils/relecture.dart << 'EOF'
// Fabrique une page de relecture du contenu : un tableau par personnage, les
// chaînes à la suite, les effets visibles. Usage :
//   dart run outils/relecture.dart > .tmp/relecture.html
import 'dart:io';

import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';
import 'package:president/moteur/jauges.dart';

String lis(String nom) => File('assets/contenu/$nom.json').readAsStringSync();

void main() {
  final c = Contenu.depuisChaines(
    cartes: lis('cartes'),
    personnages: lis('personnages'),
    parcours: lis('parcours'),
    fins: lis('fins'),
  );
  final problemes = valide(c);

  final b = StringBuffer()
    ..writeln('<!doctype html><html lang="fr"><head><meta charset="utf-8">')
    ..writeln('<title>Relecture du contenu</title><style>')
    ..writeln('body{font:15px/1.5 system-ui;margin:0;background:#14131a;color:#f6efe4}')
    ..writeln('main{max-width:900px;margin:0 auto;padding:28px}')
    ..writeln('h2{margin:32px 0 8px;color:#e9b44c}')
    ..writeln('table{border-collapse:collapse;width:100%;margin-bottom:10px}')
    ..writeln('td,th{border-bottom:1px solid #332f3d;padding:8px;text-align:left;vertical-align:top}')
    ..writeln('th{font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:#a79e93}')
    ..writeln('.eff{font-variant-numeric:tabular-nums;white-space:nowrap}')
    ..writeln('.pb{background:#5a1d1d;padding:12px;border-radius:8px;margin:16px 0}')
    ..writeln('.ch{color:#7ec8e3;font-size:12px}')
    ..writeln('</style></head><body><main>')
    ..writeln('<h1>Relecture du contenu</h1>')
    ..writeln('<p>${c.cartes.length} cartes, ${c.personnages.length} personnages, ${c.fins.length} fins.</p>');

  if (problemes.isEmpty) {
    b.writeln('<p>Le contrôle automatique ne signale rien.</p>');
  } else {
    b.writeln('<div class="pb"><b>${problemes.length} problème(s)</b><ul>');
    for (final p in problemes) {
      b.writeln('<li>$p</li>');
    }
    b.writeln('</ul></div>');
  }

  String effets(Map<Jauge, int> e) =>
      e.entries.map((x) => '${x.key.name} ${x.value > 0 ? "+" : ""}${x.value}').join(', ');

  for (final p in c.personnages.values) {
    final siennes = c.cartes.where((x) => x.personnage == p.id).toList();
    b
      ..writeln('<h2>${p.nom} — ${siennes.length} cartes</h2>')
      ..writeln('<table><tr><th>Carte</th><th>Texte</th><th>Gauche</th><th>Droite</th></tr>');
    for (final carte in siennes) {
      final ch = carte.chaine;
      b.writeln('<tr><td>${carte.id}'
          '${ch != null ? '<br><span class="ch">chaîne ${ch.id} · rang ${ch.rang}</span>' : ''}</td>'
          '<td>${carte.texte}</td>'
          '<td><b>${carte.gauche.libelle}</b><br><span class="eff">${effets(carte.gauche.effets)}</span></td>'
          '<td><b>${carte.droite.libelle}</b><br><span class="eff">${effets(carte.droite.effets)}</span></td></tr>');
    }
    b.writeln('</table>');
  }

  b.writeln('</main></body></html>');
  stdout.write(b.toString());
}
EOF
mkdir -p .tmp
dart run outils/relecture.dart > .tmp/relecture.html
echo '.tmp/' >> .gitignore
```

Envoyer la page au propriétaire, corriger ce qu'il signale, et recommencer jusqu'à ce qu'il valide.

- [ ] **Étape 5 : Équilibrer**

```bash
flutter test test/contenu/contenu_reel_test.dart
```

Si les mandats sont trop courts, adoucir les effets ; s'ils sont trop longs, durcir quelques cartes ou ajouter des situations à fort effet. Si des cartes ne sortent jamais, leurs conditions sont trop étroites.

- [ ] **Étape 6 : Commit et essai sur téléphone**

```bash
flutter analyze && flutter test
git add assets/contenu outils test/contenu/contenu_reel_test.dart .gitignore
git commit -m "Contenu : cinquante cartes, quatre parcours, cinq fins

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push origin main
flutter run --release
```

Le prototype est jouable du choix du parcours jusqu'à l'écran de fin.

---

## Ce qu'il restera à décider après le prototype

- La durée du mandat repasse-t-elle à 100 jours dès le lancement, ou reste-t-elle plus courte parce que c'est plus agréable ?
- Faut-il une carte de prestation de serment au jour 1 ?
- Le second mandat : effets amplifiés, ou cartes propres au second mandat, ou les deux ?
