from typing import Dict, Any
from app.services.tools.base import BaseTool
from app.services.rag.vector_store import QdrantStore

class VectorSearchTool(BaseTool):
    id = "vector_search"
    name = "Vector Knowledge Base Search"
    description = "Searches user's uploaded documents, attachments, and personal knowledge base."
    input_schema = {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "The search query to match against uploaded documents.",
            },
            "top_k": {
                "type": "integer",
                "description": "Number of relevant chunks to retrieve.",
                "default": 5,
            },
        },
        "required": ["query"],
    }

    def __init__(self, store: QdrantStore):
        self.store = store

    async def execute(self, query: str, top_k: int = 5, **kwargs) -> Dict[str, Any]:
        docs = await self.store.similarity_search(query=query, top_k=top_k)
        sources = []

        for d in docs:
            meta = d.get("metadata", {})
            sources.append({
                "title": meta.get("filename", "Uploaded Document"),
                "url": meta.get("url", ""),
                "description": d.get("content", ""),
                "source": "Document",
                "domain": "local",
            })

        return {
            "query": query,
            "documents": docs,
            "sources": sources,
            "display": f"Found {len(docs)} matching sections in uploaded documents.",
        }
