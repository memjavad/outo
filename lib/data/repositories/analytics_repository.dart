import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../domain/entities/analytics_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AnalyticsRepository {
  String get baseUrl => AppConfig.apiBaseUrl;
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async => await _storage.read(key: 'admin_token');

  Future<ExamKPI> fetchExamKPIs(String examId) async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl?action=get_exam_kpis&exam_id=$examId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          return ExamKPI.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return ExamKPI.empty();
  }

  Future<List<DistractorData>> fetchDistractorAnalysis(String examId) async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl?action=get_distractor_analysis&exam_id=$examId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          final List<dynamic> list = data['data'];
          return list.map((e) => DistractorData.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
