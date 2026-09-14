import httpx
from fastapi import APIRouter
from app.config import settings
from app.services.tools.registry import ToolRegistry

router = APIRouter(tags=["Health"])
registry = ToolRegistry()

@router.get("/health")
async def health_check():
    """Diagnostic health check verifying SearXNG and Qdrant connectivity."""
    searxng_ok = False
    qdrant_ok = False

    async with httpx.AsyncClient(timeout=5.0) as client:
        # Check SearXNG
        try:
            res = await client.get(f"{settings.SEARXNG_URL.rstrip('/')}/config")
            searxng_ok = res.status_code == 200
        except Exception:
            searxng_ok = False

        # Check Qdrant
        try:
            res = await client.get(f"{settings.QDRANT_URL.rstrip('/')}/collections")
            qdrant_ok = res.status_code == 200
        except Exception:
            qdrant_ok = False

    overall = "healthy" if (searxng_ok and qdrant_ok) else "degraded"

    return {
        "status": overall,
        "services": {
            "searxng": {
                "url": settings.SEARXNG_URL,
                "status": "online" if searxng_ok else "offline",
            },
            "qdrant": {
                "url": settings.QDRANT_URL,
                "status": "online" if qdrant_ok else "offline",
            },
        },
        "registered_tools": [t.id for t in registry.list_tools()],
        "version": settings.VERSION,
    }
