import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClerkRepository {
  final String baseUrl;

  ClerkRepository()
    : baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:3000';

  Future<Map<String, dynamic>> fetchProfile(String clerkId) async {
    try {
      final url = '$baseUrl/clerk/$clerkId/profile';
      final response = await http.get(Uri.parse(url));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'error': body['message']};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getStudents() async {
    try {
      final url = '$baseUrl/clerk/students';
      final response = await http.get(Uri.parse(url));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'error': body['message']};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getTeachers() async {
    try {
      final url = '$baseUrl/clerk/teachers';
      final response = await http.get(Uri.parse(url));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'error': body['message']};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createTeacher(
    Map<String, dynamic> teacher,
  ) async {
    try {
      final url = '$baseUrl/clerk/create-teacher';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(teacher),
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'error': body['message']};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
