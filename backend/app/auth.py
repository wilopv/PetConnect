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

from .database import get_supabase_client
from .models import LoginRequest, SignUpRequest, TokenResponse
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
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Crea un usuario en Supabase y devuelve su token.
    """
    client = get_supabase_client()
    result = client.auth.sign_up({"email": payload.email, "password": payload.password})
    user = result.user
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Signup failed")
    token = create_access_token({"sub": user.id})
    return TokenResponse(access_token=token, token_type="bearer")


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Autentica al usuario y emite un token nuevo.
    """
    client = get_supabase_client()
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

    token = create_access_token({"sub": user.id}) 
    return TokenResponse(access_token=token, token_type="bearer")
