import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:student_quiz_app/models/quiz_model.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _MyHttpOverrides();
  });

  test('Test student results parsing', () async {
    final response = await http.get(Uri.parse('https://s.nabuo.org/server/api.php?action=student_results'));
    print('Response: ${response.statusCode}');
    print('Body preview: ${response.body.length > 500 ? response.body.substring(0,500) : response.body}');
    final List<dynamic> data = json.decode(response.body);
    try {
      final results = data.map((item) => QuizResult.fromJson(item)).toList();
      print('SUCCESS Parse Results: ' + results.length.toString());
      if (results.isNotEmpty) {
        print('First result: ${results[0].examTitle} - Score: ${results[0].scorePercentage}%');
      }
    } catch (e, stack) {
      print('FAILED QuizResult.fromJson: $e');
      print(stack);
      fail('Results fail');
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
