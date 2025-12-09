// Autor: Wilbert López Veras
// Fecha de creación: 19 de Diciembre de 2025
// Descripción: Pantalla para editar el perfil del usuario.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:pet_connect_app/lib/config/api_config.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/lib/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}


class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _postalController = TextEditingController();
  final _cityController = TextEditingController();
  final _petNameController = TextEditingController();
  final _bioController = TextEditingController();
  final picker.ImagePicker _picker = picker.ImagePicker();

  String? _selectedPetType;
  String? _selectedPetGender;
  String? _currentAvatarUrl;
  String? _avatarBase64;
  File? _avatarFile;
  String? _editingUserId;
  bool _editingOwnProfile = true;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  ProfileService? _profileService;

  final List<String> _petTypes = const ['Perro', 'Gato', 'Pajaro', 'Reptil', 'Otro'];
  final List<String> _petGenders = const ['Macho', 'Hembra', 'Otro'];

  @override
  void initState() {
    super.initState();
    _initProfile();
  }


  // Autor: Wilbert López Veras
  // Fecha de creación: 19 de Diciembre de 2025
  // Descripción:
  // Inicializa el perfil cargando los datos del usuario.
  Future<void> _initProfile() async {
    final token = await AuthService.instance.getToken();
    final currentUserId = await AuthService.instance.getUserId();

    if (!mounted) return;

    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'No hay sesión activa';
      });
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    _profileService = ProfileService(
      baseUrl: ApiConfig.baseUrl,
      token: token,
    );

    try {
      final profile = widget.profile;
      _editingUserId = profile['id']?.toString();
      _editingOwnProfile =
          currentUserId != null && _editingUserId == currentUserId;
      _usernameController.text = profile['username'] ?? '';
      _postalController.text = profile['postal_code'] ?? '';
      _cityController.text = profile['city'] ?? '';
      _petNameController.text = profile['pet_name'] ?? '';
      _selectedPetType = profile['pet_type'];
      _selectedPetGender = profile['pet_gender'];
      _currentAvatarUrl = profile['avatar_url'];
      _bioController.text = profile['bio'] ?? '';
      _avatarBase64 = null;
      _avatarFile = null;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 19 de Diciembre de 2025
  // Descripción:
  // Guarda los cambios realizados en el perfil del usuario.
  Future<void> _saveProfile() async {
    if (_profileService == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

    final payload = {
      'username': _nullable(_usernameController.text),
      'postal_code': _nullable(_postalController.text),
      'city': _nullable(_cityController.text),
      'pet_name': _nullable(_petNameController.text),
      'pet_type': _selectedPetType,
      'pet_gender': _selectedPetGender,
      'avatar_base64': _avatarBase64,
      'bio': _nullable(_bioController.text),
    };
    payload.removeWhere((key, value) => value == null);

    try {
      if (_editingOwnProfile || _editingUserId == null) {
        await _profileService!.updateMyProfile(payload);
      } else {
        await _profileService!.updateProfileById(_editingUserId!, payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _usernameController.dispose();
    _postalController.dispose();
    _cityController.dispose();
    _petNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 19 de Diciembre de 2025
  // Descripción:
  // Permite al usuario seleccionar una imagen desde la galería o cámara.
  Future<void> _pickImage(picker.ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final mime = picked.mimeType ?? 'image/jpeg';

      setState(() {
        _avatarFile = file;
        _avatarBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la imagen: $e')),
      );
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 19 de Diciembre de 2025
  // Descripción:
  // Muestra un modal para seleccionar la fuente de la imagen (galería o cámara).
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(picker.ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(picker.ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 19 de Diciembre de 2025
  // Descripción:
  // Obtiene el proveedor de imagen para el avatar del usuario.
  ImageProvider? _avatarImageProvider() {
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    }
    if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      return NetworkImage(_currentAvatarUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Perfil')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: _avatarImageProvider(),
                        child: _avatarImageProvider() == null
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: _showImageSourceSheet,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Actualiza tu foto de perfil',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nombre de usuario'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalController,
              decoration: const InputDecoration(labelText: 'Código Postal'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _petNameController,
              decoration: const InputDecoration(labelText: 'Nombre de tu mascota'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPetType,
              decoration: const InputDecoration(labelText: 'Tipo de mascota'),
              items: _petTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedPetType = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPetGender,
              decoration: const InputDecoration(labelText: 'Género de tu mascota'),
              items: _petGenders
                  .map(
                    (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedPetGender = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Biografía'),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
