/// Autor: Wilbert López Veras
/// Fecha de creación: 19 de Noviembre de 2025
/// Descripción:
/// Lista de comentarios de un post con acciones de eliminar o reportar.

import 'package:flutter/material.dart';

typedef CommentDeleteCallback = void Function(String commentId);
typedef CommentReportCallback = void Function(String commentId);

/// Renderiza la sección de comentarios junto con los botones contextuales.
class ViewPostComments extends StatelessWidget {
  final List<Map<String, dynamic>> comments;
  final String? currentUserId;
  final Set<String> deletingCommentIds;
  final CommentDeleteCallback onDelete;
  final CommentReportCallback onReport;

  const ViewPostComments({
    super.key,
    required this.comments,
    required this.currentUserId,
    required this.deletingCommentIds,
    required this.onDelete,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Aún no hay comentarios en esta publicación'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final comment = comments[index];
        final profile = comment['profiles'] as Map<String, dynamic>?;
        final commentId = comment['id']?.toString();
        final canDelete =
            comment['user_id'] == currentUserId && commentId != null;
        final isDeleting =
            commentId != null && deletingCommentIds.contains(commentId);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profile?['avatar_url'] != null
                ? NetworkImage(profile!['avatar_url'])
                : const NetworkImage('https://placehold.co/50'),
          ),
          title: Text(profile?['username'] ?? 'Usuario'),
          subtitle: Text(comment['content'] ?? ''),
          trailing: commentId == null
              ? null
              : canDelete
                  ? IconButton(
                      icon: isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      onPressed: isDeleting ? null : () => onDelete(commentId),
                    )
                  : IconButton(
                      tooltip: 'Reportar comentario',
                      icon: const Icon(Icons.flag_outlined,
                          color: Colors.redAccent),
                      onPressed: () => onReport(commentId),
                    ),
        );
      },
    );
  }
}
