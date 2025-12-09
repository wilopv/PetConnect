// Autor: Wilbert López Veras
// Fecha de creación: 9 de Diciembre de 2025
// Descripción: Servicio para seguir y dejar de seguir usuarios.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';

class FollowService {
  FollowService._();

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

  static Future<void> followUser(String userId) async {
    /// Autor: Wilbert López Veras
    /// Fecha: 09-12-2025
    /// Descripción: Envía la solicitud para seguir al usuario indicado.
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/profile/$userId/follow'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final detail = _extractDetail(response.body);
      throw Exception(detail ?? 'No se pudo seguir al usuario');
    }
  }

  static Future<void> unfollowUser(String userId) async {
    /// Autor: Wilbert López Veras
    /// Fecha: 09-12-2025
    /// Descripción: Deja de seguir al usuario especificado.
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/profile/$userId/follow'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final detail = _extractDetail(response.body);
      throw Exception(detail ?? 'No se pudo dejar de seguir al usuario');
    }
  }

  static Future<bool> isFollowing(String userId) async {
    /// Autor: Wilbert López Veras
    /// Fecha: 09-12-2025
    /// Descripción: Verifica si el usuario autenticado sigue al perfil dado.
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile/$userId/follow/status'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final detail = _extractDetail(response.body);
      throw Exception(detail ?? 'No se pudo validar el seguimiento');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['following'] == true;
  }

  static Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    /// Autor: Wilbert López Veras
    /// Fecha: 09-12-2025
    /// Descripción: Obtiene la lista de seguidores de un usuario.
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile/$userId/followers'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener la lista de seguidores');
    }

    final List<dynamic> raw = json.decode(response.body);
    return raw.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    /// Autor: Wilbert López Veras
    /// Fecha: 09-12-2025
    /// Descripción: Devuelve los usuarios que el perfil indicado está siguiendo.
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile/$userId/following'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener la lista de seguidos');
    }

    final List<dynamic> raw = json.decode(response.body);
    return raw.cast<Map<String, dynamic>>();
  }

  static String? _extractDetail(String body) {
    try {
      final Map<String, dynamic> data = json.decode(body);
      return data['detail']?.toString();
    } catch (_) {
      return null;
    }
  }
}
