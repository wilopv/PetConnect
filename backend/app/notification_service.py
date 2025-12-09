"""
Autor: Wilbert López Veras
Fecha: 09-12-2025
Descripción: Utilidades para generar eventos de notificaciones.
"""

from __future__ import annotations

from typing import Iterable


def notify_followers_about_post(service_client, author_id: str, post_id: str) -> None:
    """
    Inserta eventos de notificación para todos los seguidores del autor.
    """

    followers_result = (
        service_client.table("user_follows")
        .select("follower_id")
        .eq("followed_id", author_id)
        .execute()
    )
    follower_ids: Iterable[str] = [
        row["follower_id"] for row in (followers_result.data or [])
        if row.get("follower_id")
    ]

    events = [
        {
            "receiver_id": follower_id,
            "author_id": author_id,
            "event_type": "post",
            "post_id": post_id,
        }
        for follower_id in follower_ids
    ]

    if not events:
        return

    try:
        service_client.table("notifications").insert(events).execute()
    except Exception as exc:  
        print(f"No se pudieron generar eventos para post {post_id}: {exc}")


def notify_user_about_message(
    service_client,
    receiver_id: str,
    author_id: str,
    conversation_id: str,
    message_id: str,
) -> None:
    """
    Inserta un evento de notificación por mensaje directo.
    """

    try:
        service_client.table("notifications").insert(
            {
                "receiver_id": receiver_id,
                "author_id": author_id,
                "event_type": "message",
                "conversation_id": conversation_id,
                "message_id": message_id,
            }
        ).execute()
    except Exception as exc:  
        print(f"No se pudo notificar mensaje {message_id}: {exc}")
