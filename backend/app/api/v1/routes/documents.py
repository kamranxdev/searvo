import logging
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.services.rag.document_processor import DocumentProcessor, TextChunker
from app.services.rag.vector_store import QdrantStore
from app.models.requests import DocumentQueryRequest

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/documents", tags=["Documents"])
store = QdrantStore()

@router.post("/upload")
async def upload_document(
    file: UploadFile = File(...),
    api_key: Optional[str] = Form(None),
):
    """
    Uploads a document (PDF, DOCX, TXT), extracts text, chunks it,
    and indexes embeddings in Qdrant for RAG.
    """
    filename = file.filename or "uploaded_file"
    try:
        content = await file.read()
        extracted_text = DocumentProcessor.extract_text(content, filename)

        if not extracted_text.strip():
            raise HTTPException(status_code=400, detail="Could not extract text from document.")

        chunks = TextChunker.chunk_text(
            text=extracted_text,
            chunk_size=1000,
            chunk_overlap=200,
            metadata={"filename": filename, "size": len(content)},
        )

        ids = await store.add_documents(chunks, api_key=api_key)

        return {
            "success": True,
            "filename": filename,
            "size": len(content),
            "total_chunks": len(chunks),
            "point_ids": ids,
            "preview": extracted_text[:300] + "...",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to process document {filename}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to process document: {str(e)}")

@router.post("/query")
async def query_documents(body: DocumentQueryRequest):
    """Direct similarity search over uploaded documents."""
    docs = await store.similarity_search(query=body.query, top_k=body.top_k)
    return {
        "query": body.query,
        "count": len(docs),
        "results": docs,
    }
