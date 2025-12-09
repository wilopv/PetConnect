// Autor: Wilbert López Veras
// Fecha de creación: 6 de Diciembre de 2025
// Descripción: Servicio para manejar operaciones de creacion, eliminacion y obtencion de posts.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';

class PostsService {
  PostsService._();

  static Future<Map<String, String>> _buildHeaders() async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      throw Exception('No hay sesión activa');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    final headers = await _buildHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/user/$userId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo posts');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createPost(
      String description, String imageBase64) async {
    final headers = await _buildHeaders();
    final body = json.encode({
      'description': description,
      'image_base64': imageBase64,
    });

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts'),
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
      throw 'No se pudo crear el post';
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  static Future<void> deletePost(String id) async {
    final headers = await _buildHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar el post');
    }
  }

  static Future<Map<String, dynamic>> getPostById(String id) async {
    final headers = await _buildHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener la publicación');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}
