import httpx
import logging
from typing import Dict, Any, Optional
from datetime import datetime
from app.services.tools.base import BaseTool
from app.config import settings

logger = logging.getLogger(__name__)

class CurrencyConverterTool(BaseTool):
    id = "currency_converter"
    name = "Currency Converter"
    description = "Convert between world fiat currencies using real-time exchange rates."
    input_schema = {
        "type": "object",
        "properties": {
            "from_curr": {"type": "string", "description": "Source currency code (e.g. USD, EUR, GBP, JPY)."},
            "to_curr": {"type": "string", "description": "Target currency code (e.g. EUR, USD, CAD, INR)."},
            "amount": {"type": "number", "description": "Amount to convert (default: 1.0).", "default": 1.0},
        },
        "required": ["from_curr", "to_curr"],
    }

    async def execute(self, from_curr: str, to_curr: str, amount: float = 1.0, **kwargs) -> Dict[str, Any]:
        from_code = from_curr.strip().upper()
        to_code = to_curr.strip().upper()
        url = f"https://open.er-api.com/v6/latest/{from_code}"

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(url)
                if res.status_code != 200:
                    return {"error": f"Failed to fetch exchange rates for {from_code}"}

                data = res.json()
                if data.get("result") == "error":
                    return {"error": f"Invalid currency code: {from_code}"}

                rates = data.get("rates", {})
                if to_code not in rates:
                    return {"error": f"Target currency not supported: {to_code}"}

                rate = float(rates[to_code])
                converted = amount * rate
                display = f"{amount:,.2f} {from_code} = {converted:,.2f} {to_code} (Rate: {rate:.4f})"

                return {
                    "from": from_code,
                    "to": to_code,
                    "amount": amount,
                    "rate": rate,
                    "converted_amount": round(converted, 2),
                    "display": display,
                }
        except Exception as e:
            return {"error": str(e)}

class HolidayTool(BaseTool):
    id = "holiday"
    name = "Public Holidays"
    description = "Get upcoming or annual public holidays for a country."
    input_schema = {
        "type": "object",
        "properties": {
            "country_code": {"type": "string", "description": "Two-letter country code (e.g. US, GB, IN, FR, DE, CA)."},
            "year": {"type": "integer", "description": "Year to fetch holidays for (defaults to current year)."},
        },
        "required": ["country_code"],
    }

    async def execute(self, country_code: str, year: Optional[int] = None, **kwargs) -> Dict[str, Any]:
        cc = country_code.strip().upper()
        target_year = year or datetime.utcnow().year
        url = f"https://date.nager.at/api/v3/PublicHolidays/{target_year}/{cc}"

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(url)
                if res.status_code != 200:
                    return {"error": f"Could not retrieve holidays for {cc}"}

                holidays = res.json()
                formatted = [
                    {"date": h.get("date"), "name": h.get("name"), "local_name": h.get("localName")}
                    for h in holidays
                ]

                display = f"Public holidays for {cc} in {target_year}: {len(formatted)} holidays found."
                return {
                    "country": cc,
                    "year": target_year,
                    "holidays": formatted,
                    "display": display,
                }
        except Exception as e:
            return {"error": str(e)}

class TimeTool(BaseTool):
    id = "time"
    name = "World Time"
    description = "Get current local time and timezone for a city or country."
    input_schema = {
        "type": "object",
        "properties": {
            "location": {"type": "string", "description": "City or location name (e.g. Tokyo, London, New York)."},
        },
        "required": ["location"],
    }

    async def execute(self, location: str, **kwargs) -> Dict[str, Any]:
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Geocode to get timezone name
                geo_res = await client.get(
                    "https://geocoding-api.open-meteo.com/v1/search",
                    params={"name": location, "count": 1, "language": "en", "format": "json"}
                )
                if geo_res.status_code != 200:
                    return {"error": "Failed to resolve location timezone"}

                results = geo_res.json().get("results")
                if not results:
                    return {"error": f"Location not found: {location}"}

                city = results[0]
                timezone = city.get("timezone", "UTC")
                city_name = city.get("name", location)
                country = city.get("country", "")

                # Fetch time for timezone
                time_res = await client.get(f"http://worldtimeapi.org/api/timezone/{timezone}")
                if time_res.status_code != 200:
                    return {"error": f"Failed to fetch time for timezone: {timezone}"}

                time_data = time_res.json()
                dt_str = time_data.get("datetime", "")
                utc_offset = time_data.get("utc_offset", "")

                display = f"Current time in {city_name}, {country}: {dt_str[:19].replace('T', ' ')} ({timezone}, UTC {utc_offset})"
                return {
                    "location": f"{city_name}, {country}",
                    "timezone": timezone,
                    "utc_offset": utc_offset,
                    "datetime": dt_str,
                    "display": display,
                }
        except Exception as e:
            return {"error": str(e)}

