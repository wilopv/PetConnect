import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SearchMap extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final LatLng defaultCenter;
  final LatLngBounds iberianBounds;
  final VoidCallback? onMapReady;
  final Widget? overlayWidget;

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
          Positioned(
            right: 12,
            top: 12,
            child: overlayWidget!,
          ),
      ],
    );
  }
}
