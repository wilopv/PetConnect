/// Autor: Wilbert López Veras
/// Fecha de creación: 2 de diciembre de 2025
/// Descripción:
/// Tarjeta reutilizable para mostrar información de reportes con acciones.

import 'package:flutter/material.dart';

class AdminReportCard extends StatelessWidget {
  final String? imageUrl;
  final List<Widget> body;
  final List<Widget> actions;

  const AdminReportCard({
    super.key,
    required this.imageUrl,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Text('Sin imagen'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...body,
                const SizedBox(height: 16),
                Row(
                  children: List.generate(actions.length, (index) {
                    final button = actions[index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == actions.length - 1 ? 0 : 16,
                        ),
                        child: button,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
