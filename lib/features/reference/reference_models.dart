import '../../core/time/local_time.dart';

int _i(Object? v) => (v as num).toInt();
int? _in(Object? v) => v == null ? null : (v as num).toInt();
String? _d(DateTime? d) => d == null ? null : isoDate(d);

class Person {
  const Person({required this.id, required this.countryCode, required this.nom, this.naissance, this.photoUrl, this.photoSource, this.photoLicence, this.wikidataId});
  final int id;
  final String countryCode;
  final String nom;
  final DateTime? naissance;
  final String? photoUrl;
  final String? photoSource;
  final String? photoLicence;
  final String? wikidataId;

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: _i(j['id']),
        countryCode: j['country_code'] as String,
        nom: j['nom'] as String,
        naissance: parseDate(j['naissance']),
        photoUrl: j['photo_url'] as String?,
        photoSource: j['photo_source'] as String?,
        photoLicence: j['photo_licence'] as String?,
        wikidataId: j['wikidata_id'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'country_code': countryCode, 'nom': nom, 'naissance': _d(naissance),
        'photo_url': photoUrl, 'photo_source': photoSource, 'photo_licence': photoLicence, 'wikidata_id': wikidataId,
      };
}

class Organization {
  const Organization({required this.id, required this.countryCode, required this.type, required this.nom, this.sigle, this.couleur, this.fondation, this.dissolution, this.parentId, this.sourceUrl});
  final int id;
  final String countryCode;
  final String type;
  final String nom;
  final String? sigle;
  final String? couleur;
  final DateTime? fondation;
  final DateTime? dissolution;
  final int? parentId;
  final String? sourceUrl;

  bool get isParty => type == 'parti' || type == 'coalition';

  factory Organization.fromJson(Map<String, dynamic> j) => Organization(
        id: _i(j['id']),
        countryCode: j['country_code'] as String,
        type: j['type'] as String,
        nom: j['nom'] as String,
        sigle: j['sigle'] as String?,
        couleur: j['couleur'] as String?,
        fondation: parseDate(j['fondation']),
        dissolution: parseDate(j['dissolution']),
        parentId: _in(j['parent_id']),
        sourceUrl: j['source_url'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'country_code': countryCode, 'type': type, 'nom': nom, 'sigle': sigle, 'couleur': couleur,
        'fondation': _d(fondation), 'dissolution': _d(dissolution), 'parent_id': parentId, 'source_url': sourceUrl,
      };
}

class OrgRelation {
  const OrgRelation({required this.id, required this.fromId, required this.toId, required this.type, this.date, this.sourceUrl});
  final int id;
  final int fromId;
  final int toId;
  final String type;
  final DateTime? date;
  final String? sourceUrl;

  factory OrgRelation.fromJson(Map<String, dynamic> j) => OrgRelation(
        id: _i(j['id']), fromId: _i(j['from_id']), toId: _i(j['to_id']), type: j['type'] as String,
        date: parseDate(j['date']), sourceUrl: j['source_url'] as String?,
      );
  Map<String, dynamic> toJson() => {'id': id, 'from_id': fromId, 'to_id': toId, 'type': type, 'date': _d(date), 'source_url': sourceUrl};
}

class Portfolio {
  const Portfolio({required this.id, required this.intitule, required this.intituleNorm, required this.bloc, required this.rang});
  final int id;
  final String intitule;
  final String intituleNorm;
  final String bloc;
  final int rang;

  factory Portfolio.fromJson(Map<String, dynamic> j) => Portfolio(
        id: _i(j['id']), intitule: j['intitule'] as String, intituleNorm: j['intitule_norm'] as String,
        bloc: j['bloc'] as String, rang: ((j['rang'] as num?) ?? 100).toInt(),
      );
  Map<String, dynamic> toJson() => {'id': id, 'intitule': intitule, 'intitule_norm': intituleNorm, 'bloc': bloc, 'rang': rang};
}

class Role {
  const Role({required this.id, required this.type, required this.intitule, required this.intituleNorm, this.organizationId});
  final int id;
  final String type;
  final String intitule;
  final String intituleNorm;
  final int? organizationId;

