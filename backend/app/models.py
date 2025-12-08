# Autor: Wilbert López Veras 
# Fecha de creación: 2 de Noviembre de 2025
# Descripción: Archivo con definición de los modelos Pydantic

from __future__ import annotations
from typing import Optional
from pydantic import BaseModel, EmailStr
from datetime import datetime


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
    posts: Optional[list["PostResponse"]] = None

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
    avatar_base64: Optional[str] = None
    bio: Optional[str] = None

# Esquemas para publicaciones
class PostBase(BaseModel):
    user_id: str
    description: str | None = None
    image_url: str
    likes_count: int = 0
    comments_count: int = 0

class PostResponse(PostBase):
    id: str
    created_at: datetime | None = None
    updated_at: datetime | None = None
    liked_by_me: bool = False

    class Config:
        from_orm = True

class PostCreate(BaseModel):
    description: str | None = None
    image_base64: str


class PostCommentCreate(BaseModel):
    content: str
