import '../../core/time/local_time.dart';

/// Réponse de l'utilisateur à une affirmation.
enum Answer { accord, desaccord, neutre, passer }

/// Position déclarée d'une organisation.
enum Position { accord, desaccord, neutre, sansPosition }

Position positionFrom(String s) => switch (s) {
      'accord' => Position.accord,
      'desaccord' => Position.desaccord,
      'neutre' => Position.neutre,
      _ => Position.sansPosition,
    };

String positionKey(Position p) => switch (p) {
      Position.accord => 'accord',
      Position.desaccord => 'desaccord',
      Position.neutre => 'neutre',
      Position.sansPosition => 'sans_position',
    };

/// Niveau de source, toujours affiché à côté de la position.
enum SourceType { reponseDirecte, documentPublic, aucune }

SourceType sourceTypeFrom(String s) => switch (s) {
      'reponse_directe' => SourceType.reponseDirecte,
      'document_public' => SourceType.documentPublic,
      _ => SourceType.aucune,
    };

String sourceTypeKey(SourceType t) => switch (t) {
      SourceType.reponseDirecte => 'reponse_directe',
      SourceType.documentPublic => 'document_public',
      SourceType.aucune => 'aucune',
    };

class Party {
  const Party({required this.id, required this.nom, this.sigle, this.couleur, this.type = 'parti'});
  final int id;
  final String nom;
  final String? sigle;
  final String? couleur;
  final String type;

  String get shortName => sigle ?? nom;

  factory Party.fromJson(Map<String, dynamic> j) => Party(
        id: (j['id'] as num).toInt(),
        nom: j['nom'] as String,
        sigle: j['sigle'] as String?,
        couleur: j['couleur'] as String?,
        type: (j['type'] as String?) ?? 'parti',
      );
  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'sigle': sigle, 'couleur': couleur, 'type': type};
}

class PartyPosition {
  const PartyPosition({
    required this.id,
    required this.statementId,
    required this.orgId,
    required this.position,
    required this.sourceType,
    this.sourceUrl,
    this.sourceExtrait,
    this.dateSource,
    this.corrigeLe,
  });

  final int id;
  final int statementId;
  final int orgId;
  final Position position;
  final SourceType sourceType;
  final String? sourceUrl;
  final String? sourceExtrait;
  final DateTime? dateSource;
  final DateTime? corrigeLe;

  factory PartyPosition.fromJson(Map<String, dynamic> j) => PartyPosition(
        id: (j['id'] as num).toInt(),
        statementId: (j['statement_id'] as num).toInt(),
        orgId: (j['org_id'] as num).toInt(),
        position: positionFrom(j['position'] as String),
        sourceType: sourceTypeFrom(j['source_type'] as String),
        sourceUrl: j['source_url'] as String?,
        sourceExtrait: j['source_extrait'] as String?,
        dateSource: parseDate(j['date_source']),
        corrigeLe: parseDate(j['corrige_le']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'statement_id': statementId,
        'org_id': orgId,
        'position': positionKey(position),
        'source_type': sourceTypeKey(sourceType),
        'source_url': sourceUrl,
        'source_extrait': sourceExtrait,
        'date_source': dateSource?.toIso8601String(),
        'corrige_le': corrigeLe?.toIso8601String(),
      };
}

class Statement {
  const Statement({required this.id, required this.ordre, required this.texte, this.theme});
  final int id;
  final int ordre;
  final String texte;
  final String? theme;

  factory Statement.fromJson(Map<String, dynamic> j) => Statement(
        id: (j['id'] as num).toInt(),
        ordre: (j['ordre'] as num).toInt(),
        texte: j['texte'] as String,
        theme: j['theme'] as String?,
      );
  Map<String, dynamic> toJson() => {'id': id, 'ordre': ordre, 'texte': texte, 'theme': theme};
}

/// Un quiz publié avec ses affirmations, les partis et toutes les positions.
class QuizBundle {
  const QuizBundle({required this.id, required this.titre, required this.version, required this.statements, required this.parties, required this.positions});

  final int id;
  final String titre;
  final int version;
  final List<Statement> statements;
  final List<Party> parties;
  final List<PartyPosition> positions;

  PartyPosition? position(int statementId, int orgId) {
    for (final p in positions) {
      if (p.statementId == statementId && p.orgId == orgId) return p;
    }
    return null;
  }

  List<PartyPosition> positionsOf(int orgId) => positions.where((p) => p.orgId == orgId).toList();

  Party? party(int id) {
    for (final p in parties) {
      if (p.id == id) return p;
    }
    return null;
  }

  factory QuizBundle.fromJson(Map<String, dynamic> j) => QuizBundle(
        id: (j['id'] as num).toInt(),
        titre: j['titre'] as String,
        version: ((j['version'] as num?) ?? 1).toInt(),
        statements: (j['statements'] as List).cast<Map<String, dynamic>>().map(Statement.fromJson).toList()..sort((a, b) => a.ordre.compareTo(b.ordre)),
        parties: (j['parties'] as List).cast<Map<String, dynamic>>().map(Party.fromJson).toList(),
        positions: (j['positions'] as List).cast<Map<String, dynamic>>().map(PartyPosition.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'version': version,
        'statements': statements.map((s) => s.toJson()).toList(),
        'parties': parties.map((p) => p.toJson()).toList(),
        'positions': positions.map((p) => p.toJson()).toList(),
      };
}
