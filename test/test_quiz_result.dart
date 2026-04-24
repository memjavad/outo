import 'dart:convert';
import 'package:student_quiz_app/domain/entities/result.dart';
void main() {
  final jsonStr = '''{
    "id": 1,
    "student_name": "Test",
    "total_questions": 10,
    "correct_answers": 8,
    "time_taken_seconds": 120,
    "answers_json": "",
    "created_at": null
  }''';
  try {
    final result = QuizResult.fromJson(json.decode(jsonStr));
    print('SUCCESS: ' + result.studentName);
  } catch (e) {
    print('FAILED: $e');
  }
  
  final jsonStr2 = '''{
    "id": 1,
    "student_name": "Test2",
    "total_questions": "10",
    "correct_answers": "8",
    "time_taken_seconds": "120",
    "answers_json": null,
    "created_at": "2023-10-10 10:10:10"
  }''';
  try {
    final result = QuizResult.fromJson(json.decode(jsonStr2));
    print('SUCCESS 2: ' + result.studentName);
  } catch (e) {
    print('FAILED 2: $e');
  }
}
