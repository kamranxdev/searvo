/// Base class for all tools available to the Orchestrator.
abstract class AgentTool {
  final String id;
  final String name;
  final String description;
  final String version;

  const AgentTool({
    required this.id,
    required this.name,
    required this.description,
    this.version = '1.0.0',
  });

  /// Returns true if the tool is currently available/enabled.
  /// This can check settings, platform availability, etc.
  Future<bool> get isAvailable;

  /// The schema of inputs this tool accepts (for LLM to understand).
  Map<String, dynamic> get inputSchema;

  /// Executes the tool with the given input.
  Future<dynamic> execute(Map<String, dynamic> input);
}
