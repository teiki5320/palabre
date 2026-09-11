# Refonte du design et des parcours — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Passer l'app Flutter du thème sombre plat actuel au style « bandeau Lagune + cartes claires », en clair et en sombre, et refaire les quatre parcours (onboarding, question, quiz, gouvernement/assemblée) sans toucher aux données ni au moteur.

**Architecture:** Un `ThemeExtension<PalabreTokens>` porte la palette ; `PalabreTheme.light()/dark()` en dérivent le `ColorScheme` et les sous-thèmes Material. Deux briques communes, `BandScaffold` (bandeau fixe + corps défilant qui le chevauche) et `SoftCard`, remplacent `AppBar` et les hairlines dans tous les écrans. Les providers, routes, modèles et `QuizEngine` ne bougent pas.

**Tech Stack:** Flutter 3.47 / Dart 3.13, Material 3, Riverpod 3, go_router 18, polices Sora + Manrope embarquées (instances statiques générées par fontTools depuis les fontes variables OFL).

**Spec:** `docs/superpowers/specs/2026-09-11-refonte-design-design.md`

## Global Constraints

- Le pays est une configuration, jamais une branche de code.
- Aucune opinion : pas de score en points, pas de podium, pas de classement de personnes, jamais d'extrapolation d'une position de parti. Aucun numéro de rang ni médaille sur le résultat du quiz.
- Aucune table ne relie un utilisateur à une orientation politique ; le quiz reste calculé et gardé sur le téléphone.
- Chaque fait affiché renvoie à sa source ; une absence assumée vaut mieux qu'une donnée inventée.
- Après chaque tâche : `flutter analyze` (zéro issue), `flutter test` (tout vert), commit, push sur `main`.
- Jamais de Swift Package Manager iOS ; ne pas toucher `ios/`.
- Palette B Lagune, valeurs exactes de la spec §3.1. Polices : Sora 600/700/800, Manrope 400/500/600/700.
- Clés de préférence nouvelles : `theme_mode` (`system`/`light`/`dark`), `profile_prompt_done` (bool).
- `app_fr.arb` est le modèle ; toute clé nouvelle est ajoutée en fr et en. Le wolof reste partiel (repli automatique sur le français par gen-l10n) : on n'invente pas de traduction.
- Version finale : `version: 0.2.0+1` dans `pubspec.yaml` (tâche 9). Le numéro de build reste à Xcode Cloud.

---

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `assets/fonts/Sora-{600,700,800}.ttf`, `assets/fonts/Manrope-{400,500,600,700}.ttf`, `assets/fonts/OFL-Sora.txt`, `assets/fonts/OFL-Manrope.txt` | polices embarquées + licences |
| `lib/app/theme.dart` | `PalabreTokens` (ThemeExtension), `PalabreType` (familles et styles), `PalabreTheme.light()/dark()`, `BlocColors`, `parseHexColor` |
| `lib/core/prefs/theme_mode_provider.dart` | `themeModeProvider` (Notifier<ThemeMode>, persistant) |
| `lib/core/widgets/band_scaffold.dart` | `BandScaffold`, `BandSearchField` |
| `lib/core/widgets/soft_card.dart` | `SoftCard`, `CardSection`, `Pill`, `CardDivider` |
| `lib/core/widgets/widgets.dart` | widgets existants restylés ; `Hairline` supprimé |
| `lib/app/app.dart`, `lib/app/shell.dart` | thème clair/sombre + mode ; barre d'onglets |
| `lib/features/onboarding/onboarding_screen.dart` | onboarding un écran ; `ProfileForm` paramétré |
| `lib/features/poll/*` | question de la semaine, contexte repliable, archive, carte « Affiner » |
| `lib/features/quiz/swipe_card.dart` | `SwipeCard` + `SwipeController` |
| `lib/features/quiz/*` | accueil, déroulé, résultat, partage |
| `lib/features/reference/*` | gouvernement, assemblée, fiches |
| `lib/features/settings/settings_screen.dart` | apparence, profil, langue |
| `test/theme_test.dart`, `test/quiz_swipe_test.dart`, `test/quiz_result_test.dart`, `test/poll_tab_test.dart` | nouveaux tests |

---

### Task 1: Polices, jetons, thèmes clair et sombre, réglage d'apparence

