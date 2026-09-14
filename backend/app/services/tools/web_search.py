import logging
import httpx
from typing import Dict, Any, List
from urllib.parse import urlparse
from app.config import settings
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class WebSearchTool(BaseTool):
    id = "web_search"
    name = "Web Search"
    description = "Searches the web for up-to-date information, news, websites, and data."
    input_schema = {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "The search query string.",
            },
            "maxResults": {
                "type": "integer",
                "description": "Maximum number of search results to return.",
                "default": 10,
            },
            "category": {
                "type": "string",
                "description": "Search category: general, news, images, videos, science.",
                "default": "general",
            },
        },
        "required": ["query"],
    }

    async def execute(self, query: str, maxResults: int = 10, category: str = "general", **kwargs) -> Dict[str, Any]:
        params = {
            "q": query,
            "format": "json",
            "categories": category,
            "pageno": 1,
        }

        url = f"{settings.SEARXNG_URL.rstrip('/')}/search"
        logger.info(f"Querying SearXNG at {url} for '{query}' (category: {category})")

        try:
            async with httpx.AsyncClient(timeout=25.0) as client:
                response = await client.get(url, params=params)
                
                if response.status_code != 200:
                    logger.warning(f"SearXNG returned status {response.status_code}: {response.text[:200]}")
                    return {"success": False, "documents": [], "sources": [], "images": [], "videos": []}

                data = response.json()
                raw_results = data.get("results", [])

                sources: List[Dict[str, Any]] = []
                documents: List[Dict[str, Any]] = []
                images: List[str] = []
                videos: List[Dict[str, Any]] = []

                for r in raw_results[:maxResults]:
                    url_str = r.get("url", "")
                    title = r.get("title", "")
                    content = r.get("content", "")
                    img_src = r.get("img_src") or r.get("thumbnail") or ""
                    engine = r.get("engine", "web")

                    domain = ""
                    try:
                        domain = urlparse(url_str).netloc
                    except Exception:
                        domain = engine

                    source_item = {
                        "title": title,
                        "url": url_str,
                        "description": content,
                        "thumbnail": img_src,
                        "domain": domain,
                        "source": engine,
                        "publishedDate": r.get("publishedDate"),
                    }
                    sources.append(source_item)
                    
                    documents.append({
                        "id": str(hash(url_str)),
                        "title": title,
                        "url": url_str,
                        "content": content,
                        "snippet": content,
                        "thumbnail": img_src,
                        "source": engine,
                        "publishedDate": r.get("publishedDate"),
                    })

                    if img_src:
                        images.append(img_src)

                    if "youtube.com" in url_str or "vimeo.com" in url_str or category == "videos":
                        videos.append({
                            "url": url_str,
                            "title": title,
                            "thumbnail": img_src,
                            "description": content,
                            "domain": domain,
                        })

                return {
                    "success": True,
                    "query": query,
                    "documents": documents,
                    "sources": sources,
                    "images": images,
                    "videos": videos,
                }

        except Exception as e:
            logger.error(f"Error querying SearXNG: {e}")
            return {
                "success": False,
                "error": str(e),
                "documents": [],
                "sources": [],
                "images": [],
                "videos": [],
            }
