import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/features/quiz/quiz_engine.dart';
import 'package:palabre/features/quiz/quiz_models.dart';

QuizBundle _quiz() {
  const parties = [Party(id: 1, nom: 'Alpha'), Party(id: 2, nom: 'Bêta'), Party(id: 3, nom: 'Gamma')];
  const statements = [
    Statement(id: 10, ordre: 1, texte: 's1'),
    Statement(id: 11, ordre: 2, texte: 's2'),
    Statement(id: 12, ordre: 3, texte: 's3'),
  ];
  PartyPosition pp(int s, int o, Position p, [SourceType st = SourceType.documentPublic]) =>
      PartyPosition(id: s * 10 + o, statementId: s, orgId: o, position: p, sourceType: st);
  return QuizBundle(
    id: 1,
    titre: 'test',
    version: 1,
    statements: statements,
    parties: parties,
    positions: [
      pp(10, 1, Position.accord), pp(10, 2, Position.desaccord), pp(10, 3, Position.sansPosition, SourceType.aucune),
      pp(11, 1, Position.accord), pp(11, 2, Position.neutre), pp(11, 3, Position.sansPosition, SourceType.aucune),
      pp(12, 1, Position.desaccord), pp(12, 2, Position.desaccord), pp(12, 3, Position.sansPosition, SourceType.aucune),
    ],
  );
}

void main() {
  group('score élémentaire', () {
    test('même position vaut 1, opposée 0, neutre contre tranchée 0.5', () {
      expect(QuizEngine.scoreOf(Answer.accord, Position.accord), 1);
      expect(QuizEngine.scoreOf(Answer.desaccord, Position.desaccord), 1);
      expect(QuizEngine.scoreOf(Answer.accord, Position.desaccord), 0);
      expect(QuizEngine.scoreOf(Answer.neutre, Position.accord), 0.5);
      expect(QuizEngine.scoreOf(Answer.accord, Position.neutre), 0.5);
      expect(QuizEngine.scoreOf(Answer.neutre, Position.neutre), 1);
    });

    test('passer ou sans position ne compte pas', () {
      expect(QuizEngine.scoreOf(Answer.passer, Position.accord), isNull);
      expect(QuizEngine.scoreOf(Answer.accord, Position.sansPosition), isNull);
    });
  });

  group('concordance', () {
    test('tous les partis listés, du plus concordant au moins concordant', () {
      final scores = QuizEngine.compute(_quiz(), {10: Answer.accord, 11: Answer.accord, 12: Answer.desaccord});
      expect(scores.map((s) => s.party.nom), ['Alpha', 'Bêta', 'Gamma']);
      expect(scores[0].concordance, 100);
      // Bêta : 0 + 0.5 + 1 sur 3 → 50 %
      expect(scores[1].concordance, 50);
      expect(scores[1].compared, 3);
      // Gamma n'a pris aucune position : non calculable, en fin de liste
      expect(scores[2].concordance, isNull);
      expect(scores[2].sansPosition, 3);
    });

    test('une réponse passée est ignorée dans le dénominateur', () {
      final scores = QuizEngine.compute(_quiz(), {10: Answer.accord, 11: Answer.passer, 12: Answer.passer});
      final alpha = scores.firstWhere((s) => s.party.id == 1);
      expect(alpha.compared, 1);
      expect(alpha.concordance, 100);
    });

    test('aucune réponse : personne n\'est calculable', () {
      final scores = QuizEngine.compute(_quiz(), {});
      expect(scores.length, 3);
      expect(scores.every((s) => s.concordance == null), isTrue);
    });
  });
}
