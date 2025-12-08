/// Autor: Wilbert López Veras 
/// Fecha de creación: 18 de noviembre de 2025
/// Descripción:
/// Pantalla para perfil del usuario en la aplicación.

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/lib/services/profile_service.dart';
import 'package:pet_connect_app/lib/services/conversations_service.dart';
import './edit_profile_screen.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? profileId;
  final bool isOwner;
  const ProfileScreen({
    super.key,
    this.profileId,
    this.isOwner = true,
  }) : assert(isOwner || profileId != null,
            'profileId debe proveerse cuando no es el propietario');

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;
  String? error;
  bool _startingConversation = false;

  ProfileService? profileService;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    final token = await AuthService.instance.getToken();

    if (!mounted) return;

    if (token == null) {
      setState(() {
        loading = false;
        error = 'No hay sesión activa';
      });
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    profileService = ProfileService(
      baseUrl: ApiConfig.baseUrl,
      token: token,
    );

    await loadProfile();
  }

  Future<void> loadProfile() async {
    if (profileService == null) return;

    try {
      final data = widget.isOwner || widget.profileId == null
          ? await profileService!.getMyProfile()
          : await profileService!.getProfileById(widget.profileId!);
      setState(() {
        profile = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _startConversation() async {
    final targetId = profile?['id'] as String?;
    if (targetId == null) return;
    setState(() => _startingConversation = true);
    try {
      final convo = await ConversationsService.createConversation(targetId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/conversation/detail',
        arguments: {
          'conversationId': convo['id'],
          'otherUserId': targetId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar la conversación: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _startingConversation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(child: Text("Error: $error")),
      );
    }

    final petName = profile!['pet_name'] ?? 'Mi mascota';
    final username = (profile!['username'] ?? '').toString().trim();
    final titleText = username.isNotEmpty ? '$petName (@$username)' : petName;
    final posts = (profile!['posts'] as List<dynamic>?) ?? [];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.zero,
              title: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(
                        profile!['avatar_url'] ??
                            'https://placehold.co/150x150/0ea5e9/white?text=Pet',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        titleText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    profile!['avatar_url'] ??
                        'https://placehold.co/600x400/0ea5e9/white?text=Pet',
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xCC000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: widget.isOwner
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Cerrar sesión",
                          style:
                              TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ]
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              profile!['pet_gender'] ?? 'Género no definido',
                              profile!['pet_type'] ?? 'Tipo no definido'
                            ].where((item) => item.isNotEmpty).join(', '),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              profile!['city'] ?? 'Sin ciudad',
                              profile!['postal_code'] ?? 'Sin código postal'
                            ].where((item) => item.isNotEmpty).join(', '),
                            style:
                                TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (widget.isOwner)
                        ElevatedButton(
                          onPressed: () async {
                            if (profile == null) return;
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  profile: Map<String, dynamic>.from(profile!),
                                ),
                              ),
                            );
                            if (updated == true && mounted) {
                              setState(() => loading = true);
                              await loadProfile();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Editar Perfil'),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _startingConversation
                              ? null
                              : () => _startConversation(),
                          icon: _startingConversation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chat_bubble_outline),
                          label: const Text('Enviar mensaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor.withOpacity(0.1),
                            foregroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile!['bio'] ?? 'Este usuario aún no tiene biografía.',
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.grid_view_rounded,
                            color: kPrimaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Publicaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(height: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: posts.isNotEmpty
            ? GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index] as Map<String, dynamic>;
                  return InkWell(
                    onTap: () {
                      final postId = post['id'] as String?;
                      if (postId == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewPostScreen(
                            postId: postId,
                            isOwner: widget.isOwner,
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      post['image_url'] ??
                          'https://placehold.co/400x400/e0f2fe/0ea5e9?text=Pet+${index + 1}',
                      fit: BoxFit.cover,
                    ),
                  );
                },
              )
            : const Center(
                child: Text('Aún no ha publicado nada'),
              ),
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  await AuthService.instance.logout();
  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
}
