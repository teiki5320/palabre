import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/intro_ecran.dart';
import 'package:president/ecrans/partie_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/ecrans/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'partie_ecran_test.dart' show contenuDEssai;

/// Les tailles d'un iPad 11 pouces, en points, dans les deux sens. Un
/// téléphone est plus étroit que `largeurMax` : c'est ici que le cadre doit
/// se voir, et nulle part ailleurs.
const _portrait = Size(834, 1194);
const _paysage = Size(1194, 834);

Future<void> _taille(WidgetTester tester, Size s) async {
  tester.view.physicalSize = s;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Aucun widget peint ne doit dépasser la largeur du cadre, à la marge près
/// des images de fond — qui, elles, ont le droit de couvrir tout l'écran.
void _dansLeCadre(WidgetTester tester, Finder f, Size ecran) {
  final r = tester.getRect(f);
  expect(r.width, lessThanOrEqualTo(largeurMax + 1), reason: 'déborde le cadre');
  final marge = (ecran.width - largeurMax) / 2;
  expect(r.left, greaterThanOrEqualTo(marge - 1), reason: 'pas centré');
}

Future<void> _lancePartie(WidgetTester tester, Contenu contenu) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [contenuProvider.overrideWith((ref) => contenu)],
      child: MaterialApp(
        theme: theme(),
        home: Consumer(
          builder: (context, ref, _) {
            return TextButton(
              onPressed: () {
                ref
                    .read(sessionProvider.notifier)
                    .demarre(parcours: contenu.parcours.first, nom: 'Awa', graine: 1);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartieEcran()));
              },
              child: const Text('commencer'),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('commencer'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final cas in [('portrait', _portrait), ('paysage', _paysage)]) {
    testWidgets('sur tablette en ${cas.$1}, le jeu reste dans son cadre', (tester) async {
      await _taille(tester, cas.$2);
      await _lancePartie(tester, contenuDEssai());
      expect(tester.takeException(), isNull);
      _dansLeCadre(tester, find.byKey(const ValueKey('jauge_armee')), cas.$2);
      _dansLeCadre(tester, find.text('JOUR 1'), cas.$2);
      _dansLeCadre(tester, find.textContaining('solde'), cas.$2);
    });

    testWidgets('sur tablette en ${cas.$1}, la presentation est centree et agrandie', (tester) async {
      await _taille(tester, cas.$2);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme(),
          home: IntroEcran(onFini: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final titre = tester.widget<Text>(find.byType(Text).at(1));
      expect(titre.textAlign, TextAlign.center, reason: 'le titre doit être centré');
      expect(titre.style!.fontSize, greaterThan(34), reason: 'la police doit grandir sur tablette');
      _dansLeCadre(tester, find.byType(FilledButton), cas.$2);
    });
  }

  testWidgets('sur telephone, le cadre ne serre rien', (tester) async {
    await _taille(tester, const Size(390, 844));
    await _lancePartie(tester, contenuDEssai());
    expect(tester.takeException(), isNull);
    // La première jauge commence contre le bord : sur un téléphone, le
    // cadre est plus large que l'écran, il ne doit donc rien rogner.
    expect(tester.getRect(find.byKey(const ValueKey('jauge_peuple'))).left, lessThan(40));
  });
}
