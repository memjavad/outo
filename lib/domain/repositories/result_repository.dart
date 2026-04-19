import '../entities/result.dart';
import '../entities/active_session.dart';

abstract class ResultRepository {
  Future<void> submitQuizResult(QuizResult result, String? token);
  Future<void> submitEssayResult(QuizResult result, String? token);
  Future<List<QuizResult>> fetchStudentResults(String token);
  Future<List<QuizResult>> fetchStudentHistory(String token);
  Future<List<QuizResult>> fetchSpecificExamResults(String token, String examId);
  Future<List<ActiveSession>> fetchLiveSessions(String token);
  Future<List<QuizResult>> fetchPendingResults(String token);
  Future<bool> gradeResult(String token, String resultId, double scorePercentage, String grade, String? feedback, String studentId, int earnedPoints);
}
