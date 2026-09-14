from enum import IntEnum
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class SearchStepStatus(IntEnum):
    PENDING = 0
    IN_PROGRESS = 1
    COMPLETED = 2
    FAILED = 3

class SearchStep(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    status: SearchStepStatus = SearchStepStatus.PENDING
    duration: int = 0  # Duration in milliseconds
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "status": int(self.status),
            "duration": self.duration,
            "timestamp": self.timestamp.isoformat(),
        }

class SourceItem(BaseModel):
    title: str = ""
    url: str = ""
    description: str = ""
    thumbnail: str = ""
    domain: str = ""
    source: str = "web"
    favicon: Optional[str] = None
    publishedDate: Optional[str] = None

    def to_dict(self):
        return {
            "title": self.title,
            "url": self.url,
            "description": self.description,
            "thumbnail": self.thumbnail,
            "domain": self.domain,
            "source": self.source,
            "favicon": self.favicon,
            "publishedDate": self.publishedDate,
        }

class ImageItem(BaseModel):
    url: str
    title: str = ""
    source: str = ""
    thumbnail: Optional[str] = None
    width: Optional[int] = None
    height: Optional[int] = None

class VideoItem(BaseModel):
    url: str
    title: str = ""
    thumbnail: str = ""
    description: str = ""
    domain: str = ""
    duration: Optional[str] = None
    views: Optional[int] = None
    publishedDate: Optional[str] = None
