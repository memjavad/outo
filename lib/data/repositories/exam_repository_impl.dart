import '../../domain/repositories/exam_repository.dart';
import '../../domain/entities/entities.dart';
import '../../core/config/app_settings.dart';
import '../sources/remote/api_exams.dart';
import '../sources/local/local_storage.dart';

class ExamRepositoryImpl implements ExamRepository {
  final ApiExams remoteDataSource;
  final LocalStorage localDataSource;

  ExamRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<AppSettings> fetchAppSettings() async {
    try {
      final res = await remoteDataSource.fetchAppSettings();
      await localDataSource.saveSettingsCache(res);
      return res;
    } catch (_) {
      final cached = await localDataSource.getSettingsCache();
      if (cached != null) return cached;
      return AppSettings.defaultSettings();
    }
  }

  @override
  Future<List<Exam>> fetchExams() async {
    try {
      final exams = await remoteDataSource.fetchExams();
      await localDataSource.saveExamsCache(exams);
      return exams;
    } catch (_) {
      final cached = await localDataSource.getExamsCache();
      if (cached != null) return cached;
      throw Exception('Failed to fetch exams natively offline.');
    }
  }

  @override
  Future<List<QuizQuestion>> fetchQuestionsForExam(String examId) async {
    try {
      final questions = await remoteDataSource.fetchQuestionsForExam(examId);
      await localDataSource.saveQuestionsCache(examId, questions);
      return questions;
    } catch (_) {
      final cached = await localDataSource.getQuestionsCache(examId);
      if (cached != null) return cached;
      throw Exception('Failed to fetch questions natively offline.');
    }
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(String token, String examId) async {
     return await remoteDataSource.fetchLeaderboard(token, examId);
  }

  @override
  Future<List<LeaderboardEntry>> fetchCampaignLeaderboard(String token) async {
     return await remoteDataSource.fetchCampaignLeaderboard(token);
  }

  @override
  Future<Map<String, dynamic>> validateAccessCode(String accessCode, String examId, String? studentId) async {
    return await remoteDataSource.validateAccessCode(accessCode, examId, studentId);
  }

  @override
  Future<ActiveSession> startExamSession(String studentName, String? examId, int totalQuestions) async {
    return await remoteDataSource.startExamSession(studentName, examId, totalQuestions);
  }

  @override
  Future<void> syncHeartbeat(String sessionId, int currentQuestion, int answeredCount, String status) async {
    await remoteDataSource.syncHeartbeat(sessionId, currentQuestion, answeredCount, status);
  }

  @override
  Future<void> endExamSession(String sessionId) async {
    await remoteDataSource.endExamSession(sessionId);
  }

  @override
  Future<bool> addQuestion(String token, QuizQuestion question) async {
    return await remoteDataSource.addQuestion(question); // Implementation handles header inside ApiExams using static inject natively now
  }

  @override
  Future<bool> updateQuestion(String token, QuizQuestion question) async {
    return await remoteDataSource.updateQuestion(question);
  }

  @override
  Future<bool> deleteQuestion(String token, String id) async {
    return false; // Deprecated directly in older API routing via non-typed `?id` fetch. We'll bypass.
  }

  @override
  Future<bool> addExam(String token, String title, {String? description, String examType = 'standard', String? prerequisiteExamId, int unlockCost = 0}) async {
    return await remoteDataSource.addExam(title, description: description, examType: examType, prerequisiteExamId: prerequisiteExamId, unlockCost: unlockCost);
  }

  @override
  Future<bool> deleteExam(String token, String examId) async {
    return await remoteDataSource.deleteExam(examId);
  }
}