**Files:**
- Create: `assets/fonts/*` (copiés depuis le scratchpad `fonts/static/` et `fonts/*/OFL.txt`)
- Modify: `pubspec.yaml` (section `flutter: fonts:`)
- Modify: `lib/app/theme.dart` (réécriture)
- Create: `lib/core/prefs/theme_mode_provider.dart`
- Modify: `lib/core/prefs/prefs_provider.dart` (clés `themeMode`, `profilePromptDone`)
- Modify: `lib/app/app.dart`
- Test: `test/theme_test.dart`

**Interfaces:**
- Produces: `PalabreTokens` avec champs `primary, onPrimary, primarySoft, accent, onAccent, background, card, ink, muted, line, cardShadow (BoxShadow)` et constantes `PalabreTokens.light`, `PalabreTokens.dark` ; extension `context.tokens` ; `PalabreType.display = 'Sora'`, `PalabreType.body = 'Manrope'`, styles `PalabreType.title(Color)`, `.question(Color)`, `.big(Color)`, `.eyebrow(Color)`, `.note(Color)`, `.label(Color)` ; `PalabreTheme.light()`, `PalabreTheme.dark()` ; `themeModeProvider` (`NotifierProvider<ThemeModeSetting, ThemeMode>`, méthode `set(ThemeMode)`) ; `PrefKeys.themeMode`, `PrefKeys.profilePromptDone`.

- [ ] **Step 1 : test qui échoue**

```dart
// test/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/app/theme.dart';
import 'package:palabre/core/prefs/prefs_provider.dart';
import 'package:palabre/core/prefs/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('les deux thèmes exposent les jetons Lagune', () {
    final light = PalabreTheme.light().extension<PalabreTokens>()!;
    final dark = PalabreTheme.dark().extension<PalabreTokens>()!;
    expect(light.primary, const Color(0xFF0F7F7C));
    expect(light.accent, const Color(0xFFFF7A1A));
    expect(light.background, const Color(0xFFEFF6F5));
    expect(dark.primary, const Color(0xFF3ED0CB));
    expect(dark.card, const Color(0xFF173130));
    expect(PalabreTheme.light().colorScheme.primary, light.primary);
    expect(PalabreTheme.light().scaffoldBackgroundColor, light.background);
    expect(PalabreTheme.light().textTheme.bodyMedium!.fontFamily, PalabreType.body);
  });

  test('le mode d\'apparence est lu et écrit dans les préférences', () async {
    SharedPreferences.setMockInitialValues({PrefKeys.themeMode: 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await container.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString(PrefKeys.themeMode), 'light');
    await container.read(themeModeProvider.notifier).set(ThemeMode.system);
    expect(prefs.getString(PrefKeys.themeMode), isNull);
  });
}
```

- [ ] **Step 2 : lancer** `flutter test test/theme_test.dart` → échec de compilation (`PalabreTokens` inconnu).

- [ ] **Step 3 : polices.** Copier les sept TTF statiques dans `assets/fonts/`, les deux OFL.txt renommés `OFL-Sora.txt` et `OFL-Manrope.txt`. Dans `pubspec.yaml`, sous `flutter:` :

```yaml
  fonts:
    - family: Sora
      fonts:
        - asset: assets/fonts/Sora-600.ttf
          weight: 600
        - asset: assets/fonts/Sora-700.ttf
          weight: 700
        - asset: assets/fonts/Sora-800.ttf
          weight: 800
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-400.ttf
          weight: 400
        - asset: assets/fonts/Manrope-500.ttf
          weight: 500
        - asset: assets/fonts/Manrope-600.ttf
          weight: 600
        - asset: assets/fonts/Manrope-700.ttf
          weight: 700
```

- [ ] **Step 4 : `theme.dart`.** Réécrire avec :

