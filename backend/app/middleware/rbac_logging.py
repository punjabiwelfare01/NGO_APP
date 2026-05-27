"""
RBAC Access Logging Middleware.
Logs every request: method, path, response status, and whether the caller was authenticated.
"""
import logging
import time

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("careskill.rbac")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-7s  %(name)s — %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


class RBACLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        start      = time.perf_counter()
        auth_header = request.headers.get("Authorization", "")
        caller     = "authenticated" if auth_header.startswith("Bearer ") else "anonymous"

        response   = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000

        logger.info(
            "%s %s → %d  [%s]  %.1fms",
            request.method,
            request.url.path,
            response.status_code,
            caller,
            elapsed_ms,
        )

        # Log 403 / 401 at WARNING level so they stand out in security reviews
        if response.status_code in (401, 403):
            logger.warning(
                "ACCESS DENIED  %s %s → %d  [%s]",
                request.method,
                request.url.path,
                response.status_code,
                caller,
            )

        return response
