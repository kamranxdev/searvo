import re
import json
import logging
from typing import Dict, Any, List, Optional
from app.services.llm.provider import LLMProvider
from app.services.tools.registry import ToolRegistry
from app.services.rag.verification import IntentClassifier

logger = logging.getLogger(__name__)

class AgentOrchestrator:
    def __init__(self, tool_registry: ToolRegistry, llm_provider: LLMProvider):
        self.registry = tool_registry
        self.llm = llm_provider

    async def plan(
        self,
        query: str,
        attachments: Optional[List[Dict[str, Any]]] = None,
        previous_messages: Optional[List[Dict[str, Any]]] = None,
        model: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Analyzes user query and decides on the best tools to execute."""

        # 1. Fast Heuristic Path (Instant execution, zero LLM latency/cost)
        fast_plan = self._heuristic_plan(query, attachments)
        if fast_plan:
            logger.info(f"Fast-path heuristic matched for '{query}': {fast_plan['reasoning']}")
            return fast_plan

        # 2. LLM Autonomous Agent Path
        tools = self.registry.get_descriptors()

        attachments_info = ""
        if attachments and len(attachments) > 0:
            names = [a.get("name", "document") for a in attachments]
            attachments_info = (
                f"\nIMPORTANT: The user attached the following files: {', '.join(names)}.\n"
                f"If the query asks about these files (e.g. 'summarize', 'what does this say'), "
                f"you MUST include the 'vector_search' tool.\n"
            )

        history_info = ""
        if previous_messages and len(previous_messages) > 0:
            history_lines = []
            for msg in previous_messages[-3:]:
                q = msg.get("query", "")
                a = msg.get("answer", "")
                if q:
                    history_lines.append(f"User: {q}")
                if a:
                    history_lines.append(f"Assistant: {a[:200]}...")
            if history_lines:
                history_info = "\nConversation History:\n" + "\n".join(history_lines) + "\n"

        system_prompt = f"""You are an intelligent orchestrator for the Searvo AI search app.
Analyze the user's query and select the best tools to fulfill the request.

Available Tools:
{jsonEncode_tools(tools)}

Instructions:
1. If the user asks for weather, stocks, crypto, definitions, math, or country facts, SELECT THAT SPECIFIC TOOL.
2. For current events, general knowledge, or web topics, SELECT 'web_search'.
3. For YouTube links, SELECT 'youtube_scraper'.
4. For specific webpage URLs in the query, SELECT 'read_page'.
5. If the user refers to attached files, SELECT 'vector_search'.
6. Keep the plan minimal (1 to 2 steps usually sufficient).

Response Format:
You must respond with ONLY a valid JSON object matching this schema:
{{
  "reasoning": "Brief explanation of tool selection",
  "steps": [
    {{
      "toolId": "id_of_tool",
      "input": {{ ... parameters matching tool schema ... }},
      "description": "Short user-facing step title"
    }}
  ]
}}
"""

        prompt = f"{history_info}User Query: {query}\n{attachments_info}"

        try:
            plan_json = await self.llm.generate_json(
                prompt=prompt,
                system_prompt=system_prompt,
                model=model,
            )
            if "steps" not in plan_json or not isinstance(plan_json["steps"], list) or len(plan_json["steps"]) == 0:
                return {
                    "reasoning": "Performing web search for query.",
                    "steps": [{"toolId": "web_search", "input": {"query": query}, "description": "Searching the web"}],
                }
            return plan_json
        except Exception as e:
            logger.warning(f"Orchestrator planning failed: {e}. Falling back to web_search.")
            return {
                "reasoning": f"Searching web sources for current information on '{query}'.",
                "steps": [{"toolId": "web_search", "input": {"query": query}, "description": "Searching the web"}],
            }

    def _heuristic_plan(self, query: str, attachments: Optional[List[Dict[str, Any]]]) -> Optional[Dict[str, Any]]:
        q = query.strip()
        q_lower = q.lower()

        # YouTube URL match
        yt_match = re.search(r"https?://(www\.)?(youtube\.com|youtu\.be)/[^\s]+", q)
        if yt_match:
            return {
                "reasoning": "Detected YouTube video URL.",
                "steps": [
                    {"toolId": "youtube_scraper", "input": {"url": yt_match.group(0)}, "description": "Extracting YouTube video metadata & transcript"},
                    {"toolId": "web_search", "input": {"query": q}, "description": "Finding additional web context"}
                ],
            }

        # Specific Webpage URL match
        url_match = re.search(r"https?://[^\s]+", q)
        if url_match and not yt_match:
            return {
                "reasoning": "Detected web URL to read.",
                "steps": [
                    {"toolId": "read_page", "input": {"url": url_match.group(0)}, "description": f"Reading page content: {url_match.group(0)[:30]}..."},
                    {"toolId": "web_search", "input": {"query": q}, "description": "Searching related sources"}
                ],
            }

        # Attachments query
        if attachments and len(attachments) > 0 and any(w in q_lower for w in ["this", "these", "summarize", "document", "file", "attachment", "what does"]):
            return {
                "reasoning": "Query refers to attached documents.",
                "steps": [
                    {"toolId": "vector_search", "input": {"query": q, "top_k": 5}, "description": "Searching uploaded document context"}
                ],
            }

        intent = IntentClassifier.classify(q)

        # Weather query
        if intent == "weather":
            loc_match = re.search(r"(?:weather|temperature|forecast)(?:\s+in|\s+for)?\s+([A-Za-z\s]+)", q_lower)
            loc = loc_match.group(1).strip() if loc_match else q.replace("weather", "").replace("forecast", "").strip()
            loc = loc if loc else "London"
            return {
                "reasoning": f"Direct weather lookup for {loc}.",
                "steps": [
                    {"toolId": "weather", "input": {"location": loc}, "description": f"Checking current weather & forecast for {loc}"},
                    {"toolId": "web_search", "input": {"query": f"weather in {loc}"}, "description": "Retrieving weather conditions"}
                ],
            }

        # Stock query
        if intent == "stock":
            symbol_match = re.search(r"\b([A-Z]{1,5})\b", q)
            symbol = symbol_match.group(1) if symbol_match else "AAPL"
            return {
                "reasoning": f"Stock price lookup for ticker {symbol}.",
                "steps": [
                    {"toolId": "stock_price", "input": {"symbol": symbol}, "description": f"Fetching live market chart for {symbol}"},
                    {"toolId": "web_search", "input": {"query": f"{symbol} stock news"}, "description": f"Retrieving recent market news for {symbol}"}
                ],
            }

        # Crypto query
        if intent == "crypto":
            coin = "bitcoin"
            for c in ["bitcoin", "ethereum", "solana", "dogecoin", "cardano", "xrp"]:
                if c in q_lower:
                    coin = c
                    break
            return {
                "reasoning": f"Cryptocurrency market data for {coin}.",
                "steps": [
                    {"toolId": "crypto_price", "input": {"coin_id": coin}, "description": f"Fetching live price for {coin.capitalize()}"},
                    {"toolId": "web_search", "input": {"query": f"{coin} price news"}, "description": f"Searching recent news for {coin}"}
                ],
            }

        # Definition query
        if intent == "dictionary":
            word_match = re.search(r"(?:define|meaning of|definition of)\s+([A-Za-z]+)", q_lower)
            word = word_match.group(1).strip() if word_match else q.split()[-1]
            return {
                "reasoning": f"Dictionary definition lookup for '{word}'.",
                "steps": [
                    {"toolId": "dictionary", "input": {"word": word}, "description": f"Looking up definition of '{word}'"}
                ],
            }

        # Math / Calculator query
        if intent == "calculator":
            clean_expr = re.sub(r"[^0-9\+\-\*\/\^\(\)\.\s]", "", q).strip()
            if clean_expr:
                return {
                    "reasoning": "Mathematical expression evaluation.",
                    "steps": [
                        {"toolId": "calculator", "input": {"expression": clean_expr}, "description": f"Calculating: {clean_expr}"}
                    ],
                }

        # World Time query
        if intent == "time":
            time_match = re.search(r"(?:time in|what time is it in)\s+([A-Za-z\s]+)", q_lower)
            loc = time_match.group(1).strip() if time_match else "London"
            return {
                "reasoning": f"World time lookup for {loc}.",
                "steps": [
                    {"toolId": "time", "input": {"location": loc}, "description": f"Checking local time in {loc}"}
                ],
            }

        return None

def jsonEncode_tools(tools: List[Dict[str, Any]]) -> str:
    return json.dumps(tools, indent=2)
