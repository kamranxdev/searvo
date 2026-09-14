import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Searvo Backend API"
    VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # Network URLs
    SEARXNG_URL: str = os.getenv("SEARXNG_URL", "http://localhost:4000")
    QDRANT_URL: str = os.getenv("QDRANT_URL", "http://localhost:6333")
    QDRANT_COLLECTION: str = "searvo_knowledge_base"
    
    # Server host & port
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # Fallback LLM Keys
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    OPENROUTER_API_KEY: str = os.getenv("OPENROUTER_API_KEY", "")
    OLLAMA_BASE_URL: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")

    # Defaults
    DEFAULT_REASONING_MODEL: str = os.getenv("DEFAULT_REASONING_MODEL", "gpt-4o-mini")
    DEFAULT_GENERATION_MODEL: str = os.getenv("DEFAULT_GENERATION_MODEL", "gpt-4o-mini")
    DEFAULT_EMBEDDING_MODEL: str = os.getenv("DEFAULT_EMBEDDING_MODEL", "text-embedding-3-small")

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
