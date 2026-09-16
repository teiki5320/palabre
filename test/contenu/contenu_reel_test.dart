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
      expect(m.joursMoyens, greaterThan(10), reason: '${p.id} : mandats trop courts (${m.joursMoyens})');
      expect(m.joursMoyens, lessThan(22), reason: '${p.id} : mandats trop longs (${m.joursMoyens})');
    }
  });

  test('aucune carte n est ecrite pour rien', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 5000);
    final ailleurs = simule(contenu: contenu, parcours: 'professeure', strategie: Strategie.equilibree, parties: 5000);
    final jamais = m.cartesJamaisVues.intersection(ailleurs.cartesJamaisVues);
    expect(jamais, isEmpty, reason: 'cartes jamais tirées : ${jamais.join(", ")}');
  });

  test('un joueur prudent atteint l election', () {
    final m = simule(contenu: contenu, parcours: 'professeure', strategie: Strategie.equilibree, parties: 2000);
    expect(m.denouements.keys.any((k) => k.startsWith('election')), isTrue,
        reason: 'aucun mandat ne va au bout : les cartes sont trop dures');
  });
}
