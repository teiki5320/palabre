import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/simulation.dart';

/// Un paquet de dix cartes équilibrées, assez pour éprouver la mécanique
/// sans dépendre du contenu réel, qui est écrit plus tard.
Contenu paquetDEssai() {
  final cartes = [
    for (var i = 0; i < 10; i++)
      '{"id":"c$i","personnage":"general","humeur":"neutre","texte":"Situation $i",'
          '"gauche":{"libelle":"Non","effets":{"peuple":-6,"caisses":6}},'
          '"droite":{"libelle":"Oui","effets":{"peuple":6,"caisses":-6}},"repetable":true}'
  ].join(',');
  return Contenu.depuisChaines(
    cartes: '[$cartes]',
    personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
    parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
        '"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
    fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
        '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
  );
}

void main() {
  final contenu = paquetDEssai();

  test('toute partie se termine', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 200);
    expect(m.parties, 200);
    expect(m.denouements.values.fold<int>(0, (s, v) => s + v), 200);
  });

  test('glisser toujours du meme cote fait chuter vite', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.toujoursGauche, parties: 50);
    expect(m.joursMoyens, lessThan(15));
  });

  test('jouer au centre permet d atteindre l election', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.equilibree, parties: 50);
    expect(m.denouements.keys.any((k) => k.startsWith('election')), isTrue);
  });

  test('les cartes jamais tirees sont signalees', () {
    final m = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 200);
    expect(m.cartesJamaisVues, isEmpty);
  });

  test('a graine egale, les mesures sont identiques', () {
    final a = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 100, graine: 5);
    final b = simule(contenu: contenu, parcours: 'general_parcours', strategie: Strategie.auHasard, parties: 100, graine: 5);
    expect(a.joursMoyens, b.joursMoyens);
  });
}
