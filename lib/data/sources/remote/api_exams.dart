import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/entities.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_settings.dart';

List<QuizQuestion> parseQuestions(String responseBody) {
  final List<dynamic> data = json.decode(responseBody);
  return data.map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>)).toList();
}

List<Exam> parseExams(String responseBody) {
  final List<dynamic> data = json.decode(responseBody);
  return data.map((item) => Exam.fromJson(item as Map<String, dynamic>)).toList();
}

List<LeaderboardEntry> parseLeaderboard(String responseBody) {
  final data = json.decode(responseBody) as Map<String, dynamic>;
  if (data['status'] == 'success') {
    final List<dynamic> l = data['leaderboard'];
    return l.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
}

class ApiExams {
  String get baseUrl => AppConfig.apiBaseUrl;

  Future<List<QuizQuestion>> fetchQuestionsForExam(String examId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=questions&exam_id=$examId'));
      if (response.statusCode == 200) {
        final qs = await compute(parseQuestions, response.body);
        return qs.where((q) => q.examId == examId).toList();
      }
    } catch (e) {
      debugPrint('Error fetching questions: $e');
    }
    return [];
  }

  Future<List<Exam>> fetchExams() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=exams'));
      if (response.statusCode == 200) {
        return await compute(parseExams, response.body);
      }
    } catch (e) {
      debugPrint('Error fetching exams: $e');
    }
    return [];
  }

  Future<bool> addExam(String title, {String? description, String examType = 'standard', String? prerequisiteExamId, int unlockCost = 0}) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'add_exam', 
          'title': title, 
          'description': description,
          'exam_type': examType,
          if (prerequisiteExamId != null) 'prerequisite_exam_id': prerequisiteExamId,
          'unlock_cost': unlockCost
        }),
      );
      return response.statusCode == 200 && json.decode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteExam(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl?action=delete_exam&id=$id'));
      return response.statusCode == 200 && json.decode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  Future<bool> addQuestion(QuizQuestion question) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=add_question'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question': question.question,
          'options': question.options,
          'correctAnswerIndex': question.correctAnswerIndex,
          'examId': question.examId,
        }),
      );
      return response.statusCode == 200 && json.decode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateQuestion(QuizQuestion question) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'update_question',
          'id': question.id,
          'question': question.question,
          'richText': question.richText,
          'options': question.options,
          'correctAnswerIndex': question.correctAnswerIndex,
          'categoryId': question.categoryId,
        }),
      );
      return response.statusCode == 200 && json.decode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  Future<AppSettings> fetchAppSettings() async {
    try {
        final response = await http.get(Uri.parse('$baseUrl?action=settings'));
        if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == 'success') {
                return AppSettings.fromMap(data['data']);
            }
        }
    } catch (_) {}
    return AppSettings.defaultSettings();
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String token, String examId) async {
      try {
          final res = await http.get(
            Uri.parse('$baseUrl?action=get_leaderboard&exam_id=$examId'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (res.statusCode == 200) {
              return await compute(parseLeaderboard, res.body);
          }
      } catch (_) {}
      return [];
  }

  Future<List<LeaderboardEntry>> fetchCampaignLeaderboard(String token) async {
      try {
          final res = await http.get(
            Uri.parse('$baseUrl?action=get_campaign_leaderboard'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (res.statusCode == 200) {
              return await compute(parseLeaderboard, res.body);
          }
      } catch (_) {}
      return [];
  }

  Future<Map<String, dynamic>> validateAccessCode(String accessCode, String examId, String? studentId) async {
      try {
          final res = await http.get(Uri.parse('$baseUrl?action=check_access_code&access_code=$accessCode'));
          if (res.statusCode == 200) {
              final data = json.decode(res.body);
              return {'success': data['status'] == 'success', 'student': data['student']};
          }
      } catch (_) {}
      return {'success': false};
  }

  Future<ActiveSession> startExamSession(String studentName, String? examId, int totalQuestions) async {
      await http.post(Uri.parse(baseUrl), body: json.encode({
          'action': 'start_session', 'studentName': studentName, 'examId': examId, 'totalQuestions': totalQuestions
      }));
      return ActiveSession(id: '', studentName: studentName, currentQuestion: 0, totalQuestions: totalQuestions, answeredCount: 0, status: 'active', lastHeartbeat: DateTime.now());
  }

  Future<void> syncHeartbeat(String sessionId, int currentQuestion, int answeredCount, String status) async {
     await http.post(Uri.parse(baseUrl), body: json.encode({
          'action': 'heartbeat_session', 'sessionId': sessionId, 'currentQuestion': currentQuestion, 'answeredCount': answeredCount
      }));
  }

  Future<void> endExamSession(String sessionId) async {}
}
