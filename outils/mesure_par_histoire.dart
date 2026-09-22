import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';
import 'package:president/moteur/tirage.dart';

/// Ce que chaque histoire, une par une, montre d'elle-même en cent jours.
///
/// `mesure_histoires.dart` donne la moyenne ; celui-ci donne le détail, et
/// surtout il joue les quatre parcours ouverts au lieu du seul général :
/// cinq romances ne s'offrent qu'à une présidente, et un mandat masculin
/// les compte à zéro sans que rien ne soit cassé.
///
///   flutter test outils/mesure_par_histoire.dart
///
/// Écrit `sources/mesures/par_histoire.csv`, que planche_histoires.py relit.
void main() {
  test('mille mandats, histoire par histoire', () async {
    Future<String> lis(String n) => File('assets/contenu/$n.json').readAsString();
    final contenu = Contenu.depuisChaines(
      cartes: await lis('cartes'),
      personnages: await lis('personnages'),
      parcours: await lis('parcours'),
      fins: await lis('fins'),
      exploits: await lis('exploits'),
      objets: await lis('objets'),
      adversaires: await lis('adversaires'),
    );

    final longueur = <String, int>{};
    for (final c in contenu.cartes) {
      final ch = c.chaine;
      if (ch == null) continue;
      longueur[ch.id] = max(longueur[ch.id] ?? 0, ch.rang);
    }

    final ouverts = contenu.parcours.where((p) => p.ouvertDesLeDebut).toList();
    expect(ouverts, isNotEmpty);

    const parties = 1000;
    final alea = Random(11);
    final entamees = <String, int>{};
    final suivies = <String, int>{}; // au moins deux crans
    final finies = <String, int>{};

    for (var p = 0; p < parties; p++) {
      // On tourne sur les parcours ouverts : c'est ce qu'un joueur neuf a
      // sous la main, et ce qui décide quelles romances peuvent s'ouvrir.
      final depart = ouverts[p % ouverts.length];
      final opposants = contenu.adversaires;
      var etat = EtatPartie(
        parcours: depart.id,
        nomJoueur: depart.femme ? 'Awa' : 'Idriss',
        jauges: depart.depart,
        adversaire: opposants.isEmpty ? null : opposants[alea.nextInt(opposants.length)].id,
      );
      final vues = <String, int>{};
      while (true) {
        if (evalue(etat) != null) break;
        final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
        if (carte == null) break;
        final ch = carte.chaine;
        if (ch != null) vues[ch.id] = max(vues[ch.id] ?? 0, ch.rang);

        int ecart(Reponse r) {
          final apres = etat.jauges.applique(
            effetsReels(effets: r.effets, style: etat.style, mandat: etat.mandat, atout: depart.atout),
          );
          return Jauge.values.fold(0, (s, j) => s + (apres.valeur(j) - 50).abs());
        }

        final cote = alea.nextInt(4) == 0
            ? (alea.nextBool() ? Cote.gauche : Cote.droite)
            : (ecart(carte.gauche) <= ecart(carte.droite) ? Cote.gauche : Cote.droite);
        etat = repond(
          etat: etat,
          carte: carte,
          cote: cote,
          atout: depart.atout,
          qui: contenu.personnageDe(carte, depart),
        );
      }
      for (final e in vues.entries) {
        entamees[e.key] = (entamees[e.key] ?? 0) + 1;
        if (e.value >= 2) suivies[e.key] = (suivies[e.key] ?? 0) + 1;
        if (e.value >= (longueur[e.key] ?? 1)) finies[e.key] = (finies[e.key] ?? 0) + 1;
      }
    }

    final sortie = File('sources/mesures/par_histoire.csv');
    sortie.parent.createSync(recursive: true);
    final lignes = <String>['chaine;crans;entamees;suivies;finies;parties'];
    for (final id in longueur.keys.toList()..sort()) {
      lignes.add('$id;${longueur[id]};${entamees[id] ?? 0};'
          '${suivies[id] ?? 0};${finies[id] ?? 0};$parties');
    }
    sortie.writeAsStringSync(lignes.join('\n'));
    stdout.writeln('${sortie.path} — ${longueur.length} histoires, $parties mandats');
  });
}
