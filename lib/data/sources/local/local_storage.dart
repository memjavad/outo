import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../domain/entities/entities.dart';
import '../../../core/config/app_settings.dart';

List<dynamic> _decodeList(String data) => jsonDecode(data) as List<dynamic>;

class LocalStorage {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jwt_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('jwt_timestamp');
    if (timestamp != null) {
      final loginDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final daysPassed = DateTime.now().difference(loginDate).inDays;
      if (daysPassed >= 14) {
        await deleteToken();
        return null;
      }
    }
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_timestamp');
    await prefs.remove('teacher_data');
  }

  Future<void> saveTeacher(Map<String, dynamic> teacher) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teacher_data', jsonEncode(teacher));
  }

  Future<Map<String, dynamic>?> getTeacher() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('teacher_data');
    if (data != null) {
      try {
        return jsonDecode(data);
      } catch (e) {
        return null; // Handle corrupt local cache
      }
    }
    return null;
  }

  Future<void> saveStudent(Student student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_data', jsonEncode(student.toJson()));
  }

  Future<Student?> getStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('student_data');
    if (data != null) {
      try {
        return Student.fromJson(jsonDecode(data));
      } catch (e) {
        return null; // Handle corrupt local cache
      }
    }
    return null;
  }

  Future<void> deleteStudent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_data');
  }

  Future<void> saveExamsCache(List<Exam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = await compute(jsonEncode, exams.map((e) => e.toJson()).toList());
    await prefs.setString('cached_exams', encoded);
  }

  Future<List<Exam>?> getExamsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cached_exams');
    if (data != null) {
      try {
        List<dynamic> parsed = await compute(_decodeList, data);
        return parsed.map((e) => Exam.fromJson(e)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveQuestionsCache(String examId, List<QuizQuestion> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = await compute(jsonEncode, questions.map((q) => q.toJson()).toList());
    await prefs.setString('cached_questions_$examId', encoded);
  }

  Future<List<QuizQuestion>?> getQuestionsCache(String examId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cached_questions_$examId');
    if (data != null) {
      try {
        List<dynamic> parsed = await compute(_decodeList, data);
        return parsed.map((q) => QuizQuestion.fromJson(q)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> savePendingResult(QuizResult result) async {
    // Basic offline syncing queue
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList('pending_results') ?? [];
    
    // Convert entity into raw string payload manually mapped since we lack direct nested string overrides on the class mapping.
    pending.add(jsonEncode({
      'student_name': result.studentName,
      'exam_id': result.examId,
      'total_questions': result.totalQuestions,
      'correct_answers': result.correctAnswers,
      'time_taken_seconds': result.timeTaken.inSeconds,
      'gps_location': result.gpsLocation,
      'cheat_flag': result.cheatFlag,
      'answers_json': result.answersJson,
    }));
    await prefs.setStringList('pending_results', pending);
  }

  Future<List<Map<String, dynamic>>> getPendingResults() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList('pending_results') ?? [];
    return pending.map((str) => jsonDecode(str) as Map<String, dynamic>).toList();
  }

  Future<void> clearPendingResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_results');
  }

  Future<void> saveSettingsCache(AppSettings settings) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_title', settings.appTitle);
      await prefs.setString('primary_color', settings.primaryColorHex);
      await prefs.setString('tg_bot_username', settings.tgBotUsername);
      await prefs.setBool('require_access_code', settings.requireAccessCode);
      await prefs.setString('flex_color_scheme', settings.flexColorScheme);
  }

  Future<AppSettings?> getSettingsCache() async {
      final prefs = await SharedPreferences.getInstance();
      final title = prefs.getString('app_title');
      if (title != null) {
          return AppSettings(
              appTitle: title,
              primaryColorHex: prefs.getString('primary_color') ?? '#673AB7',
              tgBotUsername: prefs.getString('tg_bot_username') ?? '',
              requireAccessCode: prefs.getBool('require_access_code') ?? false,
              flexColorScheme: prefs.getString('flex_color_scheme') ?? 'blueWhale',
          );
      }
      return null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await deleteToken();
  }
}
