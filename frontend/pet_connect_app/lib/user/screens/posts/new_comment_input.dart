/// Autor: Wilbert López Veras
/// Fecha de creación: 19 de Noviembre de 2025
/// Descripción:
/// Barra de entrada para escribir y enviar nuevos comentarios.

import 'package:flutter/material.dart';

/// Formulario compacto que permite redactar y enviar comentarios.
class NewCommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const NewCommentInput({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Escribe un comentario...',
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          onPressed: sending ? null : onSend,
        ),
      ],
    );
  }
}
