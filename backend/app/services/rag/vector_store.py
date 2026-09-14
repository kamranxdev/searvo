import uuid
import logging
from typing import List, Dict, Any, Optional
import litellm
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from app.config import settings

logger = logging.getLogger(__name__)

class QdrantStore:
    def __init__(self, url: Optional[str] = None, collection_name: Optional[str] = None):
        self.url = url or settings.QDRANT_URL
        self.collection_name = collection_name or settings.QDRANT_COLLECTION
        self.client = AsyncQdrantClient(url=self.url)
        self._initialized = False

    async def ensure_collection(self, vector_size: int = 1536):
        if self._initialized:
            return

        try:
            collections = await self.client.get_collections()
            names = [c.name for c in collections.collections]
            
            if self.collection_name not in names:
                logger.info(f"Creating Qdrant collection '{self.collection_name}' with dimension {vector_size}")
                await self.client.create_collection(
                    collection_name=self.collection_name,
                    vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
                )
            self._initialized = True
        except Exception as e:
            logger.warning(f"Could not connect to Qdrant at {self.url}: {e}")

    async def get_embedding(self, text: str, api_key: Optional[str] = None) -> List[float]:
        """Generate text embedding using configured embedding model or fallback."""
        model = settings.DEFAULT_EMBEDDING_MODEL
        key = api_key or settings.OPENAI_API_KEY
        try:
            res = await litellm.aembedding(
                model=model,
                input=[text],
                api_key=key if key else None,
            )
            return res.data[0]["embedding"]
        except Exception as e:
            logger.warning(f"Embedding generation failed: {e}. Falling back to zero-vector for offline dev.")
            return [0.0] * 1536

    async def add_documents(self, chunks: List[Dict[str, Any]], api_key: Optional[str] = None) -> List[str]:
        """Store chunked documents with embeddings in Qdrant."""
        if not chunks:
            return []

        await self.ensure_collection()
        points: List[PointStruct] = []
        ids: List[str] = []

        for chunk in chunks:
            text = chunk.get("text", "")
            point_id = str(uuid.uuid4())
            ids.append(point_id)
            vector = await self.get_embedding(text, api_key=api_key)

            points.append(
                PointStruct(
                    id=point_id,
                    vector=vector,
                    payload={
                        "text": text,
                        "metadata": chunk.get("metadata", {}),
                    },
                )
            )

        try:
            await self.client.upsert(
                collection_name=self.collection_name,
                points=points,
            )
            logger.info(f"Successfully indexed {len(points)} chunks into Qdrant collection '{self.collection_name}'")
        except Exception as e:
            logger.error(f"Failed to upsert points into Qdrant: {e}")
            raise e

        return ids

    async def similarity_search(self, query: str, top_k: int = 5, api_key: Optional[str] = None) -> List[Dict[str, Any]]:
        """Search similar document chunks in Qdrant."""
        await self.ensure_collection()
        query_vector = await self.get_embedding(query, api_key=api_key)

        try:
            results = await self.client.search(
                collection_name=self.collection_name,
                query_vector=query_vector,
                limit=top_k,
                with_payload=True,
            )

            docs = []
            for r in results:
                payload = r.payload or {}
                docs.append({
                    "id": str(r.id),
                    "score": r.score,
                    "content": payload.get("text", ""),
                    "metadata": payload.get("metadata", {}),
                })
            return docs
        except Exception as e:
            logger.warning(f"Qdrant similarity search failed or collection offline: {e}")
            return []
