from fastapi import APIRouter
from app.api.v1.routes.search import router as search_router
from app.api.v1.routes.discover import router as discover_router
from app.api.v1.routes.documents import router as documents_router
from app.api.v1.routes.health import router as health_router

api_v1_router = APIRouter(prefix="/api/v1")

api_v1_router.include_router(search_router)
api_v1_router.include_router(discover_router)
api_v1_router.include_router(documents_router)
api_v1_router.include_router(health_router)
