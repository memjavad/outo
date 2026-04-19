import 'dart:convert';

class QuizResult {
  final String? id;
  final String studentName;
  final String? examId;
  final String? examTitle; // Joined from exams table
  final int totalQuestions;
  final int correctAnswers;
  final Duration timeTaken;
  final String? gpsLocation;
  final String? cheatFlag;
  final Map<String, dynamic>? answersJson;
  final DateTime? createdAt;
  final int pointsEarned;
  final int earnedStars;
  final int campaignScore;
  final String? examType;
  final bool isGraded;
  final String? teacherFeedback;
  final double? _serverScorePercentage;
  final String? _serverGrade;

  QuizResult({
    this.id,
    required this.studentName,
    this.examId,
    this.examTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeTaken,
    this.gpsLocation,
    this.cheatFlag,
    this.answersJson,
    this.createdAt,
    this.pointsEarned = 0,
    this.earnedStars = 0,
    this.campaignScore = 0,
    this.examType,
    this.isGraded = true,
    this.teacherFeedback,
    double? serverScorePct,
    String? serverGrade,
  }) : _serverScorePercentage = serverScorePct,
       _serverGrade = serverGrade;

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id']?.toString(),
      studentName: json['student_name'] ?? '',
      examId: json['exam_id']?.toString(),
      examTitle: json['exam_title'],
      totalQuestions: int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      correctAnswers: int.tryParse(json['correct_answers']?.toString() ?? '0') ?? 0,
      timeTaken: Duration(seconds: int.tryParse(json['time_taken_seconds']?.toString() ?? '0') ?? 0),
      gpsLocation: json['gps_location'],
      cheatFlag: json['cheat_flag'],
      answersJson: () {
        var a = json['answers_json'];
        if (a is String && a.trim().isNotEmpty) {
          try { return (jsonDecode(a) as Map?)?.cast<String, dynamic>(); } catch (_) { return null; }
        } else if (a is Map) {
          return a.cast<String, dynamic>();
        }
        return null;
      }(),
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      pointsEarned: int.tryParse(json['points_earned']?.toString() ?? '0') ?? 0,
      earnedStars: int.tryParse(json['earned_stars']?.toString() ?? '0') ?? 0,
      campaignScore: int.tryParse(json['campaign_score']?.toString() ?? '0') ?? 0,
      examType: json['exam_type']?.toString(),
      isGraded: json['is_graded']?.toString() == '1' || json['is_graded'] == true || json['is_graded'] == null,
      teacherFeedback: json['teacher_feedback']?.toString(),
      serverScorePct: json['score_percentage'] != null ? double.tryParse(json['score_percentage'].toString()) : null,
      serverGrade: json['grade']?.toString(),
    );
  }

  double get scorePercentage => _serverScorePercentage ?? (totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100);

  String getGrade({Map<String, int>? gradingScale}) {
    if (_serverGrade != null && _serverGrade!.isNotEmpty) return _serverGrade!;
    final scale = gradingScale ?? {'A': 90, 'B': 80, 'C': 70, 'D': 60};
    final sorted = scale.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (var entry in sorted) {
      if (scorePercentage >= entry.value) return entry.key;
    }
    return 'F';
  }

  String get grade => getGrade();
}
