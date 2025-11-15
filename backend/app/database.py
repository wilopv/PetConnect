# Autor: Wilbert López Veras 
# Fecha de creación: 2 de Noviembre de 2025
# Descripción: Inicializa el cliente de Supabase usando las varialbes de entorno en .env

import os

from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]

def get_supabase_client() -> Client:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Retorna el cliente Supabase inicializado.
    """
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def get_service_client() -> Client:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Retorna un cliente Supabase inicializado con la clave service_role.
    Este cliente tiene permisos administrativos y no debe usarse fuera del backend.
    """
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
