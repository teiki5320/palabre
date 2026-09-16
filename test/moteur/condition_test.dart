import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/condition.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';

BilanMandat bilan({
  Jauges? jauges,
  int jour = 30,
  int mandat = 1,
  String? finId,
  Set<String> drapeaux = const {},
  String parcours = 'general',
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
  famillesDeFin();
  test('une condition vide est toujours remplie', () {
    expect(const Condition().remplie(bilan()), isTrue);
  });

  test('le plancher de jauge est respecte', () {
    final riche = bilan(jauges: const Jauges(peuple: 85, armee: 50, caisses: 50, presse: 50));
    final pauvre = bilan(jauges: const Jauges(peuple: 50, armee: 50, caisses: 50, presse: 50));
    expect(const Condition(jaugesMin: {Jauge.peuple: 80}).remplie(riche), isTrue);
    expect(const Condition(jaugesMin: {Jauge.peuple: 80}).remplie(pauvre), isFalse);
  });

  test('le plafond de jauge est respecte', () {
    final basse = bilan(jauges: const Jauges(peuple: 50, armee: 50, caisses: 20, presse: 50));
    expect(const Condition(jaugesMax: {Jauge.caisses: 30}).remplie(basse), isTrue);
    expect(const Condition(jaugesMax: {Jauge.caisses: 10}).remplie(basse), isFalse);
  });

  test('le nombre de jours minimum est respecte', () {
    // `jour` est le premier jour non joue : au jour 31, on a tenu 30 jours.
    expect(const Condition(joursMin: 30).remplie(bilan(jour: 31)), isTrue);
    expect(const Condition(joursMin: 30).remplie(bilan(jour: 30)), isFalse);
  });

  test('le mandat minimum est respecte', () {
    expect(const Condition(mandatMin: 2).remplie(bilan(mandat: 2)), isTrue);
    expect(const Condition(mandatMin: 2).remplie(bilan(mandat: 1)), isFalse);
  });

  test('la fin exacte est respectee, une fin differente ne suffit pas', () {
    expect(const Condition(fin: 'presse_haute').remplie(bilan(finId: 'presse_haute')), isTrue);
    expect(const Condition(fin: 'presse_haute').remplie(bilan(finId: 'armee_basse')), isFalse);
    expect(const Condition(fin: 'presse_haute').remplie(bilan(finId: null)), isFalse);
  });

  test('les drapeaux requis et interdits sont respectes', () {
    final avec = bilan(drapeaux: {'affaire_publiee'});
    expect(const Condition(drapeauxRequis: ['affaire_publiee']).remplie(avec), isTrue);
    expect(const Condition(drapeauxRequis: ['affaire_publiee']).remplie(bilan()), isFalse);
    expect(const Condition(drapeauxInterdits: ['affaire_publiee']).remplie(avec), isFalse);
    expect(const Condition(drapeauxInterdits: ['affaire_publiee']).remplie(bilan()), isTrue);
  });

  test('une seule des deux conditions satisfaite ne suffit pas', () {
    final b = bilan(jauges: const Jauges(peuple: 85, armee: 50, caisses: 50, presse: 50), jour: 10);
    expect(const Condition(jaugesMin: {Jauge.peuple: 80}, joursMin: 30).remplie(b), isFalse);
  });

  test('depuisJson lit les champs typiques', () {
    final c = Condition.depuisJson({
      'peuple_min': 80,
      'caisses_max': 20,
      'jours_min': 30,
      'mandat_min': 2,
      'fin': 'presse_haute',
      'drapeaux_requis': ['affaire_publiee'],
      'drapeaux_interdits': ['solde_impayee'],
    });
    expect(c.jaugesMin, {Jauge.peuple: 80});
    expect(c.jaugesMax, {Jauge.caisses: 20});
    expect(c.joursMin, 30);
    expect(c.mandatMin, 2);
    expect(c.fin, 'presse_haute');
    expect(c.drapeauxRequis, ['affaire_publiee']);
    expect(c.drapeauxInterdits, ['solde_impayee']);
  });

  test('depuisJson(null) rend une condition vide, toujours remplie', () {
    expect(Condition.depuisJson(null).remplie(bilan()), isTrue);
  });
}

/// Les fins dedoublees par le regime restent, pour une condition, la meme
/// fin : etre reelu, c est etre reelu.
void famillesDeFin() {
  test('une reelection seul candidat remplit la condition « election_gagnee »', () {
    const c = Condition(fin: 'election_gagnee');
    final seul = BilanMandat(
      parcours: 'p',
      jauges: Jauges.milieu,
      jour: 101,
      mandat: 1,
      finId: 'election_gagnee_seul',
      finFamille: 'election_gagnee',
    );
    expect(c.remplie(seul), isTrue);

    // Et une fin d une autre famille ne la remplit pas.
    final battu = BilanMandat(
      parcours: 'p',
      jauges: Jauges.milieu,
      jour: 101,
      mandat: 1,
      finId: 'election_perdue_comptee',
      finFamille: 'election_perdue',
    );
    expect(c.remplie(battu), isFalse);
  });

  test('la famille d une fin est l identifiant de sa fin de base', () {
    const seul = Fin(id: 'election_gagnee_seul', jauge: null, versLeHaut: true,
        titre: 't', texte: 't', image: 'i', styleMin: 72);
    expect(seul.famille, 'election_gagnee');
    const coup = Fin(id: 'armee_bas_tyran', jauge: Jauge.armee, versLeHaut: false,
        titre: 't', texte: 't', image: 'i');
    expect(coup.famille, 'armee_bas');
  });
}
