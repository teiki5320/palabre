import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_wo.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('wo'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Palabre'**
  String get appName;

  /// No description provided for @tabQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question'**
  String get tabQuestion;

  /// No description provided for @tabQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Testez-vous'**
  String get tabQuiz;

  /// No description provided for @tabGovernment.
  ///
  /// In fr, this message translates to:
  /// **'Gouvernement'**
  String get tabGovernment;

  /// No description provided for @tabAssembly.
  ///
  /// In fr, this message translates to:
  /// **'Assemblée'**
  String get tabAssembly;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get start;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @source.
  ///
  /// In fr, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sources.
  ///
  /// In fr, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @offlineNotice.
  ///
  /// In fr, this message translates to:
  /// **'Hors-ligne : données du dernier chargement.'**
  String get offlineNotice;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données.'**
  String get errorGeneric;

  /// No description provided for @notConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Serveur non configuré : l\'app fonctionne sur le cache local.'**
  String get notConfigured;

  /// No description provided for @moduleSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Ce module est suspendu dans ce pays.'**
  String get moduleSuspended;

  /// No description provided for @moduleSuspendedReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {motif}'**
  String moduleSuspendedReason(String motif);

  /// No description provided for @notSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get notSpecified;

  /// No description provided for @unknownDate.
  ///
  /// In fr, this message translates to:
  /// **'date inconnue'**
  String get unknownDate;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'arbre à palabres'**
  String get onboardingTitle;

  /// No description provided for @onboardingPrinciple.
  ///
  /// In fr, this message translates to:
  /// **'Une question par semaine, un test pour comparer vos idées aux partis, la liste de qui gouverne. Rien n\'est jugé, tout est sourcé.'**
  String get onboardingPrinciple;

  /// No description provided for @onboardingProfileWhy.
  ///
  /// In fr, this message translates to:
  /// **'Le pays, la tranche d\'âge et la région servent uniquement à découper les résultats du sondage. Ils ne sont jamais affichés individuellement, et une découpe n\'apparaît qu\'à partir de {seuil} répondants.'**
  String onboardingProfileWhy(int seuil);

  /// No description provided for @fieldCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get fieldCountry;

  /// No description provided for @fieldAge.
  ///
  /// In fr, this message translates to:
  /// **'Tranche d\'âge'**
  String get fieldAge;

  /// No description provided for @fieldRegion.
  ///
  /// In fr, this message translates to:
  /// **'Région'**
  String get fieldRegion;

  /// No description provided for @refineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Affiner les résultats'**
  String get refineTitle;

  /// No description provided for @refineLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get refineLater;

  /// No description provided for @pollWeekOf.
  ///
  /// In fr, this message translates to:
  /// **'Semaine du {date}'**
  String pollWeekOf(String date);

  /// No description provided for @pollOpensAt.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre le {date}'**
  String pollOpensAt(String date);

  /// No description provided for @pollClosesAt.
  ///
  /// In fr, this message translates to:
  /// **'Ferme le {date}'**
  String pollClosesAt(String date);

  /// No description provided for @pollClosedAt.
  ///
  /// In fr, this message translates to:
  /// **'Fermé le {date}'**
  String pollClosedAt(String date);

  /// No description provided for @pollStatusOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get pollStatusOpen;

  /// No description provided for @pollStatusScheduled.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get pollStatusScheduled;

  /// No description provided for @pollStatusClosed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get pollStatusClosed;

  /// No description provided for @pollOpenUntil.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte jusqu\'au {date}'**
  String pollOpenUntil(String date);

  /// No description provided for @pollStatusScheduledNote.
  ///
  /// In fr, this message translates to:
  /// **'Le vote ouvre le {date}.'**
  String pollStatusScheduledNote(String date);

  /// No description provided for @pollContextSources.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Contexte} =1{Contexte · 1 source} other{Contexte · {n} sources}}'**
  String pollContextSources(int n);

  /// No description provided for @pollNoCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Pas de question cette semaine.'**
  String get pollNoCurrent;

  /// No description provided for @pollVote.
  ///
  /// In fr, this message translates to:
  /// **'Voter'**
  String get pollVote;

  /// No description provided for @pollVoteFinal.
  ///
  /// In fr, this message translates to:
  /// **'Un seul vote, définitif. Les résultats s\'affichent après.'**
  String get pollVoteFinal;

  /// No description provided for @pollVoted.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez voté : {option}'**
  String pollVoted(String option);

  /// No description provided for @pollVoteBeforeResults.
  ///
  /// In fr, this message translates to:
  /// **'Votez pour voir les résultats.'**
  String get pollVoteBeforeResults;

  /// No description provided for @pollVoteError.
  ///
  /// In fr, this message translates to:
  /// **'Le vote n\'a pas pu être enregistré.'**
  String get pollVoteError;

  /// No description provided for @pollContext.
  ///
  /// In fr, this message translates to:
  /// **'Contexte'**
  String get pollContext;

  /// No description provided for @pollArchive.
  ///
  /// In fr, this message translates to:
  /// **'Semaines précédentes'**
  String get pollArchive;

  /// No description provided for @pollArchiveEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune question archivée.'**
  String get pollArchiveEmpty;

  /// No description provided for @pollRespondents.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun répondant} =1{1 répondant} other{{n} répondants}}'**
  String pollRespondents(int n);

  /// No description provided for @pollSample.
  ///
  /// In fr, this message translates to:
  /// **'{n} utilisateurs de l\'application ont répondu. Ce résultat ne représente pas la population de {pays}.'**
  String pollSample(int n, String pays);

  /// No description provided for @pollResultsProvisional.
  ///
  /// In fr, this message translates to:
  /// **'Résultats provisoires, recalculés toutes les cinq minutes.'**
  String get pollResultsProvisional;

  /// No description provided for @pollResultsFinal.
  ///
  /// In fr, this message translates to:
  /// **'Résultats définitifs.'**
  String get pollResultsFinal;

  /// No description provided for @pollNoResultsYet.
  ///
  /// In fr, this message translates to:
  /// **'Résultats en cours de calcul.'**
  String get pollNoResultsYet;

  /// No description provided for @pollBreakdowns.
  ///
  /// In fr, this message translates to:
  /// **'Découpes'**
  String get pollBreakdowns;

  /// No description provided for @pollBreakdownTotal.
  ///
  /// In fr, this message translates to:
  /// **'Ensemble'**
  String get pollBreakdownTotal;

  /// No description provided for @pollBreakdownCountry.
  ///
  /// In fr, this message translates to:
  /// **'Par pays'**
  String get pollBreakdownCountry;

  /// No description provided for @pollBreakdownAge.
  ///
  /// In fr, this message translates to:
  /// **'Par tranche d\'âge'**
  String get pollBreakdownAge;

  /// No description provided for @pollBreakdownRegion.
  ///
  /// In fr, this message translates to:
  /// **'Par région'**
  String get pollBreakdownRegion;

  /// No description provided for @pollBreakdownNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune découpe disponible : il faut au moins {seuil} répondants par cellule pour en afficher une.'**
  String pollBreakdownNone(int seuil);

  /// No description provided for @pollSuspect.
  ///
  /// In fr, this message translates to:
  /// **'Ce sondage présente des signes de manipulation. {motif}'**
  String pollSuspect(String motif);

  /// No description provided for @pollLinkedPerson.
  ///
  /// In fr, this message translates to:
  /// **'Personne concernée'**
  String get pollLinkedPerson;

  /// No description provided for @pollLinkedOrg.
  ///
  /// In fr, this message translates to:
  /// **'Institution concernée'**
  String get pollLinkedOrg;

  /// No description provided for @quizIntro.
  ///
  /// In fr, this message translates to:
  /// **'Vous répondez aux mêmes affirmations que celles posées aux partis. On calcule ensuite une concordance, parti par parti, source par source.'**
  String get quizIntro;

  /// No description provided for @quizMethod1.
  ///
  /// In fr, this message translates to:
  /// **'Les partis ont reçu le même questionnaire. Trois niveaux de source : réponse directe, document public, aucune.'**
  String get quizMethod1;

  /// No description provided for @quizMethod2.
  ///
  /// In fr, this message translates to:
  /// **'Un parti qui n\'a pas répondu apparaît comme « n\'a pas pris position ». Rien n\'est extrapolé.'**
  String get quizMethod2;

  /// No description provided for @quizMethod3.
  ///
  /// In fr, this message translates to:
  /// **'Votre résultat est calculé sur votre téléphone et n\'est jamais envoyé.'**
  String get quizMethod3;

  /// No description provided for @quizStatements.
  ///
  /// In fr, this message translates to:
  /// **'{n} affirmations'**
  String quizStatements(int n);

  /// No description provided for @quizParties.
  ///
  /// In fr, this message translates to:
  /// **'{n} partis'**
  String quizParties(int n);

  /// No description provided for @quizResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get quizResume;

  /// No description provided for @quizRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get quizRestart;

  /// No description provided for @quizEstimate.
  ///
  /// In fr, this message translates to:
  /// **'{n} affirmations · environ 5 minutes'**
  String quizEstimate(int n);

  /// No description provided for @quizLastResult.
  ///
  /// In fr, this message translates to:
  /// **'Votre dernier résultat'**
  String get quizLastResult;

  /// No description provided for @quizSwipeHint.
  ///
  /// In fr, this message translates to:
  /// **'Glissez la carte, ou touchez un bouton'**
  String get quizSwipeHint;

  /// No description provided for @quizSkipStatement.
  ///
  /// In fr, this message translates to:
  /// **'Passer cette affirmation'**
  String get quizSkipStatement;

  /// No description provided for @quizNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun questionnaire publié pour ce pays.'**
  String get quizNone;

  /// No description provided for @quizAgree.
  ///
  /// In fr, this message translates to:
  /// **'D\'accord'**
  String get quizAgree;

  /// No description provided for @quizDisagree.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'accord'**
  String get quizDisagree;

  /// No description provided for @quizNeutral.
  ///
  /// In fr, this message translates to:
  /// **'Neutre'**
  String get quizNeutral;

  /// No description provided for @quizSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get quizSkip;

  /// No description provided for @quizImportant.
  ///
  /// In fr, this message translates to:
  /// **'Important pour moi'**
  String get quizImportant;

  /// No description provided for @quizImportantLimit.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez marquer {n} affirmations au maximum.'**
  String quizImportantLimit(int n);

  /// No description provided for @quizImportantCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} sur {max} marquées, elles comptent double'**
  String quizImportantCount(int n, int max);

  /// No description provided for @quizProgress.
  ///
  /// In fr, this message translates to:
  /// **'{current} / {total}'**
  String quizProgress(int current, int total);

  /// No description provided for @quizSeeResults.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon résultat'**
  String get quizSeeResults;

  /// No description provided for @quizResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre concordance'**
  String get quizResultsTitle;

  /// No description provided for @quizResultsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{n} réponses · calculé sur votre téléphone'**
  String quizResultsSubtitle(int n);

  /// No description provided for @quizResultsAllTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tous les partis, du plus proche au plus éloigné'**
  String get quizResultsAllTitle;

  /// No description provided for @quizResultsNote.
  ///
  /// In fr, this message translates to:
  /// **'Un parti sans position sur une affirmation n\'est jamais deviné : il apparaît « n\'a pas pris position ». Chaque position renvoie à sa source.'**
  String get quizResultsNote;

  /// No description provided for @quizNotComputable.
  ///
  /// In fr, this message translates to:
  /// **'non calculable'**
  String get quizNotComputable;

  /// No description provided for @quizDetailShort.
  ///
  /// In fr, this message translates to:
  /// **'Détail par affirmation'**
  String get quizDetailShort;

  /// No description provided for @quizConcordance.
  ///
  /// In fr, this message translates to:
  /// **'{pct} %'**
  String quizConcordance(int pct);

  /// No description provided for @quizCompared.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aucune position comparée} =1{1 position comparée} other{{n} positions comparées}}'**
  String quizCompared(int n);

  /// No description provided for @quizNoPosition.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{} =1{1 sans position} other{{n} sans position}}'**
  String quizNoPosition(int n);

  /// No description provided for @quizNotComparable.
  ///
  /// In fr, this message translates to:
  /// **'Non calculable : aucune position connue sur vos réponses.'**
  String get quizNotComparable;

  /// No description provided for @quizDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail, affirmation par affirmation'**
  String get quizDetail;

  /// No description provided for @quizYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get quizYou;

  /// No description provided for @quizYouSkipped.
  ///
  /// In fr, this message translates to:
  /// **'Passée'**
  String get quizYouSkipped;

  /// No description provided for @quizPositionAgree.
  ///
  /// In fr, this message translates to:
  /// **'Accord'**
  String get quizPositionAgree;

  /// No description provided for @quizPositionDisagree.
  ///
  /// In fr, this message translates to:
  /// **'Désaccord'**
  String get quizPositionDisagree;

  /// No description provided for @quizPositionNeutral.
  ///
  /// In fr, this message translates to:
  /// **'Neutre'**
  String get quizPositionNeutral;

  /// No description provided for @quizPositionNone.
  ///
  /// In fr, this message translates to:
  /// **'N\'a pas pris position'**
  String get quizPositionNone;

  /// No description provided for @quizSourceDirect.
  ///
  /// In fr, this message translates to:
  /// **'Réponse directe'**
  String get quizSourceDirect;

  /// No description provided for @quizSourceDocument.
  ///
  /// In fr, this message translates to:
  /// **'Document public'**
  String get quizSourceDocument;

  /// No description provided for @quizSourceNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune source'**
  String get quizSourceNone;

  /// No description provided for @quizCorrectedOn.
  ///
  /// In fr, this message translates to:
  /// **'Corrigé le {date}'**
  String quizCorrectedOn(String date);

  /// No description provided for @quizContest.
  ///
  /// In fr, this message translates to:
  /// **'Contester cette position'**
  String get quizContest;

  /// No description provided for @quizContestIntro.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez contester cette position, pièce à l\'appui. Si la correction est acceptée, elle sera datée et visible.'**
  String get quizContestIntro;

  /// No description provided for @quizContestArgument.
  ///
  /// In fr, this message translates to:
  /// **'Argument'**
  String get quizContestArgument;

  /// No description provided for @quizContestPiece.
  ///
  /// In fr, this message translates to:
  /// **'Lien vers la pièce (facultatif)'**
  String get quizContestPiece;

  /// No description provided for @quizContestAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom ou organisation (facultatif)'**
  String get quizContestAuthor;

  /// No description provided for @quizContestSent.
  ///
  /// In fr, this message translates to:
  /// **'Contestation envoyée. Merci.'**
  String get quizContestSent;

  /// No description provided for @quizContestTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 20 caractères.'**
  String get quizContestTooShort;

  /// No description provided for @quizContestError.
  ///
  /// In fr, this message translates to:
  /// **'L\'envoi a échoué.'**
  String get quizContestError;

  /// No description provided for @quizShareText.
  ///
  /// In fr, this message translates to:
  /// **'Mon résultat sur Palabre, calculé sur mon téléphone et jamais stocké.'**
  String get quizShareText;

  /// No description provided for @quizShareFooter.
  ///
  /// In fr, this message translates to:
  /// **'Palabre · résultat calculé localement'**
  String get quizShareFooter;

  /// No description provided for @quizAnswered.
  ///
  /// In fr, this message translates to:
  /// **'{n} réponses sur {total}'**
  String quizAnswered(int n, int total);

  /// No description provided for @govAt.
  ///
  /// In fr, this message translates to:
  /// **'Au {date}'**
  String govAt(String date);

  /// No description provided for @govCoverage.
  ///
  /// In fr, this message translates to:
  /// **'{n} des {total} portefeuilles renseignés'**
  String govCoverage(int n, int total);

  /// No description provided for @govCoverageUnknown.
  ///
  /// In fr, this message translates to:
  /// **'{n} portefeuilles renseignés'**
  String govCoverageUnknown(int n);

  /// No description provided for @govNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun gouvernement documenté à cette date.'**
  String get govNone;

  /// No description provided for @govNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucun gouvernement documenté pour ce pays.'**
  String get govNoData;

  /// No description provided for @govHead.
  ///
  /// In fr, this message translates to:
  /// **'Chef du gouvernement'**
  String get govHead;

  /// No description provided for @govToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get govToday;

  /// No description provided for @govSliderHint.
  ///
  /// In fr, this message translates to:
  /// **'Faites glisser pour remonter le temps'**
  String get govSliderHint;

  /// No description provided for @govSince.
  ///
  /// In fr, this message translates to:
  /// **'depuis le {date}'**
  String govSince(String date);

  /// No description provided for @govFromTo.
  ///
  /// In fr, this message translates to:
  /// **'du {debut} au {fin}'**
  String govFromTo(String debut, String fin);

  /// No description provided for @blocRegalien.
  ///
  /// In fr, this message translates to:
  /// **'Régalien'**
  String get blocRegalien;

  /// No description provided for @blocEconomie.
  ///
  /// In fr, this message translates to:
  /// **'Économie'**
  String get blocEconomie;

  /// No description provided for @blocSocial.
  ///
  /// In fr, this message translates to:
  /// **'Social'**
  String get blocSocial;

  /// No description provided for @blocInfrastructure.
  ///
  /// In fr, this message translates to:
  /// **'Infrastructure'**
  String get blocInfrastructure;

  /// No description provided for @blocAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get blocAutre;

  /// No description provided for @asmSearch.
  ///
  /// In fr, this message translates to:
  /// **'Nom, circonscription ou parti'**
  String get asmSearch;

  /// No description provided for @asmFilterGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get asmFilterGroup;

  /// No description provided for @asmFilterRegion.
  ///
  /// In fr, this message translates to:
  /// **'Région'**
  String get asmFilterRegion;

  /// No description provided for @asmAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get asmAll;

  /// No description provided for @asmLegislature.
  ///
  /// In fr, this message translates to:
  /// **'{numero}e législature'**
  String asmLegislature(int numero);

  /// No description provided for @asmSeats.
  ///
  /// In fr, this message translates to:
  /// **'{n} sièges'**
  String asmSeats(int n);

  /// No description provided for @asmNoData.
  ///
  /// In fr, this message translates to:
  /// **'Composition non disponible pour ce pays.'**
  String get asmNoData;

  /// No description provided for @asmSubstitute.
  ///
  /// In fr, this message translates to:
  /// **'Suppléance'**
  String get asmSubstitute;

  /// No description provided for @asmReplaces.
  ///
  /// In fr, this message translates to:
  /// **'Remplace {nom}'**
  String asmReplaces(String nom);

  /// No description provided for @asmNoRollCall.
  ///
  /// In fr, this message translates to:
  /// **'Scrutins nominatifs indisponibles pour cette législature.'**
  String get asmNoRollCall;

  /// No description provided for @asmActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité publiée'**
  String get asmActivity;

  /// No description provided for @asmPresence.
  ///
  /// In fr, this message translates to:
  /// **'Présence en séance'**
  String get asmPresence;

  /// No description provided for @asmWrittenQuestions.
  ///
  /// In fr, this message translates to:
  /// **'Questions écrites'**
  String get asmWrittenQuestions;

  /// No description provided for @asmOralQuestions.
  ///
  /// In fr, this message translates to:
  /// **'Questions orales'**
  String get asmOralQuestions;

  /// No description provided for @asmProposals.
  ///
  /// In fr, this message translates to:
  /// **'Propositions déposées'**
  String get asmProposals;

  /// No description provided for @asmCommittees.
  ///
  /// In fr, this message translates to:
  /// **'Participations en commission'**
  String get asmCommittees;

  /// No description provided for @asmNotPublished.
  ///
  /// In fr, this message translates to:
  /// **'non publié'**
  String get asmNotPublished;

  /// No description provided for @asmActivityNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun indicateur d\'activité publié.'**
  String get asmActivityNone;

  /// No description provided for @asmResults.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun résultat} =1{1 résultat} other{{n} résultats}}'**
  String asmResults(int n);

  /// No description provided for @asmConstituency.
  ///
  /// In fr, this message translates to:
  /// **'Circonscription'**
  String get asmConstituency;

  /// No description provided for @asmGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get asmGroup;

  /// No description provided for @asmNoGroup.
  ///
  /// In fr, this message translates to:
  /// **'Sans groupe'**
  String get asmNoGroup;

  /// No description provided for @personMandates.
  ///
  /// In fr, this message translates to:
  /// **'Mandats'**
  String get personMandates;

  /// No description provided for @personAffiliations.
  ///
  /// In fr, this message translates to:
  /// **'Affiliations'**
  String get personAffiliations;

  /// No description provided for @personCareer.
  ///
  /// In fr, this message translates to:
  /// **'Parcours'**
  String get personCareer;

  /// No description provided for @personPartyPositions.
  ///
  /// In fr, this message translates to:
  /// **'Positions de son parti'**
  String get personPartyPositions;

  /// No description provided for @personPartyPositionsNote.
  ///
  /// In fr, this message translates to:
  /// **'Les positions affichées sont celles du parti, sourcées. Palabre ne positionne jamais une personne.'**
  String get personPartyPositionsNote;

  /// No description provided for @personNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée pour cette personne.'**
  String get personNoData;

  /// No description provided for @personBorn.
  ///
  /// In fr, this message translates to:
  /// **'Né(e) le {date}'**
  String personBorn(String date);

  /// No description provided for @confidenceJournalOfficiel.
  ///
  /// In fr, this message translates to:
  /// **'Journal officiel'**
  String get confidenceJournalOfficiel;

  /// No description provided for @confidenceCommunique.
  ///
  /// In fr, this message translates to:
  /// **'Communiqué officiel'**
  String get confidenceCommunique;

  /// No description provided for @confidenceAgence.
  ///
  /// In fr, this message translates to:
  /// **'Agence de presse'**
  String get confidenceAgence;

  /// No description provided for @confidenceWikidata.
  ///
  /// In fr, this message translates to:
  /// **'Wikidata'**
  String get confidenceWikidata;

  /// No description provided for @confidencePresse.
  ///
  /// In fr, this message translates to:
  /// **'Presse'**
  String get confidencePresse;

  /// No description provided for @motifFinGouvernement.
  ///
  /// In fr, this message translates to:
  /// **'fin du gouvernement'**
  String get motifFinGouvernement;

  /// No description provided for @motifRemaniement.
  ///
  /// In fr, this message translates to:
  /// **'remaniement'**
  String get motifRemaniement;

  /// No description provided for @motifDemission.
  ///
  /// In fr, this message translates to:
  /// **'démission'**
  String get motifDemission;

  /// No description provided for @motifRevocation.
  ///
  /// In fr, this message translates to:
  /// **'révocation'**
  String get motifRevocation;

  /// No description provided for @motifDeces.
  ///
  /// In fr, this message translates to:
  /// **'décès'**
  String get motifDeces;

  /// No description provided for @motifNominationGouvernement.
  ///
  /// In fr, this message translates to:
  /// **'nommé(e) au gouvernement'**
  String get motifNominationGouvernement;

  /// No description provided for @motifFinLegislature.
  ///
  /// In fr, this message translates to:
  /// **'fin de législature'**
  String get motifFinLegislature;

  /// No description provided for @motifInvalidation.
  ///
  /// In fr, this message translates to:
  /// **'invalidation'**
  String get motifInvalidation;

  /// No description provided for @motifAutre.
  ///
  /// In fr, this message translates to:
  /// **'autre'**
  String get motifAutre;

  /// No description provided for @partyMembers.
  ///
  /// In fr, this message translates to:
  /// **'Élus et membres du gouvernement en exercice'**
  String get partyMembers;

  /// No description provided for @partyPositions.
  ///
  /// In fr, this message translates to:
  /// **'Positions déclarées'**
  String get partyPositions;

  /// No description provided for @partyPositionsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune position déclarée dans le questionnaire en cours.'**
  String get partyPositionsNone;

  /// No description provided for @partyHistory.
  ///
  /// In fr, this message translates to:
  /// **'Histoire'**
  String get partyHistory;

  /// No description provided for @partyFounded.
  ///
  /// In fr, this message translates to:
  /// **'Fondé le {date}'**
  String partyFounded(String date);

  /// No description provided for @partyDissolved.
  ///
  /// In fr, this message translates to:
  /// **'Dissous le {date}'**
  String partyDissolved(String date);

  /// No description provided for @relScission.
  ///
  /// In fr, this message translates to:
  /// **'scission de'**
  String get relScission;

  /// No description provided for @relFusion.
  ///
  /// In fr, this message translates to:
  /// **'fusion avec'**
  String get relFusion;

  /// No description provided for @relRenommage.
  ///
  /// In fr, this message translates to:
  /// **'renommage de'**
  String get relRenommage;

  /// No description provided for @relCoalitionMembre.
  ///
  /// In fr, this message translates to:
  /// **'membre de'**
  String get relCoalitionMembre;

  /// No description provided for @relAbsorption.
  ///
  /// In fr, this message translates to:
  /// **'absorbé par'**
  String get relAbsorption;

  /// No description provided for @orgParti.
  ///
  /// In fr, this message translates to:
  /// **'Parti'**
  String get orgParti;

  /// No description provided for @orgCoalition.
  ///
  /// In fr, this message translates to:
  /// **'Coalition'**
  String get orgCoalition;

  /// No description provided for @orgGouvernement.
  ///
  /// In fr, this message translates to:
  /// **'Gouvernement'**
  String get orgGouvernement;

  /// No description provided for @orgAssemblee.
  ///
  /// In fr, this message translates to:
  /// **'Assemblée'**
  String get orgAssemblee;

  /// No description provided for @orgGroupe.
  ///
  /// In fr, this message translates to:
  /// **'Groupe parlementaire'**
  String get orgGroupe;

  /// No description provided for @settingsCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get settingsCountry;

  /// No description provided for @settingsProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get settingsProfile;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Une seule par semaine : l\'ouverture de la question du lundi, et un rappel le samedi si vous n\'avez pas voté.'**
  String get settingsNotificationsDesc;

  /// No description provided for @settingsNotificationsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Notifications non configurées sur cette version.'**
  String get settingsNotificationsUnavailable;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @settingsAboutText.
  ///
  /// In fr, this message translates to:
  /// **'Palabre n\'exprime aucune opinion. Elle pose des questions et documente des faits sourcés. Chaque fait affiché renvoie à sa source.'**
  String get settingsAboutText;

  /// No description provided for @settingsVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {v}'**
  String settingsVersion(String v);

  /// No description provided for @settingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil enregistré.'**
  String get settingsSaved;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get languageSystem;

  /// No description provided for @languageFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFr;

  /// No description provided for @languageEn.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageWo.
  ///
  /// In fr, this message translates to:
  /// **'Wolof'**
  String get languageWo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'wo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'wo':
      return AppLocalizationsWo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
