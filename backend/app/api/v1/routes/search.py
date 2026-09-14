import json
import logging
from typing import AsyncGenerator, List
from fastapi import APIRouter, Request
from sse_starlette.sse import EventSourceResponse

from app.models.requests import SearchStreamRequest, RawSearchRequest
from app.models.stream import RAGUpdate, RAGStatus
from app.models.message import MessageData, MessageGenerationState
from app.services.llm.provider import LLMProvider
from app.services.tools.registry import ToolRegistry
from app.services.agent.orchestrator import AgentOrchestrator
from app.services.agent.executor import AgentExecutor
from app.services.agent.synthesizer import ResponseSynthesizer
from app.services.tools.web_search import WebSearchTool
from app.services.rag.verification import ConfidenceScorer

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/search", tags=["Search"])

# Shared tool registry
tool_registry = ToolRegistry()

@router.post("/stream")
async def stream_search(request: Request, body: SearchStreamRequest):
    """
    Streaming SSE endpoint executing the complete autonomous agent RAG search pipeline.
    Yields real-time step progress, tool results, tokens, and final MessageData.
    """
    llm = LLMProvider(api_keys=body.api_keys)
    orchestrator = AgentOrchestrator(tool_registry=tool_registry, llm_provider=llm)
    executor = AgentExecutor(tool_registry=tool_registry)
    synthesizer = ResponseSynthesizer(llm_provider=llm)

    async def event_generator() -> AsyncGenerator[str, None]:
        query = body.query.strip()
        accumulated_answer: List[str] = []

        try:
            # 1. Planning Step
            yield json.dumps(
                RAGUpdate(
                    status=RAGStatus.PLANNING,
                    message="Analyzing request and selecting tools...",
                ).to_sse_dict()
            )

            plan = await orchestrator.plan(
                query=query,
                attachments=body.attachments,
                previous_messages=body.previous_messages,
                model=body.reasoning_model,
            )

            # 2. Searching & Executing Tools
            yield json.dumps(
                RAGUpdate(
                    status=RAGStatus.SEARCHING,
                    message=f"Plan: {plan.get('reasoning', 'Executing tools')}",
                ).to_sse_dict()
            )

            exec_result = await executor.execute_plan(plan)

            # 3. Thinking & Preparing Synthesis
            yield json.dumps(
                RAGUpdate(
                    status=RAGStatus.THINKING,
                    message=f"Processing {len(exec_result.sources)} sources and {len(exec_result.tool_widgets)} widgets...",
                    steps=exec_result.steps,
                    images=exec_result.images[:10],
                    videos=exec_result.videos[:5],
                ).to_sse_dict()
            )

            # 4. Streaming Synthesis Tokens
            async for token in synthesizer.stream_synthesis(
                query=query,
                execution_result=exec_result,
                previous_messages=body.previous_messages,
                model=body.generation_model,
            ):
                accumulated_answer.append(token)
                yield json.dumps(
                    RAGUpdate(
                        status=RAGStatus.STREAMING,
                        token=token,
                        steps=exec_result.steps,
                    ).to_sse_dict()
                )

            # 5. Completed Final Result
            full_text = "".join(accumulated_answer)
            conf_score, conf_level = ConfidenceScorer.calculate_score(full_text, exec_result.sources)
            
            final_message = MessageData(
                query=query,
                answer=full_text,
                sources=exec_result.sources,
                images=exec_result.images[:10],
                videos=exec_result.videos[:5],
                steps=exec_result.steps,
                toolWidgets=exec_result.tool_widgets,
                generationState=MessageGenerationState.COMPLETED,
                confidenceScore=conf_score,
                confidenceLevel=conf_level,
            )

            yield json.dumps(
                RAGUpdate(
                    status=RAGStatus.COMPLETED,
                    finalResult=final_message,
                    steps=exec_result.steps,
                ).to_sse_dict()
            )

        except Exception as e:
            logger.error(f"Error in stream_search: {e}", exc_info=True)
            yield json.dumps(
                RAGUpdate(
                    status=RAGStatus.FAILED,
                    message=f"Search failed: {str(e)}",
                ).to_sse_dict()
            )

    return EventSourceResponse(event_generator())

@router.post("/raw")
async def raw_search(body: RawSearchRequest):
    """Direct SearXNG search proxy with custom categories, pagination, and recency."""
    tool = WebSearchTool()
    return await tool.execute(
        query=body.query,
        maxResults=20,
        category=body.category,
    )

@router.get("/suggestions")
async def get_suggestions(q: str):
    """Fetch search autocomplete suggestions from SearXNG autocompleter."""
    if not q or len(q.strip()) < 1:
        return []
    
    query = q.strip()
    import httpx
    from app.config import settings
    url = f"{settings.SEARXNG_URL.rstrip('/')}/autocompleter"
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url, params={"q": query})
            if resp.status_code == 200:
                data = resp.json()
                if isinstance(data, list) and len(data) > 1 and isinstance(data[1], list):
                    return data[1]
    except Exception as e:
        logger.warning(f"Failed to fetch suggestions from SearXNG: {e}")
    return []
