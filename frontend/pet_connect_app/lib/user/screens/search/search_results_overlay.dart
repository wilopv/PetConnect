/// Autor: Wilbert López Veras
/// Fecha de creación: 20 de Noviembre de 2025
/// Descripción:
/// Widget que encapsula el campo de búsqueda y la lista desplegable de resultados.

import 'package:flutter/material.dart';

typedef ProfileTapCallback = void Function(String profileId);

/// Presenta el cuadro de búsqueda de usuarios y la lista animada de coincidencias.
class SearchResultsOverlay extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> results;
  final ValueChanged<String> onQueryChanged;
  final ProfileTapCallback onProfileTap;

  const SearchResultsOverlay({
    super.key,
    required this.controller,
    required this.query,
    required this.loading,
    required this.error,
    required this.results,
    required this.onQueryChanged,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
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
            onChanged: onQueryChanged,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: query.isEmpty
              ? const SizedBox.shrink()
              : ConstrainedBox(
                  key: ValueKey(query),
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.white,
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            error!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
          ),
        ),
      );
    }
    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sin coincidencias',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = results[index];
        final avatar = user['avatar_url'] as String? ?? '';
        final userId = user['id'] as String?;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatar.isNotEmpty
                ? NetworkImage(avatar)
                : const NetworkImage('https://placehold.co/60x60'),
          ),
          title: Text(user['username'] ?? 'usuario'),
          subtitle: Text(user['city'] ?? 'Ciudad pendiente'),
          onTap: userId == null ? null : () => onProfileTap(userId),
        );
      },
    );
  }
}
