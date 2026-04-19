import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/entities.dart';
import '../../../core/config/app_config.dart';

List<QuizResult> parseResults(String responseBody) {
  final List<dynamic> data = json.decode(responseBody);
  return data.map((item) => QuizResult.fromJson(item as Map<String, dynamic>)).toList();
}

class ApiResults {
  String get baseUrl => AppConfig.apiBaseUrl;

  Future<void> submitQuizResult(QuizResult result, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=submit_result'),
      headers: token != null ? {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
      body: json.encode({
        'action': 'submit_result',
        'student_name': result.studentName,
        'studentName': result.studentName,
        'studentId': 0, // Fallback integer mapping
        'exam_id': result.examId,
        'examId': result.examId,
        'total_questions': result.totalQuestions,
        'totalQuestions': result.totalQuestions,
        'correct_answers': result.correctAnswers,
        'correctAnswers': result.correctAnswers,
        'time_taken_seconds': result.timeTaken.inSeconds,
        'timeTakenSeconds': result.timeTaken.inSeconds,
        'scorePercentage': result.scorePercentage,
        'gps_location': result.gpsLocation,
        'gpsLocation': result.gpsLocation,
        'cheat_flag': result.cheatFlag,
        'cheatFlag': result.cheatFlag,
        'answers_json': result.answersJson,
        'answersJson': result.answersJson,
        'is_graded': result.examType == 'essay' ? 0 : 1,
        'isGraded': result.examType == 'essay' ? 0 : 1,
        'earned_stars': result.earnedStars,
        'campaign_score': result.campaignScore,
      }),
    );
    if (response.statusCode != 200) throw Exception('Submit failed');
  }

  Future<void> submitEssayResult(QuizResult result, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=submit_essay_result'),
      headers: token != null ? {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
      body: json.encode({
        'action': 'submit_essay_result', // Targets the new dedicated endpoint
        'student_name': result.studentName,
        'studentName': result.studentName,
        'student_id': 0,
        'studentId': 0,
        'exam_id': result.examId,
        'examId': result.examId,
        'total_questions': result.totalQuestions,
        'totalQuestions': result.totalQuestions,
        'correct_answers': result.correctAnswers,
        'correctAnswers': result.correctAnswers,
        'time_taken_seconds': result.timeTaken.inSeconds,
        'timeTakenSeconds': result.timeTaken.inSeconds,
        'score_percentage': result.scorePercentage,
        'scorePercentage': result.scorePercentage,
        'gps_location': result.gpsLocation,
        'gpsLocation': result.gpsLocation,
        'cheat_flag': result.cheatFlag,
        'cheatFlag': result.cheatFlag,
        'answers_json': result.answersJson,
        'answersJson': result.answersJson,
        'is_graded': 0,
        'isGraded': 0,
      }),
    );
    if (response.statusCode != 200) throw Exception('Submit Essay failed');
  }

  Future<List<QuizResult>> fetchStudentResults(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=student_results'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return await compute(parseResults, response.body);
      }
    } catch (e) {}
    return [];
  }

  Future<List<QuizResult>> fetchStudentHistory(String token) async {
    return await fetchStudentResults(token);
  }

  Future<List<QuizResult>> fetchSpecificExamResults(String token, String examId) async {
    final res = await fetchStudentResults(token);
    return res.where((r) => r.examId == examId).toList();
  }

  Future<List<ActiveSession>> fetchLiveSessions(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=live_sessions'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => ActiveSession.fromJson(item)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<QuizResult>> fetchPendingResults(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=pending_grading'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return await compute(parseResults, response.body);
      }
    } catch (e) {}
    return [];
  }

  Future<bool> gradeResult(String token, String resultId, double scorePercentage, String grade, String? feedback, String studentId, int earnedPoints) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'grade_result',
          'id': resultId,
          'score_percentage': scorePercentage,
          'grade': grade,
          'feedback': feedback ?? '',
          'student_id': studentId,
          'earned_points': earnedPoints
        }),
      );
      return response.statusCode == 200 && json.decode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
}
