"""
Autor: Wilbert Lopez Veras
Fecha: 09-12-2025
Descripcion: Utilidades para obtener coordenadas geograficas a partir
de una ciudad y codigo postal usando Nominatim (OpenStreetMap).
"""

from __future__ import annotations

import json
import logging
import os
import urllib.parse
import urllib.request
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

GEOCODING_BASE_URL = os.environ.get(
    "GEOCODING_BASE_URL", "https://nominatim.openstreetmap.org/search"
)
GEOCODING_USER_AGENT = os.environ.get(
    "GEOCODING_USER_AGENT", "petconnect-backend-geocoder/1.0"
)


def geocode_address(
    city: Optional[str], postal_code: Optional[str], country: str = "España"
) -> Tuple[Optional[float], Optional[float]]:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 09-12-2025
    Descripcion: Convierte direccion (ciudad + codigo postal) en coordenadas
    usando el servicio publico de Nominatim. Retorna (latitud, longitud) o
    (None, None) si no se pudo geocodificar.
    """

    if not city and not postal_code:
        return None, None

    query_parts = [part for part in (postal_code, city, country) if part]
    query = " ".join(query_parts)
    params = urllib.parse.urlencode({"q": query, "format": "json", "limit": 1})
    url = f"{GEOCODING_BASE_URL}?{params}"
    request = urllib.request.Request(url, headers={"User-Agent": GEOCODING_USER_AGENT})

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            payload = response.read().decode("utf-8")
            data = json.loads(payload)
    except Exception as exc:
        logger.warning("Geocoding failed for query '%s': %s", query, exc)
        return None, None

    if not data:
        return None, None

    entry = data[0]
    try:
        latitude = float(entry["lat"])
        longitude = float(entry["lon"])
    except (KeyError, TypeError, ValueError):
        return None, None

    return latitude, longitude
