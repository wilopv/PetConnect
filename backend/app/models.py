# Autor: Wilbert López Veras 
# Fecha de creación: 2 de Noviembre de 2025
# Descripción: Archivo con definición de los modelos Pydantic para solicitudes y respuestas
# relacionadas con la autenticación.

from typing import Optional
from pydantic import BaseModel, EmailStr

# Esquemas para autenticación
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
    city: Optional[str] = None
    pet_name: Optional[str] = None
    pet_type: Optional[str] = None
    pet_gender: Optional[str] = None


class LoginRequest(BaseModel):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Modelo para peticion de inicio de sesion.
    """

    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: str
    email: str
    role: str

class TokenResponse(BaseModel):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Respuesta con el token de acceso emitido.
    """

    access_token: str
    token_type: str = "bearer"
    user: UserResponse

# Esquemas para el perfil de usuario
class Profile(BaseModel):
    id: str
    email: str
    username: str
    postal_code: Optional[str]
    city: Optional[str]
    pet_name: Optional[str]
    pet_type: Optional[str]
    pet_gender: Optional[str]
    avatar_url: Optional[str]
    bio: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    role: str

    class Config:
        orm_mode = True


class ProfileUpdate(BaseModel):
    username: Optional[str] = None
    postal_code: Optional[str] = None
    city: Optional[str] = None
    pet_name: Optional[str] = None
    pet_type: Optional[str] = None
    pet_gender: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None

