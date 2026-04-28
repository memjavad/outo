import '../../domain/repositories/result_repository.dart';
import '../../domain/entities/entities.dart';
import '../sources/remote/api_results.dart';
import '../sources/local/local_storage.dart';

class ResultRepositoryImpl implements ResultRepository {
  final ApiResults remoteDataSource;
  final LocalStorage localDataSource;

  ResultRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<void> submitQuizResult(QuizResult result, String? token) async {
    try {
      await remoteDataSource.submitQuizResult(result, token);
      
      // If we are back online, aggressively batch sync any heavily pending results natively.
      final pending = await localDataSource.getPendingResults();
      if (pending.isNotEmpty) {
        for (var p in pending) {
          try {
             final pendingResult = QuizResult(
               studentName: p['student_name'] ?? 'Unknown',
               examId: p['exam_id'],
               totalQuestions: int.tryParse(p['total_questions']?.toString() ?? '0') ?? 0,
               correctAnswers: int.tryParse(p['correct_answers']?.toString() ?? '0') ?? 0,
               timeTaken: Duration(seconds: int.tryParse(p['time_taken_seconds']?.toString() ?? '0') ?? 0),
               gpsLocation: p['gps_location'],
               cheatFlag: p['cheat_flag'],
               answersJson: p['answers_json'],
             );
             await remoteDataSource.submitQuizResult(pendingResult, token);
          } catch (_) { }
        }
        await localDataSource.clearPendingResults();
      }
    } catch (_) {
      // Hardware offline, shift entirely to pending queue mapping cache natively!
      await localDataSource.savePendingResult(result);
    }
  }

  @override
  Future<void> submitEssayResult(QuizResult result, String? token) async {
    try {
      await remoteDataSource.submitEssayResult(result, token);
    } catch (_) {
      await localDataSource.savePendingResult(result);
    }
  }

  @override
  Future<List<QuizResult>> fetchStudentResults(String token) async {
     return await remoteDataSource.fetchStudentResults(token);
  }

  @override
  Future<List<QuizResult>> fetchStudentHistory(String token) async {
     return await remoteDataSource.fetchStudentHistory(token);
  }

  @override
  Future<List<QuizResult>> fetchSpecificExamResults(String token, String examId) async {
     return await remoteDataSource.fetchSpecificExamResults(token, examId);
  }

  @override
  Future<List<ActiveSession>> fetchLiveSessions(String token) async {
     return await remoteDataSource.fetchLiveSessions(token);
  }

  @override
  Future<List<QuizResult>> fetchPendingResults(String token) async {
     return await remoteDataSource.fetchPendingResults(token);
  }

  @override
  Future<bool> gradeResult(String token, String resultId, double scorePercentage, String grade, String? feedback, String studentId, int earnedPoints) async {
     return await remoteDataSource.gradeResult(token, resultId, scorePercentage, grade, feedback, studentId, earnedPoints);
  }
}
