/// Autor: Wilbert López Veras 
/// Fecha de creación: 29 de Octubre de 2025
/// Descripción:
/// Pantalla de creación de cuenta de la aplicación.  
///  

import 'package:flutter/material.dart';
import '../lib/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // CONTROLADORES
  final _usernameController = TextEditingController();   // usuario visible
  final _emailController = TextEditingController();      // email necesario
  final _passwordController = TextEditingController();
  final _postalController = TextEditingController();
  final _cityController = TextEditingController();
  final _petNameController = TextEditingController();

  String? _petType;
  String? _petGender;

  // Autor: Wilbert López Veras
  // Fecha de creación: 29 de Octubre de 2025
  // Descripción:
  // Maneja el proceso de creación de cuenta.
  Future<void> _handleSignup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa usuario, email y contraseña')),
      );
      return;
    }

    // Llamada al backend
    final postalCode = _postalController.text.trim();
    final city = _cityController.text.trim();
    final petName = _petNameController.text.trim();
    final petType = _petType;
    final petGender = _petGender;

    final error = await AuthService.instance.signup(
      email,
      password,
      username,
      postalCode: postalCode.isEmpty ? null : postalCode,
      city: city.isEmpty ? null : city,
      petName: petName.isEmpty ? null : petName,
      petType: petType,
      petGender: petGender,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _postalController.dispose();
    _cityController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _postalController,
            decoration: const InputDecoration(labelText: 'Código Postal'),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Ciudad'),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _petNameController,
            decoration: const InputDecoration(labelText: 'Nombre de tu Mascota'),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _petType,
            decoration: const InputDecoration(labelText: 'Tipo de Mascota'),
            items: const ['Perro', 'Gato', 'Pajaro', 'Reptil', 'Otro']
                .map((tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _petType = v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _petGender,
            decoration: const InputDecoration(labelText: 'Género de tu Mascota'),
            items: const ['Macho', 'Hembra', 'Otro']
                .map((genero) => DropdownMenuItem(
                      value: genero,
                      child: Text(genero),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _petGender = v),
          ),
          const SizedBox(height: 32),

          _RegisterButton(onPressed: _handleSignup),
        ],
      ),
    );
  }
}

// Autor: Wilbert López Veras
// Fecha de creación: 29 de Octubre de 2025
// Descripción:
// Botón personalizado para registrarse.
class _RegisterButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RegisterButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Registrarse'),
    );
  }
}
