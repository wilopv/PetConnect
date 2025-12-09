# Autor: Wilbert López Veras
# Fecha de creación: 9 de diciembre de 2025
# Descripción: Endpoints para listar notificaciones del usuario.

import asyncio
import json

from typing import List, Dict, Any

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, HTTPException
from jose import JWTError, jwt

from app.database import get_service_client
from app.dependencies import get_current_user
from app.routers.auth import JWT_SECRET, JWT_ALGORITHM

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("")
def list_notifications(
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Retorna las notificaciones recientes del usuario autenticado.
    """

    service = get_service_client()
    result = (
        service.table("notifications")
        .select(
            "id, event_type, post_id, conversation_id, message_id, author_id, created_at, read_at"
        )
        .eq("receiver_id", current_user["id"])
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )

    data = result.data or []
    return _attach_author_profiles(service, data)


@router.websocket("/ws")
async def notifications_ws(websocket: WebSocket, token: str | None = None):
    """
    WebSocket que emite notificaciones en "tiempo real".
    Requiere el token JWT como query param (?token=...).
    """

    auth_token = token or websocket.query_params.get("token")
    if not auth_token:
        await websocket.close(code=4403)
        return

    try:
        payload = jwt.decode(auth_token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = payload.get("sub")
    except JWTError:
        await websocket.close(code=4403)
        return

    if not user_id:
        await websocket.close(code=4403)
        return

    await websocket.accept()
    service = get_service_client()
    last_timestamp: str | None = None
    seen_ids: set[str] = set()

    try:
        while True:
            query = (
                service.table("notifications")
                .select(
                    "id, event_type, post_id, conversation_id, message_id, author_id, created_at, read_at"
                )
                .eq("receiver_id", user_id)
                .order("created_at", desc=False)
                .limit(20)
            )
            if last_timestamp:
                query = query.gt("created_at", last_timestamp)

            result = query.execute()
            data = result.data or []
            new_items = [
                item for item in data if item.get("id") not in seen_ids
            ]
            if new_items:
                enriched = _attach_author_profiles(service, new_items)
                last_timestamp = new_items[-1]["created_at"]
                for item in new_items:
                    if item.get("id"):
                        seen_ids.add(item["id"])
                await websocket.send_text(json.dumps(enriched))

            await asyncio.sleep(3)
    except WebSocketDisconnect:
        return
    except Exception as exc:
        print(f"Error en websocket de notificaciones: {exc}")
    finally:
        await websocket.close()


def _attach_author_profiles(service, notifications: List[Dict[str, Any]]):
    """
    Añade los datos del autor a cada notificación para evitar joins complejos.
    """

    author_ids = {
        item.get("author_id") for item in notifications if item.get("author_id")
    }
    profiles_map: Dict[str, Dict[str, Any]] = {}
    if author_ids:
        profile_rows = (
            service.table("profiles")
            .select("id, username, avatar_url, pet_name")
            .in_("id", list(author_ids))
            .execute()
        )
        for row in profile_rows.data or []:
            profiles_map[row["id"]] = row

    for item in notifications:
        author = profiles_map.get(item.get("author_id"))
        item["author"] = author

    return notifications


@router.delete("/{notification_id}")
def delete_notification(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Elimina una notificacion del usuario.
    """

    service = get_service_client()
    result = (
        service.table("notifications")
        .delete()
        .eq("id", notification_id)
        .eq("receiver_id", current_user["id"])
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")

    return {"message": "Notificación eliminada"}
