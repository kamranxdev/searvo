import httpx
import logging
from bs4 import BeautifulSoup
from typing import Dict, Any
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class PlayStoreScraperTool(BaseTool):
    id = "playstore_scraper"
    name = "Google Play Store Scraper"
    description = "Scrapes Android app metadata, rating, reviews, developer, and downloads from Google Play Store."
    input_schema = {
        "type": "object",
        "properties": {
            "url": {"type": "string", "description": "Google Play Store app URL (play.google.com/store/apps/details?id=...)."},
        },
        "required": ["url"],
    }

    async def execute(self, url: str, **kwargs) -> Dict[str, Any]:
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

        try:
            async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
                res = await client.get(url, headers=headers)
                if res.status_code != 200:
                    return {"error": f"Failed to fetch Play Store app page (Status {res.status_code})"}

                soup = BeautifulSoup(res.text, "html.parser")
                title_el = soup.select_one("h1[itemprop='name']") or soup.find("h1")
                title = title_el.text.strip() if title_el else "App"

                rating_el = soup.select_one("div[itemprop='starRating']") or soup.select_one("div.TT9OTd")
                rating = rating_el.text.strip() if rating_el else "N/A"

                dev_el = soup.select_one("div.Vbfug.auVDad a") or soup.select_one("a[href*='/store/apps/dev']")
                developer = dev_el.text.strip() if dev_el else "Unknown Developer"

                desc_el = soup.select_one("div[data-g-id='description']") or soup.select_one("div.bARER")
                description = desc_el.text.strip() if desc_el else ""

                display = f"Google Play App: {title} by {developer} (Rating: {rating})\n\n{description[:300]}..."

                return {
                    "url": url,
                    "title": title,
                    "developer": developer,
                    "rating": rating,
                    "description": description[:1000],
                    "display": display,
                }
        except Exception as e:
            logger.error(f"Error scraping Play Store app: {e}")
            return {"error": str(e)}
