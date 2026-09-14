import time
import uuid
import logging
from typing import Dict, Any, List, Tuple
from app.models.search import SearchStep, SearchStepStatus, SourceItem, VideoItem, ImageItem
from app.models.message import ToolWidgetData
from app.services.tools.registry import ToolRegistry

logger = logging.getLogger(__name__)

class ExecutionResult:
    def __init__(self):
        self.steps: List[SearchStep] = []
        self.sources: List[SourceItem] = []
        self.images: List[str] = []
        self.image_items: List[ImageItem] = []
        self.videos: List[VideoItem] = []
        self.tool_widgets: List[ToolWidgetData] = []
        self.context_texts: List[str] = []

class AgentExecutor:
    def __init__(self, tool_registry: ToolRegistry):
        self.registry = tool_registry

    async def execute_plan(self, plan: Dict[str, Any]) -> ExecutionResult:
        result = ExecutionResult()
        plan_steps = plan.get("steps", [])

        # Initialize steps list
        for s in plan_steps:
            step_id = str(uuid.uuid4())
            result.steps.append(
                SearchStep(
                    id=step_id,
                    title=s.get("description", "Processing step"),
                    status=SearchStepStatus.PENDING,
                )
            )

        # Execute each step
        for idx, step_plan in enumerate(plan_steps):
            tool_id = step_plan.get("toolId", "")
            tool_input = step_plan.get("input", {})
            step_model = result.steps[idx]

            step_model.status = SearchStepStatus.IN_PROGRESS
            start_time = time.time()

            tool = self.registry.get_tool(tool_id)
            if not tool:
                logger.warning(f"Tool {tool_id} not found in registry")
                step_model.status = SearchStepStatus.FAILED
                step_model.description = f"Tool {tool_id} not available"
                continue

            try:
                tool_output = await tool.execute(**tool_input)
                duration_ms = int((time.time() - start_time) * 1000)
                step_model.duration = duration_ms
                step_model.status = SearchStepStatus.COMPLETED

                # 1. Check for interactive widget data (Weather, Stock, Crypto, Dictionary)
                widget_tools = ["weather", "stock_price", "crypto_price", "dictionary", "map"]
                if tool_id in widget_tools and isinstance(tool_output, dict) and "error" not in tool_output:
                    widget = ToolWidgetData(
                        id=str(uuid.uuid4()),
                        toolId=tool_id,
                        data=tool_output,
                    )
                    result.tool_widgets.append(widget)

                # 2. Extract sources
                if isinstance(tool_output, dict):
                    if "sources" in tool_output and isinstance(tool_output["sources"], list):
                        for src in tool_output["sources"]:
                            result.sources.append(
                                SourceItem(
                                    title=src.get("title", ""),
                                    url=src.get("url", ""),
                                    description=src.get("description", ""),
                                    thumbnail=src.get("thumbnail", ""),
                                    domain=src.get("domain", ""),
                                    source=src.get("source", "web"),
                                    publishedDate=src.get("publishedDate"),
                                )
                            )

                    # 3. Extract images & videos
                    if "images" in tool_output and isinstance(tool_output["images"], list):
                        result.images.extend(tool_output["images"])
                    if "videos" in tool_output and isinstance(tool_output["videos"], list):
                        for v in tool_output["videos"]:
                            result.videos.append(VideoItem(**v))

                    # 4. Extract context text for synthesis
                    if "display" in tool_output:
                        result.context_texts.append(tool_output["display"])
                    elif "content" in tool_output:
                        result.context_texts.append(tool_output["content"])

            except Exception as e:
                logger.error(f"Error executing tool {tool_id}: {e}")
                step_model.status = SearchStepStatus.FAILED
                step_model.description = str(e)

        return result
