/// Autor: Wilbert López Veras
/// Fecha de creación: 18 de Noviembre de 2025
/// Descripción:
/// Burbuja reutilizable para mostrar un mensaje dentro de la conversación.

import 'package:flutter/material.dart';

class ConversationBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final String time;

  const ConversationBubble({
    super.key,
    required this.isMe,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMe ? Colors.teal : Colors.grey.shade200;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = isMe ? Colors.white : Colors.black87;
    String formatted = time;
    if (time.isNotEmpty) {
      try {
        final parsed = DateTime.parse(time);
        formatted =
            '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Align(
      alignment: alignment,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
