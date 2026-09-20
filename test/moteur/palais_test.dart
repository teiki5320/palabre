import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/decor.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/palais.dart';
import 'package:president/moteur/romance.dart';

EtatPartie etatAvec({
  int peuple = 50,
  int armee = 50,
  int caisses = 50,
  int presse = 50,
  int jour = 10,
  int style = styleDepart,
  Set<String> drapeaux = const {},
  Map<String, int> attache = const {},
  String? epouse,
}) =>
    EtatPartie(
      parcours: 'general_parcours',
      nomJoueur: 'Awa',
      jauges: Jauges(peuple: peuple, armee: armee, caisses: caisses, presse: presse),
      jour: jour,
      style: style,
      drapeaux: drapeaux,
      attache: attache,
      epouse: epouse,
    );

List<Objet> lisCatalogue() {
  final source = File('assets/contenu/objets.json').readAsStringSync();
  return [for (final j in (jsonDecode(source) as List).cast<Map<String, dynamic>>()) Objet.depuisJson(j)];
}

void main() {
  group('le catalogue', () {
    late List<Objet> objets;
    setUpAll(() => objets = lisCatalogue());

    test('se lit sans erreur et contient vingt-quatre objets', () {
      expect(objets, hasLength(24));
    });

    test('les identifiants sont uniques', () {
      final ids = objets.map((o) => o.id).toSet();
      expect(ids, hasLength(objets.length));
    });

    test('chaque pièce a au moins deux objets', () {
      for (final p in Piece.values) {
        final combien = objets.where((o) => o.piece == p).length;
        expect(combien, greaterThanOrEqualTo(2), reason: 'la pièce ${p.name} n\'a que $combien objet(s)');
      }
    });

    test('tout meubler coûte deux cents points de caisses', () {
      final total = objets.fold<int>(0, (s, o) => s + o.prix);
      expect(total, 200);
    });

    test('aucun objet ne coûte moins de trois ni plus de vingt', () {
      for (final o in objets) {
        expect(o.prix, inInclusiveRange(3, 20), reason: o.id);
      }
    });

    test('aucun texte ne parle de francs', () {
      for (final o in objets) {
        final texte = '${o.nom} ${o.description}'.toLowerCase();
        expect(texte.contains('franc'), isFalse, reason: o.id);
      }
    });

    test('chaque objet pose un drapeau bâti sur son identifiant', () {
      for (final o in objets) {
        expect(o.drapeau, 'objet_${o.id}');
      }
    });

    test('le coffre-fort porte bien l identifiant que le moteur attend', () {
      expect(objets.any((o) => o.drapeau == drapeauCoffre), isTrue);
    });
  });

  group('acheter', () {
    final objet = const Objet(
      id: 'climatiseur',
      piece: Piece.bureau,
      nom: 'Le climatiseur',
      description: '',
      prix: 10,
    );

    test('un achat prend son prix sur les caisses', () {
      final apres = achete(etatAvec(caisses: 60), objet);
      expect(apres.jauges.caisses, 50);
    });

    test('un achat pose le drapeau de l objet', () {
      final apres = achete(etatAvec(caisses: 60), objet);
      expect(apres.drapeaux, contains('objet_climatiseur'));
    });

    test('un achat ne touche à aucune autre jauge par défaut', () {
      final apres = achete(etatAvec(caisses: 60), objet);
      expect(apres.jauges.peuple, 50);
      expect(apres.jauges.armee, 50);
      expect(apres.jauges.presse, 50);
    });

    test('l effet d achat s ajoute au paiement', () {
      const dimanche = Objet(
        id: 'dimanche',
        piece: Piece.piscine,
        nom: '',
        description: '',
        prix: 10,
        effetAchat: {Jauge.peuple: 4},
        styleAchat: -4,
      );
      final apres = achete(etatAvec(caisses: 60, style: 50), dimanche);
      expect(apres.jauges.caisses, 50);
      expect(apres.jauges.peuple, 54);
      expect(apres.style, 46);
    });

    test('on ne peut pas acheter deux fois le même objet', () {
      expect(achetable(etatAvec(caisses: 60), objet, {'climatiseur'}), isFalse);
    });

    test('on ne peut pas acheter si les caisses tombent sous le plancher', () {
      expect(achetable(etatAvec(caisses: 24), objet, {}), isFalse);
      expect(achetable(etatAvec(caisses: 25), objet, {}), isTrue);
    });

    test('l état d origine n est pas modifié', () {
      final avant = etatAvec(caisses: 60);
      achete(avant, objet);
      expect(avant.jauges.caisses, 60);
      expect(avant.drapeaux, isEmpty);
    });
  });

  group('le coffre-fort', () {
    test('ne fait rien si le palais n en a pas', () {
      final e = etatAvec(caisses: 4);
      expect(coffreSiBesoin(e).jauges.caisses, 4);
    });

    test('rend dix points la première fois que les caisses passent sous dix', () {
      final e = etatAvec(caisses: 4, drapeaux: {drapeauCoffre});
      final apres = coffreSiBesoin(e);
      expect(apres.jauges.caisses, 14);
      expect(apres.drapeaux, contains(drapeauCoffreOuvert));
    });

    test('ne se rouvre pas une seconde fois', () {
      final e = etatAvec(caisses: 4, drapeaux: {drapeauCoffre, drapeauCoffreOuvert});
      expect(coffreSiBesoin(e).jauges.caisses, 4);
    });

    test('ne s ouvre pas tant que les caisses tiennent', () {
      final e = etatAvec(caisses: 10, drapeaux: {drapeauCoffre});
      expect(coffreSiBesoin(e).jauges.caisses, 10);
      expect(coffreSiBesoin(e).drapeaux, isNot(contains(drapeauCoffreOuvert)));
    });
  });

  group('les drapeaux du palais', () {
    test('un objet possédé pose son drapeau au premier jour', () {
      expect(drapeauxDuPalais({'poste_radio', 'velo'}), {'objet_poste_radio', 'objet_velo'});
    });

    test('un palais vide ne pose rien', () {
      expect(drapeauxDuPalais({}), isEmpty);
    });
  });

  group('le décor du balcon', () {
    test('par défaut, l avenue ordinaire', () {
      expect(decorDuBalcon(etatAvec()).etat, 'ordinaire');
    });

    test('l émeute l emporte sur tout le reste', () {
      final e = etatAvec(peuple: 20, armee: 90, caisses: 10, presse: 10);
      expect(decorDuBalcon(e).etat, 'emeute');
    });

    test('l avenue verrouillée passe avant la ville éteinte', () {
      expect(decorDuBalcon(etatAvec(armee: 75, caisses: 20)).etat, 'verrouillee');
    });

    test('la liesse ne sort que si rien de pire n est vrai', () {
      expect(decorDuBalcon(etatAvec(peuple: 80)).etat, 'liesse');
      expect(decorDuBalcon(etatAvec(peuple: 80, presse: 20)).etat, 'cameras');
    });

    test('la saison des pluies ne sort qu entre le cinquante-cinquième et le soixante-quinzième jour', () {
      expect(decorDuBalcon(etatAvec(jour: 54)).etat, 'ordinaire');
      expect(decorDuBalcon(etatAvec(jour: 60)).etat, 'pluies');
      expect(decorDuBalcon(etatAvec(jour: 76)).etat, 'ordinaire');
    });

    test('le défilé et le deuil passent avant les jauges, et restent de jour', () {
      final fete = etatAvec(peuple: 10, jour: 90, drapeaux: {'fete_nationale'});
      expect(decorDuBalcon(fete).etat, 'defile');
      expect(decorDuBalcon(fete).dossier, contains('/jour/'));

      final deuil = etatAvec(peuple: 10, drapeaux: {'deuil_national'});
      expect(decorDuBalcon(deuil).etat, 'deuil');
    });

    test('la nuit tombe au quatre-vingtième jour et pas avant', () {
      expect(decorDuBalcon(etatAvec(jour: 79)).dossier, contains('/jour/'));
      expect(decorDuBalcon(etatAvec(jour: 80)).dossier, contains('/nuit/'));
    });

    test('la chambre partagée s ouvre par la romance, et par rien d autre', () {
      // Elle a existé des mois sans qu'aucune partie puisse l'atteindre :
      // elle exigeait un drapeau que personne ne posait.
      expect(decorDeLaChambre(etatAvec()).etat, 'base');
      expect(decorDeLaChambre(etatAvec(drapeaux: {'conjoint'})).etat, 'base');
      expect(decorDeLaChambre(etatAvec(attache: {'maire': 2})).etat, 'base');
      expect(decorDeLaChambre(etatAvec(attache: {'maire': 3})).etat, 'conjoint_maire');
      expect(decorDeLaChambre(etatAvec(epouse: 'maire')).etat, 'conjoint_maire');
      // Et elle passe avant la nuit blanche : dormir à deux est ce qu'il y
      // a de plus vrai dans cette pièce.
      expect(decorDeLaChambre(etatAvec(jour: 85, epouse: 'maire')).etat, 'conjoint_maire');
      expect(decorDeLaChambre(etatAvec(jour: 85)).etat, 'nuit');
    });

    test('un rendez-vous ne se tient que si quelqu un l a pose', () {
      expect(rendezVousDe(etatAvec(epouse: 'maire')), isNull);
      final soir = etatAvec(epouse: 'maire', drapeaux: {drapeauRendezVous('maire')});
      expect(rendezVousDe(soir)!.qui, 'maire');
    });

    test('c est celle qui a invite qui attend, pas la liaison principale', () {
      // Deux liaisons en cours : sans le nom dans le drapeau, la chambre
      // montrerait la plus avancee, qui n a rien demande.
      final deux = etatAvec(
        attache: {'maire': 5, 'militante': 3},
        drapeaux: {drapeauRendezVous('militante')},
      );
      expect(partenaire(deux.attache, deux.epouse), 'maire');
      expect(rendezVousDe(deux)!.qui, 'militante');
    });

    test('la scene du rendez-vous a deux temps, debout puis sur le lit', () {
      final rdv = rendezVousDe(etatAvec(epouse: 'maire', drapeaux: {drapeauRendezVous('maire')}))!;
      expect(rdv.debout.images, 4);
      expect(rdv.debout.ratio, ratioPlaque);
      // Le lit est en portrait : il remplit l ecran du telephone au lieu
      // d en montrer un tiers.
      expect(rdv.lit.images, 6);
      expect(rdv.lit.allerRetour, isTrue);
      expect(rdv.lit.ratio, lessThan(1));
      for (var i = 1; i <= rdv.lit.images; i++) {
        expect(File(rdv.lit.chemin(i)).existsSync(), isTrue, reason: rdv.lit.chemin(i));
      }
    });

    test('les dix personnes ont leur boucle de lit', () {
      for (final qui in ['redactrice', 'cabinet', 'emissaire', 'militante', 'epouse',
        'international', 'ministre', 'renseignements', 'maire', 'epoux']) {
        final rdv = rendezVousDe(etatAvec(epouse: qui, drapeaux: {drapeauRendezVous(qui)}))!;
        expect(rdv.lit.dossier, 'pieces/chambre_lit/$qui');
        for (var i = 1; i <= rdv.lit.images; i++) {
          expect(File(rdv.lit.chemin(i)).existsSync(), isTrue, reason: rdv.lit.chemin(i));
        }
      }
    });

    test('elle se montre en quatre images, faites d un seul coup', () {
      expect(decorDeLaChambre(etatAvec(epouse: 'maire')).images, 4);
    });

    test('c est la personne avec qui l on est qu on y voit', () {
      // Dix jeux d'images, un par personne : la chambre ne montre pas une
      // figure anonyme, elle montre qui est là.
      for (final qui in ['redactrice', 'cabinet', 'emissaire', 'militante', 'epouse',
        'international', 'ministre', 'renseignements', 'maire', 'epoux']) {
        final d = decorDeLaChambre(etatAvec(epouse: qui));
        expect(d.dossier, 'pieces/chambre_conjoint/$qui');
        for (var i = 1; i <= d.images; i++) {
          expect(File(d.chemin(i)).existsSync(), isTrue, reason: d.chemin(i));
        }
      }
    });

    test('le conjoint passe avant l amante', () {
      final d = decorDeLaChambre(etatAvec(epouse: 'maire', attache: {'redactrice': 5}));
      expect(d.dossier, contains('maire'));
    });

    test('quelqu un sans plaque laisse la chambre du célibataire', () {
      expect(decorDeLaChambre(etatAvec(epouse: 'doyen')).etat, 'base');
    });

    test('les dix-huit états du balcon comptent six clés, jouées en aller-retour', () {
      // Elles sont toutes tirées d'un plan filmé de quatre secondes : la
      // dernière clé ne ressemble plus du tout à la première, donc la
      // boucle repasse par où elle est venue au lieu de sauter.
      for (final e in [
        etatAvec(),
        etatAvec(jour: 85),
        etatAvec(presse: 20),
        etatAvec(jour: 85, presse: 20),
        etatAvec(peuple: 80),
        etatAvec(peuple: 20),
        etatAvec(armee: 75),
        etatAvec(caisses: 20),
        etatAvec(jour: 60),
        etatAvec(caisses: 70, peuple: 60),
        etatAvec(drapeaux: {'fete_nationale'}),
        etatAvec(drapeaux: {'deuil_national'}),
      ]) {
        final d = decorDuBalcon(e);
        expect(d.images, 6, reason: d.etat);
        expect(d.allerRetour, isTrue, reason: d.etat);
        // Six clés en aller-retour font dix pas, sans repasser deux fois
        // par les deux bouts.
        expect(d.pas, 10, reason: d.etat);
      }
    });

    test('l aller-retour monte puis redescend, sans doubler les extrémités', () {
      const d = Decor(dossier: 'x', etat: 'x', nom: 'x', images: 6, allerRetour: true);
      expect([for (var j = 0; j < d.pas; j++) d.cle(j)], [1, 2, 3, 4, 5, 6, 5, 4, 3, 2]);
      // Et le pas suivant repart sur la première : la boucle est continue.
      expect(d.cle(d.pas), 1);
    });

    test('une boucle ordinaire tourne en rond comme avant', () {
      const d = Decor(dossier: 'x', etat: 'x', nom: 'x', images: 4);
      expect([for (var j = 0; j < d.pas; j++) d.cle(j)], [1, 2, 3, 4]);
      expect(d.cle(4), 1);
    });

    test('une image seule n a qu un pas', () {
      const d = Decor(dossier: 'x', etat: 'x', nom: 'x', allerRetour: true);
      expect(d.pas, 1);
      expect(d.cle(0), 1);
      expect(d.cle(7), 1);
    });
  });

  group('la cour des voitures', () {
    test('elle se remplit une voiture à la fois', () {
      expect(decorDuGarage({}).etat, 'base');
      expect(decorDuGarage({'velo'}).etat, 'deux');
      expect(decorDuGarage({'velo', 'motos'}).etat, 'trois');
      expect(decorDuGarage({'velo', 'motos', 'limousine'}).etat, 'parc');
      expect(decorDuGarage({'velo', 'motos', 'limousine', 'quatre_quatre'}).etat, 'parc');
    });

    test('seuls les véhicules comptent', () {
      // Un coffre-fort dans le bureau ne remplit pas la cour.
      expect(decorDuGarage({'coffre_fort', 'ventilateur'}).etat, 'base');
    });
  });

  group('le décor des pièces', () {
    test('le bureau s ensevelit quand la presse s effondre', () {
      expect(decorDuBureau(etatAvec(presse: 25)).etat, 'enseveli');
    });

    test('le bureau devient un palais sous un régime dur', () {
      expect(decorDuBureau(etatAvec(style: 80)).etat, 'chef');
    });

    test('le bureau s ouvre sous un régime tendre', () {
      expect(decorDuBureau(etatAvec(style: 20)).etat, 'ouvert');
    });

    test('la presse basse passe avant le régime', () {
      expect(decorDuBureau(etatAvec(presse: 20, style: 90)).etat, 'enseveli');
    });

    test('le dimanche du quartier s anime, et lui seul parmi les pièces', () {
      final dimanche = decorDeLaPiscine(etatAvec(caisses: 60, style: 30), {'dimanche'});
      expect(dimanche.images, 6);
      expect(dimanche.allerRetour, isTrue);
      // Les autres états de la piscine restent des plaques fixes.
      expect(decorDeLaPiscine(etatAvec(caisses: 60), {}).images, 1);
    });

    test('la piscine suit les caisses', () {
      expect(decorDeLaPiscine(etatAvec(caisses: 60), {}).etat, 'base');
      expect(decorDeLaPiscine(etatAvec(caisses: 25), {}).etat, 'verte');
      expect(decorDeLaPiscine(etatAvec(caisses: 10), {}).etat, 'vide');
    });

    test('le dimanche du quartier demande l objet et un régime tendre', () {
      expect(decorDeLaPiscine(etatAvec(caisses: 60, style: 30), {'dimanche'}).etat, 'quartier');
      expect(decorDeLaPiscine(etatAvec(caisses: 60, style: 50), {'dimanche'}).etat, 'base');
      expect(decorDeLaPiscine(etatAvec(caisses: 60, style: 30), {}).etat, 'base');
    });

    test('la chambre passe à la nuit blanche en fin de mandat', () {
      expect(decorDeLaChambre(etatAvec(jour: 85)).etat, 'nuit');
    });
  });

  group('les images existent toutes sur le disque', () {
    test('chaque décor possible pointe sur un fichier réel', () {
      final aVerifier = <Decor>[
        for (final heure in [10, 85])
          ...[
            etatAvec(jour: heure),
            etatAvec(jour: heure, peuple: 20),
            etatAvec(jour: heure, armee: 75),
            etatAvec(jour: heure, caisses: 20),
            etatAvec(jour: heure, presse: 20),
            etatAvec(jour: heure, peuple: 80),
            etatAvec(jour: heure, caisses: 70, peuple: 60),
            etatAvec(jour: heure == 10 ? 60 : 85),
          ].map(decorDuBalcon),
        decorDuBalcon(etatAvec(drapeaux: {'fete_nationale'})),
        decorDuBalcon(etatAvec(drapeaux: {'deuil_national'})),
      ];

      aVerifier.addAll([
        decorDuBureau(etatAvec()),
        decorDuBureau(etatAvec(presse: 20)),
        decorDuBureau(etatAvec(style: 80)),
        decorDuBureau(etatAvec(style: 20)),
        decorDeLaChambre(etatAvec()),
        decorDeLaChambre(etatAvec(jour: 85)),
        decorDeLaChambre(etatAvec(drapeaux: {'conjoint'})),
        // La chambre partagée : longtemps inatteignable, elle a maintenant
        // ses quatre clés, et c'est la romance qui l'ouvre.
        decorDeLaChambre(etatAvec(epouse: 'maire')),
        decorDeLaChambre(etatAvec(attache: {'redactrice': 3})),
        decorDuGarage({}),
        decorDuGarage({'velo'}),
        decorDuGarage({'velo', 'motos'}),
        decorDuGarage({'velo', 'motos', 'limousine'}),
        decorDuGarage({'velo', 'motos', 'limousine', 'quatre_quatre'}),
        decorDeLaPiscine(etatAvec(caisses: 60), {}),
        decorDeLaPiscine(etatAvec(caisses: 25), {}),
        decorDeLaPiscine(etatAvec(caisses: 10), {}),
        decorDeLaPiscine(etatAvec(caisses: 60, style: 30), {'dimanche'}),
      ]);

      final manquants = <String>[];
      for (final d in aVerifier) {
        for (var i = 1; i <= d.images; i++) {
          final chemin = d.chemin(i);
          if (!File(chemin).existsSync()) manquants.add(chemin);
        }
      }
      expect(manquants, isEmpty, reason: 'images absentes : ${manquants.join(', ')}');

      // Et l'inverse : aucune clé oubliée dans un dossier de boucle. Une
      // image que le décor ne déclare plus ne serait jamais montrée, mais
      // elle partirait dans l'application et ferait croire à une boucle
      // plus longue qu'elle n'est.
      final enTrop = <String>[];
      for (final d in aVerifier) {
        if (d.images == 1) continue;
        final dossier = Directory('assets/images/palais/${d.dossier}');
        if (!dossier.existsSync()) continue;
        final cles = dossier.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg')).length;
        if (cles != d.images) enTrop.add('${d.dossier} : $cles fichiers pour ${d.images} déclarées');
      }
      expect(enTrop, isEmpty, reason: enTrop.join(', '));
    });
  });
}
