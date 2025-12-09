/// Autor: Wilbert López Veras
/// Fecha de creación: 18 de Noviembre de 2025
/// Descripción:
/// Tarjeta con controles para filtrar la búsqueda por código postal y ciudad.

import 'package:flutter/material.dart';

/// Tarjeta reutilizable que muestra los campos de filtro y el botón de aplicar.
class SearchLocationControls extends StatelessWidget {
  final TextEditingController postalController;
  final TextEditingController cityController;
  final bool updatingLocation;
  final VoidCallback? onApplyFilters;

  const SearchLocationControls({
    super.key,
    required this.postalController,
    required this.cityController,
    required this.updatingLocation,
    required this.onApplyFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubicación de búsqueda',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: postalController,
                    decoration: InputDecoration(
                      labelText: 'Código postal',
                      prefixIcon: const Icon(Icons.local_post_office),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cityController,
                    decoration: InputDecoration(
                      labelText: 'Ciudad / Localidad',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: updatingLocation ? null : onApplyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: updatingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Actualizar búsqueda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
