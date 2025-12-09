/// Autor: Wilbert López Veras
/// Fecha de creación: 20 de Noviembre de 2025
/// Descripción:
/// Widget de mapa reutilizable para búsqueda y visualización de marcadores.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget reutilizable que dibuja el mapa y sus marcadores usando flutter_map.
class SearchMap extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final LatLng defaultCenter;
  final LatLngBounds iberianBounds;
  final VoidCallback? onMapReady;
  final Widget? overlayWidget;

  /// Crea un mapa centrado en [defaultCenter] y delimitado por [iberianBounds].
  const SearchMap({
    super.key,
    required this.mapController,
    required this.markers,
    required this.defaultCenter,
    required this.iberianBounds,
    this.onMapReady,
    this.overlayWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            // Configuracion principal del mapa y sus restricciones de camara.
            mapController: mapController,
            options: MapOptions(
              initialCenter: defaultCenter,
              initialZoom: 5.5,
              cameraConstraint: CameraConstraint.contain(bounds: iberianBounds),
              interactionOptions: const InteractionOptions(
                enableScrollWheel: true,
                scrollWheelVelocity: 0.015,
              ),
              onMapReady: onMapReady,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.petconnect',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
        if (overlayWidget != null)
          // Se permite colocar overlays livianos (botones, tarjetas) encima del mapa.
          Positioned(
            right: 12,
            top: 12,
            child: overlayWidget!,
          ),
      ],
    );
  }
}
