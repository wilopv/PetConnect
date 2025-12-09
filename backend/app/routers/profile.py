import base64
import binascii
import os
import time
from math import atan2, cos, radians, sin, sqrt

from fastapi import APIRouter, Depends, HTTPException, status
from app.dependencies import get_current_user
from app.models import Profile, ProfileUpdate
from app.database import get_supabase_client, get_service_client
from app.geocode import geocode_address
from postgrest.exceptions import APIError

router = APIRouter(prefix="/profile", tags=["Profile"])
AVATAR_BUCKET = os.environ.get("SUPABASE_AVATAR_BUCKET")
AVATAR_FOLDER = os.environ.get("SUPABASE_AVATAR_FOLDER")
USER_CONTENT_BUCKET = os.environ.get("SUPABASE_USER_BUCKET", "user-content")
USER_CONTENT_ROOT = os.environ.get("SUPABASE_USER_FOLDER", "")
EARTH_RADIUS_KM = 6371.0


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

    payload_dict = payload.dict(exclude_unset=True)
    avatar_base64 = payload_dict.pop("avatar_base64", None)
    update_data = {k: v for k, v in payload_dict.items() if v is not None}
    if not update_data and not avatar_base64:
        raise HTTPException(400, "No hay campos para actualizar")

    # ID del usuario (ya viene como string válido)
    user_id = user["id"]

    profile_result = (
        client.table("profiles")
        .select("city, postal_code")
        .eq("id", user_id)
        .single()
        .execute()
    )
    current_profile = profile_result.data
    if not current_profile:
        raise HTTPException(404, "Perfil no encontrado")

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

    should_update_coords = any(
        field in update_data for field in ("city", "postal_code")
    )
    if should_update_coords:
        target_city = update_data.get("city", current_profile.get("city"))
        target_postal = update_data.get("postal_code", current_profile.get("postal_code"))
        if target_city or target_postal:
            latitude, longitude = geocode_address(target_city, target_postal)
            update_data["latitude"] = latitude
            update_data["longitude"] = longitude

    try:
        update_result = (
            client.table("profiles")
            .update(update_data, returning="representation")
            .eq("id", user_id)
            .execute()
        )
    except APIError as e:
        if e.code == "23505":
            raise HTTPException(
                status_code=400,
                detail="El nombre de usuario ya está en uso"
            )
        raise

    if not update_result.data:
        raise HTTPException(404, "Perfil no encontrado")

    return update_result.data[0]


@router.put("/{user_id}", response_model=Profile)
def update_profile_by_admin(
    user_id: str,
    payload: ProfileUpdate,
    user = Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Permite a moderadores editar el perfil de cualquier usuario.
    """

    if user.get("role") not in ("moderator", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No autorizado para editar otros perfiles",
        )

    service = get_service_client()
    payload_dict = payload.dict(exclude_unset=True)
    avatar_base64 = payload_dict.pop("avatar_base64", None)
    update_data = {k: v for k, v in payload_dict.items() if v is not None}
    if not update_data and not avatar_base64:
        raise HTTPException(400, "No hay campos para actualizar")

    profile_result = (
        service.table("profiles")
        .select("city, postal_code")
        .eq("id", user_id)
        .single()
        .execute()
    )
    current_profile = profile_result.data
    if not current_profile:
        raise HTTPException(404, "Perfil no encontrado")

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

    if "city" in update_data or "postal_code" in update_data:
        target_city = update_data.get("city", current_profile.get("city"))
        target_postal = update_data.get("postal_code", current_profile.get("postal_code"))
        if target_city or target_postal:
            latitude, longitude = geocode_address(target_city, target_postal)
            update_data["latitude"] = latitude
            update_data["longitude"] = longitude

    try:
        update_result = (
            service.table("profiles")
            .update(update_data, returning="representation")
            .eq("id", user_id)
            .execute()
        )
    except APIError as e:
        if e.code == "23505":
            raise HTTPException(
                status_code=400,
                detail="El nombre de usuario ya está en uso"
            )
        raise

    if not update_result.data:
        raise HTTPException(404, "Perfil no encontrado")

    return update_result.data[0]


@router.delete("/{user_id}")
def delete_profile_by_admin(
    user_id: str,
    user = Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Permite a moderadores eliminar un perfil.
    """

    if user.get("role") not in ("moderator", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No autorizado para eliminar perfiles",
        )

    service = get_service_client()
    try:
        service.auth.admin.delete_user(user_id)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="No se pudo eliminar el usuario de autenticación",
        )

    try:
        service.table("profiles").delete().eq("id", user_id).execute()
    except Exception:
        pass

    return {"message": "Perfil eliminado"}


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
        .select("id, username, city, postal_code, avatar_url, pet_name, latitude, longitude")
        .or_(f"username.ilike.{normalized_query},pet_name.ilike.{normalized_query}")
        .limit(limit)
        .execute()
    )

    return result.data or []


