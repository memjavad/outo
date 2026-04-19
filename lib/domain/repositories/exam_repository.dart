import '../entities/exam.dart';
import '../entities/question.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/active_session.dart';
import '../../core/config/app_settings.dart';

abstract class ExamRepository {
  Future<AppSettings> fetchAppSettings();
  Future<List<Exam>> fetchExams();
  Future<List<QuizQuestion>> fetchQuestionsForExam(String examId);
  Future<List<LeaderboardEntry>> fetchLeaderboard(String token, String examId);
  Future<List<LeaderboardEntry>> fetchCampaignLeaderboard(String token);
  Future<Map<String, dynamic>> validateAccessCode(String accessCode, String examId, String? studentId);
  Future<ActiveSession> startExamSession(String studentName, String? examId, int totalQuestions);
  Future<void> syncHeartbeat(String sessionId, int currentQuestion, int answeredCount, String status);
  Future<void> endExamSession(String sessionId);

  Future<bool> addQuestion(String token, QuizQuestion question);
  Future<bool> updateQuestion(String token, QuizQuestion question);
  Future<bool> deleteQuestion(String token, String id);
  Future<bool> addExam(String token, String title, {String? description, String examType = 'standard', String? prerequisiteExamId, int unlockCost = 0});
  Future<bool> deleteExam(String token, String examId);
}
