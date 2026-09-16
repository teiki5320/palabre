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
