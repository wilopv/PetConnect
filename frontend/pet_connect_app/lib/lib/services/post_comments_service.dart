// Autor: Wilbert López Veras
// Fecha de creación: 06 de Diciembre de 2025
// Descripción: Servicio HTTP para administrar los comentarios de las publicaciones.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';

class PostCommentsService {
  PostCommentsService._();

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      throw Exception('No hay sesión activa');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 06-12-2025
  /// Descripción: Obtiene los comentarios asociados al post indicado.
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron obtener los comentarios');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 06-12-2025
  /// Descripción: Publica un nuevo comentario enviando su contenido al backend.
  static Future<Map<String, dynamic>> addComment(
      String postId, String content) async {
    final headers = await _headers();
    final body = json.encode({'content': content});

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      try {
        final Map<String, dynamic> payload =
            json.decode(response.body) as Map<String, dynamic>;
        final detail = payload['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          throw detail;
        }
      } catch (_) {
        final plain = response.body.trim();
        if (plain.isNotEmpty) {
          throw plain;
        }
      }
      throw 'No se pudo agregar el comentario';
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 06-12-2025
  /// Descripción: Solicita la eliminación de un comentario propio.
  static Future<void> deleteComment(String postId, String commentId) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments/$commentId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar el comentario');
    }
  }
}
