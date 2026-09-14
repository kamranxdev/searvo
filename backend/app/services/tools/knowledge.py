import httpx
import logging
import math
from typing import Dict, Any
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class DictionaryTool(BaseTool):
    id = "dictionary"
    name = "Dictionary"
    description = "Look up word definitions, phonetics, origins, parts of speech, and examples."
    input_schema = {
        "type": "object",
        "properties": {
            "word": {
                "type": "string",
                "description": "The English word to define.",
            },
        },
        "required": ["word"],
    }

    async def execute(self, word: str, **kwargs) -> Dict[str, Any]:
        clean_word = word.strip().lower()
        url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{clean_word}"

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(url)
                if res.status_code != 200:
                    return {"error": f"Definition not found for '{clean_word}'"}

                data = res.json()
                if not data or not isinstance(data, list):
                    return {"error": f"No data for '{clean_word}'"}

                entry = data[0]
                word_text = entry.get("word", clean_word)
                phonetic = entry.get("phonetic", "")
                meanings = entry.get("meanings", [])

                definitions_list = []
                for m in meanings:
                    part = m.get("partOfSpeech", "")
                    for d in m.get("definitions", [])[:2]:
                        definitions_list.append({
                            "partOfSpeech": part,
                            "definition": d.get("definition", ""),
                            "example": d.get("example"),
                        })

                first_def = definitions_list[0]["definition"] if definitions_list else "No definition."

                return {
                    "word": word_text,
                    "phonetic": phonetic,
                    "definitions": definitions_list,
                    "meanings": meanings,
                    "display": f"{word_text} ({phonetic}): {first_def}",
                }
        except Exception as e:
            logger.error(f"Error in DictionaryTool: {e}")
            return {"error": str(e)}

class WikipediaTool(BaseTool):
    id = "wikipedia"
    name = "Wikipedia"
    description = "Retrieve summary articles, background knowledge, and facts from Wikipedia."
    input_schema = {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Topic or title to search on Wikipedia.",
            },
        },
        "required": ["query"],
    }

    async def execute(self, query: str, **kwargs) -> Dict[str, Any]:
        url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{query.strip().replace(' ', '_')}"
        headers = {"User-Agent": "SearvoBot/1.0 (https://searvo.ai; contact@searvo.ai)"}

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(url, headers=headers)
                if res.status_code != 200:
                    return {"error": f"No Wikipedia article found for '{query}'"}

                data = res.json()
                title = data.get("title", query)
                extract = data.get("extract", "")
                page_url = data.get("content_urls", {}).get("desktop", {}).get("page", "")
                thumbnail = data.get("thumbnail", {}).get("source", "")

                return {
                    "title": title,
                    "summary": extract,
                    "url": page_url,
                    "thumbnail": thumbnail,
                    "display": f"Wikipedia: {title} - {extract[:300]}...",
                }
        except Exception as e:
            logger.error(f"Error in WikipediaTool: {e}")
            return {"error": str(e)}

class CountryInfoTool(BaseTool):
    id = "country_info"
    name = "Country Info"
    description = "Get detailed information about countries (capital, population, currency, region, languages)."
    input_schema = {
        "type": "object",
        "properties": {
            "country": {
                "type": "string",
                "description": "Name of the country.",
            },
        },
        "required": ["country"],
    }

    async def execute(self, country: str, **kwargs) -> Dict[str, Any]:
        url = f"https://restcountries.com/v3.1/name/{country.strip()}?fullText=false"
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(url)
                if res.status_code != 200:
                    return {"error": f"Country not found: '{country}'"}

                data = res.json()
                if not data:
                    return {"error": f"No data for '{country}'"}

                item = data[0]
                name = item.get("name", {}).get("common", country)
                capital = ", ".join(item.get("capital", []))
                population = item.get("population", 0)
                region = item.get("region", "")
                flag = item.get("flag", "")
                currencies = list(item.get("currencies", {}).keys())

                return {
                    "country": name,
                    "capital": capital,
                    "population": population,
                    "region": region,
                    "flag": flag,
                    "currencies": currencies,
                    "display": f"{name} {flag}: Capital: {capital}, Population: {population:,}, Region: {region}.",
                }
        except Exception as e:
            logger.error(f"Error in CountryInfoTool: {e}")
            return {"error": str(e)}

class CalculatorTool(BaseTool):
    id = "calculator"
    name = "Calculator"
    description = "Evaluate mathematical expressions, formulas, and arithmetic calculations."
    input_schema = {
        "type": "object",
        "properties": {
            "expression": {
                "type": "string",
                "description": "Math expression to evaluate (e.g., '14 * 25', 'sqrt(144) + 12').",
            },
        },
        "required": ["expression"],
    }

    async def execute(self, expression: str, **kwargs) -> Dict[str, Any]:
        try:
            # Safe math evaluation using math namespace
            allowed_names = {
                k: v for k, v in math.__dict__.items() if not k.startswith("__")
            }
            allowed_names["abs"] = abs
            allowed_names["round"] = round

            clean_expr = expression.replace("^", "**")
            result = eval(clean_expr, {"__builtins__": {}}, allowed_names)
            return {
                "expression": expression,
                "result": result,
                "display": f"{expression} = {result}",
            }
        except Exception as e:
            return {"error": f"Failed to evaluate expression: {e}"}
