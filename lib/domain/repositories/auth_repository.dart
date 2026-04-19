import '../entities/student.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> loginTeacher(String username, String password);
  Future<Map<String, dynamic>> loginStudent(String phone, String password);
  Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String phone,
    required String password,
    String? bio,
  });
  Future<Student> fetchStudentProfile(String token);
  Future<void> updateStudentProfile(String token, {String? name, String? bio, String? profileImage, String? password});
  Future<Map<String, dynamic>> loginWithTelegram(String tgUserId, String tgUsername, String tgFirstName);
  Future<Map<String, dynamic>?> checkTgLogin(String sessionId);
  Future<void> saveSession(String token, Student student);
  Future<void> logout();
  Future<void> clearCache();
  Future<List<Student>> fetchPendingStudents(String token);
  Future<bool> approveStudent(String token, String studentId);
  Future<bool> rejectStudent(String token, String studentId);
}