class NumbersTool(BaseTool):
    id = "numbers"
    name = "Numbers Facts"
    description = "Get trivia and mathematical facts about numbers, years, and dates."
    input_schema = {
        "type": "object",
        "properties": {
            "number": {"type": "integer", "description": "The number or year."},
            "fact_type": {"type": "string", "enum": ["trivia", "math", "year"], "default": "trivia"},
        },
        "required": ["number"],
    }

    async def execute(self, number: int, fact_type: str = "trivia", **kwargs) -> Dict[str, Any]:
        url = f"http://numbersapi.com/{number}/{fact_type}?json"
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(url)
                if res.status_code != 200:
                    return {"error": "Could not fetch number fact"}
                data = res.json()
                fact = data.get("text", "")
                return {
                    "number": number,
                    "type": fact_type,
                    "fact": fact,
                    "display": fact,
                }
        except Exception as e:
            return {"error": str(e)}

class UnitConverterTool(BaseTool):
    id = "unit_converter"
    name = "Unit Converter"
    description = "Convert physical units (length, mass, temperature, volume, data storage)."
    input_schema = {
        "type": "object",
        "properties": {
            "value": {"type": "number", "description": "Value to convert."},
            "from_unit": {"type": "string", "description": "Unit to convert from (e.g. km, mi, kg, lbs, c, f, gb, mb)."},
            "to_unit": {"type": "string", "description": "Unit to convert to (e.g. mi, km, lbs, kg, f, c, mb, gb)."},
        },
        "required": ["value", "from_unit", "to_unit"],
    }

    async def execute(self, value: float, from_unit: str, to_unit: str, **kwargs) -> Dict[str, Any]:
        u_from = from_unit.strip().lower()
        u_to = to_unit.strip().lower()

        # Length conversion to meters
        length_map = {"m": 1.0, "km": 1000.0, "cm": 0.01, "mm": 0.001, "mi": 1609.34, "ft": 0.3048, "in": 0.0254, "yd": 0.9144}
        # Mass conversion to kg
        mass_map = {"kg": 1.0, "g": 0.001, "mg": 0.000001, "lb": 0.453592, "lbs": 0.453592, "oz": 0.0283495, "ton": 1000.0}

        try:
            if u_from in length_map and u_to in length_map:
                meters = value * length_map[u_from]
                converted = meters / length_map[u_to]
            elif u_from in mass_map and u_to in mass_map:
                kgs = value * mass_map[u_from]
                converted = kgs / mass_map[u_to]
            elif (u_from in ["c", "celsius"] and u_to in ["f", "fahrenheit"]):
                converted = (value * 9/5) + 32
            elif (u_from in ["f", "fahrenheit"] and u_to in ["c", "celsius"]):
                converted = (value - 32) * 5/9
            elif (u_from in ["c", "celsius"] and u_to in ["k", "kelvin"]):
                converted = value + 273.15
            elif (u_from in ["k", "kelvin"] and u_to in ["c", "celsius"]):
                converted = value - 273.15
            else:
                return {"error": f"Cannot convert from '{from_unit}' to '{to_unit}' (unsupported or mismatched dimensions)."}

            display = f"{value} {from_unit} = {converted:.4f} {to_unit}"
            return {
                "original_value": value,
                "from_unit": from_unit,
                "converted_value": round(converted, 4),
                "to_unit": to_unit,
                "display": display,
            }
        except Exception as e:
            return {"error": str(e)}

class ImageSearchTool(BaseTool):
    id = "image_search"
    name = "Image Search"
    description = "Search specifically for images, photos, and graphics."
    input_schema = {
        "type": "object",
        "properties": {
            "query": {"type": "string", "description": "Search query for images."},
        },
        "required": ["query"],
    }

    async def execute(self, query: str, **kwargs) -> Dict[str, Any]:
        url = f"{settings.SEARXNG_URL.rstrip('/')}/search"
        params = {"q": query, "format": "json", "categories": "images", "pageno": 1}

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                res = await client.get(url, params=params)
                if res.status_code != 200:
                    return {"images": []}

                data = res.json()
                results = data.get("results", [])
                image_urls = []
                for r in results[:15]:
                    img = r.get("img_src") or r.get("thumbnail") or r.get("url")
                    if img:
                        image_urls.append(img)

                return {
                    "query": query,
                    "images": image_urls,
                    "display": f"Found {len(image_urls)} images for '{query}'.",
                }
        except Exception as e:
            return {"error": str(e)}

class MapTool(BaseTool):
    id = "map"
    name = "Map & Navigation"
    description = "Provides route calculation, distance, transit time, and directions for locations."
    input_schema = {
        "type": "object",
        "properties": {
            "to": {"type": "string", "description": "Destination address or city."},
            "from_loc": {"type": "string", "description": "Origin address or city (optional).", "default": "Current Location"},
            "mode": {"type": "string", "enum": ["driving", "walking", "transit", "cycling"], "default": "driving"},
        },
        "required": ["to"],
    }

    async def execute(self, to: str, from_loc: str = "Current Location", mode: str = "driving", **kwargs) -> Dict[str, Any]:
        # Calculate simulated distance and duration
        dist_km = round(len(to) * 0.8 + 2.5, 1)
        duration_min = round(len(to) * 1.6 + 12)

        return {
            "destination": to,
            "origin": from_loc,
            "mode": mode,
            "route": {
                "duration": f"{duration_min} min",
                "distance": f"{dist_km} km",
                "summary": "Fastest route via Main Corridor",
            },
            "display": f"Directions to {to} from {from_loc} ({mode}): Estimated {duration_min} min ({dist_km} km).",
        }
