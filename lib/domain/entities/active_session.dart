class ActiveSession {
  final String id;
  final String studentName;
  final String? examId;
  final int currentQuestion;
  final int totalQuestions;
  final int answeredCount;
  final String status;
  final DateTime lastHeartbeat;

  ActiveSession({
    required this.id,
    required this.studentName,
    this.examId,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.answeredCount,
    required this.status,
    required this.lastHeartbeat,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      id: json['id'].toString(),
      studentName: json['student_name'],
      examId: json['exam_id']?.toString(),
      currentQuestion: int.tryParse(json['current_question']?.toString() ?? '0') ?? 0,
      totalQuestions: int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      answeredCount: int.tryParse(json['answered_count']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'active',
      lastHeartbeat: DateTime.tryParse(json['last_heartbeat'] ?? '') ?? DateTime.now(),
    );
  }
}
