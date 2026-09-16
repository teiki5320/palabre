import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/condition.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/progression.dart';

const _personnages = '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]';

const _carte = '{"id":"a","personnage":"general","humeur":"neutre","texte":"Une phrase courte.",'
    '"gauche":{"libelle":"Non","effets":{"armee":-10}},'
    '"droite":{"libelle":"Oui","effets":{"armee":10}}}';

const _fins = '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
    '{"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Renverse","texte":"t","image":"i"}]';

// "musicienne" porte une condition typee en plus de son texte affiche ;
// "putschiste" n'a que le texte, jamais la condition typee correspondante
// (c'est la tache 3 qui la lui donnera dans le vrai contenu).
const _parcours = '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
    '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}},'
    '{"id":"musicienne","nom":"La star de la musique","titre":"Madame la Presidente","femme":true,'
    '"depart":{"peuple":75,"armee":35,"caisses":45,"presse":60},'
    '"condition_deblocage":"Finir un mandat avec le peuple au-dessus de 80",'
    '"condition":{"peuple_min":80}},'
    '{"id":"putschiste","nom":"L ancien putschiste","titre":"Monsieur le President","femme":false,'
    '"depart":{"peuple":35,"armee":80,"caisses":50,"presse":30},'
    '"condition_deblocage":"Se faire renverser par l armee"}]';

const _exploits = '[{"id":"tenir_jusqu_au_bout","titre":"Tenir bon","description":"Aller jusqu au jour 30",'
    '"condition":{"jours_min":30}}]';

Contenu contenu({String exploits = _exploits}) => Contenu.depuisChaines(
      cartes: '[$_carte]',
      personnages: _personnages,
      parcours: _parcours,
      fins: _fins,
      exploits: exploits,
    );

BilanMandat faits({
  Jauges? jauges,
  int jour = 30,
  int mandat = 1,
  String? finId,
  Set<String> drapeaux = const {},
  String parcours = 'general_parcours',
}) =>
    BilanMandat(
      jauges: jauges ?? Jauges.milieu,
      jour: jour,
      mandat: mandat,
      finId: finId,
      drapeaux: drapeaux,
      parcours: parcours,
    );

void main() {
  test('Progression.neuve rend des ensembles vides et des compteurs a zero', () {
    final p = Progression.neuve();
    expect(p.parcoursDebloques, isEmpty);
    expect(p.exploits, isEmpty);
    expect(p.finsDecouvertes, isEmpty);
    expect(p.mandatsJoues, 0);
    expect(p.meilleurJour, 0);
  });

  test('un exploit dont la condition est remplie entre dans la progression et les nouveautes', () {
    final resultat = bilan(avant: Progression.neuve(), mandat: faits(jour: 31), contenu: contenu());
    expect(resultat.progression.exploits, contains('tenir_jusqu_au_bout'));
    expect(resultat.nouveautes.exploits.map((e) => e.id), contains('tenir_jusqu_au_bout'));
  });

  test('le meme exploit au mandat suivant n est plus une nouveaute', () {
    final premier = bilan(avant: Progression.neuve(), mandat: faits(jour: 31), contenu: contenu());
    final second = bilan(avant: premier.progression, mandat: faits(jour: 31, mandat: 2), contenu: contenu());
    expect(second.progression.exploits, contains('tenir_jusqu_au_bout'));
    expect(second.nouveautes.exploits, isEmpty);
  });

  test('un parcours verrouille dont la condition est remplie se debloque et est annonce', () {
    final riche = faits(jauges: const Jauges(peuple: 85, armee: 50, caisses: 50, presse: 50));
    final resultat = bilan(avant: Progression.neuve(), mandat: riche, contenu: contenu());
    expect(resultat.progression.parcoursDebloques, contains('musicienne'));
    expect(resultat.nouveautes.parcours.map((p) => p.id), contains('musicienne'));
  });

  test('un parcours sans condition typee ne se debloque jamais, meme si les faits y correspondent', () {
    final renverse = faits(finId: 'armee_bas');
    final resultat = bilan(avant: Progression.neuve(), mandat: renverse, contenu: contenu());
    expect(resultat.progression.parcoursDebloques, isNot(contains('putschiste')));
    expect(resultat.nouveautes.parcours, isEmpty);
  });

  test('la fin atteinte entre dans les fins decouvertes, inedite seulement la premiere fois', () {
    final premier =
        bilan(avant: Progression.neuve(), mandat: faits(jour: 5, finId: 'election_gagnee'), contenu: contenu());
    expect(premier.progression.finsDecouvertes, contains('election_gagnee'));
    expect(premier.nouveautes.finInedite, isTrue);

    final second = bilan(
      avant: premier.progression,
      mandat: faits(jour: 5, mandat: 2, finId: 'election_gagnee'),
      contenu: contenu(),
    );
    expect(second.nouveautes.finInedite, isFalse);
  });

  test('mandatsJoues s incremente a chaque bilan', () {
    final premier = bilan(avant: Progression.neuve(), mandat: faits(jour: 5), contenu: contenu());
    expect(premier.progression.mandatsJoues, 1);
    final second = bilan(avant: premier.progression, mandat: faits(jour: 5, mandat: 2), contenu: contenu());
    expect(second.progression.mandatsJoues, 2);
  });

  test('meilleurJour garde le maximum meme si le mandat suivant est plus court', () {
    final premier = bilan(avant: Progression.neuve(), mandat: faits(jour: 31), contenu: contenu());
    expect(premier.progression.meilleurJour, 30);
    final second = bilan(avant: premier.progression, mandat: faits(jour: 12, mandat: 2), contenu: contenu());
    expect(second.progression.meilleurJour, 30);
  });

  test('rienDeNeuf est vrai quand aucune nouveaute n a ete gagnee', () {
    final avant = Progression.neuve().copie(
      exploits: {'tenir_jusqu_au_bout'},
      mandatsJoues: 3,
      meilleurJour: 30,
    );
    final resultat = bilan(avant: avant, mandat: faits(jour: 5, mandat: 4), contenu: contenu());
    expect(resultat.nouveautes.rienDeNeuf, isTrue);
  });

  test('les ensembles de la progression rendue ne partagent jamais la reference de ceux d avant', () {
    final avant = Progression.neuve().copie(
      parcoursDebloques: {'musicienne'},
      exploits: {'tenir_jusqu_au_bout'},
      finsDecouvertes: {'election_gagnee'},
    );
    // jour 5 et jauges au milieu : ni l'exploit ni le parcours ne se
    // debloquent ici, et aucune fin n'est identifiee (finId: null) - c'est
    // justement le cas qui laissait passer un ensemble partage.
    final resultat = bilan(avant: avant, mandat: faits(jour: 5), contenu: contenu());

    expect(identical(resultat.progression.parcoursDebloques, avant.parcoursDebloques), isFalse);
    expect(identical(resultat.progression.exploits, avant.exploits), isFalse);
    expect(identical(resultat.progression.finsDecouvertes, avant.finsDecouvertes), isFalse);

    resultat.progression.parcoursDebloques.add('putschiste');
    resultat.progression.exploits.add('un_autre_exploit');
    resultat.progression.finsDecouvertes.add('armee_bas');

    expect(avant.parcoursDebloques, {'musicienne'});
    expect(avant.exploits, {'tenir_jusqu_au_bout'});
    expect(avant.finsDecouvertes, {'election_gagnee'});
  });
}
