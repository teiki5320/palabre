import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';

final carteSolde = Carte(
  id: 'general_solde_1',
  personnage: 'general',
  humeur: Humeur.fache,
  texte: 'La solde a deux mois de retard.',
  gauche: const Reponse(libelle: 'Patientez', effets: {Jauge.armee: -15, Jauge.caisses: 5}, drapeaux: ['solde_impayee']),
  droite: const Reponse(libelle: 'On paie', effets: {Jauge.armee: 10, Jauge.caisses: -15}),
  chaine: const Chaine(id: 'solde', rang: 1),
);

EtatPartie depart() => const EtatPartie(parcours: 'general', nomJoueur: 'Awa', jauges: Jauges.milieu);

void main() {
  test('la reponse de gauche applique ses effets et pose ses drapeaux', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.gauche);
    expect(e.jauges.armee, 35);
    expect(e.jauges.caisses, 55);
    expect(e.drapeaux, contains('solde_impayee'));
  });

  test('la reponse de droite applique ses propres effets', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.droite);
    expect(e.jauges.armee, 60);
    expect(e.jauges.caisses, 35);
    expect(e.drapeaux, isEmpty);
  });

  test('le jour avance et la carte est retenue comme vue', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.droite);
    expect(e.jour, 2);
    expect(e.vues, contains('general_solde_1'));
  });

  test('la carte jouee devient celle d hier', () {
    final apres = repond(etat: depart(), carte: carteSolde, cote: Cote.gauche);
    expect(apres.hier, carteSolde.id);
  });

  test('la chaine memorise son rang et son jour', () {
    final e = repond(etat: depart(), carte: carteSolde, cote: Cote.droite);
    expect(e.chainesRang['solde'], 1);
    expect(e.chainesJour['solde'], 1);
  });

  test('l etat d origine n est pas modifie', () {
    final avant = depart();
    repond(etat: avant, carte: carteSolde, cote: Cote.gauche);
    expect(avant.jour, 1);
    expect(avant.jauges.armee, 50);
    expect(avant.drapeaux, isEmpty);
  });

  group('amplifie', () {
    test('au mandat 1, les effets ne changent pas', () {
      expect(amplifie(const {Jauge.armee: -12, Jauge.caisses: 5}, 1), {Jauge.armee: -12, Jauge.caisses: 5});
    });

    test('au mandat 2, les effets sont multiplies par 1,25 et arrondis', () {
      expect(amplifie(const {Jauge.armee: -12}, 2), {Jauge.armee: -15});
    });

    test('au mandat 3, les effets sont multiplies par 1,5', () {
      expect(amplifie(const {Jauge.armee: -12}, 3), {Jauge.armee: -18});
    });

    test('au mandat 4 et au-dela, le facteur reste 1,5', () {
      expect(amplifie(const {Jauge.armee: -12}, 4), {Jauge.armee: -18});
    });

    test('le resultat est toujours borne a plus ou moins 20, meme amplifie', () {
      expect(amplifie(const {Jauge.armee: 18}, 3), {Jauge.armee: 20});
      expect(amplifie(const {Jauge.armee: -18}, 3), {Jauge.armee: -20});
    });
  });

  group('repond amplifie selon le mandat de l etat', () {
    EtatPartie departMandat(int mandat) =>
        EtatPartie(parcours: 'general', nomJoueur: 'Awa', jauges: Jauges.milieu, mandat: mandat);

    test('au mandat 1, repond n amplifie rien (compatibilite avec l existant)', () {
      final e = repond(etat: departMandat(1), carte: carteSolde, cote: Cote.gauche);
      expect(e.jauges.armee, 35);
      expect(e.jauges.caisses, 55);
    });

    test('au mandat 2, repond applique les effets amplifies', () {
      final e = repond(etat: departMandat(2), carte: carteSolde, cote: Cote.gauche);
      // armee -15 * 1,25 = -18,75 -> -19 ; caisses 5 * 1,25 = 6,25 -> 6
      expect(e.jauges.armee, 50 - 19);
      expect(e.jauges.caisses, 50 + 6);
    });
  });
}