  factory Role.fromJson(Map<String, dynamic> j) => Role(
        id: _i(j['id']), type: j['type'] as String, intitule: j['intitule'] as String,
        intituleNorm: j['intitule_norm'] as String, organizationId: _in(j['organization_id']),
      );
  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'intitule': intitule, 'intitule_norm': intituleNorm, 'organization_id': organizationId};
}

class Government {
  const Government({required this.id, required this.nom, required this.debut, this.fin, this.chefGouvId, this.portefeuillesTotal, this.decretRef, this.sourceUrl});
  final int id;
  final String nom;
  final DateTime debut;
  final DateTime? fin;
  final int? chefGouvId;
  final int? portefeuillesTotal;
  final String? decretRef;
  final String? sourceUrl;

  bool coversDate(DateTime d) => !d.isBefore(debut) && (fin == null || d.isBefore(fin!));

  factory Government.fromJson(Map<String, dynamic> j) => Government(
        id: _i(j['id']), nom: j['nom'] as String, debut: parseDate(j['debut'])!, fin: parseDate(j['fin']),
        chefGouvId: _in(j['chef_gouv_id']), portefeuillesTotal: _in(j['portefeuilles_total']),
        decretRef: j['decret_ref'] as String?, sourceUrl: j['source_url'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'nom': nom, 'debut': isoDate(debut), 'fin': _d(fin), 'chef_gouv_id': chefGouvId,
        'portefeuilles_total': portefeuillesTotal, 'decret_ref': decretRef, 'source_url': sourceUrl,
      };
}

class Legislature {
  const Legislature({required this.id, required this.numero, required this.debut, this.fin, required this.siegesTotal, required this.scrutinsNominatifs, this.sourceUrl});
  final int id;
  final int numero;
  final DateTime debut;
  final DateTime? fin;
  final int siegesTotal;
  final bool scrutinsNominatifs;
  final String? sourceUrl;

  bool coversDate(DateTime d) => !d.isBefore(debut) && (fin == null || d.isBefore(fin!));

  factory Legislature.fromJson(Map<String, dynamic> j) => Legislature(
        id: _i(j['id']), numero: _i(j['numero']), debut: parseDate(j['debut'])!, fin: parseDate(j['fin']),
        siegesTotal: _i(j['sieges_total']), scrutinsNominatifs: (j['scrutins_nominatifs'] as bool?) ?? false, sourceUrl: j['source_url'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'numero': numero, 'debut': isoDate(debut), 'fin': _d(fin), 'sieges_total': siegesTotal,
        'scrutins_nominatifs': scrutinsNominatifs, 'source_url': sourceUrl,
      };
}

class Constituency {
  const Constituency({required this.id, required this.legislatureId, required this.nom, required this.type, required this.sieges, this.regionId});
  final int id;
  final int legislatureId;
  final String nom;
  final String type;
  final int sieges;
  final int? regionId;

  factory Constituency.fromJson(Map<String, dynamic> j) => Constituency(
        id: _i(j['id']), legislatureId: _i(j['legislature_id']), nom: j['nom'] as String, type: j['type'] as String,
        sieges: _i(j['sieges']), regionId: _in(j['region_id']),
      );
  Map<String, dynamic> toJson() => {'id': id, 'legislature_id': legislatureId, 'nom': nom, 'type': type, 'sieges': sieges, 'region_id': regionId};
}

class Mandate {
  const Mandate({
    required this.id, required this.personId, required this.roleId, required this.debut, required this.confiance, required this.qualite,
    this.portfolioId, this.governmentId, this.constituencyId, this.fin, this.motifFin, this.acteRef, this.sourceUrl, this.remplaceMandateId,
  });
  final int id;
  final int personId;
  final int roleId;
  final int? portfolioId;
  final int? governmentId;
  final int? constituencyId;
  final DateTime debut;
  final DateTime? fin;
  final String? motifFin;
  final String? acteRef;
  final String? sourceUrl;
  final String confiance;
  final String qualite;
  final int? remplaceMandateId;

  bool activeAt(DateTime d) => !d.isBefore(debut) && (fin == null || d.isBefore(fin!));

