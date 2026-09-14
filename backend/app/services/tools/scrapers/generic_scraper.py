import httpx
import logging
from bs4 import BeautifulSoup
from typing import Dict, Any
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class GenericWebScraperTool(BaseTool):
    id = "read_page"
    name = "Read Web Page"
    description = "Scrapes and reads the full text content, article body, and details from any specific web URL."
    input_schema = {
        "type": "object",
        "properties": {
            "url": {
                "type": "string",
                "description": "The URL of the webpage to scrape and read.",
            },
        },
        "required": ["url"],
    }

    async def execute(self, url: str, **kwargs) -> Dict[str, Any]:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        }

        try:
            async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
                res = await client.get(url, headers=headers)
                if res.status_code != 200:
                    return {"error": f"Failed to fetch page (Status {res.status_code})"}

                soup = BeautifulSoup(res.text, "html.parser")

                # Remove non-content elements
                for element in soup(["script", "style", "nav", "footer", "header", "aside", "noscript", "svg"]):
                    element.decompose()

                title = ""
                if soup.title and soup.title.string:
                    title = soup.title.string.strip()

                # Extract main text
                paragraphs = [p.get_text().strip() for p in soup.find_all(["p", "article", "section", "h1", "h2", "h3"]) if p.get_text().strip()]
                full_text = "\n\n".join(paragraphs)

                # Cap length for context limit
                capped_text = full_text[:4000] if len(full_text) > 4000 else full_text

                return {
                    "url": url,
                    "title": title,
                    "content": capped_text,
                    "display": f"Content from {url}: {title}\n\n{capped_text[:300]}...",
                }

        except Exception as e:
            logger.error(f"Error scraping {url}: {e}")
            return {"error": f"Failed to scrape webpage: {str(e)}"}
