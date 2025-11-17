import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AdminUserListScreen extends StatelessWidget {
  const AdminUserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Usuarios'),
        backgroundColor: kAdminDarkColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://placehold.co/50x50/0ea5e9/white?text=Buddy',
                    ),
                  ),
                  title: const Text('Buddy (dueño: usuario@pet.com)'),
                  subtitle: const Text('Golden Retriever'),
                  onTap: () =>
                      Navigator.pushNamed(context, '/admin/profile/edit'),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://placehold.co/50x50/34d399/white?text=Loki',
                    ),
                  ),
                  title: const Text('Loki (dueña: ana@pet.com)'),
                  subtitle: const Text('Gato Siamés'),
                  onTap: () =>
                      Navigator.pushNamed(context, '/admin/profile/edit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
