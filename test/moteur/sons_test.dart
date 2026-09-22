import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/decor.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/palais.dart';
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

  test('chaque piece a son fond, et chaque fond son fichier', () {
    const jour = EtatPartie(
        parcours: 'p', nomJoueur: 'Awa', jauges: Jauges.milieu, jour: 10);
    for (final piece in Piece.values) {
      final decor = decorDe(piece, jour, const {});
      final fond = fondDe(piece, decor, jour);
      final chemin = 'assets/${fichierDuFond(fond)}';
      expect(File(chemin).existsSync(), isTrue, reason: '$chemin manque');
    }
    for (final fond in Fond.values) {
      expect(File('assets/${fichierDuFond(fond)}').existsSync(), isTrue,
          reason: '${fond.name} n a pas de fichier');
    }
  });

  test('la nuit ne tait que les etats calmes du balcon', () {
    const tard = EtatPartie(
        parcours: 'p', nomJoueur: 'Awa', jauges: Jauges.milieu, jour: 95);
    // Le balcon ordinaire devient la nuit...
    expect(fondDe(Piece.balcon, decorDuBalcon(tard), tard), Fond.balconNuit);
    // ...mais une emeute ne se calme pas parce qu il fait nuit.
    const emeute = EtatPartie(
        parcours: 'p', nomJoueur: 'Awa',
        jauges: Jauges(peuple: 10, armee: 50, caisses: 50, presse: 50), jour: 95);
    expect(fondDe(Piece.balcon, decorDuBalcon(emeute), emeute), Fond.balconEmeute);
  });

  test('la piscine ne sonne que lorsqu il y a du monde', () {
    const riche = EtatPartie(
        parcours: 'p', nomJoueur: 'Awa', jauges: Jauges.milieu, jour: 10, style: 20);
    final vide = decorDeLaPiscine(riche, const {});
    expect(fondDe(Piece.piscine, vide, riche), Fond.musiqueBureau,
        reason: 'un bassin sans personne prend la musique');
    final plein = decorDeLaPiscine(riche, const {'dimanche'});
    expect(fondDe(Piece.piscine, plein, riche), Fond.piscineQuartier);
  });

  test('le son de la decision reste le plus court : on l entend cent fois', () {
    final decision = File('assets/${fichierDe(Son.decision)}').lengthSync();
    for (final son in [Son.mal, Son.reelu, Son.battu]) {
      expect(decision, lessThan(File('assets/${fichierDe(son)}').lengthSync()),
          reason: 'la decision doit rester plus breve que ${son.name}');
    }
  });
}
