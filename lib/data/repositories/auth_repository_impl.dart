import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/entities.dart';
import '../sources/remote/api_auth.dart';
import '../sources/local/local_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiAuth remoteDataSource;
  final LocalStorage localDataSource;

  AuthRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Map<String, dynamic>> loginTeacher(String username, String password) async {
    final response = await remoteDataSource.loginTeacher(username, password);
    if (response['success'] == true && response['token'] != null) {
      await localDataSource.saveToken(response['token']);
      if (response['teacher'] != null) {
        await localDataSource.saveTeacher(response['teacher']);
      }
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> loginStudent(String phone, String password) async {
    final response = await remoteDataSource.loginStudent(phone, password);
    if (response['success'] == true && response['token'] != null) {
      await localDataSource.saveToken(response['token']);
      if (response['student'] != null) {
         await localDataSource.saveStudent(Student.fromJson(response['student']));
      }
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String phone,
    required String password,
    String? bio,
  }) async {
    final response = await remoteDataSource.registerStudent(name: name, phone: phone, password: password, bio: bio);
    if (response['success'] == true && response['token'] != null) {
      await localDataSource.saveToken(response['token']);
      if (response['student'] != null) {
         await localDataSource.saveStudent(Student.fromJson(response['student']));
      }
    }
    return response;
  }

  @override
  Future<Student> fetchStudentProfile(String token) async {
    try {
       final student = await remoteDataSource.fetchStudentProfile(token);
       await localDataSource.saveStudent(student);
       return student;
    } catch (e) {
       final cached = await localDataSource.getStudent();
       if (cached != null) return cached;
       rethrow;
    }
  }

  @override
  Future<void> updateStudentProfile(String token, {String? name, String? bio, String? profileImage, String? password}) async {
    await remoteDataSource.updateStudentProfile(token, name: name, bio: bio, profileImage: profileImage, password: password);
    // Profile fetch implicitly updates local cache natively.
    await fetchStudentProfile(token);
  }

  @override
  Future<Map<String, dynamic>> loginWithTelegram(String tgUserId, String tgUsername, String tgFirstName) async {
    final response = await remoteDataSource.loginWithTelegram(tgUserId, tgUsername, tgFirstName);
    if (response['success'] == true && response['token'] != null) {
      await localDataSource.saveToken(response['token']);
      if (response['student'] != null) {
         await localDataSource.saveStudent(Student.fromJson(response['student']));
      }
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>?> checkTgLogin(String sessionId) async {
    return await remoteDataSource.checkTgLogin(sessionId);
  }

  @override
  Future<void> saveSession(String token, Student student) async {
    await localDataSource.saveToken(token);
    await localDataSource.saveStudent(student);
  }

  @override
  Future<List<Student>> fetchPendingStudents(String token) async {
    return await remoteDataSource.fetchPendingStudents(token);
  }

  @override
  Future<bool> approveStudent(String token, String studentId) async {
    return await remoteDataSource.approveStudent(token, studentId);
  }

  @override
  Future<bool> rejectStudent(String token, String studentId) async {
    return await remoteDataSource.rejectStudent(token, studentId);
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearAll();
  }

  @override
  Future<void> clearCache() async {
    await localDataSource.clearAll();
  }
}
