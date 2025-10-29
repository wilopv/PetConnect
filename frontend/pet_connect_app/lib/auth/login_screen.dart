/// Autor: Wilbert López Veras 
/// Fecha de creación: 29 de Octubre de 2025
/// Descripción:
/// Pantalla de inicio de sesión de la aplicación.   

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/logo_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.pets, size: 80, color: kPrimaryColor),
                  const SizedBox(height: 16),
                  const Center(child: LogoWidget(size: 40)),
                  Text(
                    'Conecta. Comparte. Ama.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Text('Iniciar Sesion'),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('¿No tienes cuenta? Crear una'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}