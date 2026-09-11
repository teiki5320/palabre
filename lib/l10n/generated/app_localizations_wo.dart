// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Wolof (`wo`).
class AppLocalizationsWo extends AppLocalizations {
  AppLocalizationsWo([String locale = 'wo']) : super(locale);

  @override
  String get appName => 'Palabre';

  @override
  String get tabQuestion => 'Laaj';

  @override
  String get tabQuiz => 'Sekkul sa bopp';

  @override
  String get tabGovernment => 'Nguur';

  @override
  String get tabAssembly => 'Péncum réew';

  @override
  String get settings => 'Tànneef';

  @override
  String get retry => 'Jéemaat';

  @override
  String get close => 'Tëj';

  @override
  String get cancel => 'Bàyyi';

  @override
  String get save => 'Denc';

  @override
  String get start => 'Tàmbali';

  @override
  String get back => 'Dellu';

  @override
  String get next => 'Topp';

  @override
  String get send => 'Yónnee';

  @override
  String get share => 'Séddoo';

  @override
  String get source => 'Gongikuwaay';

  @override
  String get sources => 'Gongikuwaay yi';

  @override
  String get offlineNotice => 'Hors-ligne : données du dernier chargement.';

  @override
  String get errorGeneric => 'Impossible de charger les données.';

  @override
  String get notConfigured =>
      'Serveur non configuré : l\'app fonctionne sur le cache local.';

  @override
  String get moduleSuspended => 'Ce module est suspendu dans ce pays.';

  @override
  String moduleSuspendedReason(String motif) {
    return 'Motif : $motif';
  }

  @override
  String get notSpecified => 'Non renseigné';

  @override
  String get unknownDate => 'date inconnue';

  @override
  String get onboardingTitle => 'Pénc mi';

  @override
  String get onboardingPrinciple =>
      'Ñu laaj, ku nekk wax sa xalaat, te waxtaan wi sukkandiku ci ay dëgg yu ñu mën a seet.';

  @override
  String onboardingProfileWhy(int seuil) {
    return 'Le pays, la tranche d\'âge et la région servent uniquement à découper les résultats du sondage. Ils ne sont jamais affichés individuellement, et une découpe n\'apparaît qu\'à partir de $seuil répondants.';
  }

  @override
  String get fieldCountry => 'Réew';

  @override
  String get fieldAge => 'At yi';

  @override
  String get fieldRegion => 'Diiwaan';

  @override
  String get refineTitle => 'Affiner les résultats';

  @override
  String get refineLater => 'Plus tard';

  @override
  String pollWeekOf(String date) {
    return 'Semaine du $date';
  }

  @override
  String pollOpensAt(String date) {
    return 'Ouvre le $date';
  }

  @override
  String pollClosedAt(String date) {
    return 'Fermé le $date';
  }

  @override
  String pollOpenUntil(String date) {
    return 'Ouverte jusqu\'au $date';
  }

  @override
  String pollStatusScheduledNote(String date) {
    return 'Le vote ouvre le $date.';
  }

