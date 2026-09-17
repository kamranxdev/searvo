# Searvo Backend Service

A high-performance asynchronous Python FastAPI backend for Searvo, handling autonomous agent orchestration, RAG pipelines, real-time Server-Sent Events (SSE) streaming, web scraping, and vector database management.

## Features

- **Autonomous Agent Orchestration**: Intelligently analyzes user intent to execute specialized tools (web search, weather, stocks, crypto, definitions, calculations, YouTube scraping, Wikipedia, vector search).
- **Streaming RAG Pipeline**: Real-time Server-Sent Events (SSE) delivering intermediate step progress, interactive UI widget payloads, sources, and token-by-token synthesized answers with citations.
- **Privacy-First Web Search**: Native integration with SearXNG, stripping tracking headers and cookies.
- **Document Processing & Vector Search**: Automatic text extraction from PDFs, DOCX, and TXT files, chunking, and embedding storage in Qdrant.
- **Universal Multi-LLM Support**: Works seamlessly with OpenAI, Anthropic, Google Gemini, Ollama, and OpenRouter with support for client-provided API keys (BYOK).

## Quick Start (Local Development)

### 1. Install Dependencies
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure Environment
Copy `.env.example` to `.env` and configure your keys and service URLs:
```bash
cp .env.example .env
```

### 3. Run Server
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation will be available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

## API Reference

### 1. Streaming Search (`POST /api/v1/search/stream`)
Streams real-time agent execution and synthesized response tokens via Server-Sent Events (SSE).

```bash
curl -N -X POST http://localhost:8000/api/v1/search/stream \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the current stock price of Apple?",
    "search_type": "general"
  }'
```

### 2. Raw Search (`POST /api/v1/search/raw`)
Direct proxy to SearXNG with custom category selection and result filtering.

```bash
curl -X POST http://localhost:8000/api/v1/search/raw \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Quantum computing advances",
    "category": "science"
  }'
```

### 3. Document Upload (`POST /api/v1/documents/upload`)
Uploads and indexes documents into the Qdrant vector database for RAG context retrieval.

```bash
curl -X POST http://localhost:8000/api/v1/documents/upload \
  -F "file=@sample.pdf"
```

### 4. Discover Feed (`GET /api/v1/discover?topic=technology`)
Fetches curated news articles with thumbnails.

```bash
curl http://localhost:8000/api/v1/discover?topic=technology
```

### 5. Health Check (`GET /api/v1/health`)
Diagnostic status check verifying connectivity to SearXNG and Qdrant.

```bash
curl http://localhost:8000/api/v1/health
```

---

## 🤝 Contributing to Backend

We warmly welcome contributions to the Searvo Backend! You can:
- Add new autonomous tools to `app/services/tools/` (e.g., Wolfram Alpha, GitHub, Reddit, Finance).
- Enhance RAG retrieval, reranking, and semantic chunking.
- Improve streaming resilience and token synthesis.
- Add support for new local/open models.

See the root **[Contributing Guide](../CONTRIBUTING.md)** and **[Monorepo Architecture Guide](../docs/architecture/monorepo.md)** for development setup and PR guidelines.

