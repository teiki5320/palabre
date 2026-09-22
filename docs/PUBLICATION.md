# PUBLICATION — état des boutiques

> Généré le 22 septembre 2026 d'après les consoles. Pour mettre à jour : relancer ce même prompt.
>
> Aucun secret ici — uniquement des références.

## Vue d'ensemble

- **iOS** : la chaîne de construction existe et fonctionne — Xcode Cloud est câblé par `ios/ci_scripts/ci_post_clone.sh`, la signature est déléguée au service, l'équipe et l'identifiant de bundle sont renseignés dans le projet Xcode. Le dépôt ne montre **aucune trace de soumission** : ni version publiée, ni numéro de build TestFlight, ni fiche. État réel de la fiche et des builds : à vérifier dans la console.
- **Android** : **rien n'est prêt**. `android/app/build.gradle.kts` signe encore la variante `release` avec la clé de debug — le `TODO` d'origine de Flutter n'a pas été traité. Aucun bundle signé ne peut donc être produit en l'état, et aucune publication n'est possible.
- **Version commune** : **0.27.0+1** (`pubspec.yaml`). Les deux plateformes en dépendent : iOS lit `FLUTTER_BUILD_NAME` et `FLUTTER_BUILD_NUMBER`, Android lit `flutter.versionName` et `flutter.versionCode`. Une seule ligne à changer pour les deux.
- **Identifiant de bundle** : **`sn.palabre.app`**, identique des deux côtés — `PRODUCT_BUNDLE_IDENTIFIER` dans `ios/Runner.xcodeproj/project.pbxproj`, `applicationId` dans `android/app/build.gradle.kts`. Le `namespace` Android, `sn.palabre.president`, est interne au code Kotlin et n'a aucun effet sur la boutique. Nom affiché des deux côtés : **« Palabre »**.
- **Monétisation** : **aucune**. Ni SDK publicitaire, ni achat intégré, ni abonnement dans `pubspec.yaml` ou dans `lib/`. L'application ne fait aucun appel réseau et ne déclare aucune permission Android. C'est la réponse la plus simple possible aux questionnaires de confidentialité des deux boutiques : aucune donnée collectée.
- **Chemin critique** : la relecture des 687 cartes, puis la décision de monétisation — qui conditionne la fiche, la classification et le questionnaire de confidentialité —, puis la première soumission iOS, la seule chaîne déjà câblée. Android suit, une fois la signature de publication en place.

### 1. iOS · App Store

| | |
|---|---|
| **État** | Chaîne de construction prête, aucune soumission visible dans le dépôt — à vérifier dans la console |
| **Console** | https://appstoreconnect.apple.com |
| **Version dans le dépôt** | 0.27.0+1 (`pubspec.yaml`) |
| **Version en ligne** | à vérifier dans la console |
| **Identifiant de bundle** | `sn.palabre.app` |
| **Équipe de développement** | `K597U7X3FZ` |
| **Nom affiché** | Palabre |
| **Cible minimale** | iOS 15.0 |
| **Construction** | Xcode Cloud, `ios/ci_scripts/ci_post_clone.sh` — Flutter 3.47.3, `build ios --release --no-codesign --config-only`, puis `pod install` |
| **Numéro de build** | fourni par Xcode Cloud (`CI_BUILD_NUMBER`), pas figé dans le dépôt |
| **Signature** | déléguée à Xcode Cloud ; aucun certificat ni profil dans le dépôt |
| **Classification** | 17+ visée, à cause des scènes de chambre — questionnaire à remplir, à vérifier dans la console |
| **Confidentialité** | aucune donnée collectée : aucun réseau, aucun outil d'analyse, sauvegarde locale par `shared_preferences` |
| **TestFlight** | à vérifier dans la console |
| **Fiche (titre, description, captures)** | non rédigée — rien dans le dépôt |

### 2. Android · Google Play

| | |
|---|---|
| **État** | **Non publiable en l'état** — la variante `release` signe avec la clé de debug |
| **Console** | https://play.google.com/console |
| **Version dans le dépôt** | 0.27.0+1 (`pubspec.yaml`) |
| **Version en ligne** | à vérifier dans la console |
| **Identifiant d'application** | `sn.palabre.app` |
| **Espace de noms** | `sn.palabre.president` |
| **Nom affiché** | Palabre |
| **Niveaux d'API** | `minSdk`, `targetSdk` et `compileSdk` suivent les valeurs par défaut de Flutter — non figés dans le dépôt |
| **Java / Kotlin** | 17 des deux côtés |
| **Permissions déclarées** | aucune (`AndroidManifest.xml`) |
| **Construction** | aucune automatisation — ni action GitHub, ni script de publication |
| **Signature** | keystore et `android/key.properties` **hors dépôt**, exclus par `.gitignore` ; emplacement à vérifier hors dépôt |
| **Classification** | 18 visée — questionnaire à remplir, à vérifier dans la console |
| **Confidentialité** | formulaire de sécurité des données à remplir ; la réponse est « aucune donnée collectée » |
| **Fiche (titre, description, captures)** | non rédigée — rien dans le dépôt |

## Ce qui reste, dans l'ordre

1. **Relire les 687 cartes** une par une — grammaire, compréhension, cohérence des deux réponses. C'est le seul point qui n'est pas mécanisable et le seul qui bloque vraiment.
2. **Trancher le modèle de rémunération.** Il décide de la fiche, de la classification et du questionnaire de confidentialité : le faire après la soumission obligerait à tout reprendre.
3. **Mettre à jour le `README.md`**, qui annonce encore une élection au jour 30 alors que le code dit 100. Il sert de première description du jeu.
4. **Rédiger les deux fiches de boutique** : titre, sous-titre, description longue, mots-clés, en français d'abord.
5. **Produire les captures d'écran** aux formats exigés par chaque boutique — une carte lisible, le palais, la carte du pays.
6. **Remplir les questionnaires** de classification et de confidentialité des deux côtés. La réponse « aucune donnée collectée » est vérifiable dans le code et doit être donnée telle quelle.
7. **Soumettre une première build iOS à TestFlight** par Xcode Cloud, et la faire tourner sur appareil réel avant toute ouverture publique.
8. **Câbler la signature de publication Android** : créer le `key.properties` hors dépôt, brancher le `signingConfig` de `release` dessus, et vérifier qu'un bundle signé sort bien. Rien n'est publiable côté Android tant que ce point n'est pas fait.
9. **Ouvrir en test fermé** sur les deux boutiques avant la publication générale.
