import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/ecrans/cadran_du_jour.dart';
import 'package:president/ecrans/partie_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'partie_ecran_test.dart' show contenuDEssai;

/// L ecran de jeu quand le systeme grossit le texte.
///
/// La ligne du jour porte son titre au centre et deux boutons sur les bords,
/// poses dans la meme pile : rien n empechait le centre de passer dessous.
/// Mesure avant correction, le hublot du jour finissait vingt-quatre points
/// sous le fronton du palais des l echelle normale, et la ligne debordait
/// l ecran des 1,3. L axe du regime debordait de son cote a 2,0.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'geste_appris': true}));

  Future<void> lanceA(WidgetTester tester, double echelle) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final contenu = contenuDEssai();
    await tester.pumpWidget(ProviderScope(
      overrides: [contenuProvider.overrideWith((ref) => contenu)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(echelle)),
          child: child!,
        ),
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

  for (final echelle in [1.0, 1.3, 1.6, 2.0]) {
    testWidgets('a l echelle $echelle, rien ne deborde et le hublot reste a sa place',
        (tester) async {
      await lanceA(tester, echelle);
      expect(tester.takeException(), isNull, reason: 'aucun debordement a $echelle');

      final cadran = tester.getRect(find.byType(CadranDuJour));
      final palais = tester.getRect(find.byTooltip('Le palais'));
      final sortie = tester.getRect(find.byTooltip('Quitter, la partie est gardée'));
      expect(cadran.right, lessThanOrEqualTo(palais.left),
          reason: 'le hublot du jour ne doit jamais passer sous le fronton du palais');
      expect(cadran.left, greaterThanOrEqualTo(sortie.right),
          reason: 'ni sous la fleche de sortie');
    });
  }
}
