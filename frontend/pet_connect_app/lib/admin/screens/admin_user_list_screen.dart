/// Autor: Wilbert López Veras
/// Fecha de creación: 17 de noviembre de 2025
/// Descripción:
/// Pantalla de lista de usuarios de la aplicación para el moderador.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/lib/services/profile_service.dart';
import 'package:pet_connect_app/shared/profile/edit_profile_screen.dart';

import '../../../theme/app_colors.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProfileService? _profileService;
  Timer? _debounce;

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _setupService();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setupService() async {
    final token = await AuthService.instance.getToken();
    final currentUserId = await AuthService.instance.getUserId();
    if (!mounted) return;
    if (token == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    _profileService =
        ProfileService(baseUrl: ApiConfig.baseUrl, token: token);
    _currentUserId = currentUserId;
    await _searchUsers('');
  }

  Future<void> _searchUsers(String query) async {
    if (_profileService == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _profileService!.searchProfiles(query);
      if (!mounted) return;
      setState(() {
        _users = results
            .where((user) => user['id']?.toString() != _currentUserId)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar la lista');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Usuarios'),
        backgroundColor: kAdminDarkColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar usuario...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _users.isEmpty
                        ? const Center(child: Text('No se encontraron usuarios'))
                        : ListView.separated(
                            itemCount: _users.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final avatar = user['avatar_url'] as String? ?? '';
                              final username =
                                  user['username']?.toString() ?? 'usuario';
                              final petName =
                                  user['pet_name']?.toString().trim().isNotEmpty ==
                                          true
                                      ? user['pet_name']
                                      : 'Sin mascota';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : const NetworkImage(
                                          'https://placehold.co/50'),
                                ),
                                title: Text('$petName (@$username)'),
                                onTap: () => _openEditProfile(user['id']),
                                trailing: IconButton(
                                  tooltip: 'Eliminar usuario',
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () => _confirmDeleteUser(
                                    user['id'],
                                    username,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(String? userId) async {
    if (userId == null || _profileService == null) return;
    try {
      final profileData = await _profileService!.getProfileById(userId);
      if (!mounted) return;
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(profile: profileData),
        ),
      );
      if (updated == true) {
        await _searchUsers(_searchController.text.trim());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el perfil: $e')),
      );
    }
  }

  void _confirmDeleteUser(String? userId, String username) {
    if (userId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Estás seguro que quieres eliminar la cuenta del usuario: $username?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    if (_profileService == null) return;
    try {
      await _profileService!.deleteProfileById(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado')),
      );
      await _searchUsers(_searchController.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }
}
