/// Autor: Wilbert López Veras
/// Fecha de creación: 21 de Noviembre de 2025
/// Descripción:
/// Sección con botones de acción, datos de mascota y biografía.

import 'package:flutter/material.dart';

class ProfileInfoSection extends StatelessWidget {
  final Widget actionRow;
  final String petGender;
  final String petType;
  final String city;
  final String postalCode;
  final String bio;

  const ProfileInfoSection({
    super.key,
    required this.actionRow,
    required this.petGender,
    required this.petType,
    required this.city,
    required this.postalCode,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    final genderType = [petGender, petType]
        .where((item) => item.isNotEmpty)
        .join(', ');
    final location = [city, postalCode]
        .where((item) => item.isNotEmpty)
        .join(', ');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: actionRow,
            ),
            Text(
              genderType.isNotEmpty
                  ? genderType
                  : 'Género y tipo no definidos',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              location.isNotEmpty ? location : 'Ubicación pendiente',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              bio.isNotEmpty
                  ? bio
                  : 'Este usuario aún no tiene biografía.',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
