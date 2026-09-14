import httpx
import logging
from typing import Dict, Any
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class StockPriceTool(BaseTool):
    id = "stock_price"
    name = "Stock Price"
    description = "Get real-time stock price and market data for US and global equities (e.g. AAPL, MSFT, TSLA, NVDA)."
    input_schema = {
        "type": "object",
        "properties": {
            "symbol": {
                "type": "string",
                "description": "Stock ticker symbol (e.g., AAPL, GOOGL, TSLA).",
            },
        },
        "required": ["symbol"],
    }

    async def execute(self, symbol: str, **kwargs) -> Dict[str, Any]:
        clean_symbol = symbol.strip().upper()
        url = f"https://query1.finance.yahoo.com/v8/finance/chart/{clean_symbol}?interval=1d&range=1d"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                res = await client.get(url, headers=headers)
                if res.status_code != 200:
                    return {"error": f"Failed to fetch stock data (Status {res.status_code})"}

                data = res.json()
                chart = data.get("chart", {})
                results = chart.get("result", [])
                if not results:
                    return {"error": f"Symbol not found: {clean_symbol}"}

                meta = results[0].get("meta", {})
                price = meta.get("regularMarketPrice", 0.0)
                prev_close = meta.get("previousClose", price)
                change = price - prev_close
                change_pct = (change / prev_close * 100) if prev_close else 0.0

                return {
                    "symbol": clean_symbol,
                    "currency": meta.get("currency", "USD"),
                    "price": price,
                    "change": round(change, 2),
                    "change_percent": round(change_pct, 2),
                    "previous_close": prev_close,
                    "day_high": meta.get("regularMarketDayHigh", price),
                    "day_low": meta.get("regularMarketDayLow", price),
                    "exchange": meta.get("exchangeName", ""),
                    "display": f"{clean_symbol}: ${price:.2f} ({change:+.2f}, {change_pct:+.2f}%)",
                }
        except Exception as e:
            logger.error(f"Error in StockPriceTool: {e}")
            return {"error": str(e)}

class CryptoPriceTool(BaseTool):
    id = "crypto_price"
    name = "Crypto Price"
    description = "Get real-time cryptocurrency prices, market caps, and 24h change (e.g. bitcoin, ethereum, solana)."
    input_schema = {
        "type": "object",
        "properties": {
            "coin_id": {
                "type": "string",
                "description": "Cryptocurrency name or ID (e.g. bitcoin, ethereum, dogecoin, solana).",
            },
            "currency": {
                "type": "string",
                "description": "Target fiat currency (default: usd).",
                "default": "usd",
            },
        },
        "required": ["coin_id"],
    }

    async def execute(self, coin_id: str, currency: str = "usd", **kwargs) -> Dict[str, Any]:
        clean_coin = coin_id.strip().lower()
        clean_curr = currency.strip().lower()
        url = f"https://api.coingecko.com/api/v3/coins/markets?vs_currency={clean_curr}&ids={clean_coin}&order=market_cap_desc&per_page=1&page=1&sparkline=false"

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                res = await client.get(url, headers={"Accept": "application/json"})
                if res.status_code != 200:
                    return {"error": f"Failed to fetch crypto data (Status {res.status_code})"}

                data = res.json()
                if not data or not isinstance(data, list):
                    return {"error": f"Coin not found: {clean_coin}"}

                coin_data = data[0]
                price = coin_data.get("current_price", 0.0)
                change_24h = coin_data.get("price_change_percentage_24h", 0.0)

                return {
                    "coin_id": clean_coin,
                    "name": coin_data.get("name", clean_coin.capitalize()),
                    "symbol": coin_data.get("symbol", "").upper(),
                    "current_price": price,
                    "price_change_percentage_24h": round(change_24h, 2),
                    "market_cap": coin_data.get("market_cap", 0),
                    "total_volume": coin_data.get("total_volume", 0),
                    "high_24h": coin_data.get("high_24h", price),
                    "low_24h": coin_data.get("low_24h", price),
                    "image": coin_data.get("image", ""),
                    "display": f"{coin_data.get('name', clean_coin)}: ${price:,.2f} ({change_24h:+.2f}% 24h)",
                }
        except Exception as e:
            logger.error(f"Error in CryptoPriceTool: {e}")
            return {"error": str(e)}
