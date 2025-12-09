/// Autor: Wilbert López Veras
/// Fecha de creación: 19 de Noviembre de 2025
/// Descripción:
/// Tarjeta reutilizable para mostrar una conversación dentro de la lista.

import 'package:flutter/material.dart';

class ConversationListTile extends StatelessWidget {
  final String name;
  final String message;
  final String avatarUrl;
  final VoidCallback onTap;

  const ConversationListTile({
    super.key,
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
