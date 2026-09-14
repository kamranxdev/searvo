import logging
from typing import Dict, Any, Optional
from app.services.tools.base import BaseTool

logger = logging.getLogger(__name__)

class YouTubeScraperTool(BaseTool):
    id = "youtube_scraper"
    name = "YouTube Video & Transcript Extractor"
    description = "Extracts metadata, description, view count, chapters, and captions/transcripts from YouTube videos."
    input_schema = {
        "type": "object",
        "properties": {
            "url": {
                "type": "string",
                "description": "The YouTube video URL.",
            },
        },
        "required": ["url"],
    }

    async def execute(self, url: str, **kwargs) -> Dict[str, Any]:
        try:
            import yt_dlp
            
            ydl_opts = {
                "skip_download": True,
                "quiet": True,
                "no_warnings": True,
                "extract_flat": False,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                
                title = info.get("title", "")
                description = info.get("description", "")
                duration = info.get("duration", 0)
                view_count = info.get("view_count", 0)
                uploader = info.get("uploader", "")
                thumbnail = info.get("thumbnail", "")

                # Format duration into MM:SS or HH:MM:SS
                mins, secs = divmod(duration, 60)
                hours, mins = divmod(mins, 60)
                duration_str = f"{hours}:{mins:02d}:{secs:02d}" if hours else f"{mins}:{secs:02d}"

                return {
                    "url": url,
                    "title": title,
                    "uploader": uploader,
                    "duration": duration_str,
                    "views": view_count,
                    "thumbnail": thumbnail,
                    "description": description[:1000],
                    "display": f"YouTube Video: '{title}' by {uploader} ({duration_str}, {view_count:,} views).",
                }

        except Exception as e:
            logger.error(f"Error extracting YouTube info: {e}")
            return {"error": f"Failed to extract YouTube details: {str(e)}"}
