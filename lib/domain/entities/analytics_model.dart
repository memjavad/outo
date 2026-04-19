class ExamKPI {
  final int totalStudents;
  final double averageScore;
  final int averageTimeSeconds;
  final double passRate;

  ExamKPI({
    required this.totalStudents,
    required this.averageScore,
    required this.averageTimeSeconds,
    required this.passRate,
  });

  factory ExamKPI.fromJson(Map<String, dynamic> json) {
    return ExamKPI(
      totalStudents: json['total_students'] ?? 0,
      averageScore: (json['average_score'] ?? 0).toDouble(),
      averageTimeSeconds: json['average_time_seconds'] ?? 0,
      passRate: (json['pass_rate'] ?? 0).toDouble(),
    );
  }

  factory ExamKPI.empty() => ExamKPI(totalStudents: 0, averageScore: 0, averageTimeSeconds: 0, passRate: 0);
}

class DistractorOption {
  final int optionIndex;
  final double percentage;

  DistractorOption({required this.optionIndex, required this.percentage});

  factory DistractorOption.fromJson(Map<String, dynamic> json) {
    return DistractorOption(
      optionIndex: json['option_index'] ?? -1,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class DistractorData {
  final String questionId;
  final String questionText;
  final int totalAnswers;
  final List<DistractorOption> distractors;

  DistractorData({
    required this.questionId,
    required this.questionText,
    required this.totalAnswers,
    required this.distractors,
  });

  factory DistractorData.fromJson(Map<String, dynamic> json) {
    var list = json['distractors'] as List? ?? [];
    return DistractorData(
      questionId: json['question_id']?.toString() ?? '',
      questionText: json['question_text'] ?? '',
      totalAnswers: json['total_answers'] ?? 0,
      distractors: list.map((e) => DistractorOption.fromJson(e)).toList(),
    );
  }
}