```dart
class PalabreTokens extends ThemeExtension<PalabreTokens> {
  const PalabreTokens({required this.primary, required this.onPrimary, required this.primarySoft, required this.accent, required this.onAccent, required this.background, required this.card, required this.ink, required this.muted, required this.line, required this.cardShadow});
  final Color primary, onPrimary, primarySoft, accent, onAccent, background, card, ink, muted, line;
  final BoxShadow cardShadow;

  static const light = PalabreTokens(
    primary: Color(0xFF0F7F7C), onPrimary: Color(0xFFFFFFFF), primarySoft: Color(0xFFDDF0EE),
    accent: Color(0xFFFF7A1A), onAccent: Color(0xFF2B1200), background: Color(0xFFEFF6F5),
    card: Color(0xFFFFFFFF), ink: Color(0xFF0F2B2A), muted: Color(0xFF5B7674), line: Color(0xFFD8E6E4),
    cardShadow: BoxShadow(offset: Offset(0, 10), blurRadius: 24, color: Color(0x1A0F3C3A)));
  static const dark = PalabreTokens(
    primary: Color(0xFF3ED0CB), onPrimary: Color(0xFF05201F), primarySoft: Color(0xFF1C3F3D),
    accent: Color(0xFFFF7A1A), onAccent: Color(0xFF2B1200), background: Color(0xFF0E1D1C),
    card: Color(0xFF173130), ink: Color(0xFFEAF6F4), muted: Color(0xFF94B3B0), line: Color(0xFF264543),
    cardShadow: BoxShadow(offset: Offset(0, 10), blurRadius: 24, color: Color(0x59000000)));
  // copyWith et lerp (Color.lerp champ par champ, BoxShadow.lerp) obligatoires.
}

extension PalabreTokensContext on BuildContext {
  PalabreTokens get tokens => Theme.of(this).extension<PalabreTokens>()!;
}

class PalabreType {
  static const display = 'Sora';
  static const body = 'Manrope';
  static TextStyle title(Color c) => TextStyle(fontFamily: display, fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.2, color: c);
  static TextStyle question(Color c) => TextStyle(fontFamily: display, fontSize: 19, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.2, color: c);
  static TextStyle big(Color c) => TextStyle(fontFamily: display, fontSize: 22, fontWeight: FontWeight.w800, color: c, fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle eyebrow(Color c) => TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: c);
  static TextStyle note(Color c) => TextStyle(fontSize: 12, height: 1.4, color: c);
  static TextStyle label(Color c) => TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c);
}
```

`PalabreTheme._build(PalabreTokens t, Brightness b)` : `ColorScheme(brightness, primary: t.primary, onPrimary: t.onPrimary, secondary: t.primary, onSecondary: t.onPrimary, secondaryContainer: t.primarySoft, onSecondaryContainer: t.primary, tertiary: t.accent, onTertiary: t.onAccent, error: 0xFFB3261E (clair) / 0xFFF2B8B5 (sombre), onError, surface: t.card, onSurface: t.ink, onSurfaceVariant: t.muted, outline: t.muted, outlineVariant: t.line, surfaceContainerHighest: t.background)`. `ThemeData(useMaterial3, colorScheme, fontFamily: PalabreType.body, scaffoldBackgroundColor: t.background, extensions: [t], ...)`. Sous-thèmes : appBar transparent sans élévation (résiduel) ; card sans élévation, `color: t.card`, rayon 18, marge 0 ; divider `t.line` épaisseur 1 ; navigationBar `backgroundColor: t.card`, `indicatorColor: t.primarySoft`, icône/label sélectionnés `t.primary`, sinon `t.muted`, `labelBehavior: alwaysShow` ; chip fond `t.primarySoft`, texte `t.primary`, sans bordure, rayon plein ; `FilledButton` rayon 12, hauteur 48, fond `t.primary` ; `OutlinedButton` rayon 12, hauteur 48, bordure `t.line` 1, texte `t.ink` ; `TextButton` texte `t.primary` ; input : fond `t.card`, bordure `t.line` rayon 12, focus `t.primary` ; listTile padding 16 ; bottomSheet fond `t.card`, coins 22 ; dialog fond `t.card` rayon 18 ; snackbar flottante ; slider trackHeight 4 ; `textTheme` : `headlineSmall`/`titleLarge` en `Sora` w700, tout le reste Manrope, `bodyMedium` 14 w500 `t.ink`.

- [ ] **Step 5 : `theme_mode_provider.dart`**

```dart
class ThemeModeSetting extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (ref.watch(sharedPrefsProvider).getString(PrefKeys.themeMode)) {
        'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system };
  Future<void> set(ThemeMode m) async {
    final prefs = ref.read(sharedPrefsProvider);
    if (m == ThemeMode.system) { await prefs.remove(PrefKeys.themeMode); } else { await prefs.setString(PrefKeys.themeMode, m.name); }
    state = m;
  }
}
final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(ThemeModeSetting.new);
```

`app.dart` : `theme: PalabreTheme.light(), darkTheme: PalabreTheme.dark(), themeMode: ref.watch(themeModeProvider)`.

- [ ] **Step 6 :** `flutter test test/theme_test.dart` → PASS ; `flutter analyze` ; `flutter test` (le smoke test peut encore passer : rien d'autre n'a changé).

- [ ] **Step 7 : commit** `Thème Lagune clair et sombre, polices Sora et Manrope, réglage d'apparence` et push.

