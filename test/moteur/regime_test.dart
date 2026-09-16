import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';

void main() {
  const decision = {
    Jauge.peuple: 10,
    Jauge.armee: -10,
    Jauge.caisses: 10,
    Jauge.presse: -10,
  };

  test('au milieu de l axe, le regime ne change rien', () {
    expect(selonRegime(decision, 50), decision);
  });

  test('vers la dictature, les caisses et la presse encaissent mieux', () {
    // Au bout de l axe : gain du camp x1,5, perte du camp x0,5, et
    // l inverse pour les jauges d en face.
    final r = selonRegime(decision, 100);
    expect(r[Jauge.caisses], 15); // gain favorise
    expect(r[Jauge.presse], -5); // perte amortie
    expect(r[Jauge.peuple], 5); // gain rogne
    expect(r[Jauge.armee], -15); // perte aggravee
  });

  test('vers la republique, le peuple et l armee encaissent mieux', () {
    final r = selonRegime(decision, 0);
    expect(r[Jauge.peuple], 15);
    expect(r[Jauge.armee], -5);
    expect(r[Jauge.caisses], 5);
    expect(r[Jauge.presse], -15);
  });

  test('a mi-chemin, l effet est de moitie', () {
    final r = selonRegime(decision, 75);
    expect(r[Jauge.caisses], 13); // 10 x 1,25
    expect(r[Jauge.peuple], 8); // 10 x 0,75
  });

  test('une decision ne perd jamais toute consequence', () {
    // Un effet de 1 rogne a 0,5 doit rester un point, pas disparaitre.
    final r = selonRegime(const {Jauge.peuple: 1, Jauge.caisses: -1}, 100);
    expect(r[Jauge.peuple], 1);
    expect(r[Jauge.caisses], -1);
  });

  auDela();

  test('le regime s applique avant l amplification du mandat', () {
    // Au mandat 2 tout est multiplie par 1,25, apres le regime.
    final r = effetsReels(effets: const {Jauge.caisses: 10}, style: 100, mandat: 2);
    expect(r[Jauge.caisses], 19); // 10 -> 15 -> 18,75 -> 19
  });
}

/// Le régime décide aussi de ce qu'on vous propose, et de ce qu'on vous
/// racontera à la fin.
void auDela() {
  test('une carte reservee a un regime ne sort pas ailleurs', () {
    final carte = Carte(
      id: 'liste',
      personnage: 'general',
      humeur: Humeur.neutre,
      texte: 't',
      conditions: const Conditions(styleMin: 70),
      gauche: const Reponse(libelle: 'g', effets: {Jauge.armee: 1}),
      droite: const Reponse(libelle: 'd', effets: {Jauge.armee: -1}),
    );
    EtatPartie etat(int style) => EtatPartie(
          parcours: 'p',
          nomJoueur: 'A',
          jauges: Jauges.milieu,
          style: style,
        );
    expect(carte.conditions.satisfaites(etat(50)), isFalse);
    expect(carte.conditions.satisfaites(etat(69)), isFalse);
    expect(carte.conditions.satisfaites(etat(70)), isTrue);
  });

  test('a score egal, le regime departage la fin', () {
    const large = Fin(
      id: 'election_gagnee',
      jauge: null,
      versLeHaut: true,
      titre: 'Réélu',
      texte: 't',
      image: 'i',
    );
    const etroite = Fin(
      id: 'election_gagnee_seul',
      jauge: null,
      versLeHaut: true,
      titre: 'Seul candidat',
      texte: 't',
      image: 'i',
      styleMin: 72,
    );
    const gagnee = Denouement(type: TypeDenouement.electionGagnee);
    // L ordre de la liste ne doit rien changer : c est la precision qui
    // tranche, pas la place dans le JSON.
    for (final fins in [
      [large, etroite],
      [etroite, large],
    ]) {
      expect(choisitFin(gagnee, fins, style: 50)!.id, 'election_gagnee');
      expect(choisitFin(gagnee, fins, style: 80)!.id, 'election_gagnee_seul');
    }
  });
}
