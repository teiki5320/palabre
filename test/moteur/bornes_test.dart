import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/condition.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/partie.dart';

void main() {
  test('un effet reel ne depasse jamais 20, quel que soit le mandat', () {
    // Le regime seul portait un effet a 30 au premier mandat, alors que
    // l amplification du second le ramenait a 20 : le second mandat
    // frappait moins fort. La borne est en sortie, une fois pour toutes.
    for (final mandat in [1, 2, 3]) {
      final r = effetsReels(effets: const {Jauge.caisses: 20}, style: 100, mandat: mandat);
      expect(r[Jauge.caisses], 20, reason: 'mandat $mandat');
    }
    // Et la borne ne mange pas le sens : un effet reel garde son signe.
    final p = effetsReels(effets: const {Jauge.peuple: -20}, style: 100, mandat: 3);
    expect(p[Jauge.peuple], -20);
  });

  test('tenir cent jours se compte en jours tenus, pas en jour non joue', () {
    const marathon = Condition(joursMin: 100);
    BilanMandat bilan(int jour) => BilanMandat(parcours: 'p', jauges: Jauges.milieu, jour: jour, mandat: 1);
    // Tombe au centieme jour : on en a tenu 99.
    expect(marathon.remplie(bilan(100)), isFalse);
    // Le mandat va a l election : jour 101, cent jours tenus.
    expect(marathon.remplie(bilan(101)), isTrue);
  });
}