  factory Mandate.fromJson(Map<String, dynamic> j) => Mandate(
        id: _i(j['id']), personId: _i(j['person_id']), roleId: _i(j['role_id']), portfolioId: _in(j['portfolio_id']),
        governmentId: _in(j['government_id']), constituencyId: _in(j['constituency_id']), debut: parseDate(j['debut'])!,
        fin: parseDate(j['fin']), motifFin: j['motif_fin'] as String?, acteRef: j['acte_ref'] as String?, sourceUrl: j['source_url'] as String?,
        confiance: (j['confiance'] as String?) ?? 'presse', qualite: (j['qualite'] as String?) ?? 'titulaire', remplaceMandateId: _in(j['remplace_mandate_id']),
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'person_id': personId, 'role_id': roleId, 'portfolio_id': portfolioId, 'government_id': governmentId,
        'constituency_id': constituencyId, 'debut': isoDate(debut), 'fin': _d(fin), 'motif_fin': motifFin, 'acte_ref': acteRef,
        'source_url': sourceUrl, 'confiance': confiance, 'qualite': qualite, 'remplace_mandate_id': remplaceMandateId,
      };
}

class Affiliation {
  const Affiliation({required this.id, required this.personId, required this.organizationId, required this.debut, this.fin, this.sourceUrl});
  final int id;
  final int personId;
  final int organizationId;
  final DateTime debut;
  final DateTime? fin;
  final String? sourceUrl;

  bool activeAt(DateTime d) => !d.isBefore(debut) && (fin == null || d.isBefore(fin!));

  factory Affiliation.fromJson(Map<String, dynamic> j) => Affiliation(
        id: _i(j['id']), personId: _i(j['person_id']), organizationId: _i(j['organization_id']),
        debut: parseDate(j['debut'])!, fin: parseDate(j['fin']), sourceUrl: j['source_url'] as String?,
      );
  Map<String, dynamic> toJson() => {'id': id, 'person_id': personId, 'organization_id': organizationId, 'debut': isoDate(debut), 'fin': _d(fin), 'source_url': sourceUrl};
}

class Career {
  const Career({required this.id, required this.personId, required this.periode, required this.fonction, this.organisation, this.sourceUrl});
  final int id;
  final int personId;
  final String periode;
  final String fonction;
  final String? organisation;
  final String? sourceUrl;

  factory Career.fromJson(Map<String, dynamic> j) => Career(
        id: _i(j['id']), personId: _i(j['person_id']), periode: j['periode'] as String, fonction: j['fonction'] as String,
        organisation: j['organisation'] as String?, sourceUrl: j['source_url'] as String?,
      );
  Map<String, dynamic> toJson() => {'id': id, 'person_id': personId, 'periode': periode, 'fonction': fonction, 'organisation': organisation, 'source_url': sourceUrl};
}

/// Uniquement ce qui est publié : une colonne nulle signifie « non publié ».
class DeputyActivity {
  const DeputyActivity({required this.id, required this.mandateId, required this.periode, required this.sourceUrl, this.seancesPresentes, this.seancesTotal, this.questionsEcrites, this.questionsOrales, this.propositions, this.commissions, this.maj});
  final int id;
  final int mandateId;
  final String periode;
  final String sourceUrl;
  final int? seancesPresentes;
  final int? seancesTotal;
  final int? questionsEcrites;
  final int? questionsOrales;
  final int? propositions;
  final int? commissions;
  final DateTime? maj;

  bool get hasAny => [seancesPresentes, questionsEcrites, questionsOrales, propositions, commissions].any((v) => v != null);

  factory DeputyActivity.fromJson(Map<String, dynamic> j) => DeputyActivity(
        id: _i(j['id']), mandateId: _i(j['mandate_id']), periode: j['periode'] as String, sourceUrl: j['source_url'] as String,
        seancesPresentes: _in(j['seances_presentes']), seancesTotal: _in(j['seances_total']), questionsEcrites: _in(j['questions_ecrites']),
        questionsOrales: _in(j['questions_orales']), propositions: _in(j['propositions']), commissions: _in(j['commissions']), maj: parseDate(j['maj']),
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'mandate_id': mandateId, 'periode': periode, 'source_url': sourceUrl, 'seances_presentes': seancesPresentes,
        'seances_total': seancesTotal, 'questions_ecrites': questionsEcrites, 'questions_orales': questionsOrales,
        'propositions': propositions, 'commissions': commissions, 'maj': _d(maj),
      };
}

/// Un membre du gouvernement à une date donnée.
class GovernmentEntry {
  const GovernmentEntry({required this.mandate, required this.person, required this.role, this.portfolio});
  final Mandate mandate;
  final Person person;
  final Role role;
  final Portfolio? portfolio;

