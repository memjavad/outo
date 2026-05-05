import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Student Quiz'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge and get graded instantly!'**
  String get welcomeSubtitle;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuiz;

  /// No description provided for @teacherLogin.
  ///
  /// In en, this message translates to:
  /// **'Teacher Login'**
  String get teacherLogin;

  /// No description provided for @enterNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name to start'**
  String get enterNameError;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String ofTotal(Object total);

  /// No description provided for @quizCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quiz Completed!'**
  String get quizCompleted;

  /// No description provided for @correctAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get correctAnswers;

  /// No description provided for @timeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time Taken'**
  String get timeTaken;

  /// No description provided for @backToStart.
  ///
  /// In en, this message translates to:
  /// **'Back to Start'**
  String get backToStart;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Login'**
  String get loginTitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @invalidLogin.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidLogin;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get unknownError;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining: {minutes}:{seconds}'**
  String timeRemaining(Object minutes, Object seconds);

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Offline Mode – Using Cached Data'**
  String get offlineBanner;

  /// No description provided for @selectExam.
  ///
  /// In en, this message translates to:
  /// **'Select Exam'**
  String get selectExam;

  /// No description provided for @pleaseSelectExam.
  ///
  /// In en, this message translates to:
  /// **'Please select an Exam'**
  String get pleaseSelectExam;

  /// No description provided for @pleaseEnterAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Access Code'**
  String get pleaseEnterAccessCode;

  /// No description provided for @accessCode.
  ///
  /// In en, this message translates to:
  /// **'Secret Access Code'**
  String get accessCode;

  /// No description provided for @loginWithTelegram.
  ///
  /// In en, this message translates to:
  /// **'Login with Telegram'**
  String get loginWithTelegram;

  /// No description provided for @invalidAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or unenrolled Access Code.'**
  String get invalidAccessCode;

  /// No description provided for @vpnDetected.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: VPN usage detected.'**
  String get vpnDetected;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: Identity not verified.'**
  String get biometricFailed;

  /// No description provided for @examNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Exam has not started yet. Starts at: {date}'**
  String examNotStarted(Object date);

  /// No description provided for @examEnded.
  ///
  /// In en, this message translates to:
  /// **'Exam has ended. Ended at: {date}'**
  String examEnded(Object date);

  /// No description provided for @confirmSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm Submission'**
  String get confirmSubmit;

  /// No description provided for @answeredOf.
  ///
  /// In en, this message translates to:
  /// **'You answered {answered} of {total} questions.'**
  String answeredOf(Object answered, Object total);

  /// No description provided for @unansweredWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ You have {count} unanswered questions!'**
  String unansweredWarning(Object count);

  /// No description provided for @confirmSubmitQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit?'**
  String get confirmSubmitQuestion;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz'**
  String get submitQuiz;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextSave.
  ///
  /// In en, this message translates to:
  /// **'Next / Save'**
  String get nextSave;

  /// No description provided for @typeAnswerHere.
  ///
  /// In en, this message translates to:
  /// **'Type your answer here'**
  String get typeAnswerHere;

  /// No description provided for @questionNavigation.
  ///
  /// In en, this message translates to:
  /// **'Question Navigation'**
  String get questionNavigation;

  /// No description provided for @reviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review Answers'**
  String get reviewAnswers;

  /// No description provided for @answerCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get answerCorrect;

  /// No description provided for @answerWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong!'**
  String get answerWrong;

  /// No description provided for @endExam.
  ///
  /// In en, this message translates to:
  /// **'End Exam'**
  String get endExam;

  /// No description provided for @studentLogin.
  ///
  /// In en, this message translates to:
  /// **'Student Login'**
  String get studentLogin;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @adminTeacherLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin / Teacher Login'**
  String get adminTeacherLogin;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @myGrades.
  ///
  /// In en, this message translates to:
  /// **'My Grades'**
  String get myGrades;

  /// No description provided for @availableExams.
  ///
  /// In en, this message translates to:
  /// **'Available Exams'**
  String get availableExams;

  /// No description provided for @noExamsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No exams available at the moment.'**
  String get noExamsAvailable;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @helloStudent.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloStudent(Object name);

  /// No description provided for @readyForChallenge.
  ///
  /// In en, this message translates to:
  /// **'Ready for your next challenge?'**
  String get readyForChallenge;

  /// No description provided for @enterPhoneAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both phone number and password'**
  String get enterPhoneAndPassword;

  /// No description provided for @telegramBrowserError.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser to Telegram'**
  String get telegramBrowserError;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @toggleAppearance.
  ///
  /// In en, this message translates to:
  /// **'Toggle app appearance'**
  String get toggleAppearance;

  /// No description provided for @quizHistory.
  ///
  /// In en, this message translates to:
  /// **'Quiz History'**
  String get quizHistory;

  /// No description provided for @noQuizzesCompleted.
  ///
  /// In en, this message translates to:
  /// **'No quizzes completed yet.'**
  String get noQuizzesCompleted;

  /// No description provided for @viewAllHistory.
  ///
  /// In en, this message translates to:
  /// **'View All History'**
  String get viewAllHistory;

  /// No description provided for @myQuizHistory.
  ///
  /// In en, this message translates to:
  /// **'My Quiz History'**
  String get myQuizHistory;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found yet.'**
  String get noResultsFound;

  /// No description provided for @generalQuiz.
  ///
  /// In en, this message translates to:
  /// **'General Quiz'**
  String get generalQuiz;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown Date'**
  String get unknownDate;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{correct} / {total} Questions'**
  String questionsCount(Object correct, Object total);

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @noScoresYet.
  ///
  /// In en, this message translates to:
  /// **'No scores yet for this exam!'**
  String get noScoresYet;

  /// No description provided for @examInstructions.
  ///
  /// In en, this message translates to:
  /// **'Exam Instructions'**
  String get examInstructions;

  /// No description provided for @rulesAndParameters.
  ///
  /// In en, this message translates to:
  /// **'Rules & Parameters'**
  String get rulesAndParameters;

  /// No description provided for @timeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time Limit'**
  String get timeLimit;

  /// No description provided for @minutesTotalLimit.
  ///
  /// In en, this message translates to:
  /// **'{limit} Minutes Total Limit'**
  String minutesTotalLimit(Object limit);

  /// No description provided for @perQuestionLimit.
  ///
  /// In en, this message translates to:
  /// **'Per-Question Limit'**
  String get perQuestionLimit;

  /// No description provided for @secondsPerQuestionLimit.
  ///
  /// In en, this message translates to:
  /// **'{limit} Seconds per question. Unanswered questions will be marked incorrect.'**
  String secondsPerQuestionLimit(Object limit);

  /// No description provided for @randomized.
  ///
  /// In en, this message translates to:
  /// **'Randomized'**
  String get randomized;

  /// No description provided for @randomizedDesc.
  ///
  /// In en, this message translates to:
  /// **'Questions and options appear in a completely random order for every student.'**
  String get randomizedDesc;

  /// No description provided for @locationTracking.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTracking;

  /// No description provided for @locationTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Your GPS coordinates will be captured when submitting this exam.'**
  String get locationTrackingDesc;

  /// No description provided for @noVpnAllowed.
  ///
  /// In en, this message translates to:
  /// **'No VPN Allowed'**
  String get noVpnAllowed;

  /// No description provided for @noVpnAllowedDesc.
  ///
  /// In en, this message translates to:
  /// **'Active VPN/Proxy connections will instantly flag and block access.'**
  String get noVpnAllowedDesc;

  /// No description provided for @biometricVerification.
  ///
  /// In en, this message translates to:
  /// **'Biometric Verification'**
  String get biometricVerification;

  /// No description provided for @biometricVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'You must verify your identity via FaceID or Fingerprint OS sensors to enter.'**
  String get biometricVerificationDesc;

  /// No description provided for @screenProtection.
  ///
  /// In en, this message translates to:
  /// **'Screen Protection'**
  String get screenProtection;

  /// No description provided for @screenRecordDesc.
  ///
  /// In en, this message translates to:
  /// **'Your screen will be recorded during the entire exam.'**
  String get screenRecordDesc;

  /// No description provided for @preventScreenshotsDesc.
  ///
  /// In en, this message translates to:
  /// **'Screenshots and screen recording boundaries are disabled internally for this exam.'**
  String get preventScreenshotsDesc;

  /// No description provided for @verifyingContext.
  ///
  /// In en, this message translates to:
  /// **'Verifying Context...'**
  String get verifyingContext;

  /// No description provided for @acceptBeginExam.
  ///
  /// In en, this message translates to:
  /// **'I Accept, Begin Exam'**
  String get acceptBeginExam;

  /// No description provided for @essayHint.
  ///
  /// In en, this message translates to:
  /// **'Write your essay here...'**
  String get essayHint;

  /// No description provided for @campaignRules.
  ///
  /// In en, this message translates to:
  /// **'Campaign Rules & Scoring'**
  String get campaignRules;

  /// No description provided for @speedAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Speed & Accuracy'**
  String get speedAccuracy;

  /// No description provided for @speedAccuracyDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn 100 Base Points per correct answer. Get +10 Bonus Points for every second left on the clock!'**
  String get speedAccuracyDesc;

  /// No description provided for @comboMultipliers.
  ///
  /// In en, this message translates to:
  /// **'Combo Multipliers'**
  String get comboMultipliers;

  /// No description provided for @comboMultipliersDesc.
  ///
  /// In en, this message translates to:
  /// **'Answer correctly in a row to build a Combo! 2-in-a-row grants 1.2x points. 5-in-a-row triggers a 2.0x score multiplier! (Levels 1-25 grant up to 3.0x!)'**
  String get comboMultipliersDesc;

  /// No description provided for @trainingLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels 1 - 50 (Training)'**
  String get trainingLevels;

  /// No description provided for @trainingLevelsDesc.
  ///
  /// In en, this message translates to:
  /// **'No negative penalties. Earning just 50% of the max score grants 1 Star. You only need 18 Stars every 10 levels to unlock the next Chapter.'**
  String get trainingLevelsDesc;

  /// No description provided for @hardcoreLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels 51-200 (Hardcore)'**
  String get hardcoreLevels;

  /// No description provided for @hardcoreLevelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Incorrect answers instantly deduct 50 points and break your combo! You must maintain a precise 60% passing rate. Chapters require a brutal 24 Stars to unlock.'**
  String get hardcoreLevelsDesc;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @campaignTab.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaignTab;

  /// No description provided for @essaysTab.
  ///
  /// In en, this message translates to:
  /// **'Essays'**
  String get essaysTab;

  /// No description provided for @examsTab.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get examsTab;

  /// No description provided for @globalStoryPoints.
  ///
  /// In en, this message translates to:
  /// **'Global Story Points'**
  String get globalStoryPoints;

  /// No description provided for @analyticsTab.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTab;

  /// No description provided for @noAvailableExams.
  ///
  /// In en, this message translates to:
  /// **'No exams available for analytics.'**
  String get noAvailableExams;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Avg Score'**
  String get averageScore;

  /// No description provided for @passRate.
  ///
  /// In en, this message translates to:
  /// **'Pass Rate'**
  String get passRate;

  /// No description provided for @distractorAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Distractor Analysis'**
  String get distractorAnalysis;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @deleteExam.
  ///
  /// In en, this message translates to:
  /// **'Delete Exam'**
  String get deleteExam;

  /// No description provided for @deleteEssay.
  ///
  /// In en, this message translates to:
  /// **'Delete Essay'**
  String get deleteEssay;

  /// No description provided for @deleteCampaign.
  ///
  /// In en, this message translates to:
  /// **'Delete Campaign'**
  String get deleteCampaign;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
