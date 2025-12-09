/// Autor: Wilbert López Veras 
/// Fecha de creación: 8 de Diciembre de 2025
/// Descripción:
/// Pantalla para ver publicaciones individuales, sus detalles y comentarios.
 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_connect_app/lib/services/posts_service.dart';
import 'package:pet_connect_app/lib/services/likes_service.dart';
import 'package:pet_connect_app/lib/services/post_comments_service.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';
import 'package:pet_connect_app/widgets/report_sheet.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_media.dart';
import 'package:pet_connect_app/user/screens/posts/view_post_comments.dart';
import 'package:pet_connect_app/user/screens/posts/new_comment_input.dart';

class ViewPostScreen extends StatefulWidget {
  final String postId;
  final bool isOwner;
  const ViewPostScreen({
    super.key,
    required this.postId,
    this.isOwner = false,
  });

  @override
  State<ViewPostScreen> createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _deleting = false;
  bool _liking = false;
  bool _sendingComment = false;
  String? _currentUserId;
  final Set<String> _deletingComments = {};
  String? _error;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPost();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await PostsService.getPostById(widget.postId);
      if (!mounted) return;
      setState(() => _post = post);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _formatError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await PostCommentsService.getComments(widget.postId);
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _formatError(e));
    }
  }

  Future<void> _loadCurrentUser() async {
    final id = await AuthService.instance.getUserId();
    if (!mounted) return;
    setState(() => _currentUserId = id);
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      final newComment =
          await PostCommentsService.addComment(widget.postId, content);
      if (!mounted) return;
      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingComment = false);
      }
    }
  }

  Future<void> _deletePost() async {
    setState(() => _deleting = true);
    try {
      await PostsService.deletePost(widget.postId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    setState(() => _deletingComments.add(commentId));
    try {
      await PostCommentsService.deleteComment(widget.postId, commentId);
      if (!mounted) return;
      setState(() {
        _comments.removeWhere((c) => c['id'] == commentId);
        _deletingComments.remove(commentId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingComments.remove(commentId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(e))),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePost();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleLike(bool likedByMe) async {
    setState(() => _liking = true);
    try {
      if (likedByMe) {
        await LikesService.unlikePost(widget.postId);
        if (!mounted) return;
        setState(() {
          _post!['liked_by_me'] = false;
          _post!['likes_count'] = (_post!['likes_count'] ?? 1) - 1;
        });
      } else {
        await LikesService.likePost(widget.postId);
        if (!mounted) return;
        setState(() {
          _post!['liked_by_me'] = true;
          _post!['likes_count'] = (_post!['likes_count'] ?? 0) + 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _liking = false);
      }
    }
  }

  void _confirmDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteComment(commentId);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'No se encontró la publicación')),
      );
    }

    final createdAt = _post!['created_at'] as String?;
    final formattedDate = createdAt != null
        ? DateFormat.yMMMMd().add_Hm().format(DateTime.parse(createdAt))
        : null;
    final likedByMe = _post!['liked_by_me'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        actions: [
          if (!widget.isOwner)
            IconButton(
              tooltip: 'Reportar publicación',
              icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              onPressed: () => showReportPostSheet(context, widget.postId),
            ),
          if (widget.isOwner)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _deleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ViewPostMedia(
                imageUrl: _post!['image_url'] ?? '',
                description: _post!['description']?.toString().trim() ?? '',
                formattedDate: formattedDate,
                likesCount: _post!['likes_count'] ?? 0,
                likedByMe: likedByMe,
                liking: _liking,
                onToggleLike: () => _handleToggleLike(likedByMe),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Comentarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ViewPostComments(
                comments: _comments,
                currentUserId: _currentUserId,
                deletingCommentIds: _deletingComments,
                onDelete: _confirmDeleteComment,
                onReport: (id) => showReportCommentSheet(context, id),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: NewCommentInput(
                  controller: _commentController,
                  sending: _sendingComment,
                  onSend: _sendComment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatError(Object error) {
    final raw = error.toString().trim();
    try {
      final Map<String, dynamic> data = jsonDecode(raw);
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // No era JSON, continuamos
    }
    return raw.replaceFirst('Exception: ', '');
  }
}
