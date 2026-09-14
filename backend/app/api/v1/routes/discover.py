import logging
import random
import httpx
from typing import List, Dict, Any, Optional
from urllib.parse import urlparse
from fastapi import APIRouter, Query
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/discover", tags=["Discover"])

TOPIC_QUERIES = {
    "technology": ["AI advancements", "tech news", "software development", "gadgets"],
    "science": ["space exploration", "quantum computing", "biotechnology", "physics breakthrough"],
    "business": ["market trends", "global economy", "startup funding", "finance"],
    "entertainment": ["film cinema", "video games", "music releases", "pop culture"],
}

@router.get("")
async def get_discover_articles(
    topic: str = Query("technology", description="Topic to fetch articles for"),
    limit: int = Query(15, description="Number of articles to return"),
):
    """Fetches and curates high-quality news articles with thumbnails for the Discover screen."""
    queries = TOPIC_QUERIES.get(topic.lower(), [f"{topic} news", f"{topic} latest"])
    random.shuffle(queries)
    selected_query = queries[0]

    url = f"{settings.SEARXNG_URL.rstrip('/')}/search"
    params = {
        "q": selected_query,
        "categories": "news",
        "format": "json",
        "language": "en",
        "pageno": 1,
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.get(url, params=params)
            if res.status_code != 200:
                return {"topic": topic, "articles": []}

            data = res.json()
            raw_results = data.get("results", [])

            articles = []
            seen_urls = set()

            for r in raw_results:
                link = r.get("url", "").strip()
                if not link or link in seen_urls:
                    continue

                thumb = r.get("img_src") or r.get("thumbnail") or ""
                # Prioritize articles with images for beautiful editorial presentation
                domain = urlparse(link).netloc or r.get("engine", "news")

                articles.append({
                    "id": str(hash(link)),
                    "title": r.get("title", ""),
                    "url": link,
                    "snippet": r.get("content", ""),
                    "thumbnail": thumb,
                    "source": domain,
                    "domain": domain,
                    "publishedDate": r.get("publishedDate"),
                    "topic": topic,
                })
                seen_urls.add(link)

            # Sort to place articles with thumbnails first
            articles.sort(key=lambda a: 0 if a["thumbnail"] else 1)

            return {
                "topic": topic,
                "count": len(articles[:limit]),
                "articles": articles[:limit],
            }

    except Exception as e:
        logger.error(f"Error fetching discover articles: {e}")
        return {"topic": topic, "error": str(e), "articles": []}
