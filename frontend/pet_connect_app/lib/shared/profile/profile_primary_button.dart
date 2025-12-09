/// Autor: Wilbert López Veras
/// Fecha de creación: 20 de Noviembre de 2025
/// Descripción:
/// Botón de acción principal reutilizable para la pantalla de perfil.

import 'package:flutter/material.dart';

class ProfilePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool showSpinner;

  const ProfilePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: showSpinner ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: showSpinner
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
    );
  }
}
