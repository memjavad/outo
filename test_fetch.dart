import 'dart:convert';
import 'dart:io';
import 'lib/domain/entities/entities.dart';
import 'lib/core/config/app_config.dart';

void main() async {
  // Override bad certs for testing
  HttpOverrides.global = _MyHttpOverrides();
  
  print('API Base URL: ${AppConfig.apiBaseUrl}');
  
  try {
    var request = await HttpClient().getUrl(Uri.parse('${AppConfig.apiBaseUrl}?action=settings'));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    print('Response status: ${response.statusCode}');
    print('Response body preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) : responseBody}');
    
    final data = json.decode(responseBody);
    final settings = AppSettings.fromMap(data);
    print('Parsed AppSettings successfully: ${settings.appTitle}');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
