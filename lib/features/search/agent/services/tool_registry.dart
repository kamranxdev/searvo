import '../models/agent_tool.dart';

class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  /// Registers a new tool.
  void registerTool(AgentTool tool) {
    _tools[tool.id] = tool;
  }

  /// Registers multiple tools.
  void registerTools(List<AgentTool> tools) {
    for (final tool in tools) {
      registerTool(tool);
    }
  }

  /// Returns a list of all registered tools.
  List<AgentTool> getAllTools() {
    return _tools.values.toList();
  }

  /// Returns a list of currently enabled/available tools.
  Future<List<AgentTool>> getAvailableTools() async {
    final availableTools = <AgentTool>[];
    for (final tool in _tools.values) {
      if (await tool.isAvailable) {
        availableTools.add(tool);
      }
    }
    return availableTools;
  }

  /// Gets a tool by its ID.
  AgentTool? getToolById(String id) {
    return _tools[id];
  }
}