  bool get isHead => role.type == 'chef_gouvernement';
  String get intitule => portfolio?.intitule ?? role.intitule;
  String? get bloc => portfolio?.bloc;
  int get rang => isHead ? 0 : (portfolio?.rang ?? 100);
}

class GovernmentComposition {
  const GovernmentComposition({required this.government, required this.entries});
  final Government government;
  final List<GovernmentEntry> entries;

  int get portefeuillesRenseignes => entries.where((e) => e.portfolio != null).map((e) => e.portfolio!.id).toSet().length;

  Map<String?, List<GovernmentEntry>> get byBloc {
    final map = <String?, List<GovernmentEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.isHead ? null : e.bloc, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.rang != b.rang ? a.rang.compareTo(b.rang) : a.person.nom.compareTo(b.person.nom));
    }
    return map;
  }
}

/// Un député à une date donnée, avec groupe et parti en vigueur.
class DeputyEntry {
  const DeputyEntry({required this.mandate, required this.person, required this.constituency, this.group, this.party, this.replaces});
  final Mandate mandate;
  final Person person;
  final Constituency constituency;
  final Organization? group;
  final Organization? party;
  final Person? replaces;
}

/// La base factuelle d'un pays, chargée d'un bloc et mise en cache : le
/// curseur temporel recompose la grille sans réseau.
class ReferenceBundle {
  const ReferenceBundle({
    required this.persons, required this.organizations, required this.orgRelations, required this.portfolios, required this.roles,
    required this.governments, required this.legislatures, required this.constituencies, required this.mandates, required this.affiliations,
    required this.careers, required this.activities,
  });

  final List<Person> persons;
  final List<Organization> organizations;
  final List<OrgRelation> orgRelations;
  final List<Portfolio> portfolios;
  final List<Role> roles;
  final List<Government> governments;
  final List<Legislature> legislatures;
  final List<Constituency> constituencies;
  final List<Mandate> mandates;
  final List<Affiliation> affiliations;
  final List<Career> careers;
  final List<DeputyActivity> activities;

  static const empty = ReferenceBundle(
    persons: [], organizations: [], orgRelations: [], portfolios: [], roles: [], governments: [], legislatures: [],
    constituencies: [], mandates: [], affiliations: [], careers: [], activities: [],
  );

