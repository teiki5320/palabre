import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';

const personnages = '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]';
const parcours = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
    '"accroche":"L armee vous suit, la presse se mefie.",'
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

String exploit({
  String id = 'ex',
  String titre = 'Un exploit',
  String description = 'Une description qui sert d indice.',
  String condition = '{"jours_min":30}',
}) =>
    '{"id":"$id","titre":"$titre","description":"$description","condition":$condition}';

Contenu contenuAvec(String cartes, {String parcours = parcours, String fins = fins, String exploits = '[]'}) =>
    Contenu.depuisChaines(cartes: '[$cartes]', personnages: personnages, parcours: parcours, fins: fins, exploits: exploits);

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
    expect(valide(contenuAvec(carte(texte: 'x' * 151))).join(), contains('150'));
  });

  test('un texte court qui devient trop long une fois habille', () {
    // 140 caracteres bruts, mais la marque {titre} en vaut vingt de plus.
    final long = 'x' * 133 + ' {titre}';
    expect(long.length, lessThanOrEqualTo(141));
    // 133 + l espace + les vingt caracteres de « Madame la Presidente ».
    expect(valide(contenuAvec(carte(texte: long))).join(), contains('154 caractères'));
  });

  test('un parcours sans accroche', () {
    final sansAccroche = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
        '"femme":false,"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}}]';
    expect(valide(contenuAvec(carte(), parcours: sansAccroche)).join(), contains('accroche'));
  });

  test('une accroche trop longue', () {
    final trop = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
        '"femme":false,"accroche":"${'x' * 61}",'
        '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}}]';
    expect(valide(contenuAvec(carte(), parcours: trop)).join(), contains('60'));
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

  test('deux fins pour le meme cas au meme endroit de l axe', () {
    final avecDoublons = '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
        '{"id":"election_gagnee_bis","jauge":null,"vers_le_haut":true,"titre":"Reelu bis","texte":"t","image":"i"},'
        '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';
    expect(valide(contenuAvec(carte(), fins: avecDoublons)).join(), contains('se disputent'));
  });

  test('deux fins pour le meme cas que le regime departage', () {
    // Une fin large sert de repli a une fin etroite qu elle contient :
    // reelu, et reelu seul candidat.
    final departagees =
        '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
        '{"id":"election_gagnee_seul","jauge":null,"vers_le_haut":true,"style_min":72,'
        '"titre":"Seul candidat","texte":"t","image":"i"},'
        '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';
    expect(valide(contenuAvec(carte(), fins: departagees)), isEmpty);
  });

  test('deux fins qui se chevauchent a moitie', () {
    // Ni l une ni l autre ne tranche : entre 60 et 70, on ne saurait pas.
    final moitie =
        '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"style_max":70,"titre":"Reelu","texte":"t","image":"i"},'
        '{"id":"election_gagnee_seul","jauge":null,"vers_le_haut":true,"style_min":60,'
        '"titre":"Seul candidat","texte":"t","image":"i"},'
        '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';
    expect(valide(contenuAvec(carte(), fins: moitie)).join(), contains('se disputent'));
  });

  test('un mot interdit dans le titre d une fin est signale', () {
    final finsAvecPays = '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu a Dakar",'
        '"texte":"t","image":"i"},'
        '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]';
    expect(valide(contenuAvec(carte(), fins: finsAvecPays)).join(), contains('interdit'));
  });

  test('un mot interdit dans le nom d un personnage est signale', () {
    const personnagesAvecPays = '[{"id":"general","nom":"Le General de Lagos","titre":"Chef d etat-major"}]';
    final c = Contenu.depuisChaines(
      cartes: '[${carte()}]',
      personnages: personnagesAvecPays,
      parcours: parcours,
      fins: fins,
    );
    expect(valide(c).join(), contains('interdit'));
  });

  test('aucun parcours ouvert des le debut', () {
    final parcoursFermes = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
        '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40},"condition_deblocage":"Avoir au moins 50 en armee"}]';
    expect(valide(contenuAvec(carte(), parcours: parcoursFermes)).join(), contains('ouvert'));
  });

  test('deux exploits avec le meme identifiant', () {
    final e = '[${exploit(id: "ex")},${exploit(id: "ex")}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('identifiant'));
  });

  test('un exploit sans titre', () {
    final e = '[${exploit(titre: "")}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('titre'));
  });

  test('un exploit sans condition se debloquerait au premier mandat venu', () {
    final e = '[${exploit(condition: "{}")}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('condition'));
  });

  test('une condition d exploit impossible a remplir sur une jauge', () {
    final e = '[${exploit(condition: '{"peuple_min":80,"peuple_max":50}')}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('impossible'));
  });

  test('une condition d exploit avec des jours au dela de la duree du mandat', () {
    final e = '[${exploit(condition: '{"jours_min":40}')}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('impossible'));
  });

  test('une condition d exploit citant une fin inconnue', () {
    final e = '[${exploit(condition: '{"fin":"fin_fantome"}')}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('inconnue'));
  });

  test('un mot interdit dans le titre d un exploit est signale', () {
    final e = '[${exploit(titre: "Un exploit a Dakar")}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('interdit'));
  });

  test('un mot interdit dans la description d un exploit est signale', () {
    final e = '[${exploit(description: "Se faire remarquer a Lagos")}]';
    expect(valide(contenuAvec(carte(), exploits: e)).join(), contains('interdit'));
  });

  test('un parcours verrouille sans condition typee reste ferme pour toujours', () {
    final parcoursSansCondition = '[{"id":"musicienne","nom":"La star","titre":"Madame la Presidente","femme":true,'
        '"depart":{"peuple":75,"armee":35,"caisses":45,"presse":60},'
        '"condition_deblocage":"Finir un mandat avec le peuple au dessus de 80"}]';
    expect(valide(contenuAvec(carte(), parcours: parcoursSansCondition)).join(), contains('condition'));
  });

  test('une condition de parcours impossible a remplir est signalee', () {
    final parcoursImpossible = '[{"id":"musicienne","nom":"La star","titre":"Madame la Presidente","femme":true,'
        '"depart":{"peuple":75,"armee":35,"caisses":45,"presse":60},'
        '"condition_deblocage":"Finir un mandat avec le peuple au dessus de 80",'
        '"condition":{"peuple_min":90,"peuple_max":50}}]';
    expect(valide(contenuAvec(carte(), parcours: parcoursImpossible)).join(), contains('impossible'));
  });

  test('une condition de parcours citant une fin inconnue est signalee', () {
    final parcoursFinInconnue = '[{"id":"putschiste","nom":"Le putschiste","titre":"Monsieur le President","femme":false,'
        '"depart":{"peuple":35,"armee":80,"caisses":50,"presse":30},'
        '"condition_deblocage":"Se faire renverser par l armee",'
        '"condition":{"fin":"fin_fantome"}}]';
    expect(valide(contenuAvec(carte(), parcours: parcoursFinInconnue)).join(), contains('inconnue'));
  });
}
