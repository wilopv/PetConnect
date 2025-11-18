from fastapi import APIRouter, Depends, HTTPException, status
from app.dependencies import get_current_user
from app.models import Profile, ProfileUpdate
from app.database import get_supabase_client
from postgrest.exceptions import APIError

router = APIRouter(prefix="/profile", tags=["Profile"])


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

    if not result.data:
        raise HTTPException(404, "Perfil no encontrado")

    return result.data



@router.put("/me", response_model=Profile)
def update_my_profile(payload: ProfileUpdate, user = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 18-11-2025
    Descripcion: Actualiza el perfil del usuario autenticado.
    """
    client = get_supabase_client()

    update_data = {k: v for k, v in payload.dict().items() if v is not None}
    if not update_data:
        raise HTTPException(400, "No hay campos para actualizar")

    # ID del usuario (ya viene como string válido)
    user_id = user["id"]

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

    if not result.data:
        raise HTTPException(404, "Perfil no encontrado")

    return result.data


