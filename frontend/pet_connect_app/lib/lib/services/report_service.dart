// Autor: Wilbert López Veras
// Fecha de creación: 09 de Diciembre de 2025
// Descripción: Servicio para enviar y gestionar reportes de publicaciones y comentarios.

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

  /// Autor: Wilbert López Veras
  /// Fecha: 09-12-2025
  /// Descripción: Envía la carga al endpoint indicado usando el token almacenado.
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

  /// Autor: Wilbert López Veras
  /// Fecha: 09-12-2025
  /// Descripción: Reporta una publicación específica con el motivo indicado.
  Future<void> reportPost(String postId, String reason) async {
    await _postReport(
      endpoint: '/posts/$postId/report',
      reason: reason,
    );
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 09-12-2025
  /// Descripción: Reporta un comentario en base a su identificador.
  Future<void> reportComment(String commentId, String reason) async {
    await _postReport(
      endpoint: '/comments/$commentId/report',
      reason: reason,
    );
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 10-12-2025
  /// Descripción: Obtiene la lista de reportes de publicaciones para moderación.
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

  /// Autor: Wilbert López Veras
  /// Fecha: 10-12-2025
  /// Descripción: Elimina un reporte de publicación una vez revisado.
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

  /// Autor: Wilbert López Veras
  /// Fecha: 10-12-2025
  /// Descripción: Permite a un moderador eliminar una publicación reportada.
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

  /// Autor: Wilbert López Veras
  /// Fecha: 10-12-2025
  /// Descripción: Lista los reportes de comentarios activos para moderación.
  Future<List<Map<String, dynamic>>> getCommentReports() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reports/comments'),
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

  /// Autor: Wilbert López Veras
  /// Fecha: 10-12-2025
  /// Descripción: Permite descartar un reporte de comentario tras la revisión.
  Future<void> ignoreCommentReport(String reportId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión');
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/reports/comments/$reportId'),
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

  /// Autor: Wilbert López Veras
  /// Fecha: 10-12-2025
  /// Descripción: Elimina un comentario reportado usando el endpoint de moderación.
  Future<void> deleteCommentAsModerator(
      String postId, String commentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión');
    }

    final response = await http.delete(
      Uri.parse(
          '${ApiConfig.baseUrl}/posts/$postId/comments/$commentId/moderate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      throw Exception('Comentario no encontrado');
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para eliminar este comentario');
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('No se pudo eliminar el comentario');
    }
  }
}
