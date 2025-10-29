/// Autor: Wilbert López Veras 
/// Fecha de creación: 29 de Octubre de 2025
/// Descripción:
/// Pantalla de creación de cuenta de la aplicación.  
///  
import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
        children: const [
          TextField(decoration: InputDecoration(labelText: 'Usuario')),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(labelText: 'Contrase\u00f1a'),
            obscureText: true,
          ),
          SizedBox(height: 16),
          TextField(decoration: InputDecoration(labelText: 'C\u00f3digo Postal')),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(labelText: 'Nombre de tu Mascota'),
          ),
          SizedBox(height: 16),
          _PetTypeDropdown(),
          SizedBox(height: 32),
          _RegisterButton(),
        ],
      ),
    );
  }
}

class _PetTypeDropdown extends StatelessWidget {
  const _PetTypeDropdown();

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Tipo de Mascota'),
      items: const ['Perro', 'Gato', 'Pajaro', 'Reptil', 'Otro']
          .map(
            (tipo) => DropdownMenuItem<String>(
              value: tipo,
              child: Text(tipo),
            ),
          )
          .toList(),
      onChanged: (_) {},
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      },
      child: const Text('Registrarse'),
    );
  }
}