@router.get("/nearby")
def get_nearby_profiles(
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float = 25,
    limit: int = 50,
    user = Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Obtiene perfiles cercanos dentro de un radio en kilometros.
    """
    client = get_supabase_client()
    result = (
        client.table("profiles")
        .select(
            "id, username, pet_name, city, postal_code, avatar_url, latitude, longitude"
        )
        .execute()
    )

    if lat is None or lng is None:
        raise HTTPException(
            status_code=400, detail="Se requieren coordenadas para la búsqueda"
        )
    lat = float(lat)
    lng = float(lng)
    profiles = result.data or []
    filtered = []
    for profile in profiles:
        if profile.get("id") == user["id"]:
            continue
        target_lat = profile.get("latitude")
        target_lng = profile.get("longitude")
        if target_lat is None or target_lng is None:
            continue
        distance = _haversine_distance(lat, lng, float(target_lat), float(target_lng))
        if distance <= radius_km:
            profile["distance_km"] = distance
            filtered.append(profile)

    filtered.sort(key=lambda item: item.get("distance_km", radius_km))
    return filtered[:limit]


@router.get("/geocode")
def resolve_location(
    postal_code: str | None = None,
    city: str | None = None,
    user = Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Convierte ciudad/codigo postal en coordenadas.
    """

    if not postal_code and not city:
        raise HTTPException(
            status_code=400,
            detail="Debe proporcionar código postal, ciudad o ambos.",
        )

    latitude, longitude = geocode_address(city, postal_code)
    if latitude is None or longitude is None:
        raise HTTPException(
            status_code=404, detail="No se pudo localizar esa dirección."
        )

    return {"latitude": latitude, "longitude": longitude}


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


@router.post("/{target_id}/follow")
def follow_user(
    target_id: str,
    user=Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Permite seguir a otro usuario.
    """

    follower_id = user["id"]
    if follower_id == target_id:
        raise HTTPException(status_code=400, detail="No puedes seguirte a ti mismo")

    service = get_service_client()
    exists = (
        service.table("profiles")
        .select("id")
        .eq("id", target_id)
        .single()
        .execute()
    ).data

    if not exists:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    try:
        service.table("user_follows").insert(
            {
                "follower_id": follower_id,
                "followed_id": target_id,
            }
        ).execute()
    except APIError as exc:
        if exc.code == "23505":
            raise HTTPException(status_code=400, detail="Ya sigues a este usuario")
        raise

    return {"message": "Ahora sigues a este usuario"}


@router.delete("/{target_id}/follow")
def unfollow_user(
    target_id: str,
    user=Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Deja de seguir a un usuario.
    """

    follower_id = user["id"]
    service = get_service_client()
    result = (
        service.table("user_follows")
        .delete()
        .eq("follower_id", follower_id)
        .eq("followed_id", target_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=404, detail="No seguías a este usuario")

    return {"message": "Has dejado de seguir a este usuario"}


@router.get("/{target_id}/follow/status")
def get_follow_status(
    target_id: str,
    user=Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Indica si el usuario autenticado sigue al perfil target.
    """

    follower_id = user["id"]
    if follower_id == target_id:
        return {"following": False}

    service = get_service_client()
    result = (
        service.table("user_follows")
        .select("follower_id")
        .eq("follower_id", follower_id)
        .eq("followed_id", target_id)
        .limit(1)
        .execute()
    )

    return {"following": bool(result.data)}


@router.get("/{user_id}/following")
def list_following(user_id: str):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Lista los usuarios seguidos por user_id.
    """

    client = get_supabase_client()
    result = (
        client.table("user_follows")
        .select(
            "followed:profiles(id, username, avatar_url, pet_name, city, postal_code)"
        )
        .eq("follower_id", user_id)
        .execute()
    )
    return [item["followed"] for item in result.data or []]


@router.get("/{user_id}/followers")
def list_followers(user_id: str):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Lista los seguidores de un usuario.
    """

    client = get_supabase_client()
    result = (
        client.table("user_follows")
        .select(
            "follower:profiles(id, username, avatar_url, pet_name, city, postal_code)"
        )
        .eq("followed_id", user_id)
        .execute()
    )
    return [item["follower"] for item in result.data or []]


def _haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Calcula la distancia en KM entre dos puntos usando Haversine.
    """

    lat1_rad, lon1_rad = radians(lat1), radians(lon1)
    lat2_rad, lon2_rad = radians(lat2), radians(lon2)

    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a = sin(dlat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return EARTH_RADIUS_KM * c


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
