from abc import ABC, abstractmethod
from typing import Dict, Any

class BaseTool(ABC):
    id: str
    name: str
    description: str
    input_schema: Dict[str, Any]

    @abstractmethod
    async def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute the tool with provided arguments and return results."""
        pass

    def to_descriptor(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "parameters": self.input_schema,
        }
