# Autor: Wilbert López Veras
# Fecha de creación: 8 de diciembre de 2025
# Descripción: Endpoints para conversaciones y mensajes privados.

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user
from app.database import get_supabase_client, get_service_client
from app.models import (
    ConversationCreate,
    ConversationResponse,
    MessageCreate,
    MessageResponse,
)

router = APIRouter(prefix="/conversations", tags=["conversations"])


@router.get("", response_model=list[ConversationResponse])
def list_conversations(current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 08-12-2025
    Descripcion: Retorna las conversaciones donde participa el usuario autenticado.
    """
    client = get_service_client()
    result = (
        client.table("conversations")
        .select(
            """
            id,
            user_a,
            user_b,
            created_at,
            last_message_at,
            user_a_profile:profiles!conversations_user_a_fkey(pet_name,username),
            user_b_profile:profiles!conversations_user_b_fkey(pet_name,username)
            """
        )
        .or_(f"user_a.eq.{current_user['id']},user_b.eq.{current_user['id']}")
        .order("last_message_at", desc=True)
        .order("created_at", desc=True)
        .execute()
    )
    return result.data or []


@router.post("", response_model=ConversationResponse, status_code=status.HTTP_201_CREATED)
def create_conversation(
    payload: ConversationCreate, current_user: dict = Depends(get_current_user)
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 08-12-2025
    Descripcion: Crea una conversacion entre el usuario actual y otro usuario.
    """
    if payload.target_user_id == current_user["id"]:
        raise HTTPException(status_code=400, detail="No puedes conversar contigo mismo")

    client = get_service_client()
    user_a = current_user["id"]
    user_b = payload.target_user_id
    ordered = sorted([user_a, user_b])

    existing = (
        client.table("conversations")
        .select("*")
        .eq("user_a", ordered[0])
        .eq("user_b", ordered[1])
        .limit(1)
        .execute()
    )
    if existing.data:
        return existing.data[0]

    result = (
        client.table("conversations")
        .insert(
            {
                "user_a": user_a,
                "user_b": user_b,
            }
        )
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=500, detail="No se pudo crear la conversacion")
    return result.data[0]


@router.get("/{conversation_id}/messages", response_model=list[MessageResponse])
def list_messages(conversation_id: str, current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 08-12-2025
    Descripcion: Retorna los mensajes de una conversacion si el usuario es participante.
    """
    client = get_service_client()
    _ensure_conversation_access(client, conversation_id, current_user["id"])

    result = (
        client.table("messages")
        .select("*")
        .eq("conversation_id", conversation_id)
        .order("created_at", desc=False)
        .execute()
    )
    return result.data or []


@router.post(
    "/{conversation_id}/messages",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
)
def send_message(
    conversation_id: str,
    payload: MessageCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 08-12-2025
    Descripcion: Permite enviar un mensaje dentro de una conversacion.
    """
    client = get_service_client()
    _ensure_conversation_access(client, conversation_id, current_user["id"])

    insert_result = (
        client.table("messages")
        .insert(
            {
                "conversation_id": conversation_id,
                "sender_id": current_user["id"],
                "content": payload.content,
            }
        )
        .execute()
    )
    if not insert_result.data:
        raise HTTPException(status_code=500, detail="No se pudo enviar el mensaje")

    get_service_client().table("conversations").update(
        {"last_message_at": datetime.utcnow().isoformat()}
    ).eq("id", conversation_id).execute()

    return insert_result.data[0]


def _ensure_conversation_access(client, conversation_id: str, user_id: str):
    conv = (
        client.table("conversations")
        .select("id, user_a, user_b")
        .eq("id", conversation_id)
        .single()
        .execute()
    )
    data = conv.data
    if not data:
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    if user_id not in (data["user_a"], data["user_b"]):
        raise HTTPException(status_code=403, detail="No tienes acceso a esta conversacion")
