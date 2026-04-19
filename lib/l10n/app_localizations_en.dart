// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to Student Quiz';

  @override
  String get welcomeSubtitle => 'Test your knowledge and get graded instantly!';

  @override
  String get enterName => 'Enter your name';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get teacherLogin => 'Teacher Login';

  @override
  String get enterNameError => 'Please enter your name to start';

  @override
  String get question => 'Question';

  @override
  String ofTotal(Object total) {
    return 'of $total';
  }

  @override
  String get quizCompleted => 'Quiz Completed!';

  @override
  String get correctAnswers => 'Correct Answers';

  @override
  String get timeTaken => 'Time Taken';

  @override
  String get backToStart => 'Back to Start';

  @override
  String get loginTitle => 'Teacher Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get invalidLogin => 'Invalid username or password';

  @override
  String get unknownError => 'An error occurred. Please try again.';

  @override
  String timeRemaining(Object minutes, Object seconds) {
    return 'Time Remaining: $minutes:$seconds';
  }

  @override
  String get offlineBanner => '⚠️ Offline Mode – Using Cached Data';

  @override
  String get selectExam => 'Select Exam';

  @override
  String get pleaseSelectExam => 'Please select an Exam';

  @override
  String get pleaseEnterAccessCode => 'Please enter your Access Code';

  @override
  String get accessCode => 'Secret Access Code';

  @override
  String get loginWithTelegram => 'Login with Telegram';

  @override
  String get invalidAccessCode => 'Invalid or unenrolled Access Code.';

  @override
  String get vpnDetected => 'Access Denied: VPN usage detected.';

  @override
  String get biometricFailed => 'Access Denied: Identity not verified.';

  @override
  String examNotStarted(Object date) {
    return 'Exam has not started yet. Starts at: $date';
  }

  @override
  String examEnded(Object date) {
    return 'Exam has ended. Ended at: $date';
  }

  @override
  String get confirmSubmit => 'Confirm Submission';

  @override
  String answeredOf(Object answered, Object total) {
    return 'You answered $answered of $total questions.';
  }

  @override
  String unansweredWarning(Object count) {
    return '⚠️ You have $count unanswered questions!';
  }

  @override
  String get confirmSubmitQuestion => 'Are you sure you want to submit?';

  @override
  String get goBack => 'Go Back';

  @override
  String get submit => 'Submit';

  @override
  String get submitQuiz => 'Submit Quiz';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get nextSave => 'Next / Save';

  @override
  String get typeAnswerHere => 'Type your answer here';

  @override
  String get questionNavigation => 'Question Navigation';

  @override
  String get reviewAnswers => 'Review Answers';

  @override
  String get answerCorrect => 'Correct!';

  @override
  String get answerWrong => 'Wrong!';

  @override
  String get endExam => 'End Exam';

  @override
  String get studentLogin => 'Student Login';

  @override
  String get createAccount => 'Create Account';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get adminTeacherLogin => 'Admin / Teacher Login';

  @override
  String get orLabel => 'OR';

  @override
  String get myProfile => 'My Profile';

  @override
  String get myGrades => 'My Grades';

  @override
  String get availableExams => 'Available Exams';

  @override
  String get noExamsAvailable => 'No exams available at the moment.';

  @override
  String get start => 'Start';

  @override
  String helloStudent(Object name) {
    return 'Hello, $name!';
  }

  @override
  String get readyForChallenge => 'Ready for your next challenge?';

  @override
  String get enterPhoneAndPassword =>
      'Please enter both phone number and password';

  @override
  String get telegramBrowserError => 'Could not open browser to Telegram';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get bio => 'Bio';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get toggleAppearance => 'Toggle app appearance';

  @override
  String get quizHistory => 'Quiz History';

  @override
  String get noQuizzesCompleted => 'No quizzes completed yet.';

  @override
  String get viewAllHistory => 'View All History';

  @override
  String get myQuizHistory => 'My Quiz History';

  @override
  String get noResultsFound => 'No results found yet.';

  @override
  String get generalQuiz => 'General Quiz';

  @override
  String get unknownDate => 'Unknown Date';

  @override
  String questionsCount(Object correct, Object total) {
    return '$correct / $total Questions';
  }

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get noScoresYet => 'No scores yet for this exam!';

  @override
  String get examInstructions => 'Exam Instructions';

  @override
  String get rulesAndParameters => 'Rules & Parameters';

  @override
  String get timeLimit => 'Time Limit';

  @override
  String minutesTotalLimit(Object limit) {
    return '$limit Minutes Total Limit';
  }

  @override
  String get perQuestionLimit => 'Per-Question Limit';

  @override
  String secondsPerQuestionLimit(Object limit) {
    return '$limit Seconds per question. Unanswered questions will be marked incorrect.';
  }

  @override
  String get randomized => 'Randomized';

  @override
  String get randomizedDesc =>
      'Questions and options appear in a completely random order for every student.';

  @override
  String get locationTracking => 'Location Tracking';

  @override
  String get locationTrackingDesc =>
      'Your GPS coordinates will be captured when submitting this exam.';

  @override
  String get noVpnAllowed => 'No VPN Allowed';

  @override
  String get noVpnAllowedDesc =>
      'Active VPN/Proxy connections will instantly flag and block access.';

  @override
  String get biometricVerification => 'Biometric Verification';

  @override
  String get biometricVerificationDesc =>
      'You must verify your identity via FaceID or Fingerprint OS sensors to enter.';

  @override
  String get screenProtection => 'Screen Protection';

  @override
  String get screenRecordDesc =>
      'Your screen will be recorded during the entire exam.';

  @override
  String get preventScreenshotsDesc =>
      'Screenshots and screen recording boundaries are disabled internally for this exam.';

  @override
  String get verifyingContext => 'Verifying Context...';

  @override
  String get acceptBeginExam => 'I Accept, Begin Exam';

  @override
  String get essayHint => 'Write your essay here...';

  @override
  String get campaignRules => 'Campaign Rules & Scoring';

  @override
  String get speedAccuracy => 'Speed & Accuracy';

  @override
  String get speedAccuracyDesc =>
      'Earn 100 Base Points per correct answer. Get +10 Bonus Points for every second left on the clock!';

  @override
  String get comboMultipliers => 'Combo Multipliers';

  @override
  String get comboMultipliersDesc =>
      'Answer correctly in a row to build a Combo! 2-in-a-row grants 1.2x points. 5-in-a-row triggers a 2.0x score multiplier! (Levels 1-25 grant up to 3.0x!)';

  @override
  String get trainingLevels => 'Levels 1 - 50 (Training)';

  @override
  String get trainingLevelsDesc =>
      'No negative penalties. Earning just 50% of the max score grants 1 Star. You only need 18 Stars every 10 levels to unlock the next Chapter.';

  @override
  String get hardcoreLevels => 'Levels 51-200 (Hardcore)';

  @override
  String get hardcoreLevelsDesc =>
      'Incorrect answers instantly deduct 50 points and break your combo! You must maintain a precise 60% passing rate. Chapters require a brutal 24 Stars to unlock.';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get campaignTab => 'Campaign';

  @override
  String get essaysTab => 'Essays';

  @override
  String get examsTab => 'Exams';

  @override
  String get globalStoryPoints => 'Global Story Points';

  @override
  String get analyticsTab => 'Analytics';

  @override
  String get noAvailableExams => 'No exams available for analytics.';

  @override
  String get totalStudents => 'Total Students';

  @override
  String get averageScore => 'Avg Score';

  @override
  String get passRate => 'Pass Rate';

  @override
  String get distractorAnalysis => 'Distractor Analysis';
}
