/// Autor: Wilbert López Veras 
/// Fecha de creación: 6 de Diciembre de 2025
/// Descripción:
/// Pantalla para crear una nueva publicación.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_connect_app/lib/services/posts_service.dart';
import 'package:pet_connect_app/theme/app_colors.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 6 de Diciembre de 2025
  // Descripción:
  // Abre el selector de imágenes para elegir una foto desde la galería o cámara.
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _selectedImage = picked);
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 6 de Diciembre de 2025
  // Descripción:
  // Maneja el envío de la nueva publicación al servidor.
  Future<void> _submitPost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una foto para continuar')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final mimeType = _selectedImage!.mimeType ?? _mimeFromPath(_selectedImage!.path);
      final bytes = await File(_selectedImage!.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUri = 'data:$mimeType;base64,$base64Image';

      final description = _descriptionController.text.trim();

      await PostsService.createPost(description, dataUri);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación creada con éxito')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 6 de Diciembre de 2025
  // Descripción:
  // Formatea el error recibido para mostrar un mensaje más amigable al usuario.
  String _formatError(Object error) {
    final raw = error.toString().trim();
    try {
      final Map<String, dynamic> data = jsonDecode(raw);
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // No era un JSON, seguimos
    }
    return raw.replaceFirst('Exception: ', '');
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 6 de Diciembre de 2025
  // Descripción:
  // Obtiene el MIME type basado en la extensión del archivo.
  String _mimeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePlaceholder = Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!, width: 2),
      ),
      child: Stack(
        children: [
          if (_selectedImage != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Toca para añadir una foto',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'gallery',
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: const Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'camera',
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: const Icon(Icons.camera_alt_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Publicación'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Publicar',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: imagePlaceholder,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Añade una descripción...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
