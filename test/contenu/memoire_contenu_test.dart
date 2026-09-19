import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/memoire.dart';

/// Ce que la mémoire exige du contenu : un opposant lisible, et des cartes
/// qui ne réclament jamais la rancune de quelqu'un qui n'existe pas.
void main() {
  late Contenu contenu;

  setUpAll(() async {
    Future<String> lis(String n) => File('assets/contenu/$n.json').readAsString();
    contenu = Contenu.depuisChaines(
      cartes: await lis('cartes'),
      personnages: await lis('personnages'),
      parcours: await lis('parcours'),
      fins: await lis('fins'),
      exploits: await lis('exploits'),
      objets: await lis('objets'),
      adversaires: await lis('adversaires'),
    );
  });

  test('il y a de quoi tirer un opposant', () {
    expect(contenu.adversaires.length, greaterThanOrEqualTo(3));
    final ids = contenu.adversaires.map((a) => a.id).toSet();
    expect(ids.length, contenu.adversaires.length, reason: 'deux opposants portent le même identifiant');
  });

  test('chaque opposant se présente en une ligne', () {
    for (final a in contenu.adversaires) {
      expect(a.nom.trim(), isNotEmpty);
      expect(a.titre.trim(), isNotEmpty);
      expect(a.accroche.trim(), isNotEmpty, reason: a.id);
      expect(a.accroche.length, lessThanOrEqualTo(140), reason: a.id);
      expect(a.forceDepart, inInclusiveRange(forcePlancher, forcePlafond), reason: a.id);
    }
  });

  test('aucune carte ne nomme un opposant inconnu', () {
    final connus = contenu.adversaires.map((a) => a.id).toSet();
    for (final c in contenu.cartes) {
      for (final id in c.conditions.adversaire) {
        expect(connus, contains(id), reason: '${c.id} attend « $id »');
      }
    }
  });

  test('aucune carte ne réclame la loyauté d un inconnu', () {
    final gens = {...contenu.personnages.keys, Contenu.conjoint};
    for (final c in contenu.cartes) {
      final de = c.conditions.loyauteDe;
      if (de != null) expect(gens, contains(de), reason: '${c.id} attend « $de »');
      // Une carte qui exige une loyauté sans dire de qui parle du
      // personnage de la carte : il doit alors en avoir une.
      final exige = c.conditions.loyauteMin != null || c.conditions.loyauteMax != null;
      if (exige && de == null) {
        expect(gens, contains(c.personnage), reason: '${c.id} exige la loyauté de personne');
      }
    }
  });

  test('les bornes de loyauté demandées sont atteignables', () {
    for (final c in contenu.cartes) {
      final min = c.conditions.loyauteMin;
      final max = c.conditions.loyauteMax;
      if (min != null) expect(min, inInclusiveRange(loyautePlancher, loyautePlafond), reason: c.id);
      if (max != null) expect(max, inInclusiveRange(loyautePlancher, loyautePlafond), reason: c.id);
      if (min != null && max != null) expect(min, lessThanOrEqualTo(max), reason: c.id);
    }
  });

  test('les forces demandées sont atteignables', () {
    for (final c in contenu.cartes) {
      final min = c.conditions.forceMin;
      final max = c.conditions.forceMax;
      if (min != null) expect(min, inInclusiveRange(forcePlancher, forcePlafond), reason: c.id);
      if (max != null) expect(max, inInclusiveRange(forcePlancher, forcePlafond), reason: c.id);
      if (min != null && max != null) expect(min, lessThanOrEqualTo(max), reason: c.id);
    }
  });

  test('chaque personnage qui parle défend une jauge', () {
    // Sans affinité, un personnage ne retient rien de ce qu'on décide : la
    // moitié du paquet ne nourrirait aucune mémoire.
    final muets = [for (final p in contenu.personnages.values) if (p.jauge == null) p.id];
    expect(muets, isEmpty, reason: 'sans jauge : ${muets.join(', ')}');
  });
}
