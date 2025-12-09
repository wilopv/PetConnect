/// Autor: Wilbert López Veras
/// Fecha de creación: 1 de diciembre de 2025
/// Descripción:
/// Pantalla de lista de reportes para el moderador.

import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/services/report_service.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_screen.dart';

import '../../theme/app_colors.dart';
import 'admin_report_button.dart';
import 'admin_report_card.dart';
import 'admin_reports_list.dart';

class AdminReportModerateScreen extends StatefulWidget {
  const AdminReportModerateScreen({super.key});

  @override
  State<AdminReportModerateScreen> createState() =>
      _AdminReportModerateScreenState();
}

class _AdminReportModerateScreenState
    extends State<AdminReportModerateScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final ReportService _reportService = ReportService.instance;

  List<Map<String, dynamic>> _postReports = [];
  List<Map<String, dynamic>> _commentReports = [];
  bool _loadingPosts = true;
  bool _loadingComments = true;
  String? _errorPosts;
  String? _errorComments;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPostReports();
    _loadCommentReports();
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Carga los reportes de posts desde el servidor.
  Future<void> _loadPostReports() async {
    setState(() {
      _loadingPosts = true;
      _errorPosts = null;
    });
    try {
      final data = await _reportService.getPostReports();
      if (!mounted) return;
      setState(() => _postReports = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorPosts = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingPosts = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Carga los reportes de comentarios desde el servidor.
  Future<void> _loadCommentReports() async {
    setState(() {
      _loadingComments = true;
      _errorComments = null;
    });
    try {
      final data = await _reportService.getCommentReports();
      if (!mounted) return;
      setState(() => _commentReports = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorComments = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingComments = false);
      }
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Ignora un reporte de post por su ID.
  Future<void> _ignorePostReport(String reportId) async {
    try {
      await _reportService.ignorePostReport(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte ignorado')),
      );
      await _loadPostReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Ignora un reporte de comentario por su ID.
  Future<void> _ignoreCommentReport(String reportId) async {
    try {
      await _reportService.ignoreCommentReport(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte ignorado')),
      );
      await _loadCommentReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Elimina un post reportado por su ID y el ID del reporte.
  Future<void> _deleteReportedPost(String reportId, String postId) async {
    try {
      await _reportService.deletePostAsModerator(postId);
      try {
        await _reportService.ignorePostReport(reportId);
      } catch (_) {
        // El reporte puede haber sido eliminado en cascada; ignoramos el error.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post eliminado')),
      );
      await _loadPostReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Elimina un comentario reportado por su ID y el ID del reporte.
  Future<void> _deleteReportedComment(
    String reportId,
    String postId,
    String commentId,
  ) async {
    try {
      await _reportService.deleteCommentAsModerator(postId, commentId);
      try {
        await _reportService.ignoreCommentReport(reportId);
      } catch (_) {
        // El reporte puede haber sido eliminado en cascada; ignoramos el error.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario eliminado')),
      );
      await _loadCommentReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Muestra un diálogo de confirmación antes de eliminar un post.
  void _confirmDeletePost(String reportId, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Deseas eliminar el post reportado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteReportedPost(reportId, postId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Autor: Wilbert López Veras
  // Fecha de creación: 1 de diciembre de 2025
  // Descripción:
  // Muestra un diálogo de confirmación antes de eliminar un comentario.
  void _confirmDeleteComment(
    String reportId,
    String postId,
    String commentId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content:
            const Text('Esta acción eliminará el comentario reportado. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteReportedComment(reportId, postId, commentId);
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
        title: const Text('Moderar Reportes'),
        backgroundColor: kAdminDarkColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        toolbarTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Comentarios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminReportsList(
            loading: _loadingPosts,
            error: _errorPosts,
            onRefresh: _loadPostReports,
            items: _postReports,
            builder: (context, report) {
              final reporter =
                  report['reporter'] as Map<String, dynamic>? ?? {};
              final post = report['post'] as Map<String, dynamic>? ?? {};
              final author =
                  post['profiles'] as Map<String, dynamic>? ?? {};
              final postId = post['id']?.toString() ?? '';
              final imageUrl = post['image_url'] ??
                  'https://placehold.co/600x400/fee2e2/b91c1c?text=Reportado';
              final description = post['description']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? post['description']
                  : 'Sin descripción';

              return AdminReportCard(
                imageUrl: imageUrl,
                body: [
                  _labelValue('Descripción: ', description),
                  const SizedBox(height: 12),
                  _labelValue(
                    'Autor del post: ',
                    '${author['username'] ?? 'Desconocido'} (${author['email'] ?? 'Sin correo'})',
                  ),
                  const SizedBox(height: 4),
                  _labelValue(
                    'Reportado por: ',
                    '${reporter['username'] ?? 'Anónimo'} (${reporter['email'] ?? 'sin correo'})',
                  ),
                  const SizedBox(height: 4),
                  _labelValue('Motivo: ', report['reason'] ?? 'Sin motivo'),
                ],
                actions: [
                  AdminReportButton(
                    label: 'Ver',
                    color: kPrimaryColor,
                    onPressed: postId.isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewPostScreen(
                                  postId: postId,
                                  isOwner: false,
                                ),
                              ),
                            ),
                  ),
                  AdminReportButton(
                    label: 'Ignorar',
                    color: Colors.grey[500],
                    onPressed: () => _ignorePostReport(report['id']),
                  ),
                  AdminReportButton(
                    label: 'Eliminar Post',
                    color: Colors.red,
                    onPressed: postId.isEmpty
                        ? null
                        : () => _confirmDeletePost(report['id'], postId),
                  ),
                ],
              );
            },
          ),
          AdminReportsList(
            loading: _loadingComments,
            error: _errorComments,
            onRefresh: _loadCommentReports,
            items: _commentReports,
            builder: (context, report) {
              final reporter =
                  report['reporter'] as Map<String, dynamic>? ?? {};
              final comment =
                  report['comment'] as Map<String, dynamic>? ?? {};
              final postId = comment['post_id']?.toString() ?? '';
              final commentId = comment['id']?.toString() ?? '';
              final author =
                  comment['profiles'] as Map<String, dynamic>? ?? {};
              final content =
                  comment['content']?.toString() ?? 'Sin contenido';

              return AdminReportCard(
                imageUrl: null,
                body: [
                  _labelValue('Comentario: ', content),
                  const SizedBox(height: 12),
                  _labelValue(
                    'Autor del comentario: ',
                    '${author['username'] ?? 'Desconocido'} (${author['email'] ?? 'Sin correo'})',
                  ),
                  const SizedBox(height: 4),
                  _labelValue(
                    'Reportado por: ',
                    '${reporter['username'] ?? 'Anónimo'} (${reporter['email'] ?? 'sin correo'})',
                  ),
                  const SizedBox(height: 4),
                  _labelValue('Motivo: ', report['reason'] ?? 'Sin motivo'),
                ],
                actions: [
                  AdminReportButton(
                    label: 'Ver',
                    color: kPrimaryColor,
                    onPressed: postId.isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewPostScreen(
                                  postId: postId,
                                  isOwner: false,
                                ),
                              ),
                            ),
                  ),
                  AdminReportButton(
                    label: 'Ignorar',
                    color: Colors.grey[500],
                    onPressed: () => _ignoreCommentReport(report['id']),
                  ),
                  AdminReportButton(
                    label: 'Eliminar comentario',
                    color: Colors.red,
                    onPressed: postId.isEmpty || commentId.isEmpty
                        ? null
                        : () =>
                            _confirmDeleteComment(
                              report['id'],
                              postId,
                              commentId,
                            ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Autor: Wilbert López Veras
// Fecha de creación: 1 de diciembre de 2025
// Descripción:
// Widget que muestra una etiqueta y su valor correspondiente.
Widget _labelValue(String label, String value) {
  return Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        TextSpan(text: value),
      ],
    ),
  );
}
