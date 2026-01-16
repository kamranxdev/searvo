import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/search/domain/entities/search_step.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';
import '../query_processing/prompt_engineer.dart';
import 'package:searvo/features/search/tools/search_tools.dart';

/// Advanced Agentic Orchestrator implementing ReAct (Reasoning + Acting) loop
class AgentOrchestrator {
  final LLMProviderManager _llmManager;
  final PromptEngineer _promptEngineer;
  final List<SearchTool> _tools;

  AgentOrchestrator({
    required LLMProviderManager llmManager,
    required PromptEngineer promptEngineer,
    required List<SearchTool> tools,
  }) : _llmManager = llmManager,
       _promptEngineer = promptEngineer,
       _tools = tools;

  /// Execute the agentic loop
  Stream<RAGUpdate> executeAgentLoop(String query) async* {
    final steps = <SearchStep>[];
    final uuid = const Uuid();
    final maxTurns = 3;
    final contextBuffer = StringBuffer();

    // Initial step
    final planningStep = _createStep(steps, uuid, "Planning strategy");
    yield RAGUpdate(
      status: RAGStatus.planning,
      message: 'Agent is thinking...',
      steps: List.from(steps),
    );

    // Prepare tools description
    final toolDescriptions = _tools
        .map((t) => '- ${t.name} (id: "${t.id}"): ${t.description}')
        .join('\n');

    for (int turn = 1; turn <= maxTurns; turn++) {
      print('🔄 Agent Turn $turn/$maxTurns');

      // 1. THOUGHT: Ask LLM what to do
      final systemPrompt = _promptEngineer.createAgentPrompt(
        query,
        toolDescriptions,
      );

      // Append context from previous turns
      String fullPrompt = systemPrompt;
      if (contextBuffer.isNotEmpty) {
        fullPrompt += "\n\nPREVIOUS ACTIONS & RESULTS:\n$contextBuffer";
      }

      // We explicitly ask for JSON mode if supported, or just rely on prompt engineering
      // TODO: Force JSON mode in LLMManager if possible

      String response = "";
      try {
        response = await _llmManager.generateResponse(fullPrompt);
        // Clean markdown code blocks if present (```json ... ```)
        response = _cleanJson(response);
      } catch (e) {
        yield RAGUpdate(
          status: RAGStatus.failed,
          message: "Agent failed to think: $e",
        );
        return;
      }

      // 2. PARSE PLAN
      Map<String, dynamic> plan;
      try {
        plan = jsonDecode(response);
      } catch (e) {
        print('❌ Failed to parse JSON plan: $e\nResponse: $response');
        // Fallback or retry logic could go here
        // For now, treat as final answer if it looks like text
        plan = {"action": "final_answer", "answer": response};
      }

      final thought = plan['thought'] as String?;
      final actions = plan['actions'] as List?; // Support batch actions
      final singleAction =
          plan['action'] as String?; // Support legacy single action

      if (thought != null) {
        _updateStep(
          steps,
          planningStep.id,
          status: SearchStepStatus.completed,
          description: thought,
        );

        // Start new step for this turn
        yield RAGUpdate(status: RAGStatus.thinking, steps: List.from(steps));
      }

      // 3. ACT: Execute tools or Finish
      if (singleAction == 'final_answer' ||
          (actions == null && singleAction == null)) {
        // final answer = plan['answer'] as String? ?? response;

        // Check if we can stream the answer (re-generating it if the model returned it directly in JSON)
        // Ideally, we want the LLM to write the final answer naturally.
        // If the 'answer' is short/already there, we just yield it.
        // But for "Pro" mode, we might want to re-stream it if it was a summary.
        // For now, let's assume we just yield the result as completed,
        // BUT if the design requires streaming, we might need a separate call.

        // Let's optimize: If 'answer' is from JSON, it's already generated.
        // To really Stream, we should have asked the Agent to "Stop and allow simple generation"
        // or we manually generate the final response using the context.

        // Proposed improved flow:
        // If final_answer, we generate a FRESH streaming response using the gathered context.

        yield RAGUpdate(
          status: RAGStatus.thinking,
          message: "Generating final answer...",
          steps: List.from(steps),
        );

        final finalSystemPrompt =
            "You are a helpful AI assistant. Answer the user's question based on the following information gathered from the web.";
        final finalUserPrompt =
            "Question: $query\n\nContext:\n$contextBuffer\n\nPlease provide a comprehensive answer.";

        final StringBuffer fullAnswer = StringBuffer();
        await for (final token in _llmManager.generateResponseStream(
          "$finalSystemPrompt\n\n$finalUserPrompt",
        )) {
          fullAnswer.write(token);
          yield RAGUpdate(
            status: RAGStatus.streaming,
            token: token,
            steps: List.from(steps),
          );
        }

        yield RAGUpdate(
          status: RAGStatus.completed,
          finalResult: MessageData(
            query: query,
            answer: fullAnswer.toString(),
            steps: steps,
            isFallback: false,
          ),
          steps: List.from(steps),
        );
        return;
      }

      // Collect all actions to run in parallel
      final actionsToRun = <Map<String, dynamic>>[];
      if (actions != null) {
        for (var a in actions) actionsToRun.add(a as Map<String, dynamic>);
      } else if (singleAction != null && singleAction != 'final_answer') {
        actionsToRun.add({
          "tool": singleAction,
          "input": plan['input'],
          "reason": plan['reason'] ?? "Required by plan",
        });
      }

      // Execute Tools
      if (actionsToRun.isNotEmpty) {
        final executionStep = _createStep(
          steps,
          uuid,
          "Executing ${actionsToRun.length} actions",
        );
        yield RAGUpdate(status: RAGStatus.searching, steps: List.from(steps));

        final futures = actionsToRun.map((action) async {
          final toolId = action['tool'];
          final toolInput = action['input'];
          final tool = _tools.firstWhere(
            (t) => t.id == toolId,
            orElse: () => throw Exception("Tool $toolId not found"),
          );

          print('🛠️ Running tool: ${tool.name} with input: $toolInput');
          try {
            final result = await tool.execute(toolInput);
            return {
              "tool": toolId,
              "input": toolInput,
              "status": result.success ? "success" : "failure",
              "output": result.success
                  ? result.data.toString()
                  : result.errorMessage,
            };
          } catch (e) {
            return {"tool": toolId, "error": e.toString()};
          }
        });

        final results = await Future.wait(futures);

        // 4. OBSERVE: Add results to context
        contextBuffer.writeln("--- Turn $turn Results ---");
        for (var r in results) {
          contextBuffer.writeln("Tool: ${r['tool']}");
          contextBuffer.writeln("Input: ${r['input']}");
          contextBuffer.writeln("Output: ${r['output']}");
          contextBuffer.writeln("---");
        }

        _updateStep(
          steps,
          executionStep.id,
          status: SearchStepStatus.completed,
          description: "Executed ${results.length} tools",
        );

        yield RAGUpdate(status: RAGStatus.thinking, steps: List.from(steps));
      }
    }

    // If max turns reached, generate final answer based on what we have
    final finalPrompt =
        "We have run out of steps. Based on the information gathered so far:\n$contextBuffer\n\nPlease answer the user's question: $query";
    final finalAnswer = await _llmManager.generateResponse(finalPrompt);

    yield RAGUpdate(
      status: RAGStatus.completed,
      finalResult: MessageData(query: query, answer: finalAnswer, steps: steps),
      steps: List.from(steps),
    );
  }

  SearchStep _createStep(List<SearchStep> steps, Uuid uuid, String title) {
    final step = SearchStep(
      id: uuid.v4(),
      title: title,
      status: SearchStepStatus.inProgress,
    );
    steps.add(step);
    return step;
  }

  void _updateStep(
    List<SearchStep> steps,
    String id, {
    SearchStepStatus? status,
    String? description,
  }) {
    final index = steps.indexWhere((s) => s.id == id);
    if (index != -1) {
      steps[index] = steps[index].copyWith(
        status: status,
        description: description,
      );
    }
  }

  String _cleanJson(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start != -1 && end != -1) {
      return response.substring(start, end + 1);
    }
    return response;
  }
}
