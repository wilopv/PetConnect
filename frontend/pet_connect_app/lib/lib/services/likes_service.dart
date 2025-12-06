// Autor: Wilbert López Veras
// Fecha de creación: 6 de Diciembre de 2025
// Descripción: Servicio para manejar operaciones de likes en publicaciones.

import 'package:http/http.dart' as http;
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';

class LikesService {
  LikesService._();

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

  static Future<void> likePost(String postId) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/like'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo registrar el like');
    }
  }

  static Future<void> unlikePost(String postId) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/like'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar el like');
    }
  }
}
