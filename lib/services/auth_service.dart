import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/pengaturan_url.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrl.login),
        body: {
          'username': username,
          'password': password,
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
    String? address,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrl.register),
        body: {
          'username': username,
          'password': password,
          'email': email,
          'full_name': fullName,
          'address': address,
          'phone': phone,
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}