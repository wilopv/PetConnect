"""
Autor: Wilbert Lopez Veras
Fecha: 9-12-2025
Descripcion: Endpoints para reportar publicaciones y comentarios.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from postgrest.exceptions import APIError

from app.database import get_service_client
from app.dependencies import get_current_user
from app.models import ReportRequest

router = APIRouter(tags=["Reports"])


def _ensure_moderator(user: dict):
    if user.get("role") not in ("moderator", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No autorizado para esta operación",
        )


@router.post("/posts/{post_id}/report")
def report_post(
    post_id: str,
    payload: ReportRequest,
    user=Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Crea un reporte de una publicacion.
    """

    service = get_service_client()
    try:
        service.table("post_reports").insert(
            {
                "post_id": post_id,
                "reporter_id": user["id"],
                "reason": payload.reason,
            }
        ).execute()
    except APIError as exc:
        if exc.code == "23505":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya has reportado este post",
            )
        raise

    return {"message": "Reporte enviado"}


@router.get("/reports/posts")
def list_post_reports(user=Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Lista reportes de publicaciones para moderadores.
    """

    _ensure_moderator(user)
    service = get_service_client()
    result = (
        service.table("post_reports")
        .select(
            "id, reason, created_at, "
            "reporter:profiles(id, username, email, avatar_url), "
            "post:posts(id, description, image_url, user_id, profiles(id, username, email))"
        )
        .order("created_at", desc=True)
        .execute()
    )
    return result.data or []


@router.delete("/reports/posts/{report_id}")
def delete_post_report(report_id: str, user=Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Permite al moderador ignorar un reporte de post.
    """

    _ensure_moderator(user)
    service = get_service_client()
    result = (
        service.table("post_reports")
        .delete()
        .eq("id", report_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    return {"message": "Reporte eliminado"}


@router.post("/comments/{comment_id}/report")
def report_comment(
    comment_id: str,
    payload: ReportRequest,
    user=Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Crea un reporte de un comentario.
    """

    service = get_service_client()
    try:
        service.table("comment_reports").insert(
            {
                "comment_id": comment_id,
                "reporter_id": user["id"],
                "reason": payload.reason,
            }
        ).execute()
    except APIError as exc:
        if exc.code == "23505":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya has reportado este comentario",
            )
        raise

    return {"message": "Reporte enviado"}


@router.get("/reports/comments")
def list_comment_reports(user=Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Lista reportes de comentarios para moderadores.
    """

    _ensure_moderator(user)
    service = get_service_client()
    result = (
        service.table("comment_reports")
        .select(
            "id, reason, created_at, "
            "reporter:profiles(id, username, email, avatar_url), "
            "comment:post_comments(id, content, post_id, user_id, profiles(id, username, email))"
        )
        .order("created_at", desc=True)
        .execute()
    )
    return result.data or []


@router.delete("/reports/comments/{report_id}")
def delete_comment_report(report_id: str, user=Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Permite al moderador ignorar un reporte de comentario.
    """

    _ensure_moderator(user)
    service = get_service_client()
    result = (
        service.table("comment_reports")
        .delete()
        .eq("id", report_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    return {"message": "Reporte eliminado"}
