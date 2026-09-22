import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/pays.dart';

Carte carte(String id, String texte) => Carte(
      id: id,
      personnage: 'general',
      humeur: Humeur.neutre,
      texte: texte,
      gauche: const Reponse(libelle: 'a', effets: {}, journal: ''),
      droite: const Reponse(libelle: 'b', effets: {}, journal: ''),
    );

void main() {
  test('la capitale est connue avant d avoir joue', () {
    expect(lieuxConnus(paquet: const [], vues: const {}), {'capitale'});
  });

  test('un lieu s allume quand une carte vue l a nomme', () {
    final paquet = [
      carte('c1', 'Le puits du quartier de la Cuvette est trouble.'),
      carte('c2', 'La mine continue de declarer moins qu elle ne sort.'),
    ];
    // Rien de vu : rien de connu, sauf la capitale.
    expect(lieuxConnus(paquet: paquet, vues: const {}), {'capitale'});
    expect(lieuxConnus(paquet: paquet, vues: {'c1'}), {'capitale', 'cuvette'});
    expect(lieuxConnus(paquet: paquet, vues: {'c1', 'c2'}),
        {'capitale', 'cuvette', 'mine'});
  });

  test('le lendemain compte autant que la question', () {
    final paquet = [
      Carte(
        id: 'c3',
        personnage: 'general',
        humeur: Humeur.neutre,
        texte: 'Rien de particulier.',
        gauche: const Reponse(
            libelle: 'a', effets: {}, journal: 'Le barrage a lache une vanne.'),
        droite: const Reponse(libelle: 'b', effets: {}, journal: ''),
      ),
    ];
    expect(lieuxConnus(paquet: paquet, vues: {'c3'}), contains('barrage'));
  });

  test('les accents et la casse ne comptent pas', () {
    expect(aplati('Le Fleuve à côté'), 'le fleuve a cote');
  });

  test('chaque lieu porte un nom et tient dans la plaque', () {
    for (final l in lieuxDuPays) {
      expect(l.nom.trim(), isNotEmpty);
      expect(l.x, inInclusiveRange(0, 1));
      expect(l.y, inInclusiveRange(0, 1));
      expect(l.motif, aplati(l.motif), reason: '${l.id} : le motif doit etre aplati');
    }
  });
}
