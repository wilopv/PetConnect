/// Autor: Wilbert López Veras
/// Fecha de creación: 9 de Diciembre de 2025
/// Descripción:
/// Pantalla que muestra las notificaciones y escucha cambios en tiempo real desde el backend.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_screen.dart';
import 'package:pet_connect_app/user/screens/notifications/notification_tile.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;
  WebSocketChannel? _channel;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Autor: Wilbert López Veras
  /// Fecha de creación: 9 de Diciembre de 2025
  /// Descripción: Inicializa la pantalla cargando usuario, notificaciones y WebSocket.
  Future<void> _init() async {
    final userId = await AuthService.instance.getUserId();
    if (!mounted) return;
    _currentUserId = userId;
    await _loadNotifications(showSpinner: true);
    await _connectWebSocket();
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Carga las notificaciones desde el backend y actualiza el estado.
  Future<void> _loadNotifications({bool showSpinner = false}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _fetchNotificationsFromBackend();
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(data);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && showSpinner) {
        setState(() => _loading = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Conecta al WebSocket del backend para recibir notificaciones en tiempo real.
  /// Autor: Wilbert López Veras
  /// Fecha de creación: 9 de Diciembre de 2025
  /// Descripción: Abre el canal WebSocket para recibir notificaciones nuevas.
  Future<void> _connectWebSocket() async {
    final userId = _currentUserId;
    final token = await AuthService.instance.getToken();
    if (userId == null || token == null) return;

    final uri = _buildWsUri(token);
    try {
      final channel = IOWebSocketChannel.connect(uri);
      channel.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message);
            if (decoded is List) {
              final List<Map<String, dynamic>> items =
                  decoded.cast<Map<String, dynamic>>();
              if (!mounted) return;
              setState(() {
                for (final item in items.reversed) {
                  final id = item['id'];
                  final exists = _notifications.any((notif) => notif['id'] == id);
                  if (!exists) {
                    _notifications.insert(0, item);
                  }
                }
              });
            }
          } catch (_) {}
        },
        onError: (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error en notificaciones: $error')),
          );
        },
        onDone: () {
          _channel = null;
        },
      );
      _channel = channel;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar al stream: $e')),
      );
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  Uri _buildWsUri(String token) {
    final base = Uri.parse(ApiConfig.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/notifications/ws',
      queryParameters: {'token': token},
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Solicita las notificaciones al backend.
  Future<List<Map<String, dynamic>>> _fetchNotificationsFromBackend() async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      throw Exception('No hay sesión activa');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las notificaciones');
    }
    final List<dynamic> raw = jsonDecode(response.body);
    return raw.cast<Map<String, dynamic>>();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: TextButton(
                    onPressed: () => _loadNotifications(showSpinner: true),
                    child: Text('Error: $_error\n\nToca para reintentar'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(showSpinner: false),
                  child: _notifications.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Aún no tienes notificaciones',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            return NotificationTile(
                              data: item,
                              onOpen: () => _handleNotificationTap(item),
                              onDelete: _deleteNotification,
                            );
                          },
                        ),
                ),
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Maneja la navegación al tocar una notificación.
  void _handleNotificationTap(Map<String, dynamic> notification) {
    final eventType = (notification['event_type'] ?? '').toString();
    if (eventType == 'post') {
      final postId = notification['post_id']?.toString();
      if (postId == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewPostScreen(
            postId: postId,
            isOwner: false,
          ),
        ),
      );
    } else if (eventType == 'message') {
      final conversationId = notification['conversation_id']?.toString();
      if (conversationId == null) return;
      final author = notification['author'] as Map<String, dynamic>? ?? {};
      final display = _formatAuthor(author);
      Navigator.pushNamed(
        context,
        '/conversation/detail',
        arguments: {
          'conversationId': conversationId,
          'otherUserId': author['id'],
          'otherUserDisplay': display,
          'otherUserAvatar': author['avatar_url'],
        },
      );
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Formatea el autor de la notificación para mostrar en pantalla.
  String _formatAuthor(Map<String, dynamic> author) {
    final petName = (author['pet_name'] ?? '').toString();
    final username = (author['username'] ?? '').toString();
    if (petName.isNotEmpty && username.isNotEmpty) {
      return '$petName (@$username)';
    }
    if (petName.isNotEmpty) return petName;
    if (username.isNotEmpty) return '@$username';
    return 'Usuario';
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Elimina una notificación específica.
  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id == null) return;
    final token = await AuthService.instance.getToken();
    if (token == null) return;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/$id');
      final response = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode != 200) {
        throw Exception('No se pudo eliminar');
      }
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere((item) => item['id'] == id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }
}
