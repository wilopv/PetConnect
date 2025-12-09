# Autor: Wilbert López Veras
# Fecha de creación: 9 de Diciembre de 2025
# Descripción: Endpoints para moderar textos usando la API de Gemini.

from __future__ import annotations

import json
import os
from typing import Any, Dict

import google.generativeai as genai
from fastapi import APIRouter, Depends, HTTPException, status

from ..dependencies import get_current_user
from ..models import ModerationRequest

router = APIRouter(prefix="/moderation", tags=["Moderación"])

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "models/gemini-flash-latest")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)


def _ensure_key():
    if not GEMINI_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gemini API key no configurada en el servidor.",
        )


def _parse_json_payload(raw_text: str) -> Dict[str, Any]:
    """
    Intenta extraer un JSON valido del texto devuelto por Gemini.
    """
    raw_text = raw_text.strip()
    start = raw_text.find("{")
    end = raw_text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("Respuesta de Gemini sin JSON valido")

    fragment = raw_text[start : end + 1]
    return json.loads(fragment)


def _normalize_decision(value: str) -> str:
    value = (value or "").strip().lower()
    if value in ("permitir", "allow", "allowed"):
        return "permitir"
    if value in ("bloquear", "block", "blocked", "rechazar", "reject"):
        return "bloquear"
    return "permitir"


def moderate_text_with_gemini(text: str) -> Dict[str, str]:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Consulta Gemini y devuelve decision de permitir o bloquear un comentario o descripcion de publicacion.
    """

    _ensure_key()

    prompt = (
        "Eres un moderador estricto en español. Debes devolver un JSON con "
        "'decision' (permitir/bloquear) y 'reason'. "
        "Bloquea textos con insultos, blasfemias fuertes, lenguaje vulgar, "
        "odio, violencia explícita, sexualidad explícita o spam. "
        "Sólo permite textos neutros o respetuosos.\n\n"
        f"Texto:\n{text}"
    )


    try:
        model = genai.GenerativeModel(GEMINI_MODEL)
        response = model.generate_content(prompt)
        raw_text = response.text or ""
        data = _parse_json_payload(raw_text)
    except Exception as exc:  # pragma: no cover - dependencias externas
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error consultando Gemini: {exc}",
        ) from exc

    decision = _normalize_decision(str(data.get("decision", "")))
    reason = data.get("reason", "Moderación completada.")
    return {"decision": decision, "reason": reason}


@router.post("/text")
def moderate_text(
    payload: ModerationRequest, current_user: dict = Depends(get_current_user)
):
    """
    Endpoint protegido para evaluar un texto con IA y retornar la decision.
    """

    result = moderate_text_with_gemini(payload.text)
    return {
        "decision": result["decision"],
        "reason": result["reason"],
        "reviewed_by": current_user["id"],
    }
