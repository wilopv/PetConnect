/// Autor: Wilbert López Veras
/// Fecha de creación: 26 de Noviembre de 2025
/// Descripción:
/// Pantalla de búsqueda de otros perfiles de usuarios en la aplicación con campo de búsqueda y mapa.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/lib/services/profile_service.dart';
import 'package:pet_connect_app/shared/profile/profile_screen.dart';
import 'package:pet_connect_app/widgets/search_map.dart';

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

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _error = null;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _performSearch);
  }

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

  Future<void> _reloadNearbyMarkers() async {
    if (_myCoordinates != null) {
      await _loadNearbyProfiles(_myCoordinates!);
    } else {
      await _clearMarkers();
    }
  }

  Future<void> _updateMarkersFromProfiles(
      List<Map<String, dynamic>> profiles) async {
    if (profiles.isEmpty) {
      await _reloadNearbyMarkers();
      return;
    }
    await _setMarkers(profiles);
  }

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

  Future<void> _clearMarkers() async {
    if (!mounted) return;
    setState(() {
      _markers.clear();
    });
  }

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

  void _moveMapTo(LatLng target, {double zoom = 11}) {
    if (_mapReady) {
      _mapController.move(target, zoom);
    } else {
      _pendingCenter = target;
    }
  }

  void _onMapReady() {
    _mapReady = true;
    if (_pendingCenter != null) {
      _mapController.move(_pendingCenter!, 11);
      _pendingCenter = null;
    }
  }

  Widget _buildMapOverlay() {
    final postalText =
        _currentPostal == null || _currentPostal!.isEmpty ? 'Sin CP' : _currentPostal!;
    final cityText =
        _currentCity == null || _currentCity!.isEmpty ? 'Sin ciudad' : _currentCity!;
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
            _mapStatusMessage,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _mapError ? Colors.redAccent : Colors.black87,
            ),
          ),
          Text(
            'CP: $postalText',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            'Ciudad: $cityText',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (_loadingMarkers)
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

  Widget _buildSearchOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Ingresa nombre de usuario',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _query.isEmpty
              ? const SizedBox.shrink()
              : ConstrainedBox(
                  key: ValueKey(_query),
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.white,
                        child: _loading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _error != null
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  )
                                : _results.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Text(
                                            'Sin coincidencias',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: _results.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final user = _results[index];
                                          final avatar =
                                              user['avatar_url'] as String? ?? '';
                                          final userId = user['id'] as String?;
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: avatar.isNotEmpty
                                                  ? NetworkImage(avatar)
                                                  : const NetworkImage(
                                                      'https://placehold.co/60x60'),
                                            ),
                                            title: Text(
                                              user['username'] ?? 'usuario',
                                            ),
                                            subtitle: Text(
                                              user['city'] ?? 'Ciudad pendiente',
                                            ),
                                            onTap: userId == null
                                                ? null
                                                : () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ProfileScreen(
                                                          profileId: userId,
                                                          isOwner: false,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                          );
                                        },
                                      ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

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
                          overlayWidget: _buildMapOverlay(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildLocationControls(),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: _buildSearchOverlay(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationControls() {
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
                    controller: _postalFilterController,
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
                    controller: _cityFilterController,
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
                onPressed: _updatingLocation ? null : _applyLocationFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _updatingLocation
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
