/// Autor: Wilbert López Veras
/// Fecha de creación: 22 de Noviembre de 2025
/// Descripción:
/// Pequeño panel que muestra el estado actual del mapa y los filtros activos.

import 'package:flutter/material.dart';

/// Widget informativo que se coloca sobre el mapa.
class MapStatusOverlay extends StatelessWidget {
  final String statusMessage;
  final String postalLabel;
  final String cityLabel;
  final bool showError;
  final bool loadingMarkers;

  const MapStatusOverlay({
    super.key,
    required this.statusMessage,
    required this.postalLabel,
    required this.cityLabel,
    required this.showError,
    required this.loadingMarkers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statusMessage,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: showError ? Colors.redAccent : Colors.black87,
            ),
          ),
          Text(
            'CP: $postalLabel',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            'Ciudad: $cityLabel',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (loadingMarkers)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
        ],
      ),
    );
  }
}
