import 'package:flutter/foundation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../data/repositories/exam_repository_impl.dart';
import '../../data/sources/remote/api_exams.dart';
import '../../data/sources/local/local_storage.dart';
import '../../core/config/app_settings.dart';

class ExamProvider extends ChangeNotifier {
  final ExamRepository _repository = ExamRepositoryImpl(remoteDataSource: ApiExams(), localDataSource: LocalStorage());

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AppSettings? _settings;
  AppSettings? get settings => _settings;

  Future<void> loadSettings() async {
    try {
      _settings = await _repository.fetchAppSettings();
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
    }
    notifyListeners();
  }

  Future<List<Exam>> fetchExams() async {
     _setLoading(true);
     try {
        final exams = await _repository.fetchExams();
        _isOffline = false;
        _setLoading(false);
        return exams;
     } catch (e) {
        _isOffline = true;
        _setLoading(false);
        throw Exception('Offline mode constraints');
     }
  }

  Future<List<QuizQuestion>> fetchQuestions(String examId) async {
     _setLoading(true);
     try {
        final qs = await _repository.fetchQuestionsForExam(examId);
        _isOffline = false;
        _setLoading(false);
        return qs;
     } catch (e) {
        _isOffline = true;
        _setLoading(false);
        throw Exception('Offline mode limits.');
     }
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String examId) async {
     _setLoading(true);
     try {
        final token = await LocalStorage().getToken();
        final lb = await _repository.fetchLeaderboard(token ?? '', examId);
        _isOffline = false;
        _setLoading(false);
        return lb;
     } catch (e) {
        _isOffline = true;
        _setLoading(false);
        return [];
     }
  }

  Future<Map<String, dynamic>> validateAccessCode(String accessCode, String examId, String? studentId) async {
    return await _repository.validateAccessCode(accessCode, examId, studentId);
  }

  Future<ActiveSession> startExamSession(String studentName, String? examId, int totalQuestions) async {
    return await _repository.startExamSession(studentName, examId, totalQuestions);
  }

  Future<void> syncHeartbeat(String sessionId, int currentQ, int answered, String status) async {
    try {
       await _repository.syncHeartbeat(sessionId, currentQ, answered, status);
    // ignore: empty_catches
    } catch (e) { } // Silent background failure.
  }

  Future<void> endExamSession(String sessionId) async {
    try {
       await _repository.endExamSession(sessionId);
    // ignore: empty_catches
    } catch (e) {} 
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
