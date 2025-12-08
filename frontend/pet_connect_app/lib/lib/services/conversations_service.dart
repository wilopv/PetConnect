// Autor: Wilbert López Veras
// Fecha de creación: 8 de Diciembre de 2025
// Descripción: Servicio HTTP para manejar conversaciones y mensajes privados.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';

class ConversationsService {
  ConversationsService._();

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

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/conversations'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('No se pudieron obtener las conversaciones');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createConversation(
      String targetUserId) async {
    final headers = await _headers();
    final body = jsonEncode({'target_user_id': targetUserId});

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/conversations'),
      headers: headers,
      body: body,
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('No se pudo iniciar la conversación');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('No se pudieron obtener los mensajes');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> sendMessage(
      String conversationId, String content) async {
    final headers = await _headers();
    final body = jsonEncode({'content': content});

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
      headers: headers,
      body: body,
    );

    if (res.statusCode != 201) {
      throw Exception('No se pudo enviar el mensaje');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
