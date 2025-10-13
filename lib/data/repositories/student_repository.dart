import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StudentRepository {
  final String baseUrl;

  StudentRepository()
    : baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api/v1';

  /// Fetch logged-in student profile
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final url = '$baseUrl/student/me/';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'error': body['message'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
