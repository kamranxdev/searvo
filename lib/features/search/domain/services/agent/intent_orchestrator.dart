import 'dart:convert';

import '../../entities/agent/orchestrator_plan.dart';
import 'tool_registry.dart';
import '../../../../llm/services/providers/llm_provider_manager.dart';

class IntentOrchestrator {
  final ToolRegistry _toolRegistry;
  final LLMProviderManager _llmManager;

  IntentOrchestrator({
    required ToolRegistry toolRegistry,
    LLMProviderManager? llmManager,
  }) : _toolRegistry = toolRegistry,
       _llmManager = llmManager ?? LLMProviderManager();

  /// Generates a plan for the user query using available tools.
  Future<OrchestratorPlan> plan(
    String userQuery, {
    List<dynamic> previousMessages = const [],
  }) async {
    final availableTools = await _toolRegistry.getAvailableTools();

    // Create tool descriptions for the prompt
    final toolsJson = availableTools
        .map(
          (t) => {
            'id': t.id,
            'name': t.name,
            'description': t.description,
            'parameters': t.inputSchema,
          },
        )
        .toList();

    final systemPrompt =
        '''
You are an intelligent orchestrator for the Searvo AI app. 
Your goal is to analyze the User Query and select the best tools to fulfill the request.

Available Tools:
${jsonEncode(toolsJson)}

Instructions:
1. **Analyze Intent**: First, determine if the user wants to perform a specific action (e.g. check weather, get directions, see stock price).
2. **Select Tools**:
   - If the intent matches a specific tool (e.g. "Directions to..." -> 'map', "Weather in..." -> 'weather'), **YOU MUST** select that tool.
   - For specific tool actions, 'web_search' is OPTIONAL. Only include it if you need extra context the tool might not provide.
   - For general informational queries (e.g. "Who is...", "News about...", "Explain quantum physics"), **YOU MUST** include 'web_search'.
3. **Sequence**: If multiple steps are needed, list them in order.
4. **Reasoning**: Provide brief reasoning.

Few-Shot Examples:
- "Directions to Tokyo" -> [{"toolId": "map", "input": {"to": "Tokyo"}}] (No web_search needed)
- "Weather in Paris" -> [{"toolId": "weather", "input": {"location": "Paris"}}]
- "Who is the CEO of Google?" -> [{"toolId": "web_search", "input": {"query": "current CEO of Google"}}]
- "Show me a map of Central Park and tell me its history" -> [{"toolId": "map", "input": {"to": "Central Park"}}, {"toolId": "web_search", "input": {"query": "history of Central Park"}}]

Response Format:
You must return ONLY a valid JSON object matching this structure:
{
  "reasoning": "Explanation of why these tools were chosen",
  "steps": [
    {
      "toolId": "tool_id",
      "input": { ... parameters ... },
      "description": "Brief description of this step"
    }
  ]
}
Do not include markdown formatting (```json). Just the raw JSON string.
''';

    // Construct conversation context
    final StringBuffer contextBuffer = StringBuffer();
    if (previousMessages.isNotEmpty) {
      contextBuffer.writeln("Conversation History:");
      for (final msg in previousMessages) {
        // Assuming msg is MessageData, but using dynamic to avoid circular imports if needed headers aren't ready
        // Better to import MessageData if possible.
        // For now, let's treat it as flexible.
        try {
          contextBuffer.writeln("User: ${msg.query}");
          contextBuffer.writeln("Assistant: ${msg.answer}");
        } catch (_) {}
      }
      contextBuffer.writeln("\nNow consider the new User Query:");
    }

    final userPrompt = "${contextBuffer.toString()}User Query: $userQuery";

    // Combine for a simple generation call if we don't have separate system prompt support in manager
    final fullPrompt = "$systemPrompt\n\n$userPrompt";

    try {
      final response = await _llmManager.generateResponse(fullPrompt);

      // Clean up response if it has markdown
      var cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }

      final Map<String, dynamic> json = jsonDecode(cleanResponse);
      return OrchestratorPlan.fromJson(json);
    } catch (e) {
      print('Orchestration failed: $e');
      // Fallback: Default to web search
      return OrchestratorPlan(
        reasoning:
            "Failed to parse plan or execute LLM. Defaulting to Web Search.",
        steps: [
          OrchestratorStep(
            toolId: 'web_search',
            input: {'query': userQuery},
            description: "Search web for '$userQuery'",
          ),
        ],
      );
    }
  }
}
