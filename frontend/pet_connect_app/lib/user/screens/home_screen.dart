/// Autor: Wilbert López Veras 
/// Fecha de creación: 29 de Octubre de 2025
/// Descripción:
/// Pantalla principal del usuario en la aplicación.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/logo_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LogoWidget(size: 28),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _HomeButton(
                title: 'Buscar Amigos',
                subtitle: 'Encuentra y visita otros perfiles.',
                icon: Icons.search,
                color: Colors.deepPurple,
                onTap: () => Navigator.pushNamed(context, '/search'),
              ),
              const SizedBox(height: 20),
              _HomeButton(
                title: 'Ver Mi Perfil',
                subtitle: 'Mira tu perfil y el de tu mascota.',
                icon: Icons.pets,
                color: kAccentColor,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              const SizedBox(height: 20),
              _HomeButton(
                title: 'Notificaciones',
                subtitle: 'Seguimientos y mensajes nuevos.',
                icon: Icons.notifications,
                color: kPrimaryColor,
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              const SizedBox(height: 20),
              _HomeButton(
                title: 'Conversaciones',
                subtitle: 'Chatea con otros dueños.',
                icon: Icons.chat,
                color: Colors.cyan,
                onTap: () => Navigator.pushNamed(context, '/conversations/list'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, size: 32, color: const Color.fromARGB(255, 104, 85, 85)),
            ],
          ),
        ),
      ),
    );
  }
}
