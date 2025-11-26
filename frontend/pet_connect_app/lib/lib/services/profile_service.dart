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

  // GET /profile/me
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

  // PUT /profile/me
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

  // GET /profile/{id} – ver perfil de otros
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

  // GET /profile/search
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
}
