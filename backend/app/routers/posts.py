# Autor: Wilbert López Veras
# Fecha de creación: 6 de diciembre de 2025
# Descripción: archivo de endpoints para crear, listar y eliminar publicaciones.

import base64
import binascii
import os
import time

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user
from app.database import get_supabase_client, get_service_client
from app.models import PostBase, PostCreate, PostResponse, PostCommentCreate

USER_CONTENT_BUCKET = os.environ.get("SUPABASE_USER_BUCKET", "user-content")
POSTS_FOLDER = os.environ.get("SUPABASE_POSTS_FOLDER", "posts")

router = APIRouter(prefix="/posts", tags=["posts"])


@router.post("", response_model=PostResponse)
def create_post(payload: PostCreate, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Crea un nuevo post para el usuario autenticado.
    """
    if not payload.image_base64:
        raise HTTPException(status_code=400, detail="La imagen es requerida.")

    service = get_service_client()
    try:
        image_url = _upload_post_image(service, current_user["id"], payload.image_base64)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="No se pudo subir la imagen del post",
        )

    data = {
        "user_id": current_user["id"],
        "description": payload.description,
        "image_url": image_url,
        "likes_count": 0,
        "comments_count": 0,
    }

    insert_result = (
        service.table("posts")
        .insert(data)
        .execute()
    )

    if not insert_result.data:
        raise HTTPException(
            status_code=500,
            detail="No se pudo crear la publicación"
        )

    post_result = (
        service.table("posts")
        .select("*")
        .eq("id", insert_result.data[0]["id"])
        .single()
        .execute()
    )

    return post_result.data


@router.get("/user/{user_id}", response_model=list[PostResponse])
def get_posts_by_user(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Retorna las publicaciones asociadas a un usuario.
    """
    client = get_supabase_client()
    result = (
        client.table("posts")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .execute()
    )

    return result.data or []


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(post_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Elimina un post si pertenece al usuario autenticado.
    """
    service = get_service_client()
    existing = (
        service.table("posts")
        .select("id,user_id,image_url")
        .eq("id", post_id)
        .single()
        .execute()
    )

    data = existing.data
    if not data:
        raise HTTPException(status_code=404, detail="Post no encontrado")

    if data["user_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No puedes eliminar este post",
        )

    _delete_post_image(service, data.get("image_url"))
    service.table("posts").delete().eq("id", post_id).execute()


@router.delete("/{post_id}/moderate", status_code=status.HTTP_204_NO_CONTENT)
def delete_post_as_moderator(post_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Elimina un post sin importar propietario (uso moderador).
    """

    if current_user.get("role") not in ("moderator", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No autorizado para eliminar este post",
        )

    service = get_service_client()
    existing = (
        service.table("posts")
        .select("id,image_url")
        .eq("id", post_id)
        .single()
        .execute()
    )
    data = existing.data
    if not data:
        raise HTTPException(status_code=404, detail="Post no encontrado")

    _delete_post_image(service, data.get("image_url"))
    service.table("posts").delete().eq("id", post_id).execute()


@router.get("/{post_id}", response_model=PostResponse)
def get_post(post_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Obtiene la información de una publicación.
    """
    client = get_supabase_client()
    try:
        result = (
            client.table("posts")
            .select("*")
            .eq("id", post_id)
            .single()
            .execute()
        )
    except Exception:
        raise HTTPException(status_code=404, detail="Post no encontrado")

    data = result.data
    if not data:
        raise HTTPException(status_code=404, detail="Post no encontrado")

    liked = (
        client.table("post_likes")
        .select("id")
        .eq("post_id", post_id)
        .eq("user_id", current_user["id"])
        .limit(1)
        .execute()
    )
    data["liked_by_me"] = bool(liked.data)

    return data


@router.post("/{post_id}/comments")
def add_comment(post_id: str, payload: PostCommentCreate, current_user: dict = Depends(get_current_user)):
    service = get_service_client()
    try:
        insert_result = (
            service.table("post_comments")
            .insert({
                "post_id": post_id,
                "user_id": current_user["id"],
                "content": payload.content,
            })
            .execute()
        )
        if not insert_result.data:
            raise HTTPException(status_code=400, detail="No se pudo agregar el comentario")

        comment_id = insert_result.data[0]["id"]
        result = (
            service.table("post_comments")
            .select("id, content, created_at, user_id, profiles(username, avatar_url)")
            .eq("id", comment_id)
            .single()
            .execute()
        )
    except Exception as exc:
        print(f"No se pudo agregar el comentario: {exc}")
        raise HTTPException(status_code=400, detail="No se pudo agregar el comentario")
    return result.data


@router.get("/{post_id}/comments")
def get_comments(post_id: str, current_user: dict = Depends(get_current_user)):
    client = get_supabase_client()
    result = (
        client.table("post_comments")
        .select("id, content, created_at, user_id, profiles(username, avatar_url)")
        .eq("post_id", post_id)
        .order("created_at", desc=True)
        .execute()
    )
    return result.data or []


@router.delete("/{post_id}/comments/{comment_id}")
def delete_comment(post_id: str, comment_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 06-12-2025
    Descripcion: Permite eliminar un comentario creado por el usuario autenticado.
    """
    service = get_service_client()
    try:
        comment_result = (
            service.table("post_comments")
            .select("id, post_id, user_id")
            .eq("id", comment_id)
            .single()
            .execute()
        )
    except Exception:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")

    comment = comment_result.data
    if not comment or comment.get("post_id") != post_id:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")

    if comment.get("user_id") != current_user["id"]:
        raise HTTPException(status_code=403, detail="No puedes eliminar este comentario")

    try:
        service.table("post_comments").delete().eq("id", comment_id).execute()
    except Exception:
        raise HTTPException(status_code=500, detail="No se pudo eliminar el comentario")

    return {"detail": "Comentario eliminado"}


@router.delete("/{post_id}/comments/{comment_id}/moderate")
def delete_comment_as_moderator(post_id: str, comment_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 10-12-2025
    Descripcion: Permite a moderadores eliminar cualquier comentario.
    """

    if current_user.get("role") not in ("moderator", "admin"):
        raise HTTPException(status_code=403, detail="No autorizado")

    service = get_service_client()
    try:
        comment_result = (
            service.table("post_comments")
            .select("id, post_id")
            .eq("id", comment_id)
            .single()
            .execute()
        )
    except Exception:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")

    comment = comment_result.data
    if not comment or comment.get("post_id") != post_id:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")

    service.table("post_comments").delete().eq("id", comment_id).execute()
    return {"detail": "Comentario eliminado"}


def _upload_post_image(service_client, user_id: str, image_base64: str) -> str:
    if not USER_CONTENT_BUCKET:
        raise ValueError("No hay bucket configurado para guardar imágenes.")

    header, _, data = image_base64.partition(",")
    payload = data or header

    try:
        binary = base64.b64decode(payload)
    except (binascii.Error, ValueError):
        raise ValueError("Imagen inválida")

    mime = "image/jpeg"
    ext = "jpg"
    header_lower = header.lower()
    if "png" in header_lower:
        mime = "image/png"
        ext = "png"
    elif "webp" in header_lower:
        mime = "image/webp"
        ext = "webp"

    folder = POSTS_FOLDER.strip("/")
    timestamp = int(time.time())
    filename = f"{user_id}/{folder}/post_{timestamp}.{ext}" if folder else f"{user_id}/post_{timestamp}.{ext}"
    path = filename.strip("/")

    storage = service_client.storage.from_(USER_CONTENT_BUCKET)
    try:
        storage.upload(
            path,
            binary,
            {"content-type": mime, "upsert": "true"},
        )
    except Exception as exc:
        print(f"Error subiendo imagen del post: {exc}")
        raise

    public_url = storage.get_public_url(path)
    url = public_url.get("publicUrl") if isinstance(public_url, dict) else public_url
    return f"{url}?v={timestamp}"


def _delete_post_image(service_client, image_url: str | None):
    if not image_url or not USER_CONTENT_BUCKET:
        return

    try:
        start = image_url.find(USER_CONTENT_BUCKET)
        if start == -1:
            return
        relative = image_url[start + len(USER_CONTENT_BUCKET) + 1 :]
        relative = relative.split("?v=", 1)[0]
        service_client.storage.from_(USER_CONTENT_BUCKET).remove([relative])
    except Exception as exc:
        print(f"No se pudo eliminar la imagen del post: {exc}")
