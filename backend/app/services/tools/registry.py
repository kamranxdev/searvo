from typing import Dict, List, Optional, Any
from app.services.tools.base import BaseTool
from app.services.tools.web_search import WebSearchTool
from app.services.tools.weather import WeatherTool
from app.services.tools.finance import StockPriceTool, CryptoPriceTool
from app.services.tools.knowledge import DictionaryTool, WikipediaTool, CountryInfoTool, CalculatorTool
from app.services.tools.scrapers.youtube_scraper import YouTubeScraperTool
from app.services.tools.scrapers.generic_scraper import GenericWebScraperTool
from app.services.tools.scrapers.scholar_scraper import ScholarScraperTool
from app.services.tools.scrapers.playstore_scraper import PlayStoreScraperTool
from app.services.tools.utilities import (
    CurrencyConverterTool,
    HolidayTool,
    TimeTool,
    NumbersTool,
    UnitConverterTool,
    ImageSearchTool,
    MapTool,
)
from app.services.tools.vector_search import VectorSearchTool
from app.services.rag.vector_store import QdrantStore

class ToolRegistry:
    def __init__(self, qdrant_store: Optional[QdrantStore] = None):
        self._tools: Dict[str, BaseTool] = {}
        self.store = qdrant_store or QdrantStore()
        self._register_default_tools()

    def _register_default_tools(self):
        tools = [
            WebSearchTool(),
            WeatherTool(),
            StockPriceTool(),
            CryptoPriceTool(),
            DictionaryTool(),
            WikipediaTool(),
            CountryInfoTool(),
            CalculatorTool(),
            CurrencyConverterTool(),
            HolidayTool(),
            TimeTool(),
            NumbersTool(),
            UnitConverterTool(),
            ImageSearchTool(),
            MapTool(),
            YouTubeScraperTool(),
            GenericWebScraperTool(),
            ScholarScraperTool(),
            PlayStoreScraperTool(),
            VectorSearchTool(self.store),
        ]
        for t in tools:
            self.register(t)

    def register(self, tool: BaseTool):
        self._tools[tool.id] = tool

    def get_tool(self, tool_id: str) -> Optional[BaseTool]:
        return self._tools.get(tool_id)

    def list_tools(self) -> List[BaseTool]:
        return list(self._tools.values())

    def get_descriptors(self) -> List[Dict[str, Any]]:
        return [t.to_descriptor() for t in self._tools.values()]
