/// Autor: Wilbert López Veras
/// Fecha de creación: 9 de Diciembre de 2025
/// Descripción:
/// Tarjeta reutilizable que muestra una notificación individual con icono y acciones.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onOpen;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const NotificationTile({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onDelete,
  });

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Obtiene el ícono adecuado según el tipo de notificación.
  IconData get _icon {
    switch (data['event_type']) {
      case 'message':
        return Icons.mail_outline;
      default:
        return Icons.notifications;
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Obtiene el color adecuado según el tipo de notificación.
  Color get _color {
    switch (data['event_type']) {
      case 'message':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Formatea la fecha y hora de la notificación para mostrar en pantalla.
  String get _timeText {
    final createdAt = data['created_at']?.toString();
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return createdAt;
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Genera la descripción de la notificación basada en su tipo y autor.
  String get _description {
    final author = data['author'] as Map<String, dynamic>? ?? {};
    final formattedAuthor = _formatAuthor(author);
    switch (data['event_type']) {
      case 'post':
        return '<strong>$formattedAuthor</strong> ha hecho una nueva publicación.';
      case 'message':
        return '<strong>$formattedAuthor</strong> te ha enviado un mensaje.';
      default:
        return '<strong>$formattedAuthor</strong> tiene una novedad.';
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Formatea el autor de la notificación para mostrar en pantalla.
  String _formatAuthor(Map<String, dynamic> author) {
    final petName = (author['pet_name'] ?? '').toString();
    final username = (author['username'] ?? '').toString();
    if (petName.isNotEmpty && username.isNotEmpty) {
      return '$petName (@$username)';
    }
    if (petName.isNotEmpty) return petName;
    if (username.isNotEmpty) return '@$username';
    return 'Usuario';
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 9 de Diciembre de 2025
  // Descripción:
  // Construye una lista de TextSpans para resaltar partes del texto.
  List<TextSpan> _buildTextSpans(String text) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'<strong>(.*?)<\/strong>');
    int start = 0;
    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onOpen,
      leading: Icon(_icon, color: _color, size: 28),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          children: _buildTextSpans(_description),
        ),
      ),
      subtitle: Text(
        _timeText,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: Colors.grey[600],
        onPressed: () => onDelete(data),
      ),
      isThreeLine: true,
    );
  }
}
