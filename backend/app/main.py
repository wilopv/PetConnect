# Autor: Wilbert López Veras 
# Fecha de creación: 2 de Noviembre de 2025
# Descripción: Archivo principal de FastAPI que configura la aplicación e incluye los routers necesarios.

from fastapi import Depends, FastAPI

from .routers.auth import router as auth_router
from .dependencies import get_current_user
from .routers.profile import router as profile_router
from .routers.posts import router as posts_router
from .routers.post_likes import router as post_likes_router
from .routers.conversations import router as conversations_router

app = FastAPI()
app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(posts_router)
app.include_router(post_likes_router)
app.include_router(conversations_router)


@app.get("/users/me")
def read_current_user(current_user: dict = Depends(get_current_user)):
    """
    Autor: Wilbert Lopez Veras
    Fecha: 02-11-2025
    Descripcion: Retorna datos basicos del usuario autenticado.
    """
    return current_user
