import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/services/report_service.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_screen.dart';

import '../../theme/app_colors.dart';

class AdminPostModerateScreen extends StatefulWidget {
  const AdminPostModerateScreen({super.key});

  @override
  State<AdminPostModerateScreen> createState() =>
      _AdminPostModerateScreenState();
}

class _AdminPostModerateScreenState extends State<AdminPostModerateScreen> {
  final ReportService _reportService = ReportService.instance;
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _reportService.getPostReports();
      if (!mounted) return;
      setState(() => _reports = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _ignoreReport(String reportId) async {
    try {
      await _reportService.ignorePostReport(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte ignorado')),
      );
      await _loadReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deletePost(String reportId, String postId) async {
    try {
      await _reportService.deletePostAsModerator(postId);
      await _reportService.ignorePostReport(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post eliminado')),
      );
      await _loadReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _confirmDeletePost(String reportId, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
          'Esta acción eliminará el post reportado. ¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePost(reportId, postId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderar Posts'),
        backgroundColor: kAdminDarkColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      final reporter =
                          report['reporter'] as Map<String, dynamic>? ?? {};
                      final post =
                          report['post'] as Map<String, dynamic>? ?? {};
                      final author =
                          post['profiles'] as Map<String, dynamic>? ?? {};
                      final postId = post['id']?.toString() ?? '';
                      final imageUrl = post['image_url'] ??
                          'https://placehold.co/600x400/fee2e2/b91c1c?text=Reportado';
                      final description =
                          post['description']?.toString().trim().isNotEmpty ==
                                  true
                              ? post['description']
                              : 'Sin descripción';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              imageUrl,
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
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Descripción: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: description,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Autor del post: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${author['username'] ?? 'Desconocido'} (${author['email'] ?? 'Sin correo'})',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Reportado por: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${reporter['username'] ?? 'Anónimo'} (${reporter['email'] ?? 'sin correo'})',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Motivo: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: report['reason'] ?? 'Sin motivo',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: postId.isEmpty
                                              ? null
                                              : () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ViewPostScreen(
                                                        postId: postId,
                                                        isOwner: false,
                                                      ),
                                                    ),
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimaryColor,
                                          ),
                                          child: const Text('Ver publicación'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _ignoreReport(report['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[500],
                                          ),
                                          child: const Text('Ignorar reporte'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: postId.isEmpty
                                              ? null
                                              : () => _confirmDeletePost(
                                                    report['id'],
                                                    postId,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Eliminar publicación'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
