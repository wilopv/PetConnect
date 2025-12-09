import 'package:flutter/material.dart';
import 'package:pet_connect_app/lib/services/report_service.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_screen.dart';

import '../../theme/app_colors.dart';

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
          _ReportsList(
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

              return _ReportCard(
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
                  _ReportButton(
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
                  _ReportButton(
                    label: 'Ignorar',
                    color: Colors.grey[500],
                    onPressed: () => _ignorePostReport(report['id']),
                  ),
                  _ReportButton(
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
          _ReportsList(
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

              return _ReportCard(
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
                  _ReportButton(
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
                  _ReportButton(
                    label: 'Ignorar',
                    color: Colors.grey[500],
                    onPressed: () => _ignoreCommentReport(report['id']),
                  ),
                  _ReportButton(
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

class _ReportsList extends StatelessWidget {
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>> items;
  final Widget Function(BuildContext, Map<String, dynamic>) builder;

  const _ReportsList({
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

class _ReportCard extends StatelessWidget {
  final String? imageUrl;
  final List<Widget> body;
  final List<_ReportButton> actions;

  const _ReportCard({
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

class _ReportButton extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const _ReportButton({
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}

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
