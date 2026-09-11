import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/features/reference/reference_models.dart';

/// Reproduit le jeu de test SQL : deux gouvernements, un portefeuille
/// renommé, une suppléance, un changement de groupe.
ReferenceBundle _bundle() {
  Person p(int id, String nom) => Person(id: id, countryCode: 'SN', nom: nom);
  Mandate m(int id, int person, int role, {int? portfolio, int? gov, int? constituency, required String debut, String? fin, String? motif, String qualite = 'titulaire', int? remplace}) =>
      Mandate(id: id, personId: person, roleId: role, portfolioId: portfolio, governmentId: gov, constituencyId: constituency, debut: DateTime.parse(debut), fin: fin == null ? null : DateTime.parse(fin), motifFin: motif, confiance: 'journal_officiel', qualite: qualite, remplaceMandateId: remplace);
  return ReferenceBundle(
    persons: [p(1, 'PM'), p(5, 'Santé'), p(9, 'Députée puis ministre'), p(10, 'Suppléante'), p(11, 'Changeuse de groupe')],
    organizations: const [
      Organization(id: 1, countryCode: 'SN', type: 'parti', nom: 'Alpha'),
      Organization(id: 7, countryCode: 'SN', type: 'groupe_parlementaire', nom: 'G-A'),
      Organization(id: 8, countryCode: 'SN', type: 'groupe_parlementaire', nom: 'G-B'),
    ],
    orgRelations: const [],
    portfolios: const [
      Portfolio(id: 5, intitule: 'Santé et Action sociale', intituleNorm: 'sante', bloc: 'social', rang: 30),
      Portfolio(id: 6, intitule: 'Santé, Hygiène publique et Action sociale', intituleNorm: 'sante', bloc: 'social', rang: 30),
      Portfolio(id: 7, intitule: 'Éducation', intituleNorm: 'education', bloc: 'social', rang: 31),
    ],
    roles: const [
      Role(id: 1, type: 'chef_gouvernement', intitule: 'Premier ministre', intituleNorm: 'pm'),
      Role(id: 2, type: 'ministre', intitule: 'Ministre', intituleNorm: 'ministre'),
      Role(id: 3, type: 'depute', intitule: 'Député', intituleNorm: 'depute'),
    ],
    governments: [
      Government(id: 1, nom: 'G I', debut: DateTime.parse('2024-04-05'), fin: DateTime.parse('2025-09-06'), portefeuillesTotal: 25),
      Government(id: 2, nom: 'G II', debut: DateTime.parse('2025-09-06'), portefeuillesTotal: 25),
    ],
    legislatures: [Legislature(id: 1, numero: 15, debut: DateTime.parse('2024-12-02'), siegesTotal: 165, scrutinsNominatifs: false)],
    constituencies: const [Constituency(id: 1, legislatureId: 1, nom: 'Dakar', type: 'departement', sieges: 7), Constituency(id: 2, legislatureId: 1, nom: 'Thiès', type: 'departement', sieges: 5)],
    mandates: [
      m(1, 1, 1, gov: 1, debut: '2024-04-05', fin: '2025-09-06', motif: 'fin_gouvernement'),
      m(5, 5, 2, portfolio: 5, gov: 1, debut: '2024-04-05', fin: '2025-09-06', motif: 'fin_gouvernement'),
      m(9, 1, 1, gov: 2, debut: '2025-09-06'),
      m(13, 5, 2, portfolio: 6, gov: 2, debut: '2025-09-06'),
      m(14, 9, 2, portfolio: 7, gov: 2, debut: '2025-09-06'),
      m(20, 9, 3, constituency: 1, debut: '2024-12-02', fin: '2025-09-06', motif: 'nomination_gouvernement'),
      m(21, 10, 3, constituency: 1, debut: '2025-09-06', qualite: 'suppleant', remplace: 20),
      m(22, 11, 3, constituency: 2, debut: '2024-12-02'),
    ],
    affiliations: [
      Affiliation(id: 1, personId: 11, organizationId: 7, debut: DateTime.parse('2024-12-02'), fin: DateTime.parse('2025-06-01')),
      Affiliation(id: 2, personId: 11, organizationId: 8, debut: DateTime.parse('2025-06-01')),
      Affiliation(id: 3, personId: 9, organizationId: 1, debut: DateTime.parse('2015-01-01')),
    ],
    careers: const [],
    activities: const [],
  );
}

void main() {
  final b = _bundle();

  test('la grille se recompose à la date demandée', () {
    final g1 = b.governmentAt(DateTime.utc(2025, 1, 1))!;
    expect(g1.government.nom, 'G I');
    expect(g1.entries.length, 2);
    expect(g1.entries.first.isHead, isTrue);
    expect(g1.entries.last.intitule, 'Santé et Action sociale');

    final g2 = b.governmentAt(DateTime.utc(2026, 1, 1))!;
    expect(g2.government.nom, 'G II');
    expect(g2.entries.map((e) => e.intitule), containsAll(['Santé, Hygiène publique et Action sociale', 'Éducation']));
    expect(g2.portefeuillesRenseignes, 2);
    expect(b.governmentAt(DateTime.utc(2020, 1, 1)), isNull);
  });

  test('intitule_norm suit le portefeuille à travers son renommage', () {
    final avant = b.governmentAt(DateTime.utc(2025, 1, 1))!.entries.firstWhere((e) => e.portfolio != null);
    final apres = b.governmentAt(DateTime.utc(2026, 1, 1))!.entries.firstWhere((e) => e.portfolio?.intituleNorm == 'sante');
    expect(avant.portfolio!.intituleNorm, apres.portfolio!.intituleNorm);
    expect(avant.portfolio!.id, isNot(apres.portfolio!.id));
  });

  test('suppléance : le titulaire nommé ministre laisse son siège', () {
    final avant = b.deputiesAt(DateTime.utc(2025, 1, 1)).firstWhere((d) => d.constituency.nom == 'Dakar');
    expect(avant.person.id, 9);
    expect(avant.mandate.qualite, 'titulaire');
    final apres = b.deputiesAt(DateTime.utc(2026, 1, 1)).firstWhere((d) => d.constituency.nom == 'Dakar');
    expect(apres.person.id, 10);
    expect(apres.mandate.qualite, 'suppleant');
    expect(apres.replaces?.id, 9);
  });

  test('l\'affiliation en vigueur dépend de la date', () {
    expect(b.affiliationAt(11, DateTime.utc(2025, 1, 1), (o) => o.type == 'groupe_parlementaire')?.id, 7);
    expect(b.affiliationAt(11, DateTime.utc(2026, 1, 1), (o) => o.type == 'groupe_parlementaire')?.id, 8);
  });

  test('le paquet survit au cache JSON', () {
    final again = ReferenceBundle.fromJson(b.toJson());
    expect(again.mandates.length, b.mandates.length);
    expect(again.governmentAt(DateTime.utc(2026, 1, 1))!.entries.length, 3);
    expect(again.earliestDate, DateTime.parse('2024-04-05'));
  });
}
