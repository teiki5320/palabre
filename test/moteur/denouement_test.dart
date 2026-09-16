import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';

EtatPartie etat(Jauges j, {int jour = 5}) =>
    EtatPartie(parcours: 'general', nomJoueur: 'Awa', jauges: j, jour: jour);

const fins = [
  Fin(id: 'armee_bas', jauge: Jauge.armee, versLeHaut: false, titre: 'Coup d Etat', texte: 't', image: 'i'),
  Fin(id: 'armee_haut', jauge: Jauge.armee, versLeHaut: true, titre: 'L armee gouverne', texte: 't', image: 'i'),
  Fin(id: 'election_gagnee', jauge: null, versLeHaut: true, titre: 'Reelu', texte: 't', image: 'i'),
  Fin(id: 'election_perdue', jauge: null, versLeHaut: false, titre: 'Battu', texte: 't', image: 'i'),
];

void main() {
  test('tant que tout va bien, il n y a pas de denouement', () {
    expect(evalue(etat(Jauges.milieu)), isNull);
  });

  test('une jauge vide fait chuter', () {
    final d = evalue(etat(const Jauges(peuple: 50, armee: 0, caisses: 50, presse: 50)))!;
    expect(d.type, TypeDenouement.chute);
    expect(d.jauge, Jauge.armee);
    expect(d.versLeHaut, isFalse);
  });

  test('une jauge pleine fait chuter aussi', () {
    final d = evalue(etat(const Jauges(peuple: 50, armee: 100, caisses: 50, presse: 50)))!;
    expect(d.type, TypeDenouement.chute);
    expect(d.jauge, Jauge.armee);
    expect(d.versLeHaut, isTrue);
  });

  test('au dela de la duree, l election est gagnee si peuple et presse depassent 50', () {
    final d = evalue(etat(const Jauges(peuple: 60, armee: 50, caisses: 50, presse: 45), jour: dureeMandat + 1))!;
    expect(d.type, TypeDenouement.electionGagnee);
  });

  test('au dela de la duree, l election est perdue si la moyenne est trop basse', () {
    final d = evalue(etat(const Jauges(peuple: 40, armee: 50, caisses: 50, presse: 45), jour: dureeMandat + 1))!;
    expect(d.type, TypeDenouement.electionPerdue);
  });

  test('la chute passe avant l election', () {
    final d = evalue(etat(const Jauges(peuple: 0, armee: 50, caisses: 50, presse: 90), jour: dureeMandat + 1))!;
    expect(d.type, TypeDenouement.chute);
  });

  test('choisitFin trouve la fin correspondante', () {
    final chute = evalue(etat(const Jauges(peuple: 50, armee: 100, caisses: 50, presse: 50)))!;
    expect(choisitFin(chute, fins)!.id, 'armee_haut');

    final gagnee = evalue(etat(const Jauges(peuple: 80, armee: 50, caisses: 50, presse: 80), jour: dureeMandat + 1))!;
    expect(choisitFin(gagnee, fins)!.id, 'election_gagnee');
  });

  test('choisitFin rend null si la fin manque au contenu', () {
    final chute = evalue(etat(const Jauges(peuple: 0, armee: 50, caisses: 50, presse: 50)))!;
    expect(choisitFin(chute, fins), isNull);
  });
}
