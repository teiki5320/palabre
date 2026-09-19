import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';

void main() {
  test('le contenu livre passe le controle', () {
    String lis(String nom) => File('assets/contenu/$nom.json').readAsStringSync();
    final c = Contenu.depuisChaines(
      cartes: lis('cartes'),
      personnages: lis('personnages'),
      parcours: lis('parcours'),
      fins: lis('fins'),
      exploits: lis('exploits'),
      objets: lis('objets'),
      adversaires: lis('adversaires'),
    );
    expect(valide(c), isEmpty, reason: valide(c).join('\n'));
  });
}
