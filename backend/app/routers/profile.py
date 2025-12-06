import base64
import binascii
import os
import time

from fastapi import APIRouter, Depends, HTTPException, status
from app.dependencies import get_current_user
from app.models import Profile, ProfileUpdate
from app.database import get_supabase_client, get_service_client
from postgrest.exceptions import APIError

router = APIRouter(prefix="/profile", tags=["Profile"])
AVATAR_BUCKET = os.environ.get("SUPABASE_AVATAR_BUCKET")
AVATAR_FOLDER = os.environ.get("SUPABASE_AVATAR_FOLDER")
USER_CONTENT_BUCKET = os.environ.get("SUPABASE_USER_BUCKET", "user-content")
USER_CONTENT_ROOT = os.environ.get("SUPABASE_USER_FOLDER", "")


@router.get("/me", response_model=Profile)
def get_my_profile(user = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 18-11-2025
    Descripcion: Obtiene el perfil del usuario autenticado.
    """
    client = get_supabase_client()

    # Consultar el perfil del usuario actual a Supabase
    result = (
        client.table("profiles")
        .select("*")
        .eq("id", user["id"])
        .single()
        .execute()
    )

    data = result.data
    if not data:
        raise HTTPException(404, "Perfil no encontrado")

    posts = (
        client.table("posts")
        .select("*")
        .eq("user_id", user["id"])
        .order("created_at", desc=True)
        .execute()
    )
    data["posts"] = posts.data or []

    return data



@router.put("/me", response_model=Profile)
def update_my_profile(payload: ProfileUpdate, user = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 18-11-2025
    Descripcion: Actualiza el perfil del usuario autenticado.
    """
    client = get_supabase_client()
    service = get_service_client()

    payload_dict = payload.dict()
    avatar_base64 = payload_dict.get("avatar_base64")
    update_data = {k: v for k, v in payload_dict.items() if k != "avatar_base64" and v is not None}
    if not update_data and not avatar_base64:
        raise HTTPException(400, "No hay campos para actualizar")

    # ID del usuario (ya viene como string válido)
    user_id = user["id"]

    if avatar_base64:
        try:
            avatar_url = _upload_avatar(service, user_id, avatar_base64)
            update_data["avatar_url"] = avatar_url
        except ValueError as exc:
            raise HTTPException(status_code=400, detail=str(exc))
        except Exception:
            raise HTTPException(
                status_code=500,
                detail="No se pudo actualizar la imagen de perfil",
            )

    try:
        # Realizar el UPDATE y pedir que devuelva el registro actualizado
        update_result = (
            client.table("profiles")
            .update(update_data, returning="representation")
            .eq("id", user_id)
            .execute()
        )
    except APIError as e:
        if e.code == "23505":  # Violacion de unicidad (usuario unico)
            raise HTTPException(
                status_code=400,
                detail="El nombre de usuario ya está en uso"
            )
        raise

    # Supabase devolverá una lista con 1 elemento si UPDATE tuvo éxito
    if not update_result.data:
        raise HTTPException(404, "Perfil no encontrado")

    return update_result.data[0]


@router.get("/search")
def search_profiles(query: str, limit: int = 20):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-12-2025
    Descripcion: Busca perfiles por nombre de usuario o nombre de mascota.
    """
    client = get_supabase_client()
    normalized_query = f"%{query.lower()}%"

    result = (
        client.table("profiles")
        .select("id, username, city, avatar_url, pet_name")
        .or_(f"username.ilike.{normalized_query},pet_name.ilike.{normalized_query}")
        .limit(limit)
        .execute()
    )

    return result.data or []


@router.get("/{id}", response_model=Profile)
def get_profile(id: str):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 18-11-2025
    Descripcion: Obtiene el perfil de un usuario por su ID.
    """
    client = get_supabase_client()

    result = (
        client.table("profiles")
        .select("*")
        .eq("id", id)
        .single()
        .execute()
    )

    data = result.data
    if not data:
        raise HTTPException(404, "Perfil no encontrado")

    posts = (
        client.table("posts")
        .select("*")
        .eq("user_id", id)
        .order("created_at", desc=True)
        .execute()
    )
    data["posts"] = posts.data or []

    return data


def _upload_avatar(service_client, user_id: str, avatar_base64: str) -> str:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 18-11-2025
    Descripcion: Sube la imagen de avatar del usuario y retorna la URL pública.
    """

    bucket = USER_CONTENT_BUCKET
    if not bucket:
        raise ValueError("No hay bucket configurado para guardar avatares")

    header, _, data = avatar_base64.partition(",")
    payload = data or header

    try:
        binary = base64.b64decode(payload)
    except (binascii.Error, ValueError):
        raise ValueError("Imagen de avatar inválida")

    mime = "image/jpeg"
    ext = "jpg"
    header_lower = header.lower()
    if "png" in header_lower:
        mime = "image/png"
        ext = "png"
    elif "webp" in header_lower:
        mime = "image/webp"
        ext = "webp"

    base_path = USER_CONTENT_ROOT or ""
    folder = f"{base_path}/{user_id}".strip("/")
    storage = service_client.storage.from_(bucket)

    # Eliminar posibles versiones anteriores del avatar
    posibles_ext = ["jpg", "png", "webp"]
    storage.remove([f"{folder}/avatar.{previous}" for previous in posibles_ext])

    path = f"{folder}/avatar.{ext}"
    storage.upload(
        path,
        binary,
        {"content-type": mime, "upsert": "true"},
    )

    public_url = storage.get_public_url(path)
    url = public_url.get("publicUrl") if isinstance(public_url, dict) else public_url
    # Obtener el ultimo avatar subido (evitar cache)
    cache_buster = int(time.time())
    return f"{url}?v={cache_buster}"
