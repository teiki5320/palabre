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
}
