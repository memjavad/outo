import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../domain/entities/store_item.dart';

class ApiStore {
  final String _baseUrl = AppConfig.productionHost;

  Future<List<StoreItem>> getItems(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/server/api.php?action=store_items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['items'] != null) {
        return (data['items'] as List).map((i) => StoreItem.fromJson(i)).toList();
      }
    }
    throw Exception('Failed to load store items');
  }

  Future<bool> buyItem(String itemKey, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/server/api.php?action=buy_item'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'item_key': itemKey}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      final err = json.decode(response.body)['error'] ?? 'Unknown error';
      throw Exception(err);
    }
  }

  Future<bool> consumeItem(String itemKey, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/server/api.php?action=consume_item'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'item_key': itemKey}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      final err = json.decode(response.body)['error'] ?? 'Unknown error';
      throw Exception(err);
    }
  }
}
