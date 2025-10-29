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
      },
    );
  }
}