  @override
  String pollContextSources(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Contexte · $n sources',
      one: 'Contexte · 1 source',
      zero: 'Contexte',
    );
    return '$_temp0';
  }

  @override
  String get pollNoCurrent => 'Pas de question cette semaine.';

  @override
  String get pollVote => 'Wote';

  @override
  String get pollVoteFinal => 'Sa wote dootul soppiku.';

  @override
  String pollVoted(String option) {
    return 'Vous avez voté : $option';
  }

  @override
  String get pollVoteError => 'Le vote n\'a pas pu être enregistré.';

  @override
  String get pollArchive => 'Ayu-bés yi weesu';

  @override
  String get pollArchiveEmpty => 'Aucune question archivée.';

  @override
  String pollRespondents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n répondants',
      one: '1 répondant',
      zero: 'Aucun répondant',
    );
    return '$_temp0';
  }

  @override
  String pollSample(int n, String pays) {
    return '$n utilisateurs de l\'application ont répondu. Ce résultat ne représente pas la population de $pays.';
  }

  @override
  String get pollResultsProvisional =>
      'Résultats provisoires, recalculés toutes les cinq minutes.';

  @override
  String get pollResultsFinal => 'Résultats définitifs.';

  @override
  String get pollNoResultsYet => 'Résultats en cours de calcul.';

  @override
  String get pollBreakdownTotal => 'Ensemble';

  @override
  String get pollBreakdownCountry => 'Par pays';

  @override
  String get pollBreakdownAge => 'Par tranche d\'âge';

  @override
  String get pollBreakdownRegion => 'Par région';

  @override
  String pollBreakdownNone(int seuil) {
    return 'Aucune découpe disponible : il faut au moins $seuil répondants par cellule pour en afficher une.';
  }

  @override
  String pollSuspect(String motif) {
    return 'Ce sondage présente des signes de manipulation. $motif';
  }

  @override
  String get pollLinkedPerson => 'Personne concernée';

  @override
  String get pollLinkedOrg => 'Institution concernée';

  @override
  String get quizIntro =>
      'Vous répondez aux mêmes affirmations que celles posées aux partis. On calcule ensuite une concordance, parti par parti, source par source.';

  @override
  String get quizMethod1 =>
      'Les partis ont reçu le même questionnaire. Trois niveaux de source : réponse directe, document public, aucune.';

  @override
  String get quizMethod2 =>
      'Un parti qui n\'a pas répondu apparaît comme « n\'a pas pris position ». Rien n\'est extrapolé.';

  @override
  String get quizMethod3 =>
      'Votre résultat est calculé sur votre téléphone et n\'est jamais envoyé.';

  @override
  String quizStatements(int n) {
    return '$n affirmations';
  }

  @override
  String quizParties(int n) {
    return '$n partis';
  }

  @override
  String get quizResume => 'Reprendre';

  @override
  String get quizRestart => 'Recommencer';

  @override
  String quizEstimate(int n) {
    return '$n affirmations · environ 5 minutes';
  }

  @override
  String get quizLastResult => 'Votre dernier résultat';

  @override
  String get quizSwipeHint => 'Glissez la carte, ou touchez un bouton';

  @override
  String get quizSkipStatement => 'Passer cette affirmation';

  @override
  String get quizNone => 'Aucun questionnaire publié pour ce pays.';

  @override
  String get quizAgree => 'Dëgg la';

  @override
  String get quizDisagree => 'Dëggul';

  @override
  String get quizNeutral => 'Diggante';

  @override
  String get quizImportant => 'Am solo ci man';

  @override
  String quizImportantLimit(int n) {
    return 'Vous pouvez marquer $n affirmations au maximum.';
  }

  @override
  String quizImportantCount(int n, int max) {
    return '$n sur $max marquées, elles comptent double';
  }

  @override
  String quizProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get quizResultsTitle => 'Votre concordance';

  @override
  String quizResultsSubtitle(int n) {
    return '$n réponses · calculé sur votre téléphone';
  }

  @override
  String get quizResultsAllTitle =>
      'Tous les partis, du plus proche au plus éloigné';

  @override
  String get quizResultsNote =>
      'Un parti sans position sur une affirmation n\'est jamais deviné : il apparaît « n\'a pas pris position ». Chaque position renvoie à sa source.';

  @override
  String get quizNotComputable => 'non calculable';

  @override
  String get quizDetailShort => 'Détail par affirmation';

  @override
  String quizConcordance(int pct) {
    return '$pct %';
  }

  @override
  String quizCompared(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n positions comparées',
      one: '1 position comparée',
      zero: 'aucune position comparée',
    );
    return '$_temp0';
  }

  @override
  String quizNoPosition(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sans position',
      one: '1 sans position',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get quizNotComparable =>
      'Non calculable : aucune position connue sur vos réponses.';

  @override
  String get quizYou => 'Vous';

  @override
  String get quizYouSkipped => 'Passée';

  @override
  String get quizPositionAgree => 'Accord';

  @override
  String get quizPositionDisagree => 'Désaccord';

  @override
  String get quizPositionNeutral => 'Neutre';

  @override
  String get quizPositionNone => 'Waxul dara';

  @override
  String get quizSourceDirect => 'Réponse directe';

  @override
  String get quizSourceDocument => 'Document public';

  @override
  String get quizSourceNone => 'Aucune source';

  @override
  String quizCorrectedOn(String date) {
    return 'Corrigé le $date';
  }

  @override
  String get quizContest => 'Contester cette position';

  @override
  String get quizContestIntro =>
      'Vous pouvez contester cette position, pièce à l\'appui. Si la correction est acceptée, elle sera datée et visible.';

  @override
  String get quizContestArgument => 'Argument';

  @override
  String get quizContestPiece => 'Lien vers la pièce (facultatif)';

  @override
  String get quizContestAuthor => 'Votre nom ou organisation (facultatif)';

  @override
  String get quizContestSent => 'Contestation envoyée. Merci.';

  @override
  String get quizContestTooShort => 'Au moins 20 caractères.';

  @override
  String get quizContestError => 'L\'envoi a échoué.';

  @override
  String get quizShareText =>
      'Mon résultat sur Palabre, calculé sur mon téléphone et jamais stocké.';

  @override
  String get quizShareFooter => 'Palabre · résultat calculé localement';

  @override
  String quizAnswered(int n, int total) {
    return '$n réponses sur $total';
  }

  @override
  String govAt(String date) {
    return 'Au $date';
  }

  @override
  String govCoverage(int n, int total) {
    return '$n des $total portefeuilles renseignés';
  }

  @override
  String govCoverageUnknown(int n) {
    return '$n portefeuilles renseignés';
  }

  @override
  String get govNone => 'Aucun gouvernement documenté à cette date.';

  @override
  String get govNoData => 'Aucun gouvernement documenté pour ce pays.';

  @override
  String get govHead => 'Njiitu nguur gi';

  @override
  String get govToday => 'aujourd\'hui';

  @override
  String get govSliderHint => 'Faites glisser pour remonter le temps';

  @override
  String govSince(String date) {
    return 'depuis le $date';
  }

  @override
  String govFromTo(String debut, String fin) {
    return 'du $debut au $fin';
  }

  @override
  String get blocRegalien => 'Régalien';

  @override
  String get blocEconomie => 'Économie';

  @override
  String get blocSocial => 'Social';

  @override
  String get blocInfrastructure => 'Infrastructure';

  @override
  String get blocAutre => 'Autre';

  @override
  String get asmSearch => 'Nom, circonscription ou parti';

  @override
  String get asmFilterGroup => 'Groupe';

  @override
  String get asmFilterRegion => 'Région';

  @override
  String get asmAll => 'Tous';

  @override
  String asmLegislature(int numero) {
    return '${numero}e législature';
  }

  @override
  String asmSeats(int n) {
    return '$n sièges';
  }

  @override
  String get asmNoData => 'Composition non disponible pour ce pays.';

  @override
  String get asmSubstitute => 'Suppléance';

  @override
  String asmReplaces(String nom) {
    return 'Remplace $nom';
  }

  @override
  String get asmNoRollCall =>
      'Scrutins nominatifs indisponibles pour cette législature.';

  @override
  String get asmActivity => 'Activité publiée';

  @override
  String get asmPresence => 'Présence en séance';

  @override
  String get asmWrittenQuestions => 'Questions écrites';

  @override
  String get asmOralQuestions => 'Questions orales';

  @override
  String get asmProposals => 'Propositions déposées';

  @override
  String get asmCommittees => 'Participations en commission';

  @override
  String get asmNotPublished => 'non publié';

  @override
  String get asmActivityNone => 'Aucun indicateur d\'activité publié.';

  @override
  String asmResults(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String get asmConstituency => 'Circonscription';

  @override
  String get asmGroup => 'Groupe';

  @override
  String get asmNoGroup => 'Sans groupe';

  @override
  String get personMandates => 'Ndombo yi';

  @override
  String get personAffiliations => 'Affiliations';

  @override
  String get personCareer => 'Yoon wi';

  @override
  String get personPartyPositions => 'Positions de son parti';

  @override
  String get personPartyPositionsNote =>
      'Les positions affichées sont celles du parti, sourcées. Palabre ne positionne jamais une personne.';

  @override
  String get personNoData => 'Aucune donnée pour cette personne.';

  @override
  String personBorn(String date) {
    return 'Né(e) le $date';
  }

  @override
  String get confidenceJournalOfficiel => 'Journal officiel';

  @override
  String get confidenceCommunique => 'Communiqué officiel';

  @override
  String get confidenceAgence => 'Agence de presse';

  @override
  String get confidenceWikidata => 'Wikidata';

  @override
  String get confidencePresse => 'Presse';

  @override
  String get motifFinGouvernement => 'fin du gouvernement';

  @override
  String get motifRemaniement => 'remaniement';

  @override
  String get motifDemission => 'démission';

  @override
  String get motifRevocation => 'révocation';

  @override
  String get motifDeces => 'décès';

  @override
  String get motifNominationGouvernement => 'nommé(e) au gouvernement';

  @override
  String get motifFinLegislature => 'fin de législature';

  @override
  String get motifInvalidation => 'invalidation';

  @override
  String get motifAutre => 'autre';

  @override
  String get partyMembers => 'Élus et membres du gouvernement en exercice';

  @override
  String get partyPositions => 'Positions déclarées';

  @override
  String get partyPositionsNone =>
      'Aucune position déclarée dans le questionnaire en cours.';

  @override
  String get partyHistory => 'Histoire';

  @override
  String partyFounded(String date) {
    return 'Fondé le $date';
  }

  @override
  String partyDissolved(String date) {
    return 'Dissous le $date';
  }

  @override
  String get relScission => 'scission de';

  @override
  String get relFusion => 'fusion avec';

  @override
  String get relRenommage => 'renommage de';

  @override
  String get relCoalitionMembre => 'membre de';

  @override
  String get relAbsorption => 'absorbé par';

  @override
  String get orgParti => 'Parti';

  @override
  String get orgCoalition => 'Coalition';

  @override
  String get orgGouvernement => 'Gouvernement';

  @override
  String get orgAssemblee => 'Assemblée';

  @override
  String get orgGroupe => 'Groupe parlementaire';

  @override
  String get settingsCountry => 'Réew';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsLanguage => 'Làkk';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsDesc =>
      'Une seule par semaine : l\'ouverture de la question du lundi, et un rappel le samedi si vous n\'avez pas voté.';

  @override
  String get settingsNotificationsUnavailable =>
      'Notifications non configurées sur cette version.';

  @override
  String get settingsAbout => 'Ci mbir mi';

  @override
  String get settingsAboutText =>
      'Palabre n\'exprime aucune opinion. Elle pose des questions et documente des faits sourcés. Chaque fait affiché renvoie à sa source.';

  @override
  String settingsVersion(String v) {
    return 'Version $v';
  }

  @override
  String get settingsSaved => 'Profil enregistré.';

  @override
  String get languageSystem => 'Làkku telefon bi';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get languageWo => 'Wolof';
}
