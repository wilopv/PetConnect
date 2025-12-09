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
