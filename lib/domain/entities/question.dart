class QuizQuestion {
  final String id;
  final String? categoryId;
  final String? examId;
  final String question;
  final String? richText;
  final String? imageUrl;
  final String questionType;
  final List<String> options;
  final int correctAnswerIndex;
  final int points;

  QuizQuestion({
    required this.id,
    this.categoryId,
    this.examId,
    required this.question,
    this.richText,
    this.imageUrl,
    this.questionType = 'single',
    required this.options,
    required this.correctAnswerIndex,
    this.points = 1,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'].toString(),
      categoryId: json['categoryId']?.toString(),
      examId: json['exam_id']?.toString() ?? json['examId']?.toString(),
      question: json['question'] ?? json['question_text'] ?? '',
      richText: json['richText'] ?? json['rich_text'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
      questionType: json['questionType'] ?? json['question_type'] ?? 'single',
      options: json['options'] != null ? List<String>.from(json['options']) : [],
      correctAnswerIndex: json['correctAnswerIndex'] ?? json['correct_answer_index'] ?? 0,
      points: int.tryParse(json['points']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'examId': examId,
      'question': question,
      'richText': richText,
      'imageUrl': imageUrl,
      'questionType': questionType,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'points': points,
    };
  }
}
