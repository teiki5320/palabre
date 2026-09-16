// Contrôle un lot de cartes avant de le verser : le contenu livré plus le lot,
// passés au même contrôle que le dépôt. Les rédacteurs s'en servent pour ne
// rendre que des cartes qui passent.
//
// Usage : LOT=.tmp/lots/lot-x.json flutter test outils/verifie_lot.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';

void main() {
  test('le lot passe le controle', () {
    final chemin = Platform.environment['LOT'];
    if (chemin == null) fail('donnez le lot : LOT=.tmp/lots/lot-x.json');
    String lis(String nom) => File('assets/contenu/$nom.json').readAsStringSync();
    final livrees = jsonDecode(lis('cartes')) as List;
    final lot = jsonDecode(File(chemin).readAsStringSync()) as List;
    final ids = {for (final c in livrees) c['id']};
    final doublons = [for (final c in lot) if (ids.contains(c['id'])) c['id']];
    final contenu = Contenu.depuisChaines(
      cartes: jsonEncode([...livrees, ...lot]),
      personnages: lis('personnages'),
      parcours: lis('parcours'),
      fins: lis('fins'),
      exploits: lis('exploits'),
    );
    final problemes = [
      for (final d in doublons) 'carte $d : identifiant deja pris dans le depot',
      ...valide(contenu),
    ];
    expect(problemes, isEmpty, reason: '${problemes.length} problemes :\n${problemes.join('\n')}');
  });
}
