/// Autor: Wilbert López Veras 
/// Fecha de creación: 26 de Noviembre de 2025
/// Descripción:
/// Pantalla de busqueda de otros perfiles de usuarios en la aplicación con campo de busqueda y mapa.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/lib/services/profile_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  ProfileService? _profileService;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupService();
  }

  Future<void> _setupService() async {
    final token = await AuthService.instance.getToken();
    if (!mounted) return;
    if (token == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }
    setState(() {
      _profileService =
          ProfileService(baseUrl: ApiConfig.baseUrl, token: token);
    });
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _error = null;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _performSearch);
  }

  Future<void> _performSearch() async {
    if (_profileService == null || _query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await _profileService!.searchProfiles(_query.trim());
      if (!mounted) return;
      setState(() => _results = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo buscar usuarios');
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
        title: const Text('Buscar amigos'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 96),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Mapa próximamente',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ingresa nombre de usuario',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onQueryChanged,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _query.isEmpty
                      ? const SizedBox.shrink()
                      : ConstrainedBox(
                          key: ValueKey(_query),
                          constraints: const BoxConstraints(
                            maxHeight: 260,
                          ),
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: Colors.white,
                                child: _loading
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : _error != null
                                        ? Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                _error!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          )
                                        : _results.isEmpty
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(24),
                                                  child: Text(
                                                    'Sin coincidencias',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                shrinkWrap: true,
                                                itemCount: _results.length,
                                                separatorBuilder: (_, __) =>
                                                    const Divider(height: 1),
                                                itemBuilder: (context, index) {
                                                  final user =
                                                      _results[index];
                                                  final avatar =
                                                      user['avatar_url']
                                                              as String? ??
                                                          '';
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundImage:
                                                          avatar.isNotEmpty
                                                              ? NetworkImage(
                                                                  avatar)
                                                              : const NetworkImage(
                                                                  'https://placehold.co/60x60'),
                                                    ),
                                                    title: Text(
                                                        user['username'] ??
                                                            'usuario'),
                                                    subtitle: Text(
                                                      user['city'] ??
                                                          'Ciudad pendiente',
                                                    ),
                                                    onTap: () {},
                                                  );
                                                },
                                              ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