  Person? person(int id) => _find(persons, (p) => p.id == id);
  Organization? organization(int? id) => id == null ? null : _find(organizations, (o) => o.id == id);
  Portfolio? portfolio(int? id) => id == null ? null : _find(portfolios, (p) => p.id == id);
  Role? role(int id) => _find(roles, (r) => r.id == id);
  Government? government(int? id) => id == null ? null : _find(governments, (g) => g.id == id);
  Constituency? constituency(int? id) => id == null ? null : _find(constituencies, (c) => c.id == id);
  Mandate? mandate(int? id) => id == null ? null : _find(mandates, (m) => m.id == id);
  Legislature? legislature(int? id) => id == null ? null : _find(legislatures, (l) => l.id == id);

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final x in list) {
      if (test(x)) return x;
    }
    return null;
  }

  DateTime? get earliestDate {
    DateTime? min;
    for (final g in governments) {
      if (min == null || g.debut.isBefore(min)) min = g.debut;
    }
    for (final l in legislatures) {
      if (min == null || l.debut.isBefore(min)) min = l.debut;
    }
    return min;
  }

  /// Composition du gouvernement à une date : la grille se recompose.
  GovernmentComposition? governmentAt(DateTime date) {
    final g = _find(governments, (g) => g.coversDate(date));
    if (g == null) return null;
    final entries = <GovernmentEntry>[];
    for (final m in mandates) {
      if (m.governmentId != g.id || !m.activeAt(date)) continue;
      final r = role(m.roleId);
      final p = person(m.personId);
      if (r == null || p == null) continue;
      if (r.type != 'ministre' && r.type != 'chef_gouvernement') continue;
      entries.add(GovernmentEntry(mandate: m, person: p, role: r, portfolio: portfolio(m.portfolioId)));
    }
    entries.sort((a, b) => a.rang != b.rang ? a.rang.compareTo(b.rang) : a.person.nom.compareTo(b.person.nom));
    return GovernmentComposition(government: g, entries: entries);
  }

  Legislature? legislatureAt(DateTime date) => _find(legislatures, (l) => l.coversDate(date));

  Organization? affiliationAt(int personId, DateTime date, bool Function(Organization) test) {
    Affiliation? best;
    for (final a in affiliations) {
      if (a.personId != personId || !a.activeAt(date)) continue;
      final o = organization(a.organizationId);
      if (o == null || !test(o)) continue;
      if (best == null || a.debut.isAfter(best.debut)) best = a;
    }
    return best == null ? null : organization(best.organizationId);
  }

  List<DeputyEntry> deputiesAt(DateTime date) {
    final l = legislatureAt(date);
    if (l == null) return const [];
    final out = <DeputyEntry>[];
    for (final m in mandates) {
      if (!m.activeAt(date) || m.constituencyId == null) continue;
      final c = constituency(m.constituencyId);
      if (c == null || c.legislatureId != l.id) continue;
      final r = role(m.roleId);
      if (r == null || r.type != 'depute') continue;
      final p = person(m.personId);
      if (p == null) continue;
      final replaced = mandate(m.remplaceMandateId);
      out.add(DeputyEntry(
        mandate: m,
        person: p,
        constituency: c,
        group: affiliationAt(p.id, date, (o) => o.type == 'groupe_parlementaire'),
        party: affiliationAt(p.id, date, (o) => o.isParty),
        replaces: replaced == null ? null : person(replaced.personId),
      ));
    }
    out.sort((a, b) => a.person.nom.compareTo(b.person.nom));
    return out;
  }

  List<Mandate> mandatesOf(int personId) => mandates.where((m) => m.personId == personId).toList()..sort((a, b) => b.debut.compareTo(a.debut));
  List<Affiliation> affiliationsOf(int personId) => affiliations.where((a) => a.personId == personId).toList()..sort((a, b) => b.debut.compareTo(a.debut));
  List<Career> careerOf(int personId) => careers.where((c) => c.personId == personId).toList();
  List<DeputyActivity> activityOf(int mandateId) => activities.where((a) => a.mandateId == mandateId).toList();

  /// Élus et membres du gouvernement affiliés à une organisation à une date.
  List<Person> membersOf(int orgId, DateTime date) {
    final ids = <int>{};
    for (final a in affiliations) {
      if (a.organizationId == orgId && a.activeAt(date)) ids.add(a.personId);
    }
    final out = <Person>[];
    for (final id in ids) {
      final p = person(id);
      if (p != null && mandates.any((m) => m.personId == id && m.activeAt(date))) out.add(p);
    }
    out.sort((a, b) => a.nom.compareTo(b.nom));
    return out;
  }

  factory ReferenceBundle.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((j[key] as List?) ?? const []).cast<Map<String, dynamic>>().map(f).toList();
    return ReferenceBundle(
      persons: list('persons', Person.fromJson),
      organizations: list('organizations', Organization.fromJson),
      orgRelations: list('org_relations', OrgRelation.fromJson),
      portfolios: list('portfolios', Portfolio.fromJson),
      roles: list('roles', Role.fromJson),
      governments: list('governments', Government.fromJson),
      legislatures: list('legislatures', Legislature.fromJson),
      constituencies: list('constituencies', Constituency.fromJson),
      mandates: list('mandates', Mandate.fromJson),
      affiliations: list('affiliations', Affiliation.fromJson),
      careers: list('careers', Career.fromJson),
      activities: list('activities', DeputyActivity.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'persons': persons.map((x) => x.toJson()).toList(),
        'organizations': organizations.map((x) => x.toJson()).toList(),
        'org_relations': orgRelations.map((x) => x.toJson()).toList(),
        'portfolios': portfolios.map((x) => x.toJson()).toList(),
        'roles': roles.map((x) => x.toJson()).toList(),
        'governments': governments.map((x) => x.toJson()).toList(),
        'legislatures': legislatures.map((x) => x.toJson()).toList(),
        'constituencies': constituencies.map((x) => x.toJson()).toList(),
        'mandates': mandates.map((x) => x.toJson()).toList(),
        'affiliations': affiliations.map((x) => x.toJson()).toList(),
        'careers': careers.map((x) => x.toJson()).toList(),
        'activities': activities.map((x) => x.toJson()).toList(),
      };
}
