import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/services/orchestration/agent_orchestrator.dart';
import 'package:searvo/features/search/rag/services/query_processing/prompt_engineer.dart';
import 'package:searvo/features/search/tools/search_tools.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';

// Generate Mocks
@GenerateMocks([LLMProviderManager, PromptEngineer, SearchTool])
import 'agent_orchestrator_test.mocks.dart';

void main() {
  late AgentOrchestrator orchestrator;
  late MockLLMProviderManager mockLLMManager;
  late MockPromptEngineer mockPromptEngineer;
  late MockSearchTool mockTool;

  setUp(() {
    mockLLMManager = MockLLMProviderManager();
    mockPromptEngineer = MockPromptEngineer();
    mockTool = MockSearchTool();

    when(mockTool.name).thenReturn('Test Tool');
    when(mockTool.id).thenReturn('test_tool');
    when(mockTool.description).thenReturn('A test tool');

    orchestrator = AgentOrchestrator(
      llmManager: mockLLMManager,
      promptEngineer: mockPromptEngineer,
      tools: [mockTool],
    );
  });

  test('AgentOrchestrator should execute tools and stream final answer', () async {
    // Arrange
    final query = "test query";

    // 1. Plan: Agent decides to use the tool
    when(mockPromptEngineer.createAgentPrompt(any, any)).thenReturn("Prompt");
    when(mockLLMManager.generateResponse(any)).thenAnswer(
      (_) async =>
          '{"thought": "Need to test", "tool": "test_tool", "action": "test_tool", "input": "input"}',
    );

    // 2. Tool Execution
    when(
      mockTool.execute(any),
    ).thenAnswer((_) async => ToolResult.success("Tool Output"));

    // 3. Final Answer Phase
    // The agent loop logic will call generateResponse a second time or stream it?
    // Based on my implementation:
    // It loops. Turn 1: tool execution. Turn 2: final answer.

    // Setup second response for Turn 2 -> Final Answer
    // Note: My implementation loops up to 3 times.
    // For the FIRST response, I mocked it above.
    // Wait, generateResponse is called inside the loop.
    // I need to sequence the responses using `answers` logic in mockito or a counter.

    int callCount = 0;
    when(mockLLMManager.generateResponse(any)).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        return '{"thought": "Checking tool", "action": "test_tool", "input": "check"}';
      } else {
        return '{"thought": "Done", "action": "final_answer", "answer": "The Answer"}';
      }
    });

    // Mock streaming for final answer
    when(
      mockLLMManager.generateResponseStream(any),
    ).thenAnswer((_) => Stream.fromIterable(['The ', 'Final ', 'Answer']));

    // Act
    final stream = orchestrator.executeAgentLoop(query);
    final events = await stream.toList();

    // Assert
    // Check if we visited statuses
    expect(
      events.any((e) => e.status == RAGStatus.searching),
      true,
    ); // Executing tool
    expect(
      events.any((e) => e.status == RAGStatus.streaming),
      true,
    ); // Streaming final answer
    expect(
      events.any((e) => e.finalResult?.answer == "The Final Answer"),
      true,
    );
  });
}
