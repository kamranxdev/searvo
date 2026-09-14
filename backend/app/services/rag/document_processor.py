import io
import logging
from typing import List, Dict, Any, Tuple
from pypdf import PdfReader
import docx

logger = logging.getLogger(__name__)

class DocumentProcessor:
    @staticmethod
    def extract_text(file_bytes: bytes, filename: str) -> str:
        """Extract plain text from uploaded file based on its extension."""
        name_lower = filename.lower()

        if name_lower.endswith(".pdf"):
            reader = PdfReader(io.BytesIO(file_bytes))
            text_parts = []
            for i, page in enumerate(reader.pages):
                page_text = page.extract_text()
                if page_text:
                    text_parts.append(page_text)
            return "\n\n".join(text_parts)

        elif name_lower.endswith(".docx") or name_lower.endswith(".doc"):
            doc = docx.Document(io.BytesIO(file_bytes))
            return "\n".join([p.text for p in doc.paragraphs if p.text])

        elif name_lower.endswith(".txt") or name_lower.endswith(".md"):
            return file_bytes.decode("utf-8", errors="replace")

        else:
            # Fallback text decoding
            try:
                return file_bytes.decode("utf-8", errors="replace")
            except Exception as e:
                logger.error(f"Cannot parse file {filename}: {e}")
                return ""

class TextChunker:
    @staticmethod
    def chunk_text(
        text: str,
        chunk_size: int = 1000,
        chunk_overlap: int = 200,
        metadata: Dict[str, Any] = None,
    ) -> List[Dict[str, Any]]:
        """Split text into overlapping chunks with metadata."""
        if not text:
            return []

        meta = metadata or {}
        chunks = []
        start = 0
        text_length = len(text)

        while start < text_length:
            end = min(start + chunk_size, text_length)
            chunk_content = text[start:end].strip()

            if chunk_content:
                chunks.append({
                    "text": chunk_content,
                    "metadata": {
                        **meta,
                        "start_char": start,
                        "end_char": end,
                    },
                })

            if end == text_length:
                break
            start += chunk_size - chunk_overlap

        return chunks
