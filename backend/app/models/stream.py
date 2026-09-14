from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field
from app.models.search import SearchStep, VideoItem
from app.models.message import MessageData

class RAGStatus(str, Enum):
    PLANNING = "planning"
    SEARCHING = "searching"
    SCRAPING = "scraping"
    RANKING = "ranking"
    FUSION = "fusion"
    THINKING = "thinking"
    STREAMING = "streaming"
    COMPLETED = "completed"
    FAILED = "failed"

class RAGUpdate(BaseModel):
    status: RAGStatus
    message: Optional[str] = None
    token: Optional[str] = None
    images: Optional[List[str]] = None
    videos: Optional[List[VideoItem]] = None
    finalResult: Optional[MessageData] = None
    steps: Optional[List[SearchStep]] = None
    generatedTitle: Optional[str] = None

    def to_sse_dict(self):
        data = {
            "status": self.status.value,
            "message": self.message,
            "token": self.token,
            "images": self.images,
            "videos": [v.model_dump() for v in self.videos] if self.videos else None,
            "steps": [s.to_dict() for s in self.steps] if self.steps else None,
            "generatedTitle": self.generatedTitle,
        }
        if self.finalResult:
            data["finalResult"] = self.finalResult.to_dict()
        return {k: v for k, v in data.items() if v is not None}
