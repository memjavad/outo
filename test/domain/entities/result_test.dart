import 'package:flutter_test/flutter_test.dart';
import 'package:student_quiz_app/domain/entities/result.dart';

void main() {
  group('QuizResult getGrade', () {
    test('returns server grade if present', () {
      final result = QuizResult(
        studentName: 'Test',
        totalQuestions: 10,
        correctAnswers: 5,
        timeTaken: Duration.zero,
        serverGrade: 'A+',
      );
      expect(result.getGrade(), 'A+');
    });

    test('returns default F when below 60', () {
      final result = QuizResult(
        studentName: 'Test',
        totalQuestions: 10,
        correctAnswers: 5, // 50%
        timeTaken: Duration.zero,
      );
      expect(result.getGrade(), 'F');
    });

    test('returns correct grade from default scale', () {
      final resultA = QuizResult(studentName: 'A', totalQuestions: 10, correctAnswers: 9, timeTaken: Duration.zero); // 90%
      final resultB = QuizResult(studentName: 'B', totalQuestions: 10, correctAnswers: 8, timeTaken: Duration.zero); // 80%
      final resultC = QuizResult(studentName: 'C', totalQuestions: 10, correctAnswers: 7, timeTaken: Duration.zero); // 70%
      final resultD = QuizResult(studentName: 'D', totalQuestions: 10, correctAnswers: 6, timeTaken: Duration.zero); // 60%

      expect(resultA.getGrade(), 'A');
      expect(resultB.getGrade(), 'B');
      expect(resultC.getGrade(), 'C');
      expect(resultD.getGrade(), 'D');
    });

    test('returns correct grade using custom scale', () {
      final result = QuizResult(studentName: 'Test', totalQuestions: 100, correctAnswers: 85, timeTaken: Duration.zero); // 85%
      final customScale = {'Distinction': 80, 'Pass': 50};
      expect(result.getGrade(gradingScale: customScale), 'Distinction');
    });

    test('handles zero total questions gracefully', () {
      final result = QuizResult(
        studentName: 'Test',
        totalQuestions: 0,
        correctAnswers: 0,
        timeTaken: Duration.zero,
      );
      expect(result.scorePercentage, 0.0);
      expect(result.getGrade(), 'F');
    });

    test('grade getter uses getGrade()', () {
      final result = QuizResult(studentName: 'A', totalQuestions: 10, correctAnswers: 9, timeTaken: Duration.zero);
      expect(result.grade, 'A');
    });
  });
}
