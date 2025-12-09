/// Autor: Wilbert López Veras
/// Fecha de creación: 21 de Noviembre de 2025
/// Descripción:
/// Encabezado decorativo para la sección de publicaciones del perfil.

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ProfilePostsHeader extends StatelessWidget {
  const ProfilePostsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: kPrimaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Publicaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
