import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/supabase/supabase_providers.dart';
import 'quiz_engine.dart';
import 'quiz_models.dart';

/// Le quiz publié du pays (dernière version), null s'il n'y en a pas.
class QuizNotifier extends CachedNotifier<QuizBundle?> {
  QuizNotifier(this.countryCode);
  final String countryCode;

  @override
  String get cacheKey => 'quiz:$countryCode';

  @override
  Future<QuizBundle?> fetchRemote() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) throw const NotConfiguredException();
    final quiz = await client
        .from('quiz')
        .select('id, titre, version')
        .eq('country_code', countryCode)
        .eq('publie', true)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
    if (quiz == null) return null;
    final id = (quiz['id'] as num).toInt();
    final statements = await client.from('statement').select().eq('quiz_id', id).order('ordre');
    final statementIds = statements.map((s) => (s['id'] as num).toInt()).toList();
    final positions = statementIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client.from('party_position').select().inFilter('statement_id', statementIds);
    final orgIds = positions.map((p) => (p['org_id'] as num).toInt()).toSet().toList();
    final orgs = orgIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client.from('organization').select('id, nom, sigle, couleur, type').inFilter('id', orgIds).order('nom');
    return QuizBundle(
      id: id,
      titre: quiz['titre'] as String,
      version: ((quiz['version'] as num?) ?? 1).toInt(),
      statements: statements.map(Statement.fromJson).toList(),
      parties: orgs.map(Party.fromJson).toList(),
      positions: positions.map(PartyPosition.fromJson).toList(),
    );
  }

  @override
  QuizBundle? decode(Map<String, dynamic> json) => json['quiz'] == null ? null : QuizBundle.fromJson(json['quiz'] as Map<String, dynamic>);

  @override
  Map<String, dynamic> encode(QuizBundle? value) => {'quiz': value?.toJson()};
}

final quizProvider = AsyncNotifierProvider.family<QuizNotifier, QuizBundle?, String>(QuizNotifier.new);

final currentQuizProvider = Provider<AsyncValue<QuizBundle?>>((ref) {
  final code = ref.watch(selectedCountryProvider);
  return ref.watch(quizProvider(code));
});

/// Réponses en cours. En mémoire uniquement : jamais écrites, ni sur le
/// serveur ni sur le disque. Fermer l'app efface tout.
@immutable
class QuizSession {
  const QuizSession({this.quizId, this.answers = const {}, this.important = const {}, this.index = 0});
  final int? quizId;
  final Map<int, Answer> answers;
  final Set<int> important;
  final int index;

  QuizSession copyWith({int? quizId, Map<int, Answer>? answers, Set<int>? important, int? index}) => QuizSession(
        quizId: quizId ?? this.quizId,
        answers: answers ?? this.answers,
        important: important ?? this.important,
        index: index ?? this.index,
      );

  bool get started => answers.isNotEmpty;
}

class QuizSessionNotifier extends Notifier<QuizSession> {
  @override
  QuizSession build() => const QuizSession();

  void start(int quizId) {
    if (state.quizId != quizId) state = QuizSession(quizId: quizId);
  }

  void reset() => state = QuizSession(quizId: state.quizId);

  void answer(int statementId, Answer a) =>
      state = state.copyWith(answers: {...state.answers, statementId: a});

  /// Retourne false si la limite est atteinte.
  bool toggleImportant(int statementId) {
    final set = {...state.important};
    if (set.contains(statementId)) {
      set.remove(statementId);
    } else {
      if (set.length >= QuizEngine.maxImportant) return false;
      set.add(statementId);
    }
    state = state.copyWith(important: set);
    return true;
  }

  void goTo(int index) => state = state.copyWith(index: index);
}

final quizSessionProvider = NotifierProvider<QuizSessionNotifier, QuizSession>(QuizSessionNotifier.new);

/// Résultat, recalculé à la volée. Jamais stocké.
final quizScoresProvider = Provider<List<PartyScore>>((ref) {
  final quiz = ref.watch(currentQuizProvider).value;
  final session = ref.watch(quizSessionProvider);
  if (quiz == null || session.quizId != quiz.id) return const [];
  return QuizEngine.compute(quiz, session.answers, session.important);
});

/// Droit de correction : dépôt d'une contestation, pièce à l'appui.
class ContestationAction {
  ContestationAction(this.ref);
  final Ref ref;

  Future<void> send({required int positionId, required String argument, String? pieceUrl, String? auteur}) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) throw const NotConfiguredException();
    await client.from('position_contestation').insert({
      'position_id': positionId,
      'argument': argument.trim(),
      'piece_url': (pieceUrl ?? '').trim().isEmpty ? null : pieceUrl!.trim(),
      'auteur': (auteur ?? '').trim().isEmpty ? null : auteur!.trim(),
    });
  }
}

final contestationActionProvider = Provider<ContestationAction>(ContestationAction.new);
