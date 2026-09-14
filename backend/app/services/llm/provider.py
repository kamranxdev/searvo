import os
import json
import logging
from typing import AsyncGenerator, Dict, Any, Optional, List
import litellm
from app.config import settings

logger = logging.getLogger(__name__)

# Suppress noisy LiteLLM logs
litellm.suppress_debug_info = True

class LLMProvider:
    """
    Unified LLM provider handling completions, streaming, and tool planning
    across OpenAI, Anthropic, Gemini, Ollama, and OpenRouter.
    Supports both server-configured keys and client BYOK (per-request keys).
    """

    def __init__(self, api_keys: Optional[Dict[str, str]] = None):
        self.api_keys = api_keys or {}

    def _resolve_key(self, provider: str) -> Optional[str]:
        # First check client-provided keys
        if provider in self.api_keys and self.api_keys[provider]:
            return self.api_keys[provider]
        if provider == "google" and "gemini" in self.api_keys and self.api_keys["gemini"]:
            return self.api_keys["gemini"]
        if provider == "gemini" and "google" in self.api_keys and self.api_keys["google"]:
            return self.api_keys["google"]

        # Then check server environment
        env_map = {
            "openai": settings.OPENAI_API_KEY,
            "anthropic": settings.ANTHROPIC_API_KEY,
            "gemini": settings.GEMINI_API_KEY,
            "google": settings.GEMINI_API_KEY,
            "openrouter": settings.OPENROUTER_API_KEY,
        }
        return env_map.get(provider) or os.getenv(f"{provider.upper()}_API_KEY")

    def has_available_provider(self) -> bool:
        """Check whether any LLM credentials or local base URLs are configured."""
        if any(self._resolve_key(p) for p in ["openai", "gemini", "anthropic", "openrouter"]):
            return True
        if self.api_keys.get("ollama_base_url") or settings.OLLAMA_BASE_URL:
            return True
        return False

    def normalize_model_name(self, model: str) -> str:
        """Ensure provider prefix is attached so LiteLLM dispatches properly."""
        m = model.strip()
        m_lower = m.lower()
        if (m_lower.startswith("gemini") or "gemini" in m_lower) and not m_lower.startswith("gemini/"):
            return f"gemini/{m}"
        if (m_lower.startswith("claude") or "anthropic" in m_lower) and not m_lower.startswith("anthropic/"):
            return f"anthropic/{m}"
        if "openrouter" in m_lower and not m_lower.startswith("openrouter/"):
            return f"openrouter/{m}"
        if "ollama" in m_lower and not m_lower.startswith("ollama/"):
            return f"ollama/{m}"
        return m

    def resolve_best_model(self, requested_model: Optional[str] = None, use_case: str = "generation") -> Optional[str]:
        """
        Dynamically selects the best model matching available API credentials.
        If a requested model lacks a corresponding key, falls back to a provider that has a key.
        """
        # 1. If requested model was specified, check if its provider has a key
        if requested_model and requested_model.strip():
            normalized = self.normalize_model_name(requested_model)
            norm_lower = normalized.lower()

            if "gemini" in norm_lower:
                if self._resolve_key("gemini"):
                    return normalized
            elif "anthropic" in norm_lower or "claude" in norm_lower:
                if self._resolve_key("anthropic"):
                    return normalized
            elif "openrouter" in norm_lower:
                if self._resolve_key("openrouter"):
                    return normalized
            elif "ollama" in norm_lower:
                return normalized
            elif "gpt" in norm_lower or "openai" in norm_lower:
                if self._resolve_key("openai"):
                    return normalized

        # 2. Find any provider with an available API key
        if self._resolve_key("gemini"):
            return "gemini/gemini-2.0-flash"
        if self._resolve_key("openai"):
            return settings.DEFAULT_GENERATION_MODEL if use_case == "generation" else settings.DEFAULT_REASONING_MODEL
        if self._resolve_key("anthropic"):
            return "anthropic/claude-3-5-sonnet-20241022"
        if self._resolve_key("openrouter"):
            return "openrouter/meta-llama/llama-3.3-70b-instruct"
        if self.api_keys.get("ollama_base_url"):
            return "ollama/llama3"

        return None

    def _get_model_kwargs(self, model: str) -> Dict[str, Any]:
        normalized_model = self.normalize_model_name(model)
        kwargs: Dict[str, Any] = {"model": normalized_model}
        m_lower = normalized_model.lower()

        # Check provider from model prefix
        if "anthropic" in m_lower or m_lower.startswith("claude"):
            key = self._resolve_key("anthropic")
            if key:
                kwargs["api_key"] = key
        elif "gemini" in m_lower or "google" in m_lower:
            key = self._resolve_key("gemini") or self._resolve_key("google")
            if key:
                kwargs["api_key"] = key
        elif "openrouter" in m_lower:
            key = self._resolve_key("openrouter")
            if key:
                kwargs["api_key"] = key
        elif "ollama" in m_lower or "localhost:11434" in m_lower:
            kwargs["api_base"] = self.api_keys.get("ollama_base_url") or settings.OLLAMA_BASE_URL
        else:
            # Default to OpenAI
            key = self._resolve_key("openai")
            if key:
                kwargs["api_key"] = key

        return kwargs

    async def generate_json(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        model: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Generate structured JSON response (used for agent planning)."""
        target_model = self.resolve_best_model(model, use_case="reasoning")
        if not target_model:
            raise ValueError("No configured LLM credentials found for reasoning.")

        kwargs = self._get_model_kwargs(target_model)

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        try:
            response = await litellm.acompletion(
                messages=messages,
                response_format={"type": "json_object"},
                temperature=0.1,
                **kwargs,
            )
            content = response.choices[0].message.content
            return json.loads(content)
        except Exception as e:
            logger.warning(f"Failed with response_format=json_object, retrying with raw prompt: {e}")
            # Fallback without response_format
            response = await litellm.acompletion(
                messages=messages,
                temperature=0.1,
                **kwargs,
            )
            content = response.choices[0].message.content.strip()
            # Clean markdown backticks if present
            if content.startswith("```json"):
                content = content[7:]
            if content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]
            return json.loads(content.strip())

    async def stream_completion(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        model: Optional[str] = None,
    ) -> AsyncGenerator[str, None]:
        """Stream completion tokens as they are generated."""
        target_model = self.resolve_best_model(model, use_case="generation")
        if not target_model:
            yield "[Missing credentials: No active LLM provider configured]"
            return

        kwargs = self._get_model_kwargs(target_model)

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        try:
            response = await litellm.acompletion(
                messages=messages,
                stream=True,
                temperature=0.3,
                **kwargs,
            )
            async for chunk in response:
                delta = chunk.choices[0].delta.content
                if delta:
                    yield delta
        except Exception as e:
            logger.error(f"Error in stream_completion: {e}")
            yield f"\n\n[Error generating response: {str(e)}]"
