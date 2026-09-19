import 'package:flutter_test/flutter_test.dart';
import 'package:president/ecrans/fin_ecran.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/memoire.dart';

const opposant = Adversaire(
  id: 'animateur',
  nom: "L'animateur de la radio du matin",
  titre: 'Trois millions d\'auditeurs',
  accroche: 'Il en fait tous les matins.',
);

EtatPartie etat({int peuple = 60, int presse = 60, int force = 50, String? qui = 'animateur'}) => EtatPartie(
      parcours: 'general',
      nomJoueur: 'Awa',
      jauges: Jauges(peuple: peuple, armee: 50, caisses: 50, presse: presse),
      jour: 101,
      adversaire: qui,
      force: force,
    );

void main() {
  test('une chute ne se compte pas en points', () {
    final ligne = resultatDuScrutin(
      denouement: const Denouement(type: TypeDenouement.chute, jauge: Jauge.armee),
      etat: etat(),
      adversaire: opposant,
    );
    expect(ligne, isNull);
  });

  test('sans opposant connu, rien ne s affiche', () {
    final ligne = resultatDuScrutin(
      denouement: const Denouement(type: TypeDenouement.electionGagnee),
      etat: etat(qui: null),
      adversaire: null,
    );
    expect(ligne, isNull);
  });

  test('une élection gagnée dit de combien', () {
    final ligne = resultatDuScrutin(
      denouement: const Denouement(type: TypeDenouement.electionGagnee),
      etat: etat(peuple: 60, presse: 60, force: 50),
      adversaire: opposant,
    );
    expect(ligne, contains("L'animateur"));
    expect(ligne, contains('10 points de mieux'));
  });

  test('une élection perdue dit ce qui manquait', () {
    final ligne = resultatDuScrutin(
      denouement: const Denouement(type: TypeDenouement.electionPerdue),
      etat: etat(peuple: 40, presse: 40, force: 55),
      adversaire: opposant,
    );
    expect(ligne, contains('Il vous manquait 15 points'));
  });

  test('un seul point ne prend pas de s', () {
    final ligne = resultatDuScrutin(
      denouement: const Denouement(type: TypeDenouement.electionPerdue),
      etat: etat(peuple: 49, presse: 49, force: 50),
      adversaire: opposant,
    );
    expect(ligne, contains('1 point.'));
  });

  test('à égalité, on ne compte pas zéro point', () {
    final ligne = resultatDuScrutin(
      denouement: const Denouement(type: TypeDenouement.electionPerdue),
      etat: etat(peuple: 50, presse: 50, force: 50),
      adversaire: opposant,
    );
    expect(ligne, contains("Il s'en est fallu de rien"));
  });

  test('la ligne n accorde aucun participe au joueur', () {
    for (final t in [TypeDenouement.electionGagnee, TypeDenouement.electionPerdue]) {
      final ligne = resultatDuScrutin(
        denouement: Denouement(type: t),
        etat: etat(peuple: 55, presse: 55, force: 50),
        adversaire: opposant,
      )!;
      // « battu », « élu », « réélue » : tout ce qui s'accorderait avec un
      // joueur dont on ne connaît pas le genre.
      for (final mot in ['battu', 'élu', 'vaincu', 'sorti']) {
        expect(ligne.toLowerCase().contains(mot), isFalse, reason: ligne);
      }
    }
  });
}
