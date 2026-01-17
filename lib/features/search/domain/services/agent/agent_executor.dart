import '../../entities/message_data.dart';
import '../../entities/message_generation_state.dart';
import '../../entities/source_item.dart';
import '../../entities/video_item.dart';
import '../../entities/search_step.dart';
import '../../entities/tool_widget_data.dart';
import '../../entities/agent/orchestrator_plan.dart';
import 'tool_registry.dart';
import 'package:uuid/uuid.dart';

/// Executes an OrchestratorPlan step-by-step and emits MessageData updates.
class AgentExecutor {
  final ToolRegistry _toolRegistry;
  final Uuid _uuid = Uuid();

  AgentExecutor({required ToolRegistry toolRegistry})
    : _toolRegistry = toolRegistry;

  Stream<MessageData> executePlan(
    String query,
    OrchestratorPlan plan, {
    MessageData? initialData,
  }) async* {
    var currentData =
        initialData ??
        MessageData(
          query: query,
          answer: '',
          generationState: MessageGenerationState.generating,
          steps: [],
        );

    // Initial plan update
    final planSteps = <SearchStep>[];
    for (var i = 0; i < plan.steps.length; i++) {
      planSteps.add(
        SearchStep(
          id: _uuid.v4(),
          title: plan.steps[i].description,
          status: SearchStepStatus.pending,
        ),
      );
    }

    currentData = currentData.copyWith(steps: planSteps);
    yield currentData;

    // Execute steps
    for (var i = 0; i < plan.steps.length; i++) {
      final stepPlan = plan.steps[i];

      // Update step to in-progress
      planSteps[i] = planSteps[i].copyWith(status: SearchStepStatus.inProgress);
      currentData = currentData.copyWith(steps: List.from(planSteps));
      yield currentData;

      final stepStartTime = DateTime.now();

      try {
        final tool = _toolRegistry.getToolById(stepPlan.toolId);
        if (tool == null) {
          throw Exception('Tool ${stepPlan.toolId} not found');
        }

        final result = await tool.execute(stepPlan.input);
        print('AgentExecutor: Tool ${tool.id} returned: $result');

        // Process result based on tool type
        if (tool.id == 'image_generator' &&
            result is Map &&
            result.containsKey('imageUrl')) {
          final newImages = List<String>.from(currentData.images)
            ..add(result['imageUrl']);
          currentData = currentData.copyWith(images: newImages);
        } else if (tool.id == 'web_search' && result is Map) {
          // Handle direct answer if present
          if (result.containsKey('answer')) {
            currentData = currentData.copyWith(answer: result['answer']);
          }

          // Handle sources from 'sources' or 'documents' key
          var sourcesList = [];
          if (result['sources'] != null) {
            sourcesList = result['sources'] as List;
          } else if (result['documents'] != null) {
            sourcesList = result['documents'] as List;
          }

          if (sourcesList.isNotEmpty) {
            final sources = sourcesList.map((s) {
              // Handle potential mismatch in keys if using 'documents'
              if (result['documents'] != null) {
                String domain = '';
                try {
                  final uri = Uri.parse(s['url'] ?? '');
                  domain = uri.host;
                } catch (_) {
                  domain = s['source'] ?? 'web';
                }

                // Map document format to SourceItem expected map
                return SourceItem(
                  title: s['title'] ?? '',
                  url: s['url'] ?? '',
                  description: s['snippet'] ?? s['content'] ?? '',
                  thumbnail: s['thumbnail'] ?? '',
                  source: s['source'] ?? 'web',
                  domain: domain,
                  publishedDate: s['publishedDate'] != null
                      ? DateTime.tryParse(s['publishedDate'])
                      : null,
                );
              }
              return SourceItem.fromMap(s);
            }).toList();
            currentData = currentData.copyWith(sources: sources);
          }

          if (result['images'] != null &&
              (result['images'] as List).isNotEmpty) {
            currentData = currentData.copyWith(
              images: List<String>.from(result['images']),
            );
          }

          if (result['videos'] != null &&
              (result['videos'] as List).isNotEmpty) {
            final videos = (result['videos'] as List)
                .map((v) => VideoItem.fromMap(v))
                .toList();
            currentData = currentData.copyWith(videos: videos);
          }
        } else if (tool.id == 'calculator') {
          if (result is Map && result.containsKey('result')) {
            currentData = currentData.copyWith(
              answer: 'The result is ${result['result']}',
            );
          }
        } else if ([
          'weather',
          'stock_price',
          'crypto_price',
          'dictionary',
        ].contains(tool.id)) {
          // Capture data for tool widgets
          if (result is Map<String, dynamic> && !result.containsKey('error')) {
            final toolWidget = ToolWidgetData(
              id: _uuid.v4(),
              toolId: tool.id,
              data: result,
            );
            final newWidgets = List<ToolWidgetData>.from(
              currentData.toolWidgets,
            )..add(toolWidget);
            currentData = currentData.copyWith(toolWidgets: newWidgets);
          }
        } else {
          // Generic fallback for other tools that might return a direct answer
          if (result is Map && result.containsKey('answer')) {
            currentData = currentData.copyWith(answer: result['answer']);
          } else if (result is Map && result.containsKey('result')) {
            // For generic tools returning 'result'
            currentData = currentData.copyWith(
              answer: result['result'].toString(),
            );
          }
        }

        // Mark step complete
        planSteps[i] = planSteps[i].copyWith(
          status: SearchStepStatus.completed,
          duration: DateTime.now().difference(stepStartTime),
        );
        currentData = currentData.copyWith(steps: List.from(planSteps));
        currentData = currentData.copyWith(steps: List.from(planSteps));
        print(
          'AgentExecutor: Yielding update after step $i. Answer: "${currentData.answer}"',
        );
        yield currentData;
      } catch (e) {
        planSteps[i] = planSteps[i].copyWith(
          status: SearchStepStatus.failed,
          description: "${stepPlan.description} (Failed: $e)",
          duration: DateTime.now().difference(stepStartTime),
        );
        currentData = currentData.copyWith(steps: List.from(planSteps));
        yield currentData;
      }
    }

    currentData = currentData.copyWith(
      generationState: MessageGenerationState.completed,
    );
    yield currentData;
  }
}
