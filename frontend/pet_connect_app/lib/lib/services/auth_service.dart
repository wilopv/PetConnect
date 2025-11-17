// Autor: Wilbert López Veras
// Fecha de creación: 2 de Noviembre de 2025
// Descripción: Servicio de autenticación que consume los endpoints de autenticación del backend.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pet_connect_app/lib/config/api_config.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _storage = const FlutterSecureStorage();

  // Funcion de login
  Future<String?> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if(res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Guardar token
        final token = data['access_token'] as String;
        await _storage.write(key: 'access_token', value: token);

        // Guardar rol
        final role = data['user']['role'] as String;
        await _storage.write(key: 'role', value: role);

        // Guardar ID
        final userId = data['user']['id'] as String;
        await _storage.write(key: 'user_id', value: userId);

        return null; // null significa que todo OK


      } else {
        final data = jsonDecode(res.body);
        return data['detail']?.toString() ?? 'Error al iniciar sesin';
      }
    } catch (e) {
      return 'Error de red o conectando al servidor';
    }
  }

  // Funcion de registro
  Future<String?> signup(String email, String password, String username) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/signup');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if(res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Guardar token
        final token = data['access_token'] as String;
        await _storage.write(key: 'access_token', value: token);

        // Guardar rol
        final role = data['user']['role'] as String;
        await _storage.write(key: 'role', value: role);

        // Guardar ID
        final userId = data['user']['id'] as String;
        await _storage.write(key: 'user_id', value: userId);

        return null; // null significa que todo OK
      } else {
        final data = jsonDecode(res.body);
        return data['detail']?.toString() ?? 'Error al registrar usuario';
      }
    } catch (e) {
      return 'Error de red o conectando al servidor';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  Future<String?> getToken() => _storage.read(key: 'access_token');
}