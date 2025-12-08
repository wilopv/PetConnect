import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/lib/services/conversations_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final userId = await AuthService.instance.getUserId();
    if (!mounted) return;
    setState(() => _currentUserId = userId);
    await _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ConversationsService.getConversations();
      if (!mounted) return;
      setState(() => _conversations = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadConversations,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: _loadConversations,
          child: Text('Error: $_error\n\nToca para reintentar'),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(child: Text('Aún no tienes conversaciones'));
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final otherUserId = conversation['user_a'] == _currentUserId
            ? conversation['user_b']
            : conversation['user_a'];

        final lastMessage = conversation['last_message_at'] as String?;
        String subtitle = 'Sin mensajes aún';
        if (lastMessage != null) {
          try {
            final parsed = DateTime.parse(lastMessage);
            final formatted =
                '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
            subtitle = 'Último mensaje: $formatted';
          } catch (_) {
            subtitle = 'Último mensaje: $lastMessage';
          }
        }

        final otherProfile = conversation['user_a'] == _currentUserId
            ? conversation['user_b_profile']
            : conversation['user_a_profile'];
        final petName = otherProfile?['pet_name'] ?? 'Sin nombre';
        final username = otherProfile?['username'] ?? 'usuario';

        final displayName = '$petName (@$username)';

        return _ConversationListTile(
          name: displayName,
          message: subtitle,
          avatarUrl: 'https://placehold.co/60x60/0ea5e9/ffffff?text=🐾',
          onTap: () {
            Navigator.pushNamed(
              context,
              '/conversation/detail',
              arguments: {
                'conversationId': conversation['id'],
                'otherUserId': otherUserId,
                'otherUserDisplay': displayName,
              },
            );
          },
        );
      },
    );
  }
}

class _ConversationListTile extends StatelessWidget {
  final String name;
  final String message;
  final String avatarUrl;
  final VoidCallback onTap;

  const _ConversationListTile({
    required this.name,
    required this.message,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
