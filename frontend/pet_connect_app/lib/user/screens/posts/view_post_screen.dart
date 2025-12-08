/// Autor: Wilbert López Veras 
/// Fecha de creación: 8 de Diciembre de 2025
/// Descripción:
/// Pantalla para ver publicaciones individuales, sus detalles y comentarios.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_connect_app/lib/services/posts_service.dart';
import 'package:pet_connect_app/lib/services/likes_service.dart';
import 'package:pet_connect_app/lib/services/post_comments_service.dart';
import 'package:pet_connect_app/lib/services/auth_service.dart';

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
      setState(() => _error = e.toString());
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
      setState(() => _error = e.toString());
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
      setState(() => _error = e.toString());
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
        SnackBar(content: Text(e.toString())),
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
        SnackBar(content: Text(e.toString())),
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
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 360,
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _post!['image_url'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text('Sin imagen')),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formattedDate != null)
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _post!['description']?.toString().trim().isNotEmpty == true
                          ? _post!['description']
                          : 'Sin descripción',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_post!['likes_count'] ?? 0} me gusta',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(
                        likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: likedByMe ? Colors.red : Colors.grey[600],
                      ),
                      onPressed: _liking
                          ? null
                          : () async {
                              setState(() => _liking = true);
                              try {
                                if (likedByMe) {
                                  await LikesService.unlikePost(widget.postId);
                                  setState(() {
                                    _post!['liked_by_me'] = false;
                                    _post!['likes_count'] =
                                        (_post!['likes_count'] ?? 1) - 1;
                                  });
                                } else {
                                  await LikesService.likePost(widget.postId);
                                  setState(() {
                                    _post!['liked_by_me'] = true;
                                    _post!['likes_count'] =
                                        (_post!['likes_count'] ?? 0) + 1;
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _liking = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Comentarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _comments.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Aún no hay comentarios en esta publicación'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final profile = comment['profiles'] as Map<String, dynamic>?;
                        final commentId = comment['id']?.toString();
                        final canDelete = comment['user_id'] == _currentUserId && commentId != null;
                        final isDeleting = commentId != null && _deletingComments.contains(commentId);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profile?['avatar_url'] != null
                                ? NetworkImage(profile!['avatar_url'])
                                : const NetworkImage('https://placehold.co/50'),
                          ),
                          title: Text(profile?['username'] ?? 'Usuario'),
                          subtitle: Text(comment['content'] ?? ''),
                          trailing: canDelete
                              ? IconButton(
                                  icon: isDeleting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.delete_outline),
                                  onPressed: isDeleting
                                      ? null
                                      : () => _confirmDeleteComment(commentId),
                                )
                              : null,
                        );
                      },
                    ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un comentario...',
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: _sendingComment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _sendingComment ? null : _sendComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
