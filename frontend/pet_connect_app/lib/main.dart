/// Autor: Wilbert López Veras 
/// Fecha de creación: 29 de Octubre de 2025
/// Descripción:
/// Archivo principal de la aplicación Flutter. 
/// Configura el tema, las rutas y el punto de entrada de la aplicación.

import 'package:flutter/material.dart';

import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'theme/app_theme.dart';
import 'user/main_wrapper.dart';
import 'admin/main_admin_wrapper.dart';
import 'user/screens/search_screen.dart';
import 'shared/profile/profile_screen.dart';
import 'user/screens/conversations/conversation_list_screen.dart';
import 'user/screens/conversations/conversation_details_screen.dart';


void main() {
  runApp(const PetConnectApp());
}

class PetConnectApp extends StatelessWidget {
  const PetConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainWrapper(initialIndex: 0),
        '/moderatorHome': (context) => const MainAdminWrapper(initialIndex: 0),
        '/search': (context) => const SearchScreen(),
        '/profile': (context) => const ProfileScreen(isOwner: true),
        '/conversations/list': (context) => const ConversationListScreen(),
        '/conversation/detail': (context) => const ConversationDetailsScreen(),
      },
    );
  }
}
