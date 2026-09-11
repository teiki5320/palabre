import '../../core/time/local_time.dart';

class PollSource {
  const PollSource({required this.titre, this.url, this.date});
  final String titre;
  final String? url;
  final String? date;

  factory PollSource.fromJson(Map<String, dynamic> j) =>
      PollSource(titre: (j['titre'] ?? j['url'] ?? '').toString(), url: j['url'] as String?, date: j['date']?.toString());
  Map<String, dynamic> toJson() => {'titre': titre, 'url': url, 'date': date};
}

class PollOption {
  const PollOption({required this.id, required this.ordre, required this.libelle, required this.neutre});
  final int id;
  final int ordre;
  final String libelle;
  final bool neutre;

  factory PollOption.fromJson(Map<String, dynamic> j) => PollOption(
        id: (j['id'] as num).toInt(),
        ordre: (j['ordre'] as num).toInt(),
        libelle: j['libelle'] as String,
        neutre: (j['neutre'] as bool?) ?? false,
      );
  Map<String, dynamic> toJson() => {'id': id, 'ordre': ordre, 'libelle': libelle, 'neutre': neutre};
}

enum PollStatus { brouillon, programme, ouvert, ferme }

class Poll {
  const Poll({
    required this.id,
    required this.countryCode,
    required this.semaine,
    required this.question,
    required this.contexte,
    required this.sources,
    required this.ouverture,
    required this.fermeture,
    required this.options,
    required this.repondants,
    required this.suspect,
    required this.resultatFinal,
    this.suspectMotif,
    this.personId,
    this.organizationId,
  });

  final int id;
  final String countryCode;
  final DateTime semaine;
  final String question;
  final String contexte;
  final List<PollSource> sources;
  final DateTime ouverture;
  final DateTime fermeture;
  final List<PollOption> options;
  final int repondants;
  final bool suspect;
  final String? suspectMotif;
  final bool resultatFinal;
  final int? personId;
  final int? organizationId;

  /// L'état se déduit des horodatages, comme côté base.
  PollStatus statusAt(DateTime now) {
    if (now.isBefore(ouverture)) return PollStatus.programme;
    if (now.isBefore(fermeture)) return PollStatus.ouvert;
    return PollStatus.ferme;
  }

  PollStatus get status => statusAt(DateTime.now().toUtc());

  PollOption? option(int? id) {
    if (id == null) return null;
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }

  factory Poll.fromJson(Map<String, dynamic> j) => Poll(
        id: (j['id'] as num).toInt(),
        countryCode: j['country_code'] as String,
        semaine: parseDate(j['semaine'])!,
        question: j['question'] as String,
        contexte: (j['contexte'] as String?) ?? '',
        sources: ((j['sources'] as List?) ?? const []).cast<Map<String, dynamic>>().map(PollSource.fromJson).toList(),
        ouverture: parseDate(j['ouverture'])!.toUtc(),
        fermeture: parseDate(j['fermeture'])!.toUtc(),
        options: ((j['options'] as List?) ?? const []).cast<Map<String, dynamic>>().map(PollOption.fromJson).toList()
          ..sort((a, b) => a.ordre.compareTo(b.ordre)),
        repondants: ((j['repondants'] as num?) ?? 0).toInt(),
        suspect: (j['suspect'] as bool?) ?? false,
        suspectMotif: j['suspect_motif'] as String?,
        resultatFinal: (j['resultat_final'] as bool?) ?? false,
        personId: (j['person_id'] as num?)?.toInt(),
        organizationId: (j['organization_id'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'country_code': countryCode,
        'semaine': isoDate(semaine),
        'question': question,
        'contexte': contexte,
        'sources': sources.map((s) => s.toJson()).toList(),
        'ouverture': ouverture.toIso8601String(),
        'fermeture': fermeture.toIso8601String(),
        'options': options.map((o) => o.toJson()).toList(),
        'repondants': repondants,
        'suspect': suspect,
        'suspect_motif': suspectMotif,
        'resultat_final': resultatFinal,
        'person_id': personId,
        'organization_id': organizationId,
      };
}

/// Une cellule de résultat : dimension (total, pays, tranche_age, region),
/// valeur, taille de la cellule et votes par option.
class ResultCell {
  const ResultCell({required this.dimension, required this.valeur, required this.nCellule, required this.counts});
  final String dimension;
  final String valeur;
  final int nCellule;
  final Map<int, int> counts;

  double fraction(int optionId) => nCellule == 0 ? 0 : (counts[optionId] ?? 0) / nCellule;

  factory ResultCell.fromJson(Map<String, dynamic> j) => ResultCell(
        dimension: j['dimension'] as String,
        valeur: (j['valeur'] ?? '').toString(),
        nCellule: ((j['n_cellule'] as num?) ?? 0).toInt(),
        counts: {
          for (final o in ((j['options'] as List?) ?? const []).cast<Map<String, dynamic>>())
            (o['option_id'] as num).toInt(): ((o['n'] as num?) ?? 0).toInt(),
        },
      );

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'valeur': valeur,
        'n_cellule': nCellule,
        'options': counts.entries.map((e) => {'option_id': e.key, 'n': e.value}).toList(),
      };
}

class PollResults {
  const PollResults({required this.pollId, required this.repondants, required this.isFinal, required this.seuil, required this.cells, this.calcule});
  final int pollId;
  final int repondants;
  final bool isFinal;
  final int seuil;
  final List<ResultCell> cells;
  final DateTime? calcule;

  ResultCell? get total {
    for (final c in cells) {
      if (c.dimension == 'total') return c;
    }
    return null;
  }

  List<ResultCell> dimension(String d) => cells.where((c) => c.dimension == d).toList();
  bool get hasBreakdowns => cells.any((c) => c.dimension != 'total');

  factory PollResults.fromJson(Map<String, dynamic> j) => PollResults(
        pollId: (j['poll_id'] as num).toInt(),
        repondants: ((j['repondants'] as num?) ?? 0).toInt(),
        isFinal: (j['final'] as bool?) ?? false,
        seuil: ((j['seuil'] as num?) ?? 30).toInt(),
        cells: ((j['cellules'] as List?) ?? const []).cast<Map<String, dynamic>>().map(ResultCell.fromJson).toList(),
        calcule: parseDate(j['calcule']),
      );

  Map<String, dynamic> toJson() => {
        'poll_id': pollId,
        'repondants': repondants,
        'final': isFinal,
        'seuil': seuil,
        'cellules': cells.map((c) => c.toJson()).toList(),
        'calcule': calcule?.toIso8601String(),
      };
}

class PollFeed {
  const PollFeed({required this.current, required this.archive});
  final Poll? current;
  final List<Poll> archive;

  factory PollFeed.fromJson(Map<String, dynamic> j) => PollFeed(
        current: j['current'] == null ? null : Poll.fromJson(j['current'] as Map<String, dynamic>),
        archive: ((j['archive'] as List?) ?? const []).cast<Map<String, dynamic>>().map(Poll.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {'current': current?.toJson(), 'archive': archive.map((p) => p.toJson()).toList()};

  Poll? byId(int id) {
    if (current?.id == id) return current;
    for (final p in archive) {
      if (p.id == id) return p;
    }
    return null;
  }
}
