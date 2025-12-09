import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pet_connect_app/lib/config/api_config.dart';

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> _postReport({
    required String endpoint,
    required String reason,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión para reportar');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 400) {
      throw Exception('Ya has reportado esto');
    }

    throw Exception('No se pudo enviar el reporte');
  }

  Future<void> reportPost(String postId, String reason) async {
    await _postReport(
      endpoint: '/posts/$postId/report',
      reason: reason,
    );
  }

  Future<void> reportComment(String commentId, String reason) async {
    await _postReport(
      endpoint: '/comments/$commentId/report',
      reason: reason,
    );
  }

  Future<List<Map<String, dynamic>>> getPostReports() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reports/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para ver los reportes');
    }

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los reportes');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> ignorePostReport(String reportId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión');
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/reports/posts/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      throw Exception('Reporte no encontrado');
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para esta acción');
    }

    if (response.statusCode != 200) {
      throw Exception('No se pudo ignorar el reporte');
    }
  }

  Future<void> deletePostAsModerator(String postId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión');
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/moderate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      throw Exception('Post no encontrado');
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para eliminar este post');
    }

    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar el post');
    }
  }
}
