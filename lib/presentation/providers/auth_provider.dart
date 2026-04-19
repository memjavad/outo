import 'package:flutter/foundation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/sources/remote/api_auth.dart';
import '../../data/sources/local/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepositoryImpl(remoteDataSource: ApiAuth(), localDataSource: LocalStorage());
  final LocalStorage _localStorage = LocalStorage();

  Student? _currentStudent;
  Student? get currentStudent => _currentStudent;

  Map<String, dynamic>? _teacherProfile;
  Map<String, dynamic>? get teacherProfile => _teacherProfile;

  bool _isTeacher = false;
  bool get isTeacher => _isTeacher;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> init() async {
    final token = await _localStorage.getToken();
    if (token != null) {
      final cachedStudent = await _localStorage.getStudent();
      if (cachedStudent != null) {
        _currentStudent = cachedStudent;
        notifyListeners();
      }
    }
  }

  Future<bool> loginStudent(String phone, String password) async {
    _setLoading(true);
    try {
      final result = await _repository.loginStudent(phone, password);
      if (result['success'] == true) {
         _currentStudent = await _repository.fetchStudentProfile(result['token']);
         _setLoading(false);
         return true;
      }
      _error = result['error'] ?? 'Login failed';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Network error during login.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerStudent({required String name, required String phone, required String password, String? bio}) async {
    _setLoading(true);
    try {
      final result = await _repository.registerStudent(name: name, phone: phone, password: password, bio: bio);
      if (result['success'] == true) {
         _currentStudent = await _repository.fetchStudentProfile(result['token']);
         _setLoading(false);
         return true;
      }
      _error = result['error'] ?? 'Registration failed';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Network error during registration.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> loginTeacher(String username, String password) async {
    _setLoading(true);
    try {
      final result = await _repository.loginTeacher(username, password);
      if (result['success'] == true) {
         _isTeacher = true;
         _teacherProfile = result['teacher'];
         _setLoading(false);
         return true;
      }
      _error = result['error'] ?? 'Invalid admin credentials.';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Network error logging in.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> loginWithTelegram(String tgUserId, String tgUsername, String tgFirstName) async {
     _setLoading(true);
     try {
       final result = await _repository.loginWithTelegram(tgUserId, tgUsername, tgFirstName);
       if (result['success'] == true) {
          _currentStudent = await _repository.fetchStudentProfile(result['token']);
       }
     } catch (_) {
       _error = 'Telegram auth failed';
     }
     _setLoading(false);
  }

  Future<void> updateProfile({String? name, String? bio, String? profileImage, String? password}) async {
    _setLoading(true);
    try {
        final token = await _localStorage.getToken();
        if (token != null) {
           await _repository.updateStudentProfile(token, name: name, bio: bio, profileImage: profileImage, password: password);
           _currentStudent = await _repository.fetchStudentProfile(token);
        }
    } catch (e) {
        _error = 'Update failed';
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    _currentStudent = null;
    _isTeacher = false;
    _teacherProfile = null;
    await _repository.logout();
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
