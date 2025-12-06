# Autor: Wilbert López Veras
# Fecha de creación: 6 de diciembre de 2025
# Descripción: Archivo con endpoints para gestionar los likes de las publicaciones.

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user
from app.database import get_supabase_client, get_service_client

router = APIRouter(prefix="/posts", tags=["post_likes"])


@router.post("/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
def like_post(post_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Registra el like de una publicación e incrementa el contador.
    """
    service = get_service_client()
    data = {
        "post_id": post_id,
        "user_id": current_user["id"],
    }

    service.table("post_likes").insert(data).execute()
    service.rpc("increment_likes", {"p_post_id": post_id}).execute()


@router.delete("/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
def unlike_post(post_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Elimina el like de una publicación y actualiza el contador.
    """
    service = get_service_client()
    (
        service.table("post_likes")
        .delete()
        .eq("post_id", post_id)
        .eq("user_id", current_user["id"])
        .execute()
    )
    service.rpc("decrement_likes", {"p_post_id": post_id}).execute()


@router.get("/{post_id}/likes/count")
def get_likes_count(post_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Retorna el número de likes almacendo en la publicación.
    """
    client = get_supabase_client()
    result = (
        client.table("posts")
        .select("likes_count")
        .eq("id", post_id)
        .single()
        .execute()
    )

    data = result.data
    if not data:
        raise HTTPException(status_code=404, detail="Post no encontrado")

    return {"likes_count": data.get("likes_count", 0)}
