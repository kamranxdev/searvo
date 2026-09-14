import re
import asyncio
import logging
from typing import AsyncGenerator, List, Dict, Any, Optional
from app.services.llm.provider import LLMProvider
from app.services.agent.executor import ExecutionResult

logger = logging.getLogger(__name__)

class ResponseSynthesizer:
    def __init__(self, llm_provider: LLMProvider):
        self.llm = llm_provider

    async def stream_synthesis(
        self,
        query: str,
        execution_result: ExecutionResult,
        previous_messages: Optional[List[Dict[str, Any]]] = None,
        model: Optional[str] = None,
    ) -> AsyncGenerator[str, None]:
        """Synthesizes context and sources into a structured, cited answer."""
        context_blocks: List[str] = []

        # 0. Add previous conversation history
        if previous_messages and len(previous_messages) > 0:
            hist = []
            for msg in previous_messages[-3:]:
                q = msg.get("query", "")
                a = msg.get("answer", "")
                if q:
                    hist.append(f"User: {q}")
                if a:
                    hist.append(f"Assistant: {a}")
            if hist:
                context_blocks.append("[Conversation History]:\n" + "\n".join(hist))

        # 1. Add tool output text
        for text in execution_result.context_texts:
            context_blocks.append(f"[Tool Output]: {text}")

        # 2. Add numbered sources
        for idx, src in enumerate(execution_result.sources[:8], start=1):
            snippet = src.description[:400] if src.description else ""
            context_blocks.append(f"[{idx}] {src.title} ({src.domain}):\n{snippet}")

        context_string = "\n\n".join(context_blocks)

        system_prompt = """You are Searvo, an authoritative, comprehensive AI Answer Engine similar to Perplexity.
Your task is to synthesize a direct, insightful, beautifully formatted, and cited answer based on the provided context.

Guidelines:
1. Lead with the Direct Answer: Begin immediately with the core factual answer in the opening paragraph. Bold key entities, dates, or terms. Do not use filler introductions like "Based on the search results" or "According to the context".
2. Precise Inline Citations: Back up every factual claim, statement, and metric with inline numeric citations matching the numbered sources, e.g., [1], [2], [2][3]. Place citations immediately after facts.
3. Structured Formatting: Use clean markdown hierarchy:
   - Direct concise summary paragraph
   - '### Key Facts & Overview' or relevant subheadings with informative bullet points
   - Comparative tables or bulleted analysis where appropriate
4. Direct Tool Outputs: If the context contains a direct tool calculation or figure (e.g. live weather, stock price, crypto, math), present that prominently at the very top.
5. Avoid Fluff: Maintain an objective, authoritative, encyclopedic, yet engaging tone.
"""

        user_prompt = f"""Context:
{context_string if context_string.strip() else 'No external sources retrieved.'}

User Query: {query}

Please provide an insightful and cited answer:"""

        had_tokens = False
        error_encountered = False

        if self.llm.has_available_provider():
            try:
                async for token in self.llm.stream_completion(
                    prompt=user_prompt,
                    system_prompt=system_prompt,
                    model=model,
                ):
                    if "[Error generating response" in token or "Missing credentials" in token:
                        error_encountered = True
                        break
                    had_tokens = True
                    yield token
            except Exception as e:
                logger.warning(f"Error streaming LLM completion: {e}")
                error_encountered = True
        else:
            error_encountered = True

        # If LLM credentials were not provided, failed, or produced no tokens,
        # perform intelligent Perplexity-style RAG synthesis from the retrieved context
        if error_encountered or not had_tokens:
            async for token in self._stream_rag_synthesis(query, execution_result):
                yield token

    async def _stream_rag_synthesis(
        self,
        query: str,
        execution_result: ExecutionResult,
    ) -> AsyncGenerator[str, None]:
        """
        Synthesizes a structured Perplexity-style AI Answer from retrieved sources
        and tool outputs when an external LLM is not configured or fails.
        Streams tokens smoothly to match an AI answer engine experience.
        """
        sections: List[str] = []

        # 1. Lead with direct tool outputs if available (weather, math, crypto, stocks)
        if execution_result.context_texts:
            tool_outputs = "\n\n".join(t.strip() for t in execution_result.context_texts if t.strip())
            if tool_outputs:
                sections.append(f"### Direct Result\n\n{tool_outputs}")

        sources = execution_result.sources
        if not sources and not sections:
            full_text = (
                f"No verified information or sources were found for query: **{query}**.\n\n"
                "Please try rephrasing your search query or check your connection."
            )
            for word in full_text.split(" "):
                yield word + " "
                await asyncio.sleep(0.015)
            return

        if sources:
            stopwords = {
                "who", "what", "where", "when", "why", "how", "is", "are", "was", "were",
                "the", "a", "an", "in", "on", "of", "for", "to", "and", "or", "which",
            }
            query_tokens = [w.lower() for w in re.findall(r"\b[a-zA-Z0-9]+\b", query) if w.lower() not in stopwords]

            scored_sentences = []
            seen_signatures = set()

            for idx, src in enumerate(sources[:8], start=1):
                title = (src.title or "").strip()
                desc = (src.description or "").strip()
                if not desc:
                    continue

                raw_sentences = re.split(r"(?<=[.!?])\s+", desc)
                for s in raw_sentences:
                    s_clean = s.strip()
                    # Clean trailing ellipses and boilerplate
                    s_clean = re.sub(r"\.{3,}$", "", s_clean).strip()
                    s_clean = re.sub(r"^[sS] of\s+", "As of ", s_clean)
                    if len(s_clean) < 25:
                        continue

                    sig = re.sub(r"[^a-zA-Z0-9]", "", s_clean[:50]).lower()
                    if sig in seen_signatures:
                        continue
                    seen_signatures.add(sig)

                    # Score sentence relevance
                    s_lower = s_clean.lower()
                    relevance = 0
                    for token in query_tokens:
                        if token in s_lower:
                            relevance += 3
                    if re.search(r"\b(is|was|served as|appointed as|current|elected as|prime minister|president|capital|leader)\b", s_lower):
                        relevance += 2
                    if idx <= 3:
                        relevance += 2

                    clean_title = title.split(" - ")[0].split(" | ")[0].strip()
                    scored_sentences.append({
                        "text": s_clean,
                        "source_idx": idx,
                        "title": clean_title,
                        "score": relevance,
                    })

            scored_sentences.sort(key=lambda x: x["score"], reverse=True)

            lead_sentences = []
            key_points = []

            for item in scored_sentences:
                if len(lead_sentences) < 2 and item["score"] >= 4:
                    lead_sentences.append(f"{item['text']} [{item['source_idx']}]")
                elif len(key_points) < 5 and item["score"] >= 2:
                    key_points.append(f"- **{item['title']}**: {item['text']} [{item['source_idx']}]")

            if not lead_sentences and scored_sentences:
                item = scored_sentences[0]
                lead_sentences.append(f"{item['text']} [{item['source_idx']}]")
                key_points = [f"- {s['text']} [{s['source_idx']}]" for s in scored_sentences[1:5]]

            if lead_sentences:
                sections.append(" ".join(lead_sentences))

            if key_points:
                sections.append("### Key Facts & Context\n" + "\n".join(key_points))

            # Footer note guiding user to configure API key if desired
            sections.append(
                "> *💡 Synthesized from web sources. For deep generative reasoning and chat follow-ups, "
                "configure your Gemini, OpenAI, Claude, or Ollama key in Settings.*"
            )

        full_output = "\n\n".join(sections)
        # Stream out words smoothly with micro-delay
        words = full_output.split(" ")
        for i, word in enumerate(words):
            yield word + (" " if i < len(words) - 1 else "")
            if i % 3 == 0:
                await asyncio.sleep(0.01)
