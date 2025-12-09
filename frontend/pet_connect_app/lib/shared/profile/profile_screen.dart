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
import 'package:pet_connect_app/lib/services/follow_service.dart';
import './edit_profile_screen.dart';
import 'profile_header.dart';
import 'profile_info_section.dart';
import 'profile_posts_header.dart';
import 'profile_posts_grid.dart';
import 'profile_primary_button.dart';

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
  bool _followLoading = false;
  bool? _isFollowing;

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

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Carga el perfil del usuario, ya sea propio o de otro usuario.
  Future<void> loadProfile() async {
    if (profileService == null) return;

    try {
      final data = widget.isOwner || widget.profileId == null
          ? await profileService!.getMyProfile()
          : await profileService!.getProfileById(widget.profileId!);
      if (!mounted) return;
      setState(() {
        profile = data;
        loading = false;
      });
      if (!widget.isOwner) {
        await _loadFollowStatus();
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Inicia una nueva conversación con el usuario cuyo perfil se está viendo.
  Future<void> _startConversation() async {
    final targetId = profile?['id'] as String?;
    if (targetId == null) return;
    final petName = profile?['pet_name'] ?? 'Sin nombre';
    final username = (profile?['username'] ?? '').toString().trim();
    final displayName =
        username.isNotEmpty ? '$petName (@$username)' : petName;
    final avatar = profile?['avatar_url'] as String?;

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
          'otherUserDisplay': displayName,
          'otherUserAvatar': avatar,
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

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Abre la pantalla de edición de perfil.
  Future<void> _openEditProfile() async {
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
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Construye el botón de seguir/dejar de seguir.
  Widget _buildFollowButton() {
    final isFollowing = _isFollowing ?? false;
    final showSpinner = _followLoading || _isFollowing == null;
    final backgroundColor =
        isFollowing ? Colors.grey[200] : kPrimaryColor;
    final foregroundColor =
        isFollowing ? Colors.black87 : Colors.white;

    return ElevatedButton(
      onPressed: showSpinner ? null : _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: showSpinner
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isFollowing ? 'Siguiendo' : 'Seguir',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Carga el estado de seguimiento del usuario mostrado en el perfil.
  Future<void> _loadFollowStatus() async {
    final targetId = (widget.profileId ?? profile?['id']) as String?;
    if (targetId == null) return;

    setState(() {
      _followLoading = true;
      _isFollowing ??= false;
    });

    try {
      final following = await FollowService.isFollowing(targetId);
      if (!mounted) return;
      setState(() => _isFollowing = following);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo verificar el seguimiento: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _followLoading = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Alterna el estado de seguimiento del usuario mostrado en el perfil.
  Future<void> _toggleFollow() async {
    final targetId = (widget.profileId ?? profile?['id']) as String?;
    if (targetId == null) return;
    final currentlyFollowing = _isFollowing ?? false;

    setState(() => _followLoading = true);
    try {
      if (currentlyFollowing) {
        await FollowService.unfollowUser(targetId);
      } else {
        await FollowService.followUser(targetId);
      }
      if (!mounted) return;
      setState(() => _isFollowing = !currentlyFollowing);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el seguimiento: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _followLoading = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Construye la fila de acciones (botones) en el perfil.
  Widget _buildActionRow() {
    if (widget.isOwner) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          ProfilePrimaryButton(
            label: 'Editar perfil',
            onPressed: _openEditProfile,
            color: kPrimaryColor,
          ),
          ProfilePrimaryButton(
            label: 'Cerrar sesión',
            onPressed: () => _logout(context),
            color: Colors.red,
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildFollowButton(),
        ProfilePrimaryButton(
          label: 'Enviar mensaje',
          onPressed: _startingConversation ? null : _startConversation,
          color: Colors.teal,
          showSpinner: _startingConversation,
        ),
      ],
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 18 de Noviembre de 2025
  // Descripción:
  // Construye la acción en el encabezado de la pantalla.
  Widget _buildHeaderAction() {
    return const SizedBox.shrink();
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
    final avatarUrl = profile!['avatar_url'] ??
        'https://placehold.co/150x150/0ea5e9/white?text=Pet';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          ProfileHeader(
            titleText: titleText,
            avatarUrl: avatarUrl,
            action: _buildHeaderAction(),
          ),
          ProfileInfoSection(
            actionRow: _buildActionRow(),
            petGender: (profile!['pet_gender'] ?? '').toString(),
            petType: (profile!['pet_type'] ?? '').toString(),
            city: (profile!['city'] ?? '').toString(),
            postalCode: (profile!['postal_code'] ?? '').toString(),
            bio: (profile!['bio'] ?? '').toString(),
          ),
          const ProfilePostsHeader(),
        ],
        body: ProfilePostsGrid(
          posts: posts,
          isOwner: widget.isOwner,
        ),
      ),
    );
  }
}

// Autor: Wilbert López Veras
// Fecha de creación: 18 de Noviembre de 2025
// Descripción:
// Cierra la sesión del usuario y navega a la pantalla de inicio de sesión.
Future<void> _logout(BuildContext context) async {
  await AuthService.instance.logout();
  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
}

// Autor: Wilbert López Veras
// Fecha de creación: 18 de Noviembre de 2025
// Descripción:
// Botón de acción primario reutilizable.
