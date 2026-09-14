import httpx
import logging
from typing import Dict, Any
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class WeatherTool(BaseTool):
    id = "weather"
    name = "Weather"
    description = "Get current weather and forecast for a specific city or location."
    input_schema = {
        "type": "object",
        "properties": {
            "location": {
                "type": "string",
                "description": 'The city or location name (e.g., "Paris", "New York", "Tokyo").',
            },
        },
        "required": ["location"],
    }

    async def execute(self, location: str, **kwargs) -> Dict[str, Any]:
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                # 1. Geocode location
                geo_url = "https://geocoding-api.open-meteo.com/v1/search"
                geo_res = await client.get(geo_url, params={"name": location, "count": 1, "language": "en", "format": "json"})
                if geo_res.status_code != 200:
                    return {"error": "Failed to geocode location"}

                geo_data = geo_res.json()
                results = geo_data.get("results")
                if not results:
                    return {"error": f"Location not found: {location}"}

                city = results[0]
                lat = city["latitude"]
                lon = city["longitude"]
                city_name = city["name"]
                country = city.get("country", "")

                # 2. Fetch detailed forecast
                weather_url = "https://api.open-meteo.com/v1/forecast"
                weather_params = {
                    "latitude": lat,
                    "longitude": lon,
                    "current": "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,visibility,uv_index",
                    "daily": "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max",
                    "hourly": "temperature_2m,weather_code,precipitation_probability",
                    "timezone": "auto",
                    "forecast_days": 2,
                }
                weather_res = await client.get(weather_url, params=weather_params)
                if weather_res.status_code != 200:
                    return {"error": "Failed to fetch weather forecast"}

                weather_data = weather_res.json()
                current = weather_data.get("current", {})
                daily = weather_data.get("daily", {})
                hourly = weather_data.get("hourly", {})

                temp = current.get("temperature_2m", "N/A")
                humidity = current.get("relative_humidity_2m", "N/A")
                wind = current.get("wind_speed_10m", "N/A")

                display = f"Weather for {city_name}, {country}: Temperature: {temp}°C, Humidity: {humidity}%, Wind: {wind} km/h."

                return {
                    "location": {
                        "name": city_name,
                        "country": country,
                        "latitude": lat,
                        "longitude": lon,
                    },
                    "current": current,
                    "daily": daily,
                    "hourly": hourly,
                    "display": display,
                }
        except Exception as e:
            logger.error(f"Error in WeatherTool: {e}")
            return {"error": str(e)}
