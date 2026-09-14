import httpx
import logging
from bs4 import BeautifulSoup
from typing import Dict, Any
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class ScholarScraperTool(BaseTool):
    id = "scholar_scraper"
    name = "Academic & Scholar Scraper"
    description = "Scrapes research papers, abstracts, citations, and authors from arXiv, PubMed, and academic portals."
    input_schema = {
        "type": "object",
        "properties": {
            "url": {"type": "string", "description": "Academic URL (e.g., arxiv.org, pubmed)."},
        },
        "required": ["url"],
    }

    async def execute(self, url: str, **kwargs) -> Dict[str, Any]:
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

        try:
            async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
                res = await client.get(url, headers=headers)
                if res.status_code != 200:
                    return {"error": f"Failed to fetch academic paper (Status {res.status_code})"}

                soup = BeautifulSoup(res.text, "html.parser")
                title = ""
                abstract = ""
                authors = []

                if "arxiv.org" in url:
                    t_el = soup.select_one("h1.title")
                    title = t_el.text.replace("Title:", "").strip() if t_el else ""
                    a_el = soup.select_one("blockquote.abstract")
                    abstract = a_el.text.replace("Abstract:", "").strip() if a_el else ""
                    for auth in soup.select("div.authors a"):
                        authors.append(auth.text.strip())

                elif "pubmed" in url:
                    t_el = soup.select_one("h1.heading-title")
                    title = t_el.text.strip() if t_el else ""
                    a_el = soup.select_one("div.abstract-content")
                    abstract = a_el.text.strip() if a_el else ""

                else:
                    title = soup.title.string.strip() if soup.title else ""
                    p_tags = [p.get_text().strip() for p in soup.find_all("p") if len(p.get_text().strip()) > 80]
                    abstract = p_tags[0] if p_tags else ""

                authors_str = ", ".join(authors) if authors else "Unknown Authors"
                display = f"Academic Paper: '{title}' by {authors_str}\n\nAbstract:\n{abstract[:400]}..."

                return {
                    "url": url,
                    "title": title,
                    "authors": authors,
                    "abstract": abstract,
                    "display": display,
                }
        except Exception as e:
            logger.error(f"Error scraping academic paper: {e}")
            return {"error": str(e)}
