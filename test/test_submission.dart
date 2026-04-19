import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  HttpOverrides.global = _MyHttpOverrides();

  final payload = {
    'action': 'save_result',
    'studentName': 'Test AI Student',
    'scorePercentage': 90.0,
    'grade': 'A',
    'totalQuestions': 10,
    'correctAnswers': 9,
    'timeTakenSeconds': 120,
    'examId': '1'
  };

  print('Sending payload: $payload');
  final response = await http.post(
    Uri.parse('https://s.nabuo.org/server/api.php'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(payload),
  );

  print('Response code: ${response.statusCode}');
  print('Response body: ${response.body}');
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
