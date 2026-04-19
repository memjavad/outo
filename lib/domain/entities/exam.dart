bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  final str = value.toString().toLowerCase().trim();
  return str == '1' || str == 'true' || str == 'yes' || str == 'on';
}

class Exam {
  final String id;
  final String title;
  final String? description;
  final bool isActive;
  final String? prerequisiteExamId;
  final int unlockCost;
  final String examType;
  
  // 18 UI/Behavior/Security Properties overrides
  final int examTimerMinutes;
  final bool randomizeQuestions;
  final bool randomizeOptions;
  final bool strictAppFocus;
  final int questionTimerSeconds;
  final bool requireGps;
  final bool recordScreen;
  final bool preventScreenshots;
  final bool detectVpn;
  final bool requireBiometrics;
  final bool requireTgLogin;
  final bool allowReview;
  final bool allowBacktracking;
  final String examStartDate;
  final String examEndDate;
  final bool recordAudio;
  final bool immediateFeedback;

  Exam({
    required this.id,
    required this.title,
    this.description,
    this.isActive = true,
    this.examTimerMinutes = 10,
    this.randomizeQuestions = true,
    this.randomizeOptions = true,
    this.strictAppFocus = false,
    this.questionTimerSeconds = 0,
    this.requireGps = false,
    this.recordScreen = false,
    this.preventScreenshots = false,
    this.detectVpn = false,
    this.requireBiometrics = false,
    this.requireTgLogin = false,
    this.allowReview = false,
    this.allowBacktracking = false,
    this.examStartDate = '',
    this.examEndDate = '',
    this.recordAudio = false,
    this.immediateFeedback = false,
    this.prerequisiteExamId,
    this.unlockCost = 0,
    this.examType = 'standard',
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      isActive: _parseBool(json['is_active'], defaultValue: true),
      examTimerMinutes: int.tryParse(json['exam_timer']?.toString() ?? '10') ?? 10,
      randomizeQuestions: _parseBool(json['randomize_questions'], defaultValue: true),
      randomizeOptions: _parseBool(json['randomize_options'], defaultValue: true),
      strictAppFocus: _parseBool(json['strict_app_focus'], defaultValue: false),
      questionTimerSeconds: int.tryParse(json['question_timer']?.toString() ?? '0') ?? 0,
      requireGps: _parseBool(json['require_gps'], defaultValue: false),
      recordScreen: _parseBool(json['record_screen'], defaultValue: false),
      preventScreenshots: _parseBool(json['prevent_screenshots'], defaultValue: false),
      detectVpn: _parseBool(json['detect_vpn'], defaultValue: false),
      requireBiometrics: _parseBool(json['require_biometrics'], defaultValue: false),
      requireTgLogin: _parseBool(json['require_tg_login'], defaultValue: false),
      allowReview: _parseBool(json['allow_review'], defaultValue: false),
      allowBacktracking: _parseBool(json['allow_backtracking'], defaultValue: false),
      examStartDate: json['exam_start_date'] ?? '',
      examEndDate: json['exam_end_date'] ?? '',
      recordAudio: _parseBool(json['record_audio'], defaultValue: false),
      immediateFeedback: _parseBool(json['immediate_feedback'], defaultValue: false),
      prerequisiteExamId: (json['prerequisite_exam_id'] == null || json['prerequisite_exam_id'].toString().trim().isEmpty || json['prerequisite_exam_id'].toString() == '0') ? null : json['prerequisite_exam_id'].toString(),
      unlockCost: int.tryParse(json['unlock_cost']?.toString() ?? '0') ?? 0,
      examType: json['exam_type']?.toString() ?? 'standard',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_active': isActive,
      'exam_timer': examTimerMinutes,
      'randomize_questions': randomizeQuestions,
      'randomize_options': randomizeOptions,
      'strict_app_focus': strictAppFocus,
      'question_timer': questionTimerSeconds,
      'require_gps': requireGps,
      'record_screen': recordScreen,
      'prevent_screenshots': preventScreenshots,
      'detect_vpn': detectVpn,
      'require_biometrics': requireBiometrics,
      'require_tg_login': requireTgLogin,
      'allow_review': allowReview,
      'allow_backtracking': allowBacktracking,
      'exam_start_date': examStartDate,
      'exam_end_date': examEndDate,
      'record_audio': recordAudio,
      'immediate_feedback': immediateFeedback,
      'prerequisite_exam_id': prerequisiteExamId,
      'unlock_cost': unlockCost,
      'exam_type': examType,
    };
  }
}
