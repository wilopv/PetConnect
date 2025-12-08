import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/services/conversations_service.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  Future<void> _setup() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _conversationId = args?['conversationId'] as String?;
    _otherUserId = args?['otherUserId'] as String?;
    _otherUserDisplay = args?['otherUserDisplay'] as String?;
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
            const CircleAvatar(
              radius: 18,
              backgroundImage:
                  NetworkImage('https://placehold.co/50x50/34d399/white?text=A'),
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
          _ConversationInput(
            controller: _controller,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

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
          child: _ConversationBubble(
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

class _ConversationBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final String time;

  const _ConversationBubble({
    required this.isMe,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMe ? Colors.teal : Colors.grey.shade200;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = isMe ? Colors.white : Colors.black87;
    String formatted = time;
    if (time.isNotEmpty) {
      try {
        final parsed = DateTime.parse(time);
        formatted =
            '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Align(
      alignment: alignment,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

  const _ConversationInput({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton.small(
              onPressed: sending ? null : onSend,
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
