import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/app/theme.dart';
import 'package:palabre/core/widgets/band_scaffold.dart';
import 'package:palabre/core/widgets/soft_card.dart';

void main() {
  testWidgets('BandScaffold affiche surtitre, titre et enfants, sans retour à la racine', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: PalabreTheme.light(),
      home: const BandScaffold(title: 'Titre', eyebrow: 'Surtitre', children: [Text('corps')]),
    ));
    expect(find.text('Titre'), findsOneWidget);
    expect(find.text('SURTITRE'), findsOneWidget);
    expect(find.text('corps'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('BandScaffold propose un retour quand la route peut revenir', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: PalabreTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BandScaffold(title: 'Fiche', children: []))),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Fiche'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('ouvrir'), findsOneWidget);
  });

  testWidgets('SoftCard réagit au tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: PalabreTheme.light(),
      home: Scaffold(body: SoftCard(onTap: () => taps++, child: const Text('x'))),
    ));
    await tester.tap(find.text('x'));
    expect(taps, 1);
  });
}
