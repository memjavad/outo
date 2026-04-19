import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:student_quiz_app/models/quiz_model.dart';
import 'dart:io';

void main() {
  setUpAll(() {
    HttpOverrides.global = _MyHttpOverrides();
  });

  test('Test settings parsing', () async {
    final response = await http.get(Uri.parse('https://s.nabuo.org/server/api.php?action=settings'));
    final Map<String, dynamic> data = json.decode(response.body);
    
    try {
      final settings = AppSettings.fromMap(data);
      print('SUCCESS Parse Settings: ' + settings.appTitle);
    } catch (e, stack) {
      print('FAILED AppSettings.fromMap: $e');
      print(stack);
      fail('Settings fail');
    }
  });

  test('Test exams parsing', () async {
    final response = await http.get(Uri.parse('https://s.nabuo.org/server/api.php?action=exams'));
    final List<dynamic> data = json.decode(response.body);
    try {
      final exams = data.map((item) => Exam.fromJson(item)).toList();
      print('SUCCESS Parse Exams: ' + exams.length.toString());
    } catch (e, stack) {
      print('FAILED Exam.fromJson: $e');
      print(stack);
      fail('Exams fail');
    }
  });

  test('Test questions parsing', () async {
    final response = await http.get(Uri.parse('https://s.nabuo.org/server/api.php?action=questions'));
    final List<dynamic> data = json.decode(response.body);
    try {
      final q = data.map((item) => QuizQuestion.fromJson(item)).toList();
      print('SUCCESS Parse Questions: ' + q.length.toString());
    } catch (e, stack) {
      print('FAILED QuizQuestion.fromJson: $e');
      print(stack);
      fail('Questions fail');
    }
  });
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
