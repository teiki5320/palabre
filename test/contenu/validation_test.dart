import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';

const personnages = '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]';
const parcours = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
    '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}}]';
const fins = '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
    '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';

String carte({
  String id = 'a',
  String personnage = 'general',
  String texte = 'Une phrase courte.',
  String libelleGauche = 'Non',
  String effetsGauche = '{"armee":-10}',
  String extra = '',
}) =>
    '{"id":"$id","personnage":"$personnage","humeur":"neutre","texte":"$texte",'
    '"gauche":{"libelle":"$libelleGauche","effets":$effetsGauche},'
    '"droite":{"libelle":"Oui","effets":{"armee":10}}$extra}';

Contenu contenuAvec(String cartes) =>
    Contenu.depuisChaines(cartes: '[$cartes]', personnages: personnages, parcours: parcours, fins: fins);

void main() {
  test('un contenu correct ne remonte aucun probleme', () {
    expect(valide(contenuAvec(carte())), isEmpty);
  });

  test('deux cartes avec le meme identifiant', () {
    expect(valide(contenuAvec('${carte(id: 'a')},${carte(id: 'a')}')).join(), contains('identifiant'));
  });

  test('un personnage inconnu', () {
    expect(valide(contenuAvec(carte(personnage: 'fantome'))).join(), contains('personnage'));
  });

  test('un texte trop long', () {
    expect(valide(contenuAvec(carte(texte: 'x' * 141))).join(), contains('140'));
  });

  test('un libelle trop long', () {
    expect(valide(contenuAvec(carte(libelleGauche: 'x' * 19))).join(), contains('18'));
  });

  test('un effet hors bornes', () {
    expect(valide(contenuAvec(carte(effetsGauche: '{"armee":-30}'))).join(), contains('20'));
  });

  test('une reponse sans effet', () {
    expect(valide(contenuAvec(carte(effetsGauche: '{}'))).join(), contains('effet'));
  });

  test('un drapeau exige que personne ne pose', () {
    final c = carte(extra: ',"conditions":{"drapeaux_requis":["jamais_pose"]}');
    expect(valide(contenuAvec(c)).join(), contains('jamais_pose'));
  });

  test('une chaine a trou', () {
    final un = carte(id: 'c1', extra: ',"chaine":{"id":"affaire","rang":1}');
    final trois = carte(id: 'c3', extra: ',"chaine":{"id":"affaire","rang":3}');
    expect(valide(contenuAvec('$un,$trois')).join(), contains('affaire'));
  });

  test('des conditions impossibles', () {
    final c = carte(extra: ',"conditions":{"jour_min":10,"jour_max":4}');
    expect(valide(contenuAvec(c)).join(), contains('impossible'));
  });

  test('un pays reel dans le texte', () {
    expect(valide(contenuAvec(carte(texte: 'Le Senegal nous observe.'))).join(), contains('interdit'));
  });

  test('un parcours inconnu dans les conditions', () {
    final c = carte(extra: ',"conditions":{"parcours":["pilote"]}');
    expect(valide(contenuAvec(c)).join(), contains('pilote'));
  });
}
