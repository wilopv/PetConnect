/// Autor: Wilbert López Veras
/// Fecha de creación: 2 de diciembre de 2025
/// Descripción:
/// Botón reutilizable para las acciones de moderación de reportes.

import 'package:flutter/material.dart';

class AdminReportButton extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const AdminReportButton({
    super.key,
    required this.label,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}
