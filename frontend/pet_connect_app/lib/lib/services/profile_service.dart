// Autor: Wilbert López Veras
// Fecha de creación: 18 de Noviembre de 2025
// Descripción: Servicio para manejar operaciones relacionadas con el perfil de usuario.


import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  final String baseUrl;
  final String token;

  ProfileService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Autor: Wilbert López Veras
  /// Fecha: 18-11-2025
  /// Descripción: Obtiene el perfil del usuario autenticado desde la API.
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/me'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo perfil');
    }

    return json.decode(response.body);
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 18-11-2025
  /// Descripción: Envía los cambios del perfil propio al backend.
  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/me'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 400) {
      final body = json.decode(response.body);
      throw Exception(body['detail']); // Ej: "El nombre de usuario ya está en uso"
    }

    if (response.statusCode != 200) {
      throw Exception('Error actualizando perfil');
    }

    return json.decode(response.body);
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 18-11-2025
  /// Descripción: Consulta el perfil de otro usuario usando su ID.
  Future<Map<String, dynamic>> getProfileById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Perfil no encontrado');
    }

    return json.decode(response.body);
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 18-11-2025
  /// Descripción: Permite a moderadores actualizar perfiles de terceros.
  Future<Map<String, dynamic>> updateProfileById(
      String userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 400) {
      final body = json.decode(response.body);
      throw Exception(body['detail'] ?? 'No se pudo actualizar el perfil');
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para editar este perfil');
    }

    if (response.statusCode != 200) {
      throw Exception('Error actualizando perfil');
    }

    return json.decode(response.body);
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 18-11-2025
  /// Descripción: Solicita al backend la eliminación de un perfil específico.
  Future<void> deleteProfileById(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para eliminar este perfil');
    }

    if (response.statusCode == 404) {
      throw Exception('Perfil no encontrado');
    }

    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar el perfil');
    }
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 02-12-2025
  /// Descripción: Busca usuarios por nombre de usuario o mascota.
  Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    final uri = Uri.parse('$baseUrl/profile/search')
        .replace(queryParameters: {'query': query});

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Error buscando usuarios');
    }

    final List<dynamic> raw = json.decode(response.body);
    return raw.cast<Map<String, dynamic>>();
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 09-12-2025
  /// Descripción: Recupera perfiles dentro de un radio determinado usando coordenadas.
  Future<List<Map<String, dynamic>>> getNearbyProfiles({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/profile/nearby').replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius_km': radiusKm.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Error obteniendo perfiles cercanos');
    }

    final List<dynamic> raw = json.decode(response.body);
    return raw.cast<Map<String, dynamic>>();
  }

  /// Autor: Wilbert López Veras
  /// Fecha: 09-12-2025
  /// Descripción: Convierte ciudad o código postal en coordenadas usando el backend.
  Future<Map<String, double>> geocodeLocation({
    String? postalCode,
    String? city,
  }) async {
    final params = <String, String>{};
    if (postalCode != null && postalCode.trim().isNotEmpty) {
      params['postal_code'] = postalCode.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      params['city'] = city.trim();
    }
    if (params.isEmpty) {
      throw Exception('Debe proporcionar código postal o ciudad');
    }

    final uri =
        Uri.parse('$baseUrl/profile/geocode').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      try {
        final body = json.decode(response.body);
        throw Exception(body['detail'] ?? 'No se pudieron obtener coordenadas');
      } catch (_) {
        throw Exception('No se pudieron obtener coordenadas');
      }
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return {
      'latitude': (data['latitude'] as num).toDouble(),
      'longitude': (data['longitude'] as num).toDouble(),
    };
  }
}
