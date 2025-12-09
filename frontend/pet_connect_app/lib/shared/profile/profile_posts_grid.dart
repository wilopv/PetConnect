/// Autor: Wilbert López Veras
/// Fecha de creación: 22 de Noviembre de 2025
/// Descripción:
/// Grid reutilizable que muestra las publicaciones del perfil.

import 'package:flutter/material.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_screen.dart';

class ProfilePostsGrid extends StatelessWidget {
  final List<dynamic> posts;
  final bool isOwner;

  const ProfilePostsGrid({
    super.key,
    required this.posts,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('Aún no ha publicado nada'));
    }

    return GridView.builder(
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
                  isOwner: isOwner,
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
    );
  }
}
