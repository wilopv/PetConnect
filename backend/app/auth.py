# Autor: Wilbert López Veras 
# Fecha de creación: 2 de Noviembre de 2025
# Descripción: Archiv con los endpoints de autenticación login y signup 
# y funciones relacionadas con la creación de tokens JWT.

import os
from datetime import datetime, timedelta
from typing import Optional

from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt

from .database import get_supabase_client, get_service_client
from .models import LoginRequest, SignUpRequest, TokenResponse, UserResponse
from supabase_auth.errors import AuthApiError


load_dotenv()

JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ALGORITHM = os.environ.get("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = 60

router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Genera un JWT con expiracion.
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)


def verify_access_token(token: str) -> dict:
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Valida el JWT y retorna su payload.
    """
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")


@router.post("/signup", response_model=TokenResponse)
def signup(payload: SignUpRequest):
    client = get_supabase_client() # cliente publico
    service = get_service_client()  # cliente admin

    # 1. Validar email único
    users = service.auth.admin.list_users()
    for u in users:
        if u.email and u.email.lower() == payload.email.lower():
            raise HTTPException(
                status_code=400,
                detail="Este correo ya está registrado."
            )
        
    # 2. Validar username único 
    existing_username = service.table("profiles")\
        .select("username")\
        .eq("username", payload.username)\
        .execute()

    if existing_username.data:
        raise HTTPException(
            status_code=400,
            detail="Este nombre de usuario ya está en uso."
        )

    try:
        result = client.auth.sign_up({
            "email": payload.email,
            "password": payload.password
        })
    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    user = result.user
    if user is None:
        raise HTTPException(status_code=400, detail="No se pudo crear la cuenta.")

    try:
        service.table("profiles").insert({
            "id": user.id,
            "email": payload.email,
            "username": payload.username,
            "postal_code": payload.postal_code,
            "pet_name": payload.pet_name,
            "pet_type": payload.pet_type,
            "role": "user"
        }).execute()
    except Exception:
        service.auth.admin.delete_user(user.id)
        raise HTTPException(
            status_code=400,
            detail="No se pudo crear el perfil del usuario."
        )

    token = create_access_token({"sub": user.id})
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse(
            id=user.id,
            email=payload.email,
            role="user"
        )
    )




@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Autentica al usuario y emite un token nuevo.
    """
    client = get_supabase_client()
    service = get_service_client()
    all_users = service.auth.admin.list_users()

    user_match = None
    for u in all_users:
        if u.email and u.email.lower() == payload.email.lower():
            user_match = u
            break

    # Verificar si el email está confirmado
    if user_match and user_match.email_confirmed_at is None:
        raise HTTPException(
            status_code=400,
            detail="Debes confirmar tu correo antes de iniciar sesión."
        )

    try:
        result = client.auth.sign_in_with_password(
            {"email": payload.email, "password": payload.password}
        )
    except AuthApiError:
        # Supabase rechaz las credenciales
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email o contraseña incorrectos",
        )
    except Exception:
        # error inesperado de Supabase u otra cosa
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno al iniciar sesión",
        )
    session = result.session
    user = result.user
    if not user or not session:
        # Cuando Supabase no lanza excepción pero no hay sesión/usuario
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email o contraseña incorrectos",
        )
    
        # Obtener el rol desde profiles
    try:
        profile = (
            client.table("profiles")
            .select("role")
            .eq("id", user.id)
            .single()
            .execute()
        )
        role = profile.data["role"]
    except Exception:
        role = "user"  # rol por defecto si hay error

    

    token = create_access_token({"sub": user.id}) 
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse(
            id=user.id,
            email=user.email,
            role=role
        )
    )


