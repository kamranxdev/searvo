import re
from typing import List, Dict, Any, Tuple
from app.models.search import SourceItem

class ConfidenceScorer:
    """
    Algorithmic response quality evaluator that calculates confidence metrics
    based on citation density, source count, and response formulation without LLM calls.
    """

    HEDGING_PATTERNS = [
        r"\b(might|maybe|possibly|perhaps|it seems|could be|unclear|not certain|allegedly)\b",
        r"\b(i think|i believe|it appears|hard to say)\b",
    ]

    @classmethod
    def calculate_score(cls, answer: str, sources: List[SourceItem]) -> Tuple[int, str]:
        if not answer.strip():
            return 0, "Low"

        # 1. Citation Metrics (matches [1], [2], etc.)
        citations = re.findall(r"\[(\d+)\]", answer)
        citation_count = len(citations)
        words = len(answer.split())
        density = (citation_count / words * 100) if words > 0 else 0.0

        citation_score = 0.0
        if 1.5 <= density <= 8.0:
            citation_score = 1.0
        elif 0.5 <= density < 1.5 or 8.0 < density <= 12.0:
            citation_score = 0.75
        elif density > 0:
            citation_score = 0.5
        else:
            citation_score = 0.3 if sources else 0.5

        # 2. Source Quality Metrics
        source_score = 0.0
        if len(sources) >= 5:
            source_score = 1.0
        elif len(sources) >= 2:
            source_score = 0.8
        elif len(sources) == 1:
            source_score = 0.6
        else:
            source_score = 0.4

        # 3. Hedging vs Factual language
        lower_ans = answer.lower()
        hedging_matches = sum(len(re.findall(p, lower_ans)) for p in cls.HEDGING_PATTERNS)
        hedging_penalty = min(hedging_matches * 0.05, 0.3)
        response_score = max(1.0 - hedging_penalty, 0.4)

        # Final weighted score
        final_fraction = (citation_score * 0.4) + (source_score * 0.35) + (response_score * 0.25)
        score = int(round(final_fraction * 100))
        score = max(min(score, 99), 30)

        if score >= 85:
            level = "High"
        elif score >= 70:
            level = "Good"
        elif score >= 50:
            level = "Moderate"
        else:
            level = "Low"

        return score, level

class IntentClassifier:
    """Fast regex & heuristic intent classifier."""

    @classmethod
    def classify(cls, query: str) -> str:
        q = query.strip().lower()

        if re.search(r"\b(weather|temperature|forecast|rain|snow|humidity)\b", q):
            return "weather"
        if re.search(r"\b(stock|shares|nasdaq|dow|nyse|ticker)\b", q) or re.search(r"\b[A-Z]{2,5}\b", query):
            return "stock"
        if re.search(r"\b(crypto|bitcoin|btc|eth|ethereum|solana|doge)\b", q):
            return "crypto"
        if re.search(r"\b(define|meaning of|definition|synonym|phonetic)\b", q):
            return "dictionary"
        if re.search(r"\b(convert|exchange rate|how much is \d+)\b", q) and any(c in q for c in ["usd", "eur", "gbp", "inr", "yen", "dollar"]):
            return "currency"
        if re.search(r"\b(directions|navigate|route to|how far is|distance to)\b", q):
            return "navigation"
        if re.search(r"\b(calculate|sqrt|\+|\-|\*|\/|\^|eval)\b", q) and any(char.isdigit() for char in q):
            return "calculator"
        if re.search(r"\b(holiday|vacation|bank holiday)\b", q):
            return "holiday"
        if re.search(r"\b(time in|what time is it in|timezone)\b", q):
            return "time"
        if re.search(r"\b(paper|arxiv|abstract|citation|pubmed)\b", q):
            return "scholar"
        if re.search(r"\b(youtube\.com|youtu\.be)\b", q):
            return "youtube"
        if re.search(r"\b(how to|guide|tutorial|step by step)\b", q):
            return "how_to"
        if re.search(r"\b(vs|versus|compare|difference between)\b", q):
            return "comparison"

        return "general_search"
