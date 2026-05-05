// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcomeTitle => 'مرحباً بك في اختبار الطلاب';

  @override
  String get welcomeSubtitle => 'اختبر معلوماتك واحصل على تقييم فوري!';

  @override
  String get enterName => 'أدخل اسمك';

  @override
  String get startQuiz => 'ابدأ الاختبار';

  @override
  String get teacherLogin => 'تسجيل دخول المعلم';

  @override
  String get enterNameError => 'الرجاء إدخال اسمك للبدء';

  @override
  String get question => 'السؤال';

  @override
  String ofTotal(Object total) {
    return 'من $total';
  }

  @override
  String get quizCompleted => 'اكتمل الاختبار!';

  @override
  String get correctAnswers => 'الإجابات الصحيحة';

  @override
  String get timeTaken => 'الوقت المستغرق';

  @override
  String get backToStart => 'العودة للبداية';

  @override
  String get loginTitle => 'تسجيل دخول المعلم';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'دخول';

  @override
  String get invalidLogin => 'اسم المستخدم أو كلمة المرور غير صحيحة';

  @override
  String get unknownError => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String timeRemaining(Object minutes, Object seconds) {
    return 'الوقت المتبقي: $minutes:$seconds';
  }

  @override
  String get offlineBanner =>
      '⚠️ وضع عدم الاتصال – يتم استخدام البيانات المخزنة';

  @override
  String get selectExam => 'اختر الامتحان';

  @override
  String get pleaseSelectExam => 'يرجى اختيار امتحان';

  @override
  String get pleaseEnterAccessCode => 'يرجى إدخال رمز الدخول';

  @override
  String get accessCode => 'رمز الدخول السري';

  @override
  String get loginWithTelegram => 'تسجيل الدخول عبر تيليجرام';

  @override
  String get invalidAccessCode => 'رمز الدخول غير صالح أو غير مسجل.';

  @override
  String get vpnDetected => 'تم رفض الوصول: تم اكتشاف استخدام VPN.';

  @override
  String get biometricFailed => 'تم رفض الوصول: لم يتم التحقق من الهوية.';

  @override
  String examNotStarted(Object date) {
    return 'الامتحان لم يبدأ بعد. يبدأ في: $date';
  }

  @override
  String examEnded(Object date) {
    return 'انتهى وقت الامتحان في: $date';
  }

  @override
  String get confirmSubmit => 'تأكيد التسليم';

  @override
  String answeredOf(Object answered, Object total) {
    return 'أجبت على $answered من $total سؤال.';
  }

  @override
  String unansweredWarning(Object count) {
    return '⚠️ لديك $count سؤال بدون إجابة!';
  }

  @override
  String get confirmSubmitQuestion => 'هل أنت متأكد من تسليم الامتحان؟';

  @override
  String get goBack => 'رجوع';

  @override
  String get submit => 'تسليم';

  @override
  String get submitQuiz => 'إنهاء الامتحان';

  @override
  String get previous => 'السابق';

  @override
  String get next => 'التالي';

  @override
  String get nextSave => 'التالي / حفظ';

  @override
  String get typeAnswerHere => 'اكتب إجابتك هنا';

  @override
  String get questionNavigation => 'أرقام الأسئلة';

  @override
  String get reviewAnswers => 'مراجعة الإجابات';

  @override
  String get answerCorrect => 'صحيح!';

  @override
  String get answerWrong => 'خطأ!';

  @override
  String get endExam => 'إنهاء الامتحان';

  @override
  String get studentLogin => 'تسجيل دخول الطالب';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get signUp => 'تسجيل جديد';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ تسجيل';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب؟ دخول';

  @override
  String get adminTeacherLogin => 'دخول المعلم / الإدارة';

  @override
  String get orLabel => 'أو';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get myGrades => 'درجاتي';

  @override
  String get availableExams => 'الامتحانات المتاحة';

  @override
  String get noExamsAvailable => 'لا توجد امتحانات متاحة حالياً.';

  @override
  String get start => 'ابدأ';

  @override
  String helloStudent(Object name) {
    return 'مرحباً، $name!';
  }

  @override
  String get readyForChallenge => 'هل أنت مستعد للتحدي القادم؟';

  @override
  String get enterPhoneAndPassword => 'الرجاء إدخال رقم الهاتف وكلمة المرور';

  @override
  String get telegramBrowserError => 'تعذر فتح المتصفح للوصول إلى تيليجرام';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get updateFailed => 'فشل التحديث';

  @override
  String get notLoggedIn => 'غير مسجل الدخول';

  @override
  String get bio => 'النبذة التعريفية';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get toggleAppearance => 'تغيير مظهر التطبيق';

  @override
  String get quizHistory => 'سجل الاختبارات';

  @override
  String get noQuizzesCompleted => 'لم تكمل أي اختبارات بعد.';

  @override
  String get viewAllHistory => 'عرض كل السجل';

  @override
  String get myQuizHistory => 'سجل اختباراتي';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج بعد.';

  @override
  String get generalQuiz => 'اختبار عام';

  @override
  String get unknownDate => 'تاريخ غير معروف';

  @override
  String questionsCount(Object correct, Object total) {
    return '$correct / $total أسئلة';
  }

  @override
  String get leaderboard => 'لوحة الصدارة';

  @override
  String get noScoresYet => 'لا توجد درجات حتى الآن لهذا الامتحان!';

  @override
  String get examInstructions => 'تعليمات الامتحان';

  @override
  String get rulesAndParameters => 'القواعد والإعدادات';

  @override
  String get timeLimit => 'الحد الزمني';

  @override
  String minutesTotalLimit(Object limit) {
    return '$limit دقيقة كحد أقصى للوقت';
  }

  @override
  String get perQuestionLimit => 'وقت لكل سؤال';

  @override
  String secondsPerQuestionLimit(Object limit) {
    return '$limit ثانية لكل سؤال. سيتم احتساب الأسئلة غير المجابة كإجابات خاطئة.';
  }

  @override
  String get randomized => 'ترتيب عشوائي';

  @override
  String get randomizedDesc =>
      'تظهر الأسئلة والخيارات بترتيب عشوائي تماماً لكل طالب.';

  @override
  String get locationTracking => 'تتبع الموقع';

  @override
  String get locationTrackingDesc =>
      'سيتم تسجيل إحداثيات GPS الخاصة بك عند تسليم هذا الامتحان.';

  @override
  String get noVpnAllowed => 'شبكات VPN غير مسموحة';

  @override
  String get noVpnAllowedDesc =>
      'اتصالات VPN/البروكسي النشطة ستقوم بحظر الوصول فوراً.';

  @override
  String get biometricVerification => 'التحقق البيومتري';

  @override
  String get biometricVerificationDesc =>
      'يجب عليك التحقق من هويتك عبر مستشعرات بصمة الوجه أو الأصبع للدخول.';

  @override
  String get screenProtection => 'حماية الشاشة';

  @override
  String get screenRecordDesc => 'سيتم تسجيل شاشتك خلال مدة الامتحان بأكملها.';

  @override
  String get preventScreenshotsDesc =>
      'تم تعطيل أخذ لقطات الشاشة وتسجيلها داخلياً لهذا الامتحان.';

  @override
  String get verifyingContext => 'جاري التحقق...';

  @override
  String get acceptBeginExam => 'أوافق، ابدأ الامتحان';

  @override
  String get essayHint => 'اكتب مقالتك هنا...';

  @override
  String get campaignRules => 'قواعد الحملة وتسجيل النقاط';

  @override
  String get speedAccuracy => 'السرعة والدقة';

  @override
  String get speedAccuracyDesc =>
      'اكسب 100 نقطة أساسية لكل إجابة صحيحة. احصل على +10 نقاط إضافية عن كل ثانية متبقية في الوقت!';

  @override
  String get comboMultipliers => 'مضاعفات الكومبو (السلسلة)';

  @override
  String get comboMultipliersDesc =>
      'أجب إجابات صحيحة متتالية لبناء كومبو! إجابتان متتاليتان تمنح 1.2x. 5 إجابات تفعّل مضاعف 2.0x! (المستويات 1-25 تمنح حتى 3.0x!)';

  @override
  String get trainingLevels => 'المستويات 1 - 50 (تدريب)';

  @override
  String get trainingLevelsDesc =>
      'لا توجد خصومات على الأخطاء. الحصول على 50% فقط من النتيجة القصوى يمنحك نجمة. تحتاج فقط 18 نجمة كل 10 مستويات لفتح الفصل التالي.';

  @override
  String get hardcoreLevels => 'المستويات 51-200 (صعوبة عالية)';

  @override
  String get hardcoreLevelsDesc =>
      'الإجابات الخاطئة تخصم 50 نقطة فوراً وتكسر السلسلة! يجب الحفاظ على معدل نجاح 60%. الفصول تتطلب 24 نجمة لفتحها.';

  @override
  String get iUnderstand => 'أنا أفهم';

  @override
  String get campaignTab => 'الحملة';

  @override
  String get essaysTab => 'الواجبات البيتية';

  @override
  String get examsTab => 'الامتحانات';

  @override
  String get globalStoryPoints => 'نقاط الحملة العالمية';

  @override
  String get analyticsTab => 'التحليلات';

  @override
  String get noAvailableExams => 'لا توجد امتحانات متاحة للتحليل.';

  @override
  String get totalStudents => 'إجمالي الطلاب';

  @override
  String get averageScore => 'متوسط الدرجات';

  @override
  String get passRate => 'نسبة النجاح';

  @override
  String get distractorAnalysis => 'تحليل الخيارات الخاطئة';

  @override
  String get info => 'معلومات';

  @override
  String get store => 'المتجر';

  @override
  String get deleteExam => 'حذف الامتحان';

  @override
  String get deleteEssay => 'حذف الواجب';

  @override
  String get deleteCampaign => 'حذف الحملة';

  @override
  String get approve => 'قبول';

  @override
  String get reject => 'رفض';
}
