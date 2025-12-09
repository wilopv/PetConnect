/// Autor: Wilbert López Veras
/// Fecha de creación: 26 de Noviembre de 2025
/// Descripción:
/// Pantalla de búsqueda de otros perfiles de usuarios en la aplicación con campo de búsqueda y mapa.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/lib/services/profile_service.dart';
import 'package:pet_connect_app/shared/profile/profile_screen.dart';
import 'package:pet_connect_app/widgets/search_map.dart';
import 'package:pet_connect_app/user/screens/search/map_status_overlay.dart';
import 'package:pet_connect_app/user/screens/search/search_location_controls.dart';
import 'package:pet_connect_app/user/screens/search/search_results_overlay.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _postalFilterController = TextEditingController();
  final TextEditingController _cityFilterController = TextEditingController();
  String _query = '';
  ProfileService? _profileService;
  List<Map<String, dynamic>> _results = [];
  String? _currentUserId;
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final LatLng _defaultCenter = LatLng(40.0, -4.0);
  final LatLngBounds _iberianBounds =
      LatLngBounds(LatLng(35.0, -10.0), LatLng(44.5, 4.0));
  bool _mapReady = false;
  LatLng? _pendingCenter;
  String? _currentPostal;
  String? _currentCity;
  String _mapStatusMessage = 'Preparando mapa...';
  bool _mapError = false;
  bool _loadingMarkers = false;
  bool _updatingLocation = false;
  LatLng? _myCoordinates;

  @override
  void initState() {
    super.initState();
    _setupService();
  }

  @override
  void dispose() {
    _controller.dispose();
    _postalFilterController.dispose();
    _cityFilterController.dispose();
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción:
  // Configura el servicio de perfiles y centra el mapa en la ubicación del usuario.
  Future<void> _setupService() async {
    final token = await AuthService.instance.getToken();
    final userId = await AuthService.instance.getUserId();
    if (!mounted) return;
    if (token == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    setState(() {
      _profileService =
          ProfileService(baseUrl: ApiConfig.baseUrl, token: token);
      _currentUserId = userId;
      _mapStatusMessage = 'Centrando mapa...';
      _mapError = false;
    });
    await _centerMapOnProfile();
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Maneja los cambios en el campo de búsqueda con debounce.
  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _error = null;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _performSearch);
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Realiza la búsqueda de perfiles según el query actual.
  Future<void> _performSearch() async {
    if (_profileService == null || _query.trim().length < 2) {
      setState(() => _results = []);
      await _reloadNearbyMarkers();
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await _profileService!.searchProfiles(_query.trim());
      final filtered = _currentUserId == null
          ? data
          : data
              .where((item) => item['id']?.toString() != _currentUserId)
              .toList();
      if (!mounted) return;
      setState(() => _results = filtered);
      await _updateMarkersFromProfiles(filtered);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo buscar usuarios');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Centra el mapa en la ubicación del perfil del usuario actual.
  Future<void> _centerMapOnProfile() async {
    if (_profileService == null) return;
    try {
      final profile = await _profileService!.getMyProfile();
      final lat = _parseDouble(profile['latitude']);
      final lng = _parseDouble(profile['longitude']);
      final city = profile['city']?.toString() ?? '';
      final postal = profile['postal_code']?.toString() ?? '';

      setState(() {
        _currentPostal = postal.isEmpty ? 'Sin CP' : postal;
        _currentCity = city.isEmpty ? 'Sin ciudad' : city;
        _postalFilterController.text = postal;
        _cityFilterController.text = city;
      });

      if (lat != null && lng != null) {
        final coords = LatLng(lat, lng);
        _myCoordinates = coords;
        _moveMapTo(coords);
        if (mounted) {
          setState(() {
            _mapStatusMessage = 'Mapa centrado en tu ubicación';
            _mapError = false;
          });
        }
        await _loadNearbyProfiles(coords);
      } else {
        debugPrint(
            'No hay coordenadas guardadas para ciudad="$city" CP="$postal"');
        _moveMapTo(_defaultCenter, zoom: 5.5);
        if (mounted) {
          setState(() {
            _mapStatusMessage = 'No se encontró tu ubicación';
            _mapError = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error centrando mapa: $e');
      if (mounted) {
        setState(() {
          _mapStatusMessage = 'No se pudo centrar el mapa';
          _mapError = true;
        });
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Aplica los filtros de ubicación y actualiza el mapa.
  Future<void> _applyLocationFilters() async {
    if (_profileService == null) return;
    final postal = _postalFilterController.text.trim();
    final city = _cityFilterController.text.trim();
    if (postal.isEmpty && city.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa un código postal o una ciudad'),
          ),
        );
      }
      return;
    }

    setState(() {
      _updatingLocation = true;
      _mapStatusMessage = 'Actualizando búsqueda...';
      _mapError = false;
    });

    try {
      final coords = await _profileService!.geocodeLocation(
        postalCode: postal.isEmpty ? null : postal,
        city: city.isEmpty ? null : city,
      );
      final target = LatLng(coords['latitude']!, coords['longitude']!);
      _moveMapTo(target);
      await _loadNearbyProfiles(target);
      if (!mounted) return;
      setState(() {
        _currentPostal = postal.isEmpty ? 'Sin CP' : postal;
        _currentCity = city.isEmpty ? 'Sin ciudad' : city;
        _mapStatusMessage = 'Búsqueda actualizada';
        _mapError = false;
      });
    } catch (e) {
      debugPrint('Error actualizando ubicación: $e');
      if (mounted) {
        setState(() {
          _mapStatusMessage = 'No se pudo actualizar la búsqueda';
          _mapError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingLocation = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Carga perfiles cercanos y actualiza los marcadores en el mapa
  Future<void> _loadNearbyProfiles(LatLng origin) async {
    if (_profileService == null) return;
    setState(() {
      _loadingMarkers = true;
      _mapStatusMessage = 'Buscando perfiles cercanos...';
      _mapError = false;
    });
    try {
      final data = await _profileService!.getNearbyProfiles(
        latitude: origin.latitude,
        longitude: origin.longitude,
      );
      await _setMarkers(data);
      if (mounted) {
        setState(() {
          _mapStatusMessage = data.isEmpty
              ? 'Sin perfiles cercanos'
              : 'Perfiles cercanos encontrados';
        });
      }
    } catch (e) {
      debugPrint('Error cargando perfiles cercanos: $e');
      if (mounted) {
        setState(() {
          _mapStatusMessage = 'No se pudieron cargar los marcadores';
          _mapError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMarkers = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Recarga los marcadores cercanos en el mapa.
  Future<void> _reloadNearbyMarkers() async {
    if (_myCoordinates != null) {
      await _loadNearbyProfiles(_myCoordinates!);
    } else {
      await _clearMarkers();
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Actualiza los marcadores en el mapa según los perfiles dados.
  Future<void> _updateMarkersFromProfiles(
      List<Map<String, dynamic>> profiles) async {
    if (profiles.isEmpty) {
      await _reloadNearbyMarkers();
      return;
    }
    await _setMarkers(profiles);
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Establece los marcadores en el mapa basados en los perfiles
  Future<void> _setMarkers(List<Map<String, dynamic>> profiles) async {
    final newMarkers = <Marker>[];
    for (final profile in profiles) {
      final lat = _parseDouble(profile['latitude']);
      final lng = _parseDouble(profile['longitude']);
      if (lat == null || lng == null) continue;
      final point = randomOffset(LatLng(lat, lng));
      final profileId = profile['id']?.toString();
      final username = profile['username']?.toString() ?? 'usuario';
      final petName = profile['pet_name']?.toString() ?? '';
      final avatarUrl = profile['avatar_url']?.toString() ?? '';
      final tooltip =
          petName.isNotEmpty ? '$petName (@$username)' : '@$username';
      newMarkers.add(
        Marker(
          width: 44,
          height: 58,
          point: point,
          child: GestureDetector(
            onTap: profileId == null ? null : () => _openProfile(profileId),
            child: Tooltip(
              message: tooltip,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.teal.shade400, width: 2),
                    ),
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.pets,
                                color: Colors.black54,
                                size: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Limpia todos los marcadores del mapa.
  Future<void> _clearMarkers() async {
    if (!mounted) return;
    setState(() {
      _markers.clear();
    });
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Abre la pantalla de perfil para el ID dado.
  void _openProfile(String profileId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: profileId,
          isOwner: false,
        ),
      ),
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Mueve el mapa a la ubicación objetivo dada.
  void _moveMapTo(LatLng target, {double zoom = 11}) {
    if (_mapReady) {
      _mapController.move(target, zoom);
    } else {
      _pendingCenter = target;
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Marca el mapa como listo y mueve a la ubicación pendiente si existe.
  void _onMapReady() {
    _mapReady = true;
    if (_pendingCenter != null) {
      _mapController.move(_pendingCenter!, 11);
      _pendingCenter = null;
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Parsea un valor dinámico a double, retornando null si no
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 26 de Noviembre de 2025
  // Descripción: Genera un pequeño offset aleatorio para las coordenadas dadas.
  LatLng randomOffset(LatLng base) {
    final rand = Random();
    const double maxOffset = 0.001;
    final latOffset = (rand.nextDouble() * 2 - 1) * maxOffset;
    final lngOffset = (rand.nextDouble() * 2 - 1) * maxOffset;
    return LatLng(base.latitude + latOffset, base.longitude + lngOffset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar amigos'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 96),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SearchMap(
                          mapController: _mapController,
                          markers: _markers,
                          defaultCenter: _defaultCenter,
                          iberianBounds: _iberianBounds,
                          onMapReady: _onMapReady,
                          overlayWidget: MapStatusOverlay(
                            statusMessage: _mapStatusMessage,
                            postalLabel: _postalLabel,
                            cityLabel: _cityLabel,
                            showError: _mapError,
                            loadingMarkers: _loadingMarkers,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SearchLocationControls(
                        postalController: _postalFilterController,
                        cityController: _cityFilterController,
                        updatingLocation: _updatingLocation,
                        onApplyFilters: _updatingLocation
                            ? null
                            : () {
                                _applyLocationFilters();
                              },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: SearchResultsOverlay(
                    controller: _controller,
                    query: _query,
                    loading: _loading,
                    error: _error,
                    results: _results,
                    onQueryChanged: _onQueryChanged,
                    onProfileTap: _openProfile,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Autor: Wilbert López Veras
  /// Fecha de creación: 26 de Noviembre de 2025
  /// Descripción: Obtiene la etiqueta de código postal actual.
  String get _postalLabel =>
      _currentPostal == null || _currentPostal!.isEmpty ? 'Sin CP' : _currentPostal!;

  /// Autor: Wilbert López Veras
  /// Fecha de creación: 26 de Noviembre de 2025
  /// Descripción: Obtiene la etiqueta de ciudad actual.
  String get _cityLabel =>
      _currentCity == null || _currentCity!.isEmpty ? 'Sin ciudad' : _currentCity!;

}
