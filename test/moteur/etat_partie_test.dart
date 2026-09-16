import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';

EtatPartie etat({
  Jauges? jauges,
  int jour = 5,
  int mandat = 1,
  Set<String> drapeaux = const {},
  String parcours = 'general',
}) =>
    EtatPartie(
      parcours: parcours,
      nomJoueur: 'Awa',
      jauges: jauges ?? Jauges.milieu,
      jour: jour,
      mandat: mandat,
      drapeaux: drapeaux,
    );

void main() {
  test('sans condition, la carte peut sortir', () {
    expect(const Conditions().satisfaites(etat()), isTrue);
  });

  test('le jour minimum et maximum sont respectes', () {
    expect(const Conditions(jourMin: 6).satisfaites(etat(jour: 5)), isFalse);
    expect(const Conditions(jourMin: 5).satisfaites(etat(jour: 5)), isTrue);
    expect(const Conditions(jourMax: 4).satisfaites(etat(jour: 5)), isFalse);
  });

  test('le mandat minimum est respecte', () {
    expect(const Conditions(mandatMin: 2).satisfaites(etat(mandat: 1)), isFalse);
    expect(const Conditions(mandatMin: 2).satisfaites(etat(mandat: 2)), isTrue);
  });

  test('les planchers et plafonds de jauges sont respectes', () {
    final pauvre = etat(jauges: const Jauges(peuple: 50, armee: 50, caisses: 20, presse: 50));
    expect(const Conditions(maximums: {Jauge.caisses: 30}).satisfaites(pauvre), isTrue);
    expect(const Conditions(maximums: {Jauge.caisses: 10}).satisfaites(pauvre), isFalse);
    expect(const Conditions(minimums: {Jauge.caisses: 30}).satisfaites(pauvre), isFalse);
    expect(const Conditions(minimums: {Jauge.caisses: 10}).satisfaites(pauvre), isTrue);
  });

  test('les drapeaux requis et interdits sont respectes', () {
    final avec = etat(drapeaux: {'solde_impayee'});
    expect(const Conditions(drapeauxRequis: ['solde_impayee']).satisfaites(avec), isTrue);
    expect(const Conditions(drapeauxRequis: ['solde_impayee']).satisfaites(etat()), isFalse);
    expect(const Conditions(drapeauxInterdits: ['solde_impayee']).satisfaites(avec), isFalse);
  });

  test('le parcours filtre les cartes personnelles', () {
    expect(const Conditions(parcours: ['general']).satisfaites(etat(parcours: 'general')), isTrue);
    expect(const Conditions(parcours: ['general']).satisfaites(etat(parcours: 'professeure')), isFalse);
    expect(const Conditions().satisfaites(etat(parcours: 'professeure')), isTrue);
  });

  test('copie ne change que ce qu on lui donne', () {
    final e = etat();
    final f = e.copie(jour: 9, drapeaux: {'x'});
    expect(f.jour, 9);
    expect(f.drapeaux, {'x'});
    expect(f.mandat, e.mandat);
    expect(f.nomJoueur, 'Awa');
    expect(e.jour, 5, reason: 'l etat d origine reste intact');
  });
}
