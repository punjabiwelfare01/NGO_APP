"""
Auth0 ID-token verification using JWKS (RS256).

The JWKS is fetched once on first use and cached for the process lifetime.
Call verify_auth0_token(id_token) → decoded payload dict.
"""

import logging

import requests as http_requests
from jose import JWTError, jwt

from .config import settings

logger = logging.getLogger(__name__)

_jwks_cache: dict | None = None


def _get_jwks() -> dict:
    global _jwks_cache
    if _jwks_cache is None:
        url = f"https://{settings.auth0_domain}/.well-known/jwks.json"
        resp = http_requests.get(url, timeout=10)
        resp.raise_for_status()
        _jwks_cache = resp.json()
        logger.info("Auth0 JWKS loaded from %s", url)
    return _jwks_cache


def _rsa_key_for_token(token: str) -> dict:
    jwks = _get_jwks()
    try:
        header = jwt.get_unverified_header(token)
    except JWTError as exc:
        raise ValueError(f"Cannot read token header: {exc}") from exc

    kid = header.get("kid")
    for key in jwks.get("keys", []):
        if key.get("kid") == kid:
            return {"kty": key["kty"], "kid": key["kid"],
                    "use": key["use"], "n": key["n"], "e": key["e"]}

    # JWKS may have rotated — bust cache and retry once
    global _jwks_cache
    _jwks_cache = None
    for key in _get_jwks().get("keys", []):
        if key.get("kid") == kid:
            return {"kty": key["kty"], "kid": key["kid"],
                    "use": key["use"], "n": key["n"], "e": key["e"]}

    raise ValueError(f"No matching key (kid={kid!r}) found in Auth0 JWKS")


def verify_auth0_token(token: str) -> dict:
    """Verify an Auth0 ID token and return its decoded payload."""
    rsa_key = _rsa_key_for_token(token)
    payload = jwt.decode(
        token,
        rsa_key,
        algorithms=["RS256"],
        audience=settings.auth0_client_id,
        issuer=f"https://{settings.auth0_domain}/",
        options={"verify_at_hash": False},
    )
    return payload
