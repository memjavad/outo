import 'package:flutter/foundation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/store_item.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/repositories/result_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/exam_repository_impl.dart';
import '../../data/repositories/result_repository_impl.dart';
import '../../data/sources/remote/api_auth.dart';
import '../../data/sources/remote/api_exams.dart';
import '../../data/sources/remote/api_results.dart';
import '../../data/sources/remote/api_store.dart';
import '../../data/sources/local/local_storage.dart';
import '../../core/config/app_settings.dart';

class QuizService extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepositoryImpl(remoteDataSource: ApiAuth(), localDataSource: LocalStorage());
  final ExamRepository _examRepo = ExamRepositoryImpl(remoteDataSource: ApiExams(), localDataSource: LocalStorage());
  final ResultRepository _resultRepo = ResultRepositoryImpl(remoteDataSource: ApiResults(), localDataSource: LocalStorage());
  final ApiStore _apiStore = ApiStore();
  final LocalStorage _localStorage = LocalStorage();

  // Core State
  Student? _currentStudent;
  Student? get currentStudent => _currentStudent;

  Map<String, dynamic>? _teacherProfile;
  Map<String, dynamic>? get teacherProfile => _teacherProfile;

  bool _isTeacher = false;
  bool get isTeacher => _isTeacher;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
  String? get lastError => _error; // Legacy Alias

  AppSettings? _settings;
  AppSettings? get settings => _settings;
  AppSettings? get appSettings => _settings; // Legacy Alias
  
  bool get isStudentLoggedIn => _currentStudent != null; // Legacy Alias

  List<QuizQuestion> _questions = [];
  List<QuizQuestion> get questions => _questions; // Legacy Alias

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> init() async {
    final token = await _localStorage.getToken();
    if (token != null) {
      final cachedStudent = await _localStorage.getStudent();
      if (cachedStudent != null) {
        _currentStudent = cachedStudent;
      } else {
        final cachedTeacher = await _localStorage.getTeacher();
        if (cachedTeacher != null) {
          _isTeacher = true;
          _teacherProfile = cachedTeacher;
        }
      }
      notifyListeners();
    } else {
      await logout();
    }
  }

  Future<void> fetchAppSettings() async {
     try {
       _settings = await _examRepo.fetchAppSettings();
       _isOffline = false;
     } catch (_) {
       _isOffline = true;
     }
     notifyListeners();
  }

  // Auth Group
  Future<bool> adminLogin(String username, String password) async => loginTeacher(username, password);

  Future<bool> loginTeacher(String username, String password) async {
    _setLoading(true);
    try {
      final res = await _authRepo.loginTeacher(username, password);
      if (res['success'] == true) {
        _isTeacher = true;
        _teacherProfile = res['teacher'];
        _setLoading(false);
        return true;
      }
      _error = res['error'] ?? 'Login failed';
    } catch (_) {
      _error = 'Network error';
    }
    _setLoading(false);
    return false;
  }

  Future<bool> studentLogin(String phone, String password) async => loginStudent(phone, password);

  Future<bool> loginStudent(String phone, String password) async {
    _setLoading(true);
    try {
      final res = await _authRepo.loginStudent(phone, password);
      if (res['success'] == true) {
        _currentStudent = await _authRepo.fetchStudentProfile(res['token']);
        _setLoading(false);
        return true;
      }
      _error = res['error'] ?? 'Login failed';
    } catch (_) {
      _error = 'Network error';
    }
    _setLoading(false);
    return false;
  }

  Future<bool> studentRegister(String name, String phone, String password, {String? bio}) async => registerStudent(name: name, phone: phone, password: password, bio: bio);

  Future<bool> registerStudent({required String name, required String phone, required String password, String? bio}) async {
    _setLoading(true);
    try {
      final res = await _authRepo.registerStudent(name: name, phone: phone, password: password, bio: bio);
      if (res['success'] == true) {
        _currentStudent = await _authRepo.fetchStudentProfile(res['token']);
        _setLoading(false);
        return true;
      }
      _error = res['error'] ?? 'Registration failed';
    } catch (_) {
      _error = 'Network error';
    }
    _setLoading(false);
    return false;
  }

  Future<void> refreshStudentProfile() async {
    final token = await _localStorage.getToken();
    if (token != null) {
      try {
        _currentStudent = await _authRepo.fetchStudentProfile(token);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> fetchStudentProfile(String token) async {
    _setLoading(true);
    try {
      _currentStudent = await _authRepo.fetchStudentProfile(token);
    } catch (_) {
      _error = 'Profile fetch failed';
    }
    _setLoading(false);
  }

  Future<bool> updateStudentProfile({String? name, String? bio, String? profileImage, String? password}) async {
    _setLoading(true);
    try {
      final token = await _localStorage.getToken();
      if (token == null) return false;
      await _authRepo.updateStudentProfile(token, name: name, bio: bio, profileImage: profileImage, password: password);
      _currentStudent = await _authRepo.fetchStudentProfile(token);
      _setLoading(false);
      return true;
    } catch (_) {
      _error = 'Profile update failed';
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkTgLogin(String sessionId) async {
      return await _authRepo.checkTgLogin(sessionId);
  }

  Future<void> setTelegramUser(Map<String, dynamic> sessionData) async {
      if (sessionData['token'] != null) {
          await _authRepo.saveSession(sessionData['token'], Student.fromJson(sessionData['student']));
          _currentStudent = await _authRepo.fetchStudentProfile(sessionData['token']);
          notifyListeners();
      }
  }

  Future<void> loginWithTelegram(String tgUserId, String tgUsername, String tgFirstName) async {
    _setLoading(true);
    try {
      final res = await _authRepo.loginWithTelegram(tgUserId, tgUsername, tgFirstName);
      if (res['success'] == true) {
        _currentStudent = await _authRepo.fetchStudentProfile(res['token']);
      }
    } catch (_) {}
    _setLoading(false);
  }

  // Store Group
  Future<List<StoreItem>> getStoreItems() async {
    final token = await _localStorage.getToken();
    if (token == null) return [];
    try {
      return await _apiStore.getItems(token);
    } catch (_) {
      return [];
    }
  }

  Future<bool> buyStoreItem(String itemKey) async {
    _setLoading(true);
    try {
      final token = await _localStorage.getToken();
      if (token == null) return false;
      
      final success = await _apiStore.buyItem(itemKey, token);
      if (success) {
        await refreshStudentProfile(); // Instantly visually drains the coin balance & updates inventory!
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> consumeStoreItem(String itemKey) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) return false;
      final success = await _apiStore.consumeItem(itemKey, token);
      if (success) {
        await refreshStudentProfile();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  void logoutStudent() => logout();

  Future<void> logout() async {
    _currentStudent = null;
    _isTeacher = false;
    _teacherProfile = null;
    await _authRepo.logout();
    notifyListeners();
  }

  Future<List<Student>> fetchPendingStudents() async {
    final token = await _localStorage.getToken();
    return await _authRepo.fetchPendingStudents(token ?? '');
  }

  Future<bool> approveStudent(String id) async {
    final token = await _localStorage.getToken();
    return await _authRepo.approveStudent(token ?? '', id);
  }

  Future<bool> rejectStudent(String id) async {
    final token = await _localStorage.getToken();
    return await _authRepo.rejectStudent(token ?? '', id);
  }

  // Exam Group
  Future<List<Exam>> fetchExams() async {
    _setLoading(true);
    try {
       final e = await _examRepo.fetchExams();
       _isOffline = false;
       _setLoading(false);
       return e;
    } catch (_) {
       _isOffline = true;
       _setLoading(false);
       return [];
    }
  }

  Future<List<QuizQuestion>> fetchQuestionsForExam(String examId) async {
    _setLoading(true);
    try {
       _questions = await _examRepo.fetchQuestionsForExam(examId);
       _isOffline = false;
       _setLoading(false);
       return _questions;
    } catch (_) {
       _isOffline = true;
       _setLoading(false);
       return [];
    }
  }

  Future<bool> addExam(String title, {String? description, String examType = 'standard', String? prerequisiteExamId, int unlockCost = 0}) async {
    final token = await _localStorage.getToken();
    return await _examRepo.addExam(token ?? '', title, description: description, examType: examType, prerequisiteExamId: prerequisiteExamId, unlockCost: unlockCost);
  }

  Future<bool> deleteExam(String examId) async {
    final token = await _localStorage.getToken();
    return await _examRepo.deleteExam(token ?? '', examId);
  }

  Future<void> addQuestion(QuizQuestion q) async {
    final token = await _localStorage.getToken();
    await _examRepo.addQuestion(token ?? '', q);
  }

  Future<bool> updateQuestion(QuizQuestion q) async {
    final token = await _localStorage.getToken();
    return await _examRepo.updateQuestion(token ?? '', q);
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String examId) async {
    _setLoading(true);
    try {
      final token = await _localStorage.getToken();
      final lb = await _examRepo.fetchLeaderboard(token ?? '', examId);
      _setLoading(false);
      return lb;
    } catch (_) {
      _setLoading(false);
      return [];
    }
  }

  Future<List<LeaderboardEntry>> fetchCampaignLeaderboard() async {
    _setLoading(true);
    try {
      final token = await _localStorage.getToken();
      final lb = await _examRepo.fetchCampaignLeaderboard(token ?? '');
      _setLoading(false);
      return lb;
    } catch (_) {
      _setLoading(false);
      return [];
    }
  }

  Future<Map<String, dynamic>> validateAccessCode(String accessCode, String examId, String? studentId) async {
    _setLoading(true);
    try {
      final res = await _examRepo.validateAccessCode(accessCode, examId, studentId);
      _setLoading(false);
      return res;
    } catch (_) {
      _setLoading(false);
      return {'success': false, 'error': 'Validation error'};
    }
  }

  Future<ActiveSession?> startExamSession(String studentName, String? examId, int totalQuestions) async {
    try {
      return await _examRepo.startExamSession(studentName, examId, totalQuestions);
    } catch (_) {
      return null;
    }
  }

  Future<void> startSession(String studentName, String? examId, int totalQuestions) async {
      await startExamSession(studentName, examId, totalQuestions);
  }

  Future<void> syncHeartbeat(String sessionId, int currentQuestion, int answeredCount, String status) async {
    try {
      await _examRepo.syncHeartbeat(sessionId, currentQuestion, answeredCount, status);
    } catch (_) {}
  }

  Future<void> heartbeatSession(String studentName, int currentQuestion, int answeredCount) async {
      await syncHeartbeat(studentName, currentQuestion, answeredCount, 'active');
  }

  Future<void> endExamSession(String sessionId) async {
    try {
      await _examRepo.endExamSession(sessionId);
    } catch (_) {}
  }

  // Results Group
  Future<void> submitResult(QuizResult result) async {
     final token = await _localStorage.getToken();
     if (result.examType == 'essay') {
         await submitEssayResult(result, token);
     } else {
         await submitQuizResult(result, token);
     }
  }

  Future<void> submitEssayResult(QuizResult result, String? token) async {
    _setLoading(true);
    try {
      await _resultRepo.submitEssayResult(result, token);
    } catch (_) {
      _error = 'Essay submission cached offline.';
    }
    _setLoading(false);
  }

  Future<void> submitQuizResult(QuizResult result, String? token) async {
    _setLoading(true);
    try {
      await _resultRepo.submitQuizResult(result, token);
    } catch (_) {
      _error = 'Result submission cached offline.';
    }
    _setLoading(false);
  }

  Future<List<QuizResult>> fetchStudentResults() async {
    _setLoading(true);
    try {
      final token = await _localStorage.getToken();
      final res = await _resultRepo.fetchStudentResults(token ?? '');
      _setLoading(false);
      return res;
    } catch (_) {
      _setLoading(false);
      return [];
    }
  }

  Future<List<QuizResult>> fetchStudentHistory(String token) async {
    _setLoading(true);
    try {
      final res = await _resultRepo.fetchStudentHistory(token);
      _setLoading(false);
      return res;
    } catch (_) {
      _setLoading(false);
      return [];
    }
  }

  Future<List<QuizResult>> fetchSpecificExamResults(String token, String examId) async {
    _setLoading(true);
    try {
      final res = await _resultRepo.fetchSpecificExamResults(token, examId);
      _setLoading(false);
      return res;
    } catch (_) {
      _setLoading(false);
      return [];
    }
  }

  Future<List<ActiveSession>> fetchLiveSessions() async {
    final token = await _localStorage.getToken();
    return await _resultRepo.fetchLiveSessions(token ?? '');
  }

  Future<List<QuizResult>> fetchPendingResults() async {
    _setLoading(true);
    try {
      final token = await _localStorage.getToken();
      final res = await _resultRepo.fetchPendingResults(token ?? '');
      _setLoading(false);
      return res;
    } catch (_) {
      _setLoading(false);
      return [];
    }
  }

  Future<bool> gradeResult(String resultId, double scorePercentage, String grade, String? feedback, String studentId, int earnedPoints) async {
    final token = await _localStorage.getToken();
    return await _resultRepo.gradeResult(token ?? '', resultId, scorePercentage, grade, feedback, studentId, earnedPoints);
  }
}
