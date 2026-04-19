import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/entities.dart';
import '../../../core/config/app_config.dart';

class ApiAuth {
  String get baseUrl => AppConfig.apiBaseUrl;

  Future<Map<String, dynamic>> loginTeacher(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'admin_login', 'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') return {'success': true, 'teacher': data};
      }
      return {'success': false, 'error': 'Invalid credentials'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> loginStudent(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=student_login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'token': data['token'], 'student': data['student']};
        }
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> registerStudent({required String name, required String phone, required String password, String? bio}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=student_register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'phone': phone, 'password': password, 'bio': bio}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'token': data['token'], 'student': data['student']};
        }
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  Future<Student> fetchStudentProfile(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=student_profile'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return Student.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      throw Exception('Network error');
    }
  }

  Future<void> updateStudentProfile(String token, {String? name, String? bio, String? profileImage, String? password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=update_student_profile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (profileImage != null) 'profile_image': profileImage,
        if (password != null) 'password': password,
      }),
    );
    if (response.statusCode != 200) throw Exception('Update failed');
  }

  Future<Map<String, dynamic>> loginWithTelegram(String tgUserId, String tgUsername, String tgFirstName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=tg_login&id=$tgUserId&username=$tgUsername&first_name=$tgFirstName'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'token': data['token'], 'student': data['student']};
        }
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>?> checkTgLogin(String sessionId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=check_tg_login&session_id=$sessionId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') return data['data'];
      }
    } catch (e) {}
    return null;
  }

  Future<List<Student>> fetchPendingStudents(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=pending_students'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Student.fromJson(item)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<bool> approveStudent(String token, String studentId) async {
    try {
      final response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: json.encode({'action': 'approve_student', 'id': studentId}));
      return response.statusCode == 200 && json.decode(response.body)['status'] == 'success';
    } catch (e) { return false; }
  }

  Future<bool> rejectStudent(String token, String studentId) async {
    try {
      final response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: json.encode({'action': 'reject_student', 'id': studentId}));
      return response.statusCode == 200 && json.decode(response.body)['status'] == 'success';
    } catch (e) { return false; }
  }
}
