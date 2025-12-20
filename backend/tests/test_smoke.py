import importlib
import os

from fastapi.testclient import TestClient


def _set_env_defaults() -> None:
    os.environ.setdefault("SUPABASE_URL", "https://example.supabase.co")
    os.environ.setdefault("SUPABASE_KEY", "test-key")
    os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "test-service-key")
    os.environ.setdefault("JWT_SECRET", "test-secret")
    os.environ.setdefault("SUPABASE_PUBLIC_ASSETS", "")
    os.environ.setdefault("SUPABASE_USER_BUCKET", "")
    os.environ.setdefault("SUPABASE_USER_FOLDER", "")


def _get_client() -> TestClient:
    _set_env_defaults()
    from app import main as app_main

    importlib.reload(app_main)
    return TestClient(app_main.app)


def test_openapi_available() -> None:
    # Smoke test: OpenAPI disponible.
    client = _get_client()
    response = client.get("/openapi.json")
    assert response.status_code == 200
    payload = response.json()
    assert "paths" in payload


def test_docs_available() -> None:
    # Smoke test: Swagger UI accesible.
    client = _get_client()
    response = client.get("/docs")
    assert response.status_code == 200


def test_auth_routes_registered() -> None:
    # Smoke test: rutas auth registradas en OpenAPI.
    client = _get_client()
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json().get("paths", {})
    assert "/auth/login" in paths
    assert "/auth/signup" in paths


def test_auth_endpoints_validate_payloads() -> None:
    # Contrato: auth rechaza body vacio.
    client = _get_client()
    login_response = client.post("/auth/login")
    signup_response = client.post("/auth/signup")
    assert login_response.status_code == 422
    assert signup_response.status_code == 422
