/// Autor: Wilbert López Veras
/// Fecha de creación: 2 de diciembre de 2025
/// Descripción:
/// Lista reutilizable para mostrar reportes con manejo de estados (carga/error/vacío).

import 'package:flutter/material.dart';

class AdminReportsList extends StatelessWidget {
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>> items;
  final Widget Function(BuildContext, Map<String, dynamic>) builder;

  const AdminReportsList({
    super.key,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.items,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 60),
            Center(child: Text('No hay reportes')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => builder(context, items[index]),
      ),
    );
  }
}
