// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Palabre';

  @override
  String get tabQuestion => 'Question';

  @override
  String get tabQuiz => 'Test yourself';

  @override
  String get tabGovernment => 'Government';

  @override
  String get tabAssembly => 'Assembly';

  @override
  String get settings => 'Settings';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get start => 'Start';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get send => 'Send';

  @override
  String get share => 'Share';

  @override
  String get source => 'Source';

  @override
  String get sources => 'Sources';

  @override
  String get offlineNotice => 'Offline: showing the last loaded data.';

  @override
  String get errorGeneric => 'Unable to load data.';

  @override
  String get notConfigured =>
      'Server not configured: the app runs on its local cache.';

  @override
  String get moduleSuspended => 'This module is suspended in this country.';

  @override
  String moduleSuspendedReason(String motif) {
    return 'Reason: $motif';
  }

  @override
  String get notSpecified => 'Not specified';

  @override
  String get unknownDate => 'unknown date';

  @override
  String get onboardingTitle => 'The palaver tree';

  @override
  String get onboardingPrinciple =>
      'One question a week, a test to compare your views with the parties, the list of who governs. Nothing is judged, everything is sourced.';

  @override
  String onboardingProfileWhy(int seuil) {
    return 'Country, age bracket and region are used only to break down poll results. They are never shown individually, and a breakdown only appears from $seuil respondents.';
  }

  @override
  String get fieldCountry => 'Country';

  @override
  String get fieldAge => 'Age bracket';

  @override
  String get fieldRegion => 'Region';

  @override
  String get refineTitle => 'Refine the results';

  @override
  String get refineLater => 'Later';

  @override
  String pollWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String pollOpensAt(String date) {
    return 'Opens on $date';
  }

  @override
  String pollClosesAt(String date) {
    return 'Closes on $date';
  }

  @override
  String pollClosedAt(String date) {
    return 'Closed on $date';
  }

  @override
  String get pollStatusOpen => 'Open';

  @override
  String get pollStatusScheduled => 'Upcoming';

  @override
  String get pollStatusClosed => 'Closed';

  @override
  String get pollNoCurrent => 'No question this week.';

  @override
  String get pollVote => 'Vote';

  @override
  String get pollVoteFinal => 'Your vote is final.';

  @override
  String pollVoted(String option) {
    return 'You voted: $option';
  }

  @override
  String get pollVoteBeforeResults => 'Vote to see the results.';

  @override
  String get pollVoteError => 'Your vote could not be recorded.';

  @override
  String get pollContext => 'Context';

  @override
  String get pollArchive => 'Previous weeks';

  @override
  String get pollArchiveEmpty => 'No archived question.';

  @override
  String pollRespondents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respondents',
      one: '1 respondent',
      zero: 'No respondents',
    );
    return '$_temp0';
  }

  @override
  String pollSample(int n, String pays) {
    return '$n app users answered. This result does not represent the population of $pays.';
  }

  @override
  String get pollResultsProvisional =>
      'Provisional results, recomputed every five minutes.';

  @override
  String get pollResultsFinal => 'Final results.';

  @override
  String get pollNoResultsYet => 'Results are being computed.';

  @override
  String get pollBreakdowns => 'Breakdowns';

  @override
  String get pollBreakdownTotal => 'All';

  @override
  String get pollBreakdownCountry => 'By country';

  @override
  String get pollBreakdownAge => 'By age bracket';

  @override
  String get pollBreakdownRegion => 'By region';

  @override
  String pollBreakdownNone(int seuil) {
    return 'No breakdown available: at least $seuil respondents per cell are needed to show one.';
  }

  @override
  String pollSuspect(String motif) {
    return 'This poll shows signs of manipulation. $motif';
  }

  @override
  String get pollLinkedPerson => 'Person concerned';

  @override
  String get pollLinkedOrg => 'Institution concerned';

  @override
  String get quizIntro =>
      'You answer the same statements that were put to the parties. A match score is then computed, party by party, source by source.';

  @override
  String get quizMethod1 =>
      'Parties received the same questionnaire. Three source levels: direct answer, public document, none.';

  @override
  String get quizMethod2 =>
      'A party that did not answer appears as “no position taken”. Nothing is extrapolated.';

  @override
  String get quizMethod3 =>
      'Your result is computed on your phone and never sent.';

  @override
  String quizStatements(int n) {
    return '$n statements';
  }

  @override
  String quizParties(int n) {
    return '$n parties';
  }

  @override
  String get quizResume => 'Resume';

  @override
  String get quizRestart => 'Start over';

  @override
  String get quizNone => 'No published questionnaire for this country.';

  @override
  String get quizAgree => 'Agree';

  @override
  String get quizDisagree => 'Disagree';

  @override
  String get quizNeutral => 'Neutral';

  @override
  String get quizSkip => 'Skip';

  @override
  String get quizImportant => 'Important to me';

  @override
  String quizImportantLimit(int n) {
    return 'You can mark at most $n statements.';
  }

  @override
  String quizImportantCount(int n, int max) {
    return '$n of $max marked, they count double';
  }

  @override
  String quizProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get quizSeeResults => 'See my result';

  @override
  String get quizResultsTitle => 'Your match';

  @override
  String get quizResultsAll =>
      'All parties are listed. A full ranking is less biased than a single verdict.';

  @override
  String quizConcordance(int pct) {
    return '$pct%';
  }

  @override
  String quizCompared(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n positions compared',
      one: '1 position compared',
      zero: 'no positions compared',
    );
    return '$_temp0';
  }

  @override
  String quizNoPosition(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n no position',
      one: '1 no position',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get quizNotComparable =>
      'Not computable: no known position on your answers.';

  @override
  String get quizDetail => 'Detail, statement by statement';

  @override
  String get quizYou => 'You';

  @override
  String get quizYouSkipped => 'Skipped';

  @override
  String get quizPositionAgree => 'Agree';

  @override
  String get quizPositionDisagree => 'Disagree';

  @override
  String get quizPositionNeutral => 'Neutral';

  @override
  String get quizPositionNone => 'No position taken';

  @override
  String get quizSourceDirect => 'Direct answer';

  @override
  String get quizSourceDocument => 'Public document';

  @override
  String get quizSourceNone => 'No source';

  @override
  String quizCorrectedOn(String date) {
    return 'Corrected on $date';
  }

  @override
  String get quizContest => 'Challenge this position';

  @override
  String get quizContestIntro =>
      'You can challenge this position with supporting evidence. If the correction is accepted, it will be dated and visible.';

  @override
  String get quizContestArgument => 'Argument';

  @override
  String get quizContestPiece => 'Link to evidence (optional)';

  @override
  String get quizContestAuthor => 'Your name or organisation (optional)';

  @override
  String get quizContestSent => 'Challenge sent. Thank you.';

  @override
  String get quizContestTooShort => 'At least 20 characters.';

  @override
  String get quizContestError => 'Sending failed.';

  @override
  String get quizShareText =>
      'My Palabre result, computed on my phone and never stored.';

  @override
  String get quizShareFooter => 'Palabre · result computed locally';

  @override
  String quizAnswered(int n, int total) {
    return '$n answers out of $total';
  }

  @override
  String govAt(String date) {
    return 'As of $date';
  }

  @override
  String govCoverage(int n, int total) {
    return '$n of $total portfolios documented';
  }

  @override
  String govCoverageUnknown(int n) {
    return '$n portfolios documented';
  }

  @override
  String get govNone => 'No government documented at this date.';

  @override
  String get govNoData => 'No government documented for this country.';

  @override
  String get govHead => 'Head of government';

  @override
  String govSince(String date) {
    return 'since $date';
  }

  @override
  String govFromTo(String debut, String fin) {
    return 'from $debut to $fin';
  }

  @override
  String get blocRegalien => 'Sovereign';

  @override
  String get blocEconomie => 'Economy';

  @override
  String get blocSocial => 'Social';

  @override
  String get blocInfrastructure => 'Infrastructure';

  @override
  String get blocAutre => 'Other';

  @override
  String get asmSearch => 'Name, constituency or party';

  @override
  String get asmFilterGroup => 'Group';

  @override
  String get asmFilterRegion => 'Region';

  @override
  String get asmAll => 'All';

  @override
  String asmLegislature(int numero) {
    return 'Legislature $numero';
  }

  @override
  String asmSeats(int n) {
    return '$n seats';
  }

  @override
  String get asmNoData => 'Composition not available for this country.';

  @override
  String get asmSubstitute => 'Substitute';

  @override
  String asmReplaces(String nom) {
    return 'Replaces $nom';
  }

  @override
  String get asmNoRollCall =>
      'Roll-call votes unavailable for this legislature.';

  @override
  String get asmActivity => 'Published activity';

  @override
  String get asmPresence => 'Attendance in plenary';

  @override
  String get asmWrittenQuestions => 'Written questions';

  @override
  String get asmOralQuestions => 'Oral questions';

  @override
  String get asmProposals => 'Bills tabled';

  @override
  String get asmCommittees => 'Committee participations';

  @override
  String get asmNotPublished => 'not published';

  @override
  String get asmActivityNone => 'No activity indicator published.';

  @override
  String asmResults(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get asmConstituency => 'Constituency';

  @override
  String get asmGroup => 'Group';

  @override
  String get asmNoGroup => 'No group';

  @override
  String get personMandates => 'Mandates';

  @override
  String get personAffiliations => 'Affiliations';

  @override
  String get personCareer => 'Career';

  @override
  String get personPartyPositions => 'Their party\'s positions';

  @override
  String get personPartyPositionsNote =>
      'The positions shown are the party\'s, sourced. Palabre never positions a person.';

  @override
  String get personNoData => 'No data for this person.';

  @override
  String personBorn(String date) {
    return 'Born on $date';
  }

  @override
  String get confidenceJournalOfficiel => 'Official gazette';

  @override
  String get confidenceCommunique => 'Official statement';

  @override
  String get confidenceAgence => 'News agency';

  @override
  String get confidenceWikidata => 'Wikidata';

  @override
  String get confidencePresse => 'Press';

  @override
  String get motifFinGouvernement => 'end of government';

  @override
  String get motifRemaniement => 'reshuffle';

  @override
  String get motifDemission => 'resignation';

  @override
  String get motifRevocation => 'dismissal';

  @override
  String get motifDeces => 'death';

  @override
  String get motifNominationGouvernement => 'appointed to government';

  @override
  String get motifFinLegislature => 'end of legislature';

  @override
  String get motifInvalidation => 'invalidation';

  @override
  String get motifAutre => 'other';

  @override
  String get partyMembers => 'Current elected officials and government members';

  @override
  String get partyPositions => 'Declared positions';

  @override
  String get partyPositionsNone =>
      'No declared position in the current questionnaire.';

  @override
  String get partyHistory => 'History';

  @override
  String partyFounded(String date) {
    return 'Founded on $date';
  }

  @override
  String partyDissolved(String date) {
    return 'Dissolved on $date';
  }

  @override
  String get relScission => 'split from';

  @override
  String get relFusion => 'merged with';

  @override
  String get relRenommage => 'renamed from';

  @override
  String get relCoalitionMembre => 'member of';

  @override
  String get relAbsorption => 'absorbed by';

  @override
  String get orgParti => 'Party';

  @override
  String get orgCoalition => 'Coalition';

  @override
  String get orgGouvernement => 'Government';

  @override
  String get orgAssemblee => 'Assembly';

  @override
  String get orgGroupe => 'Parliamentary group';

  @override
  String get settingsCountry => 'Country';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsDesc =>
      'Only one a week: the Monday question opening, and a Saturday reminder if you have not voted.';

  @override
  String get settingsNotificationsUnavailable =>
      'Notifications are not configured in this build.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutText =>
      'Palabre holds no opinion. It asks questions and documents sourced facts. Every fact shown links to its source.';

  @override
  String settingsVersion(String v) {
    return 'Version $v';
  }

  @override
  String get settingsSaved => 'Profile saved.';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get languageWo => 'Wolof';
}
