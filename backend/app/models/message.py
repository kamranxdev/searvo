from enum import Enum
from typing import List, Dict, Any, Optional
from datetime import datetime
from pydantic import BaseModel, Field
from app.models.search import SourceItem, ImageItem, VideoItem, SearchStep

class MessageGenerationState(str, Enum):
    IDLE = "idle"
    SEARCHING = "searching"
    READING = "reading"
    THINKING = "thinking"
    STREAMING = "streaming"
    COMPLETED = "completed"
    FAILED = "failed"

class ToolWidgetData(BaseModel):
    id: str
    toolId: str
    data: Dict[str, Any]
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "toolId": self.toolId,
            "data": self.data,
            "timestamp": self.timestamp.isoformat(),
        }

class AttachmentMetadata(BaseModel):
    id: str
    name: str
    path: str = ""
    type: str
    size: int = 0
    uploadedAt: datetime = Field(default_factory=datetime.utcnow)
    extractedText: Optional[str] = None

class MessageData(BaseModel):
    query: str
    answer: str = ""
    relatedQuestions: List[str] = Field(default_factory=list)
    sources: List[SourceItem] = Field(default_factory=list)
    images: List[str] = Field(default_factory=list)
    imageItems: List[ImageItem] = Field(default_factory=list)
    videos: List[VideoItem] = Field(default_factory=list)
    generationState: MessageGenerationState = MessageGenerationState.COMPLETED
    isFallback: bool = False
    attachments: List[AttachmentMetadata] = Field(default_factory=list)
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    errorMessage: Optional[str] = None
    steps: List[SearchStep] = Field(default_factory=list)
    toolWidgets: List[ToolWidgetData] = Field(default_factory=list)
    confidenceScore: Optional[int] = None
    confidenceLevel: Optional[str] = None

    def to_dict(self):
        return {
            "query": self.query,
            "answer": self.answer,
            "relatedQuestions": self.relatedQuestions,
            "sources": [s.to_dict() for s in self.sources],
            "images": self.images,
            "imageItems": [i.model_dump() for i in self.imageItems],
            "videos": [v.model_dump() for v in self.videos],
            "generationState": self.generationState.value,
            "isFallback": self.isFallback,
            "attachments": [a.model_dump() for a in self.attachments],
            "timestamp": self.timestamp.isoformat(),
            "errorMessage": self.errorMessage,
            "steps": [s.to_dict() for s in self.steps],
            "toolWidgets": [w.to_dict() for w in self.toolWidgets],
            "confidenceScore": self.confidenceScore,
            "confidenceLevel": self.confidenceLevel,
        }
