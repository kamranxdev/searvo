from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class SearchStreamRequest(BaseModel):
    query: str
    conversation_id: Optional[str] = None
    attachments: Optional[List[Dict[str, Any]]] = Field(default_factory=list)
    previous_messages: Optional[List[Dict[str, Any]]] = None
    search_type: str = "general"
    recency: str = "any"
    max_results: int = 10
    
    # Optional client-provided API keys (BYOK)
    api_keys: Optional[Dict[str, str]] = None
    # Optional client-preferred model overrides
    reasoning_model: Optional[str] = None
    generation_model: Optional[str] = None

class RawSearchRequest(BaseModel):
    query: str
    page: int = 1
    category: str = "general"
    language: str = "auto"
    time_range: Optional[str] = None
    search_type: str = "general"

class DocumentQueryRequest(BaseModel):
    query: str
    top_k: int = 5
    collection: Optional[str] = None
