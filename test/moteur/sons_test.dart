import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/sons.dart';

void main() {
  test('une reponse ordinaire ne fait que le bruit de la carte', () {
    expect(sonDeLaReponse({Jauge.peuple: 6, Jauge.caisses: -4}), Son.decision);
    expect(sonDeLaReponse(const {}), Son.decision);
  });

  test('un grand mouvement remplace le bruit de la carte', () {
    expect(sonDeLaReponse({Jauge.peuple: seuilNotable}), Son.mieux);
    expect(sonDeLaReponse({Jauge.armee: -seuilNotable}), Son.mal);
  });

  test('juste sous le seuil, rien ne change', () {
    expect(sonDeLaReponse({Jauge.peuple: seuilNotable - 1}), Son.decision);
    expect(sonDeLaReponse({Jauge.peuple: 1 - seuilNotable}), Son.decision);
  });

  test('c est le mouvement le plus ample qui parle, pas la somme', () {
    // Quinze donnes au peuple, quinze repris aux caisses : la somme est
    // nulle, mais il s est passe quelque chose.
    expect(sonDeLaReponse({Jauge.peuple: 15, Jauge.caisses: -15}), Son.mal);
    expect(sonDeLaReponse({Jauge.peuple: 15, Jauge.caisses: -14}), Son.mieux);
  });

  test('a egalite, la mauvaise nouvelle gagne', () {
    expect(sonDeLaReponse({Jauge.peuple: 14, Jauge.presse: -14}), Son.mal);
  });

  test('les six sons sont livres avec le jeu', () {
    for (final son in Son.values) {
      final chemin = 'assets/${fichierDe(son)}';
      expect(File(chemin).existsSync(), isTrue, reason: '$chemin manque');
      // Un son d interface qui depasse cinq secondes est un son qu on
      // finira par couper.
      expect(File(chemin).lengthSync(), lessThan(60000), reason: '$chemin est trop lourd');
    }
  });

  test('le son de la decision reste le plus court : on l entend cent fois', () {
    final decision = File('assets/${fichierDe(Son.decision)}').lengthSync();
    for (final son in [Son.mal, Son.reelu, Son.battu]) {
      expect(decision, lessThan(File('assets/${fichierDe(son)}').lengthSync()),
          reason: 'la decision doit rester plus breve que ${son.name}');
    }
  });
}
