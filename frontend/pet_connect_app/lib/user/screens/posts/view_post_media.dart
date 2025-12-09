/// Autor: Wilbert López Veras
/// Fecha de creación: 18 de Noviembre de 2025
/// Descripción:
/// Tarjeta que muestra la imagen del post, descripción y acción de "me gusta".

import 'package:flutter/material.dart';

/// Componente reutilizable para renderizar la sección principal de la publicación.
class ViewPostMedia extends StatelessWidget {
  final String imageUrl;
  final String description;
  final String? formattedDate;
  final int likesCount;
  final bool likedByMe;
  final bool liking;
  final Future<void> Function() onToggleLike;

  const ViewPostMedia({
    super.key,
    required this.imageUrl,
    required this.description,
    required this.formattedDate,
    required this.likesCount,
    required this.likedByMe,
    required this.liking,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 360),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Text('Sin imagen')),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (formattedDate != null)
                Text(
                  formattedDate!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              const SizedBox(height: 8),
              Text(
                description.isNotEmpty ? description : 'Sin descripción',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                '$likesCount me gusta',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(
                  likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: likedByMe ? Colors.red : Colors.grey[600],
                ),
                onPressed: liking ? null : onToggleLike,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
