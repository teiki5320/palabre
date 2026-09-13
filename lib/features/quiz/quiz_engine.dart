import 'quiz_models.dart';

/// Comparaison d'une affirmation : ta réponse contre celle d'un parti.
class StatementMatch {
  const StatementMatch({required this.statement, required this.answer, required this.position, required this.score});
  final Statement statement;
  final Answer? answer;
  final PartyPosition? position;

  /// 1 = même position, 0.5 = l'un neutre l'autre non, 0 = opposés, null = non comparable.
  final double? score;
}

class PartyScore {
  const PartyScore({required this.party, required this.concordance, required this.compared, required this.sansPosition, required this.matches});
  final Party party;

  /// Pourcentage 0–100, null si aucune position comparable.
  final int? concordance;
  final int compared;
  final int sansPosition;
  final List<StatementMatch> matches;
}

/// Le score est calculé ici, sur le téléphone, et n'est jamais envoyé.
class QuizEngine {

  static double? scoreOf(Answer answer, Position position) {
    if (answer == Answer.passer || position == Position.sansPosition) return null;
    if (answer == Answer.accord && position == Position.accord) return 1;
    if (answer == Answer.desaccord && position == Position.desaccord) return 1;
    if (answer == Answer.neutre && position == Position.neutre) return 1;
    if (answer == Answer.neutre || position == Position.neutre) return 0.5;
    return 0;
  }

  /// Tous les partis sont listés, du plus concordant au moins concordant ;
  /// les partis non calculables en fin de liste.
  static List<PartyScore> compute(QuizBundle quiz, Map<int, Answer> answers) {
    final out = <PartyScore>[];
    for (final party in quiz.parties) {
      double num = 0;
      double den = 0;
      var compared = 0;
      var sans = 0;
      final matches = <StatementMatch>[];
      for (final s in quiz.statements) {
        final a = answers[s.id];
        final p = quiz.position(s.id, party.id);
        double? sc;
        if (a != null && p != null) {
          sc = scoreOf(a, p.position);
          if (a != Answer.passer && p.position == Position.sansPosition) sans++;
          if (sc != null) {
            num += sc;
            den += 1;
            compared++;
          }
        }
        matches.add(StatementMatch(statement: s, answer: a, position: p, score: sc));
      }
      out.add(PartyScore(
        party: party,
        concordance: den == 0 ? null : (100 * num / den).round(),
        compared: compared,
        sansPosition: sans,
        matches: matches,
      ));
    }
    out.sort((a, b) {
      if (a.concordance == null && b.concordance == null) return a.party.nom.compareTo(b.party.nom);
      if (a.concordance == null) return 1;
      if (b.concordance == null) return -1;
      final c = b.concordance!.compareTo(a.concordance!);
      return c != 0 ? c : a.party.nom.compareTo(b.party.nom);
    });
    return out;
  }
}
