import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/simulation.dart';

Contenu contenuLivre() {
  String lis(String nom) => File('assets/contenu/$nom.json').readAsStringSync();
  return Contenu.depuisChaines(
    cartes: lis('cartes'),
    personnages: lis('personnages'),
    parcours: lis('parcours'),
    fins: lis('fins'),
    exploits: lis('exploits'),
    objets: lis('objets'),
    adversaires: lis('adversaires'),
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

  test('quatre parcours sont ouverts et six sont verrouilles', () {
    expect(contenu.parcours.length, 10);
    expect(contenu.parcours.where((p) => p.ouvertDesLeDebut).length, 4);
    expect(contenu.parcours.where((p) => !p.ouvertDesLeDebut).length, 6);
  });

  test('la galerie alterne un homme, une femme', () {
    final genres = contenu.parcours.map((p) => p.femme).toList();
    for (var i = 1; i < genres.length; i++) {
      expect(genres[i], isNot(genres[i - 1]),
          reason: 'deux parcours du même genre se suivent en position ${i + 1}');
    }
  });

  test('les parcours verrouilles portent une condition typee', () {
    for (final p in contenu.parcours.where((p) => !p.ouvertDesLeDebut)) {
      expect(p.condition, isNotNull, reason: '${p.id} resterait verrouille pour toujours');
    }
  });

  test('huit exploits sont definis, chacun avec un identifiant unique', () {
    expect(contenu.exploits.length, 8);
    expect(contenu.exploits.map((e) => e.id).toSet().length, 8);
  });

  // Jouer au hasard ne doit jamais mener bien loin : un joueur qui répond
  // sans réfléchir n'atteint pas la moitié du mandat. Ce que ce test attrape, c'est un parcours qui
  // s'effondre en quelques jours, ou qu'aucune carte ne met jamais en
  // danger. L'écart entre parcours, lui, est voulu.
  test('un mandat joue au hasard n atteint jamais la moitie', () {
    for (final p in contenu.parcours.where((p) => p.ouvertDesLeDebut)) {
      final m = simule(contenu: contenu, parcours: p.id, strategie: Strategie.auHasard, parties: 2000);
      expect(m.joursMoyens, greaterThan(12), reason: '${p.id} : mandats trop courts (${m.joursMoyens})');
      expect(m.joursMoyens, lessThan(dureeMandat / 2),
          reason: '${p.id} : mandats trop longs (${m.joursMoyens})');
    }
  });

  // Et jouer attentivement doit permettre d'aller au bout : c'est l'autre
  // bord de la fourchette, celui qu'on oublie de tester.
  test('un mandat joue prudemment atteint l election', () {
    for (final p in contenu.parcours.where((p) => p.ouvertDesLeDebut)) {
      final m = simule(contenu: contenu, parcours: p.id, strategie: Strategie.equilibree, parties: 1000);
      expect(m.joursMoyens, greaterThan(dureeMandat * 0.7),
          reason: '${p.id} : même en jouant bien, on n\'arrive pas au bout (${m.joursMoyens})');
    }
  });

  // Une carte réservée à un parcours ne sort évidemment pas quand on en joue
  // un autre : il faut donc jouer les dix, et longuement, pour savoir si une
  // carte est vraiment inatteignable. Les mandats durent cent jours ici,
  // parce que certaines cartes ne se débloquent que tard.
  test('aucune carte n est ecrite pour rien', () {
    var jamais = contenu.cartes.map((c) => c.id).toSet();
    for (final p in contenu.parcours) {
      for (final strategie in Strategie.values) {
        final m = simule(
          contenu: contenu,
          parcours: p.id,
          strategie: strategie,
          parties: 600,
          mandats: 2,
          duree: 100,
        );
        jamais = jamais.intersection(m.cartesJamaisVues);
        if (jamais.isEmpty) return;
      }
    }
    expect(jamais, isEmpty, reason: 'cartes jamais tirées : ${jamais.join(", ")}');
  });

  test('un joueur prudent atteint l election', () {
    final m = simule(contenu: contenu, parcours: 'professeure', strategie: Strategie.equilibree, parties: 2000);
    expect(m.denouements.keys.any((k) => k.startsWith('election')), isTrue,
        reason: 'aucun mandat ne va au bout : les cartes sont trop dures');
  });
}
