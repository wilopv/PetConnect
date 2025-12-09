// Autor: Wilbert López Veras
// Fecha de creación: 8 de Diciembre de 2025
// Descripción:
// Pantalla que muestra los detalles de una conversación específica,
// incluyendo los mensajes y la opción para enviar nuevos mensajes.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/services/conversations_service.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/user/screens/conversations/conversation_bubble.dart';
import 'package:pet_connect_app/user/screens/conversations/conversation_input.dart';

class ConversationDetailsScreen extends StatefulWidget {
  const ConversationDetailsScreen({super.key});

  @override
  State<ConversationDetailsScreen> createState() =>
      _ConversationDetailsScreenState();
}

class _ConversationDetailsScreenState extends State<ConversationDetailsScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _fetching = false;

  String? _conversationId;
  String? _currentUserId;
  String? _otherUserId;
  String? _otherUserDisplay;
  String? _otherUserAvatar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 8 de Diciembre de 2025
  // Descripción:
  // Configura la pantalla obteniendo los argumentos y cargando los mensajes.
  Future<void> _setup() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _conversationId = args?['conversationId'] as String?;
    _otherUserId = args?['otherUserId'] as String?;
    _otherUserDisplay = args?['otherUserDisplay'] as String?;
    _otherUserAvatar = args?['otherUserAvatar'] as String?;
    _currentUserId = await AuthService.instance.getUserId();
    if (_conversationId == null) {
      setState(() {
        _error = 'Conversación inválida';
        _loading = false;
      });
      return;
    }
    await _loadMessages();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(showSpinner: false));
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 8 de Diciembre de 2025
  // Descripción:
  Future<void> _loadMessages({bool showSpinner = true}) async {
    if (_conversationId == null || _fetching) return;
    _fetching = true;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await ConversationsService.getMessages(_conversationId!);
      if (!mounted) return;
      setState(() {
        _messages = data;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      _fetching = false;
      if (mounted) {
        if (showSpinner) {
          setState(() => _loading = false);
        }
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 8 de Diciembre de 2025
  // Descripción:
  // Maneja el envío de un nuevo mensaje en la conversación.
  Future<void> _sendMessage() async {
    if (_conversationId == null ||
        _controller.text.trim().isEmpty ||
        _sending) {
      return;
    }
    setState(() => _sending = true);
    final content = _controller.text.trim();
    try {
      await ConversationsService.sendMessage(
        _conversationId!,
        content,
      );
      if (!mounted) return;
      setState(() {
        _controller.clear();
      });
      await _loadMessages(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando mensaje: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 8 de Diciembre de 2025
  // Descripción:
  // Desplaza la vista de mensajes hacia el final para mostrar el mensaje más reciente.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                _otherUserAvatar ??
                    'https://placehold.co/50x50/34d399/white?text=A',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _otherUserDisplay ??
                    (_otherUserId != null
                        ? 'Usuario $_otherUserId'
                        : 'Conversación'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          ConversationInput(
            controller: _controller,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 8 de Diciembre de 2025
  // Descripción:
  // Construye el widget que muestra la lista de mensajes en la conversación.
  Widget _buildMessages() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: _loadMessages,
          child: Text('Error: $_error\n\nToca para reintentar'),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('Todavía no hay mensajes en esta conversación'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg['sender_id'] == _currentUserId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ConversationBubble(
            isMe: isMe,
            message: msg['content'] ?? '',
            time: msg['created_at'] ?? '',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
}