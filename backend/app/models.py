# Autor: Wilbert López Veras 
# Fecha de creación: 2 de Noviembre de 2025
# Descripción: Archivo con definición de los modelos Pydantic para solicitudes y respuestas
# relacionadas con la autenticación.

from typing import Optional
from pydantic import BaseModel, EmailStr


class SignUpRequest(BaseModel):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Modelo para peticion de registro de usuario.
    """

    email: str
    password: str
    username: str
    postal_code: Optional[str] = None
    pet_name: Optional[str] = None
    pet_type: Optional[str] = None



class LoginRequest(BaseModel):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Modelo para peticion de inicio de sesion.
    """

    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Respuesta con el token de acceso emitido.
    """

    access_token: str
    token_type: str = "bearer"
