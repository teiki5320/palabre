import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/moteur/partie.dart';
import 'package:president/moteur/progression.dart';
import 'package:president/sauvegarde/sauvegarde.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un contenu dont la seule carte n est jouable qu au jour 50 : le paquet
/// est vide des le premier jour.
Contenu paquetVide() => Contenu.depuisChaines(
      cartes: '[{"id":"c1","personnage":"general","humeur":"neutre","texte":"t",'
          '"conditions":{"jour_min":50},'
          '"gauche":{"libelle":"g","effets":{"armee":-1}},"droite":{"libelle":"d","effets":{"armee":1}}}]',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"accroche":"a","depart":{"peuple":80,"armee":50,"caisses":85,"presse":80}}]',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
      exploits: '[{"id":"coffres","titre":"Coffres","description":"d","condition":{"caisses_min":80}}]',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('un paquet vide sans un jour joue ne prend aucun bilan', () async {
    final contenu = paquetVide();
    final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    await container.read(progressionProvider.future);

    container.read(sessionProvider.notifier).demarre(parcours: contenu.parcours.first, nom: 'Awa', graine: 1);
    final s = container.read(sessionProvider)!;
    expect(s.terminee, isTrue);
    // Rien n est debloque sur des jauges de depart, et rien n est ecrit.
    expect(s.nouveautes.exploits, isEmpty);
    final progression = await Sauvegarde.lisProgression();
    expect(progression.mandatsJoues, 0);
    expect(progression.exploits, isEmpty);

    // Et « Continuer, deuxieme mandat » n enchaine rien.
    container.read(sessionProvider.notifier).mandatSuivant();
    expect(container.read(sessionProvider), same(s));
  });

  test('une progression non lue n est jamais reecrite par un bilan', () async {
    // Une progression riche est sur le disque, mais personne ne l a lue.
    await Sauvegarde.enregistreProgression(
      Progression.neuve().copie(parcoursDebloques: {'x', 'y'}, exploits: {'a', 'b'}, mandatsJoues: 7),
    );
    final contenu = Contenu.depuisChaines(
      cartes: '[{"id":"c1","personnage":"general","humeur":"neutre","texte":"t",'
          '"gauche":{"libelle":"g","effets":{"armee":-20}},"droite":{"libelle":"d","effets":{"armee":-20}}}]',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"accroche":"a","depart":{"peuple":50,"armee":15,"caisses":50,"presse":50}}]',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"},'
          '{"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Coup","texte":"t","image":"i"}]',
    );
    final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    // Volontairement : pas de lecture de progressionProvider.

    final notifier = container.read(sessionProvider.notifier);
    notifier.demarre(parcours: contenu.parcours.first, nom: 'Awa', graine: 1);
    notifier.repondA(Cote.gauche); // armee 15 - 20 : chute au premier jour
    expect(container.read(sessionProvider)!.terminee, isTrue);

    final apres = await Sauvegarde.lisProgression();
    expect(apres.mandatsJoues, 7, reason: 'la progression du disque a ete ecrasee');
    expect(apres.exploits, {'a', 'b'});
  });

  test('une progression a laquelle il manque un compteur est reparee, pas effacee', () async {
    SharedPreferences.setMockInitialValues({
      'progression': '{"parcours_debloques":["putschiste"],"exploits":["x"],"fins_decouvertes":[]}',
    });
    final p = await Sauvegarde.lisProgression();
    expect(p.parcoursDebloques, {'putschiste'});
    expect(p.exploits, {'x'});
    expect(p.mandatsJoues, 0);
  });
}
