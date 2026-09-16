import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/tirage.dart';

Carte carte(String id, {bool ouverture = false, int poids = 1}) => Carte(
      id: id,
      personnage: 'general',
      humeur: Humeur.neutre,
      texte: 't',
      poids: poids,
      ouverture: ouverture,
      gauche: const Reponse(libelle: 'g', effets: {Jauge.armee: -1}),
      droite: const Reponse(libelle: 'd', effets: {Jauge.armee: 1}),
    );

EtatPartie etat({int jour = 1, int mandat = 1, Set<String> vues = const {}}) => EtatPartie(
      parcours: 'general_parcours',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      jour: jour,
      mandat: mandat,
      vues: vues,
    );

void main() {
  // Le paquet est charge de cartes ordinaires tres lourdes : sans la regle
  // d ouverture, le serment ne sortirait quasiment jamais au premier jour.
  final paquet = [
    for (var i = 0; i < 20; i++) carte('ordinaire$i', poids: 50),
    carte('serment', ouverture: true),
  ];

  test('le serment ouvre le premier jour du premier mandat, quelle que soit la graine', () {
    for (var graine = 0; graine < 50; graine++) {
      final choisie = choisitCarte(paquet: paquet, etat: etat(), alea: Random(graine));
      expect(choisie?.id, 'serment', reason: 'graine $graine');
    }
  });

  test('le serment ne revient pas les jours suivants', () {
    final choisie = choisitCarte(
      paquet: paquet,
      etat: etat(jour: 2, vues: {'serment'}),
      alea: Random(1),
    );
    expect(choisie?.id, isNot('serment'));
  });

  test('on ne rejure pas au second mandat', () {
    // Meme au jour 1, mais du mandat 2, et meme si la carte n a jamais ete vue.
    for (var graine = 0; graine < 30; graine++) {
      final choisie = choisitCarte(paquet: paquet, etat: etat(mandat: 2), alea: Random(graine));
      if (choisie?.id == 'serment') {
        // Elle reste tirable au hasard comme n importe quelle carte, mais
        // elle ne doit plus etre prioritaire : avec des poids de 50 contre 1,
        // la voir sortir a chaque graine signalerait la priorite.
        continue;
      }
      expect(choisie?.id, isNot('serment'));
      return;
    }
    fail('le serment sort encore systematiquement au mandat 2');
  });

  test('sans carte d ouverture, le premier jour tire normalement', () {
    final sansServent = paquet.where((c) => !c.ouverture).toList();
    final choisie = choisitCarte(paquet: sansServent, etat: etat(), alea: Random(3));
    expect(choisie, isNotNull);
    expect(choisie!.ouverture, isFalse);
  });
}
