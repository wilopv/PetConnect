# PetConnect App

PetConnect es la app Flutter del proyecto PetConnect. Permite a los usuarios crear perfiles con datos de su mascota, compartir publicaciones con imagen, buscar personas cercanas en un mapa, chatear y recibir notificaciones.

## Caracteristicas principales
- Autenticacion y registro con datos de mascota.
- Feed de publicaciones con imagenes y acciones sociales.
- Busqueda geolocalizada con mapa interactivo.
- Mensajeria privada y centro de notificaciones.
- Acceso diferenciado para moderadores.

## Requisitos
- Flutter SDK 3.22+ y Dart 3.4+.
- Backend activo (FastAPI) y base en Supabase.

## Configuracion
Opcionalmente crea un archivo `.env` en `frontend/pet_connect_app` con:
```
API_BASE_URL=https://tu-backend.com
```
Si no lo defines, se usa la URL por defecto configurada en `lib/lib/config/api_config.dart`.

## Ejecutar en desarrollo
Desde `frontend/pet_connect_app`:
```
flutter pub get
flutter run
```

Para usar un backend local en emulador Android:
```
API_BASE_URL=http://10.0.2.2:8000
```

## Estructura rapida
- `lib/auth`: pantallas de login y registro.
- `lib/user`: navegacion principal y pantallas del usuario.
- `lib/admin`: pantallas de moderacion.
- `lib/shared`: componentes compartidos (perfil, headers, botones).
- `lib/widgets`: widgets reutilizables (mapa, logo, hojas).

## Notas
- Esta app consume endpoints del backend FastAPI.
- Requiere configurar Supabase (auth, storage, tablas) en el backend.
