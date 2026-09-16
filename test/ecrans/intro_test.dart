import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/ecrans/intro_ecran.dart';
import 'package:president/sauvegarde/sauvegarde.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<int> montre(WidgetTester tester) async {
    var finis = 0;
    await tester.pumpWidget(MaterialApp(home: IntroEcran(onFini: () => finis++)));
    await tester.pumpAndSettle();
    return finis;
  }

  testWidgets('l intro s ouvre sur ce qu on vient de devenir', (tester) async {
    await montre(tester);
    expect(find.textContaining('élu'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('les trois panneaux expliquent le geste puis les jauges', (tester) async {
    await montre(tester);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('glissez'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('peuple'), findsOneWidget);
    // Au dernier panneau, le bouton mene au jeu.
    expect(find.text('Prendre mes fonctions'), findsOneWidget);
  });

  testWidgets('passer termine l intro tout de suite', (tester) async {
    var finis = 0;
    await tester.pumpWidget(MaterialApp(home: IntroEcran(onFini: () => finis++)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pump();
    expect(finis, 1);
  });

  testWidgets('l intro ne se montre qu une fois', (tester) async {
    expect(await Sauvegarde.introVue(), isFalse);
    await Sauvegarde.noteIntroVue();
    expect(await Sauvegarde.introVue(), isTrue);
  });
}