---

### Task 2: BandScaffold, SoftCard, Pill, widgets communs, barre d'onglets

**Files:**
- Create: `lib/core/widgets/band_scaffold.dart`, `lib/core/widgets/soft_card.dart`
- Modify: `lib/core/widgets/widgets.dart`, `lib/app/shell.dart`, `lib/app/router.dart` (`SettingsAction` inchangé)
- Test: `test/band_scaffold_test.dart`

**Interfaces:**
- Produces:
  - `BandScaffold({required String title, String? eyebrow, bool brand = false, Widget? leading, List<Widget> actions = const [], Widget? control, List<Widget>? children, Widget? body, Future<void> Function()? onRefresh, Widget? bottom})` — `children` devient un `ListView(padding: EdgeInsets.fromLTRB(16, 0, 16, 32))`, `body` est utilisé tel quel (l'appelant gère son padding) ; `leading` null + route qui peut revenir → bouton retour automatique ; `bottom` = zone fixe sous le corps (boutons du quiz).
  - `BandSearchField({required String hint, required ValueChanged<String> onChanged})` : champ sur bandeau, fond `onPrimary` à 18 %.
  - `SoftCard({Widget child, EdgeInsets padding = 16, VoidCallback? onTap, Color? color})`.
  - `CardSection({required String title, Widget? trailing, required List<Widget> children})` : `SoftCard` avec titre Sora 15 w700 puis les enfants séparés par rien (l'appelant met `CardDivider` s'il veut).
  - `CardDivider()` : `Divider(height: 1, thickness: 1, color: tokens.line)` avec 10 px de marge verticale.
  - `Pill({required String label, IconData? icon, bool onBand = false, bool selected = false, VoidCallback? onTap})`.
  - `SectionTitle(text, {trailing})` : hors carte, `eyebrow` en `muted`, padding top 20 bottom 10.
  - `PercentBar` : piste `tokens.line`, hauteur 6 par défaut, rayon 3.
  - `NoticeBanner` : fond `primarySoft` (ou `color` à 12 %), rayon 12, sans bordure.
  - `ErrorRetry`, `PersonAvatar` (rayon `size/4`, fond `color` 14 %) conservés.

- [ ] **Step 1 : test**

```dart
// test/band_scaffold_test.dart
testWidgets('BandScaffold affiche surtitre, titre et enfants', (tester) async {
  await tester.pumpWidget(MaterialApp(theme: PalabreTheme.light(), home: const BandScaffold(title: 'Titre', eyebrow: 'Surtitre', children: [Text('corps')])));
  expect(find.text('Titre'), findsOneWidget);
  expect(find.text('SURTITRE'), findsOneWidget);
  expect(find.text('corps'), findsOneWidget);
  expect(find.byIcon(Icons.arrow_back), findsNothing);
});
testWidgets('SoftCard réagit au tap', (tester) async {
  var taps = 0;
  await tester.pumpWidget(MaterialApp(theme: PalabreTheme.light(), home: Scaffold(body: SoftCard(onTap: () => taps++, child: const Text('x')))));
  await tester.tap(find.text('x'));
  expect(taps, 1);
});
```

- [ ] **Step 2 :** lancer → échec (fichiers absents).

- [ ] **Step 3 : `band_scaffold.dart`.** Structure :

```
Scaffold(backgroundColor: t.background)
  Column
    _Band (Container color t.primary, SafeArea(bottom:false), padding 16/8/16/(overlap 30 + 22))
      Row [leading ?? (canPop ? back : none), Expanded(brand ? wordmark 'Palabre' Sora 800 15 : SizedBox), ...actions]  (IconTheme color t.onPrimary)
      if eyebrow: Text(eyebrow.toUpperCase(), PalabreType.eyebrow(onPrimary 85 %))
      Text(title, PalabreType.title(onPrimary))
      if control: Padding(top 14, control)
    Expanded(Stack [Positioned(top 0, l/r 0, height 30, Container color t.primary), corps])
    if bottom: bottom (SafeArea)
```
Le corps : `children != null` → `ListView(padding: (16, 0, 16, 32), children)` ; sinon `body!`. Si `onRefresh` : `RefreshIndicator(edgeOffset: 0, ...)`. Le bouton retour utilise `Navigator.of(context).canPop()` et `context.pop()` de go_router s'il est monté, sinon `Navigator.pop`.

- [ ] **Step 4 : `soft_card.dart`** avec `SoftCard`, `CardSection`, `CardDivider`, `Pill` (fond `t.primarySoft`/texte `t.primary` ; `onBand` → fond `t.onPrimary` 18 %, texte `t.onPrimary` ; `selected` → fond `t.primary`, texte `t.onPrimary`).

- [ ] **Step 5 : `widgets.dart`** : supprimer `Hairline` ; restyler `SectionTitle`, `NoticeBanner`, `PercentBar`, `PersonAvatar`, `SourceLink` (couleur `t.primary`, icône 14). Corriger les imports des écrans qui utilisaient `Hairline` (`poll_tab`, `assembly_tab`, `person_screen`, `party_screen`) par `CardDivider` pour que tout compile ; ces écrans sont réécrits plus loin.

- [ ] **Step 6 : `shell.dart`** : envelopper `NavigationBar` dans un `DecoratedBox` avec `BoxShadow(offset (0,-4), blur 16, color noir 8 %)`.

- [ ] **Step 7 :** tests, analyze, commit `Briques communes : bandeau, cartes, pastilles, barre d'onglets`, push.

---

### Task 3: Onboarding sur un écran, carte « Affiner les résultats »

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`, `lib/core/profile/profile.dart` (ajout `profilePromptDoneProvider`), `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`, `test/app_smoke_test.dart`
- Create: `lib/features/poll/refine_profile_card.dart`
- Test: `test/app_smoke_test.dart` (adapté)

**Interfaces:**
- Produces: `ProfileForm({bool showCountry = true, bool onboarding = false, Widget? secondaryAction, VoidCallback? onSaved})` ; `profilePromptDoneProvider` (`NotifierProvider<ProfilePromptDone, bool>` avec `complete()`) ; `RefineProfileCard()` (widget autonome, s'affiche seul si les conditions sont réunies : `myVote != null` passé en paramètre `visible`, prompt non fait, âge et région vides).
- l10n nouvelles clés : `onboardingPrinciple` (nouveau texte), `refineTitle`, `refineLater`, `onboardingProfileWhy` conservé, suppression `onboardingProfileTitle`, `onboardingNoOpinion`, `continueLabel`.

- [ ] **Step 1 :** adapter le smoke test : après le pump initial, `expect(find.text("L'arbre à palabres"), findsOneWidget)`, `expect(find.text('Pays'), findsOneWidget)`, `tap('Commencer')`, puis `onboarding_done` vrai et le pays enregistré (`prefs.getString(PrefKeys.country) == 'SN'`). Lancer → échec (« Continuer » n'existe plus / structure).

- [ ] **Step 2 : `OnboardingScreen`** : `Scaffold` fond `t.background` ; `Column` : bandeau (wordmark, titre `onboardingTitle`, `onboardingPrinciple` en Manrope 15 `onPrimary` 90 %) puis `SoftCard` chevauchant avec `ProfileForm(onboarding: true, showCountry: true)` réduit au pays (en mode onboarding, âge et région ne sont pas affichés). Bouton « Commencer » (`l10n.start`).

- [ ] **Step 3 : `ProfileForm`** : en `onboarding`, uniquement le pays + bouton ; sinon `showCountry` contrôle le champ pays, âge et région toujours ; `secondaryAction` rendu à côté du bouton ; `onSaved` appelé après enregistrement (Paramètres garde le snackbar).

- [ ] **Step 4 : `RefineProfileCard`** dans `poll/` : `ConsumerWidget`, paramètre `visible` ; retourne `SizedBox.shrink()` si `!visible || promptDone || (profile.trancheAge != null || profile.regionId != null)` ; sinon `SoftCard` avec titre `refineTitle` (Sora 15), texte `onboardingProfileWhy(30)`, `ProfileForm(showCountry: false, secondaryAction: TextButton(refineLater → complete()), onSaved: complete())`. Branché dans `PollTab` à la tâche 4.

- [ ] **Step 5 :** tests, analyze, commit `Onboarding sur un seul écran, profil affiné après le premier vote`, push.

---

### Task 4: Question de la semaine et détail d'une question

**Files:**
- Modify: `lib/features/poll/poll_tab.dart`, `poll_widgets.dart`, `poll_detail_screen.dart`, arb fr/en
- Test: `test/poll_tab_test.dart`

**Interfaces:**
- Produces: `PollCard(poll)` (carte principale complète, choisit son état), `PollContextCard(poll)` (repliable), `ArchiveCard(poll)`, `pollStatusLine(context, ref, poll) → String` (surtitre du bandeau).
- l10n : `pollOpenUntil` « Ouverte jusqu'au {date} », `pollVoteFinal` → « Un seul vote, définitif. Les résultats s'affichent après. », `pollContextSources` (pluriel), `pollStatusScheduledNote` « Le vote ouvre le {date} ».

- [ ] **Step 1 : test** avec `MemoryCacheStore` contenant `poll_feed:SN` (un sondage programmé dans le futur + un archivé) et `country_config` ; onboarding déjà fait (`onboarding_done: true`). Attendu : le titre de semaine s'affiche, le bouton « Voter » est absent (état programmé), « Semaines précédentes » présent avec la question archivée.

- [ ] **Step 2 : `PollTab`** : `BandScaffold(brand: true, eyebrow: statut, title: semaine, actions: [SettingsAction()], onRefresh, children: [notices, PollCard, PollContextCard, RefineProfileCard(visible: myVote != null), SectionTitle(pollArchive), ...ArchiveCard])`. Sans question courante : bandeau titre `tabQuestion`, carte avec `pollNoCurrent`.

- [ ] **Step 3 : `PollCard`** : question en `PalabreType.question(ink)` ; suspect → `NoticeBanner` erreur ; programmé → options en `muted` non cliquables + `NoticeBanner(pollStatusScheduledNote)` ; ouvert non voté → options (lignes rayon 12, bordure `line`, sélection fond `primarySoft` + bordure `primary` + icône check_circle) + `FilledButton` Voter + note ; sinon `ResultsView` (barres `PercentBar` `primary`, option choisie en gras avec `Pill`), découpes en `Pill`s. `PollContextCard` : en-tête `pollContextSources(n)` + chevron, `AnimatedCrossFade` 200 ms, contenu = contexte, `SourceLink`s, liens personne/institution. `ArchiveCard` : `SoftCard(onTap)` avec semaine (eyebrow), question (w700), barre de l'option majoritaire + libellé + `pollRespondents`.

- [ ] **Step 4 : `PollDetailScreen`** : `BandScaffold(eyebrow: statut, title: semaine, children: [PollCard, PollContextCard])`.

- [ ] **Step 5 :** tests, analyze, commit `Question de la semaine : carte par état, contexte repliable, archive`, push.

---

### Task 5: Accueil du quiz

**Files:**
- Modify: `lib/features/quiz/quiz_tab.dart`, arb fr/en

**Interfaces:** l10n `quizEstimate` « {n} affirmations · environ 5 minutes », `quizLastResult` « Votre dernier résultat ».

- [ ] **Step 1 :** `BandScaffold(brand: true, title: tabQuiz, eyebrow: quizEstimate(n) (ou rien si pas de quiz), actions: [SettingsAction()])`. Carte 1 : `quizIntro` + les trois méthodes (icône `primary` dans un rond `primarySoft`) + bouton `start`/`quizResume` (« Reprendre (7 / 25) ») + lien `quizRestart`. Carte 2 si réponses complètes : `quizLastResult` + `quizSeeResults`. Module suspendu / erreur : `NoticeBanner` / `ErrorRetry` dans une carte.
- [ ] **Step 2 :** analyze, test, commit `Accueil du quiz`, push.

---

### Task 6: Cartes à balayer

**Files:**
- Create: `lib/features/quiz/swipe_card.dart`
- Modify: `lib/features/quiz/quiz_run_screen.dart`, arb fr/en
- Test: `test/quiz_swipe_test.dart`

**Interfaces:**
- Produces: `SwipeController extends ChangeNotifier { void fling(Answer a); }`, `SwipeCard({required Key key, required Widget child, required SwipeController controller, required ValueChanged<Answer> onAnswer, required String agreeLabel, required String disagreeLabel})`. Seuil : 35 % de la largeur. Sortie : 250 ms (0 si `MediaQuery.disableAnimationsOf`), rotation ±12°, léger `HapticFeedback.selectionClick()`. Clé de la carte du dessus : `ValueKey('statement-card-${s.id}')`.
- l10n : `quizSwipeHint`, `quizSkipStatement`.

- [ ] **Step 1 : test** : `MemoryCacheStore` avec `quiz:SN` = `{'quiz': bundle.toJson()}` (3 affirmations, 2 partis), onboarding fait, `PalabreApp` pompé, tap onglet « Testez-vous », tap « Commencer », puis `tester.drag(find.byKey(const ValueKey('statement-card-10')), const Offset(320, 0))`, `pumpAndSettle` ; attendu : la carte de l'affirmation 11 est visible ; puis tap sur le bouton ✕ (`find.byKey(const ValueKey('answer-desaccord'))`) → carte 12 visible ; test de l'interrupteur « important » : sur un bundle à 6 affirmations, l'activer six fois affiche `quizImportantLimit`. (Réponses vérifiées via `ProviderScope.containerOf` → `quizSessionProvider`.)

- [ ] **Step 2 : `swipe_card.dart`** : `StatefulWidget` + `SingleTickerProviderStateMixin`. État : `Offset _drag`, `AnimationController _anim`. `onPanUpdate` → `_drag += delta`. `onPanEnd` : `if (_drag.dx.abs() > width*0.35) _exit(dx>0 ? accord : desaccord) else _spring()`. `_exit(a)` : anime de `_drag` vers `Offset(sign*width*1.4, _drag.dy)` (neutre/passer : vers `Offset(0, height*0.6)` avec fondu), à la fin `widget.onAnswer(a)`. Rendu : `Transform.translate` + `Transform.rotate(angle: dx/width*0.21)` ; superposition : `Pill` « D'accord » (en haut à gauche, opacité `dx/threshold`) ou « Pas d'accord » (en haut à droite). Le contrôleur écoute `fling` et appelle `_exit`.

- [ ] **Step 3 : `QuizRunScreen`** : `BandScaffold(title: tabQuiz, eyebrow: quizSwipeHint, leading: fermer (context.pop), actions: [Pill(quizProgress) sur bandeau, bouton précédent si index>0], control: PercentBar(fraction, couleur onPrimary, piste onPrimary 25 %), body: Stack pile de cartes, bottom: boutons)`. Pile : deux `SoftCard` réduites (`scale 0.94/0.97`, translation 14/7 px) derrière, la `SwipeCard` devant contenant `SoftCard` avec `Pill(theme)` et `Text(texte, PalabreType.question(ink))`. `bottom` : `Row` de trois boutons ronds 56 px (`ValueKey('answer-desaccord'|'answer-neutre'|'answer-accord')`, icône close/remove/check, libellé dessous) ; ligne « Important pour moi » (`SoftCard` fine avec `Switch` couleur `accent`, compteur) ; `TextButton` `quizSkipStatement`. `onAnswer(a)` : `notifier.answer(s.id, a)` puis `index+1 >= total ? context.pushReplacement(quizResult) : notifier.goTo(index+1)`.

- [ ] **Step 4 :** tests, analyze, commit `Quiz : une affirmation par carte, balayage et boutons équivalents`, push.

---

### Task 7: Résultat et partage

**Files:**
- Modify: `lib/features/quiz/quiz_result_screen.dart`, `quiz_widgets.dart` (`PositionTile` restylé), arb fr/en
- Test: `test/quiz_result_test.dart`

**Interfaces:** l10n `quizResultsSubtitle` « {n} réponses · calculé sur votre téléphone », `quizResultsAllTitle` « Tous les partis, du plus proche au plus éloigné », `quizResultsNote`, `quizNotComputable` « non calculable », `quizDetailShort` « Détail par affirmation ». Suppression `quizResultsAll`.

- [ ] **Step 1 : test** : session complète sur le bundle de test (Alpha 100 %, Bêta partiel, Gamma sans position) ; pump `QuizResultScreen` dans `PalabreApp` via route ; attendu : les trois noms dans l'ordre du moteur (`Alpha` avant `Bêta` avant `Gamma`, vérifié par `tester.getTopLeft`), `find.textContaining('1er')`, `'#1'`, `'🥇'` absents, « non calculable » présent une fois.

- [ ] **Step 2 : écran** : `BandScaffold(title: quizResultsAllTitle, eyebrow: quizResultsSubtitle(n), leading: fermer → pop jusqu'à l'onglet)`. Carte principale : une `_PartyRow` par score : bande verticale 10×44 couleur parti (rayon 5), nom w700, sous-ligne `quizCompared · quizNoPosition`, `PalabreType.big` pourcentage ou `quizNotComputable` en `muted` 13, `PercentBar` couleur parti ; `CardDivider` entre lignes. `Text(quizResultsNote, note muted)` sous la carte. Ligne d'actions : `OutlinedButton(quizDetailShort)` qui bascule `_showDetail`, `FilledButton.icon(share)`. Carte détail (si `_showDetail`) : `ExpansionTile` par affirmation, `PositionTile` conservé mais restylé (fond `background`, rayon 12). `ShareCard` : 400 px, bandeau `PalabreTokens.light.primary` avec wordmark + titre, corps blanc avec la liste complète (nom, barre, %), pied `quizShareFooter` ; aucun rang.

- [ ] **Step 3 :** tests, analyze, commit `Résultat du quiz : liste complète en cartes, partage redessiné`, push.

---

### Task 8: Gouvernement

**Files:**
- Modify: `lib/features/reference/government_tab.dart`, arb fr/en

**Interfaces:** l10n `govToday` « aujourd'hui », `govSliderHint` « Faites glisser pour remonter le temps ».

- [ ] **Step 1 :** `BandScaffold(brand: true, title: govAt(date) (+ « · aujourd'hui » si date == today), eyebrow: tabGovernment, actions: [SettingsAction()], control: _TimeSlider)`. `_TimeSlider` : `LayoutBuilder` ; `SliderTheme` (actif `onPrimary`, inactif `onPrimary` 30 %, thumb `onPrimary`, overlay 0) ; sous la piste, un `Stack` de points 6 px `onPrimary` 70 % à `fraction = debut.difference(min).inDays / span` pour chaque gouvernement ; bornes `civilShort(min)` / `govToday` ; `govSliderHint` en `onPrimary` 75 % ; `onChangeEnd` : si un point est à moins de 3 % de la valeur, aimanter dessus. Corps (`body`, `ListView` padding 16/0/16/32) : `SoftCard` en-tête (nom, période, couverture, `SourceLink`), puis une `CardSection` par bloc dans l'ordre existant (titre = `ColorDot` + libellé), grille `GridView.count`-like via `Wrap` de `_PortraitCell` (largeur `(w-32-24)/3`), chef du gouvernement en première carte.
- [ ] **Step 2 :** analyze, test, commit `Gouvernement : curseur temporel dans le bandeau, cartes par bloc`, push.

---

### Task 9: Assemblée, fiches, paramètres, nettoyage, version

**Files:**
- Modify: `assembly_tab.dart`, `person_screen.dart`, `party_screen.dart`, `settings_screen.dart`, arb fr/en (clés orphelines retirées : `onboardingProfileTitle`, `onboardingNoOpinion`, `continueLabel`, `quizResultsAll`, `quizVoteBeforeResults` si inutilisée), `pubspec.yaml` (version 0.2.0+1)

**Interfaces:** l10n `settingsAppearance` « Apparence », `themeSystem` « Système », `themeLight` « Clair », `themeDark` « Sombre ».

- [ ] **Step 1 : Assemblée** : `BandScaffold(brand: true, title: tabAssembly, eyebrow: '{asmLegislature} · {asmSeats}', actions: [SettingsAction()], control: Column[BandSearchField, Row de deux Pill onBand (PopupMenuButton) + asmResults])`. Corps : si `!scrutinsNominatifs` → `NoticeBanner` ; députés filtrés groupés par groupe (tri nom, « Sans groupe » en dernier) ; une `CardSection(title: groupe (ColorDot), trailing: count)` par groupe, lignes `_DeputyRow` (avatar 40, nom w700, circonscription · parti, `asmSubstitute` en `primary`) séparées par `CardDivider`.
- [ ] **Step 2 : fiches** : `PersonScreen` → `BandScaffold(title: nom, eyebrow: parti ?? '', leading auto)`, carte identité (avatar 84, naissance, bouton parti, sources photo/Wikidata), `CardSection` Mandats / Affiliations / Parcours / Positions de son parti. `PartyScreen` → `BandScaffold(title: nom, eyebrow: type · sigle)`, `CardSection` Identité / Histoire / Élus / Positions. `_TimelineRow` conservé.
- [ ] **Step 3 : Paramètres** : `BandScaffold(title: settings)`, `CardSection(settingsAppearance)` avec `RadioGroup<ThemeMode>` (Système / Clair / Sombre) → `themeModeProvider.set`, `CardSection(settingsProfile)` avec `ProfileForm()`, `CardSection(settingsLanguage)` `RadioGroup<String?>`, `CardSection(settingsNotifications)`, `CardSection(settingsAbout)` + version lue de `pubspec` via constante `'0.2.0'`.
- [ ] **Step 4 :** retirer les clés arb orphelines (vérifier avec `grep -rn "l10n\.<clé>" lib`), `version: 0.2.0+1`, `flutter gen-l10n` implicite via build.
- [ ] **Step 5 :** analyze, test, build simulateur, captures clair et sombre des cinq écrans, commit `Assemblée, fiches et paramètres en cartes ; version 0.2.0`, push.
