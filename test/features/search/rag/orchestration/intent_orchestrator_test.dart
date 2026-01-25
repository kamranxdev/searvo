import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';
import 'package:searvo/features/search/domain/entities/agent/orchestrator_plan.dart';
import 'package:searvo/features/search/domain/services/agent/intent_orchestrator.dart';
import 'package:searvo/features/search/domain/services/agent/tool_registry.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/llm/services/providers/base_llm_provider.dart';
import 'package:langchain/langchain.dart';

// --- Mocks ---

class MockTool extends AgentTool {
  final Map<String, dynamic> _inputSchema;

  MockTool(String id, String name, String description)
    : _inputSchema = const {'type': 'object'},
      super(id: id, name: name, description: description);

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => _inputSchema;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    return {'result': 'executed $id'};
  }
}

class MockLLMProvider implements BaseLLMProvider {
  String responseToReturn;

  MockLLMProvider({this.responseToReturn = '{}'});

  @override
  String get providerName => 'MockProvider';

  @override
  BaseChatModel get model => FakeChatModel(responses: [responseToReturn]);

  @override
  bool get isConfigured => true;

  @override
  void setModel(String model) {}

  @override
  Future<void> initialize() async {}

  @override
  Future<String> generateResponse(String message) async {
    return responseToReturn;
  }

  @override
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    return responseToReturn;
  }

  @override
  Stream<String> generateResponseStream(String message) async* {
    yield responseToReturn;
  }

  @override
  bool get supportsEmbeddings => false;

  @override
  Future<List<double>> generateEmbeddings(String text) async => [];

  @override
  void dispose() {}
}

void main() {
  group('IntentOrchestrator', () {
    late IntentOrchestrator orchestrator;
    late ToolRegistry toolRegistry;
    late MockLLMProvider mockLLM;
    late LLMProviderManager llmManager;

    setUp(() {
      toolRegistry = ToolRegistry();
      toolRegistry.registerTools([
        MockTool('web_search', 'Web Search', 'Search the web'),
        MockTool('map', 'Map', 'Show map'),
        MockTool('weather', 'Weather', 'Show weather'),
      ]);

      mockLLM = MockLLMProvider();

      // We need to register the mock provider to the manager
      llmManager = LLMProviderManager();
      llmManager.dispose(); // clean slate
      llmManager.registerProvider(LLMProviderType.openrouter, mockLLM);
      llmManager.setActiveProvider(LLMProviderType.openrouter);

      orchestrator = IntentOrchestrator(
        toolRegistry: toolRegistry,
        llmManager: llmManager,
      );
    });

    tearDown(() {
      llmManager.dispose();
    });

    test('plan returns valid steps when LLM returns valid JSON', () async {
      mockLLM.responseToReturn = '''
      {
        "reasoning": "User wants weather",
        "steps": [
          {
            "toolId": "weather",
            "input": {"location": "London"},
            "description": "Get weather for London"
          }
        ]
      }
      ''';

      final plan = await orchestrator.plan("Weather in London");

      expect(plan.steps.length, 1);
      expect(plan.steps.first.toolId, 'weather');
      expect(plan.steps.first.input['location'], 'London');
    });

    test('plan defaults to web_search on JSON error', () async {
      mockLLM.responseToReturn = 'Invalid JSON Response';

      final plan = await orchestrator.plan("Random query");

      expect(plan.steps.length, 1);
      expect(plan.steps.first.toolId, 'web_search');
      expect(plan.reasoning, contains('Failed to parse'));
    });

    test('plan handles markdown wrapped JSON', () async {
      mockLLM.responseToReturn = '''
      ```json
      {
        "reasoning": "Wrapped in markdown",
        "steps": [
          {
            "toolId": "map",
            "input": {"to": "Paris"},
            "description": "Show map"
          }
        ]
      }
      ```
      ''';

      final plan = await orchestrator.plan("Map to Paris");

      expect(plan.steps.length, 1);
      expect(plan.steps.first.toolId, 'map');
    });
  });
}
