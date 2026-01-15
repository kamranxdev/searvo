import 'dart:convert';

import '../models/orchestrator_plan.dart';
import 'tool_registry.dart';
import '../../../llm/services/providers/llm_provider_manager.dart';

class IntentOrchestrator {
  final ToolRegistry _toolRegistry;
  final LLMProviderManager _llmManager;

  IntentOrchestrator({
    required ToolRegistry toolRegistry,
    LLMProviderManager? llmManager,
  }) : _toolRegistry = toolRegistry,
       _llmManager = llmManager ?? LLMProviderManager();

  /// Generates a plan for the user query using available tools.
  Future<OrchestratorPlan> plan(String userQuery) async {
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
1. Analyze the user's intent.
2. Select one or more tools to execute in sequence or parallel.
3. If the user wants to search, use 'web_search'.
4. If the user asks for an image, use 'image_generator'.
5. If the request requires multiple steps, list them in order.
6. Provide a brief reasoning for your plan.

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

    final userPrompt = "User Query: $userQuery";

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
