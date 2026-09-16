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

Contenu contenuAvec(String cartes, {String parcours = parcours, String fins = fins}) =>
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

  test('un texte legitime contenant monument malin et benigne', () {
    final c = carte(texte: 'Un monument est inauguré, le geste est bénigne, malin.');
    expect(valide(contenuAvec(c)), isEmpty);
  });

  test('une phrase avec Senegal avec trait d union', () {
    final c = carte(texte: 'Le Séné-gal nous observe.');
    expect(valide(contenuAvec(c)).join(), contains('interdit'));
  });

  test('une phrase avec ONU et apostrophe', () {
    final c = carte(texte: "L'ONU s'inquiète.");
    expect(valide(contenuAvec(c)).join(), contains('interdit'));
  });

  test('un poids inferieur a 1', () {
    final c = carte(extra: ',"poids":0');
    expect(valide(contenuAvec(c)).join(), contains('poids'));
  });

  test('une reponse touche plus de trois jauges', () {
    final c = carte(effetsGauche: '{"armee":10,"peuple":-5,"caisses":5,"presse":3}');
    expect(valide(contenuAvec(c)).join(), contains('jauges'));
  });

  test('un effet nul', () {
    final c = carte(effetsGauche: '{"armee":0}');
    expect(valide(contenuAvec(c)).join(), contains('nul'));
  });

  test('il manque la fin d election gagnee', () {
    final sansGagnee = '[{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';
    expect(valide(contenuAvec(carte(), fins: sansGagnee)).join(), contains('gagnée'));
  });

  test('il manque la fin d election perdue', () {
    final sansPerdue = '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"}]';
    expect(valide(contenuAvec(carte(), fins: sansPerdue)).join(), contains('perdue'));
  });

  test('deux fins pour le meme cas', () {
    final avecDoublons = '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
        '{"id":"election_gagnee_bis","jauge":null,"vers_le_haut":true,"titre":"Reelu bis","texte":"t","image":"i"},'
        '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';
    expect(valide(contenuAvec(carte(), fins: avecDoublons)).join(), contains('deux fins'));
  });

  test('aucun parcours ouvert des le debut', () {
    final parcoursFermes = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
        '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40},"condition_deblocage":"Avoir au moins 50 en armee"}]';
    expect(valide(contenuAvec(carte(), parcours: parcoursFermes)).join(), contains('ouvert'));
  });
}
