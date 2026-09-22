import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/ciel.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';

CielDuJour au(int jour) => cielDe(EtatPartie(
      parcours: 'p', nomJoueur: 'Awa', jauges: Jauges.milieu, jour: jour,
    ));

void main() {
  test('le soleil tient les dix premieres cartes, la lune les dix suivantes', () {
    expect(au(1).astre, Astre.soleil);
    expect(au(10).astre, Astre.soleil);
    expect(au(11).astre, Astre.lune);
    expect(au(20).astre, Astre.lune);
    expect(au(21).astre, Astre.soleil);
  });

  test('l astre se leve a la premiere carte et se couche a la dixieme', () {
    expect(au(1).course, 0);
    expect(au(10).course, 1);
    expect(au(11).course, 0);
    // Au milieu de la traversee il est au plus haut, et il rase l horizon
    // aux deux bouts : c est ce qui fait qu on voit passer le temps.
    expect(au(1).hauteur, closeTo(0, .001));
    expect(au(5).hauteur, greaterThan(.9));
    expect(au(10).hauteur, closeTo(0, .001));
  });

  test('la lune croit d une nuit a l autre et n est pleine qu a la fin', () {
    expect(nuitsParMandat, 5);
    expect(au(11).phase, closeTo(.5, .001));
    expect(au(31).phase, closeTo(.625, .001));
    expect(au(100).phase, 1);
    // Le soleil n a pas de phase : il est toujours entier.
    expect(au(1).phase, 1);
  });

  test('le centieme jour tombe la nuit, sous la pleine lune', () {
    expect(au(100).astre, Astre.lune);
    expect(au(100).course, 1);
  });
}
