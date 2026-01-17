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
        // Process result based on tool type and updated fallback
        // RAG SYNTHESIS MODE: All tool outputs are converted to sources for the LLM to process.
        if (tool.id == 'image_generator' &&
            result is Map &&
            result.containsKey('imageUrl')) {
          final newImages = List<String>.from(currentData.images)
            ..add(result['imageUrl']);
          currentData = currentData.copyWith(images: newImages);
        } else if (tool.id == 'wikipedia') {
          // Wikipedia specific handling
          if (result is Map) {
            // Add as source ONLY
            if (result.containsKey('title')) {
              final source = SourceItem(
                title: result['title'] ?? 'Wikipedia',
                url: result['url'] ?? '',
                description: result['summary'] ?? '',
                thumbnail: '',
                source: 'Wikipedia',
                domain: 'wikipedia.org',
              );
              final newSources = List<SourceItem>.from(currentData.sources)
                ..add(source);
              currentData = currentData.copyWith(sources: newSources);
            }
          }
        } else if (tool.id == 'web_search' && result is Map) {
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

          // Convert content to source for RAG
          final potentialAnswerKeys = [
            'display',
            'answer',
            'result',
            'definition',
          ];
          String? content;

          // Special handling for Weather tool to generate a descriptive string
          if (tool.id == 'weather' && result is Map) {
            try {
              final loc = result['location'] ?? {};
              final curr = result['current'] ?? {};
              final fc = result['forecast_today'] ?? {};
              content =
                  "Weather in ${loc['name']}, ${loc['country']}: "
                  "${curr['condition']}, ${curr['temperature']}. "
                  "Feels like ${curr['feels_like']}. Humidity: ${curr['humidity']}. "
                  "Wind: ${curr['wind_speed']} ${curr['wind_direction']}. "
                  "Forecast: High ${fc['max_temp']}, Low ${fc['min_temp']}, ${fc['condition']}.";
            } catch (e) {
              // Fallback if structure doesn't match
              content = result.toString();
            }
          } else if (tool.id == 'map' && result is Map) {
            try {
              final route = result['route'] ?? {};
              content =
                  "Map: Directions to ${result['destination']}. "
                  "Estimated time: ${route['duration']}, Distance: ${route['distance']}. "
                  "Route: ${route['summary']}.";
            } catch (e) {
              content = "Here is the map for your request.";
            }
          }

          if (content == null) {
            for (final key in potentialAnswerKeys) {
              if (result is Map &&
                  result.containsKey(key) &&
                  result[key] is String &&
                  (result[key] as String).isNotEmpty) {
                content = result[key];
                break;
              }
            }
          }

          if (content != null) {
            final source = SourceItem(
              title: tool.name,
              url: '',
              description: content,
              thumbnail: '',
              source: tool.name,
              domain: tool.name,
            );
            final newSources = List<SourceItem>.from(currentData.sources)
              ..add(source);
            currentData = currentData.copyWith(sources: newSources);
          }
        } else {
          // Generic fallback for ALL other tools
          if (result is Map) {
            // 1. Try to find a text content
            final potentialKeys = [
              'answer',
              'result',
              'summary',
              'fact',
              'display',
              'text',
              'content',
              'analysis',
              'definition',
            ];
            String? foundContent;
            for (final key in potentialKeys) {
              if (result.containsKey(key) &&
                  result[key] is String &&
                  (result[key] as String).isNotEmpty) {
                foundContent = result[key];
                break;
              }
            }

            // 2. Add as SourceItem if content found OR if it looks like a source object
            if (result.containsKey('title') && result.containsKey('url')) {
              // Single source result
              final source = SourceItem(
                title: result['title'] ?? tool.name,
                url: result['url'] ?? '',
                description: foundContent ?? '',
                thumbnail: '',
                source: tool.name,
                domain: Uri.tryParse(result['url'] ?? '')?.host ?? tool.name,
              );
              final newSources = List<SourceItem>.from(currentData.sources)
                ..add(source);
              currentData = currentData.copyWith(sources: newSources);
            } else if (result.containsKey('documents') &&
                result['documents'] is List) {
              // List of documents (like read_page)
              final docs = result['documents'] as List;
              if (docs.isNotEmpty) {
                final newSources = docs.map((d) {
                  if (d is! Map) {
                    try {
                      return SourceItem(
                        title: 'Document',
                        url: '',
                        source: tool.name,
                        domain: tool.name,
                        description: 'Document content',
                        thumbnail: '',
                      );
                    } catch (e) {
                      return SourceItem(
                        title: 'Document',
                        url: '',
                        source: tool.name,
                        domain: tool.name,
                        description: '',
                        thumbnail: '',
                      );
                    }
                  }

                  return SourceItem(
                    title: d['title'] ?? d['url'] ?? 'Document',
                    url: d['url'] ?? '',
                    description:
                        d['snippet'] ?? d['content']?.substring(0, 100) ?? '',
                    thumbnail: d['thumbnail'] ?? '',
                    source: tool.name,
                    domain: Uri.tryParse(d['url'] ?? '')?.host ?? tool.name,
                  );
                }).toList();

                final allSources = List<SourceItem>.from(currentData.sources)
                  ..addAll(newSources);
                currentData = currentData.copyWith(sources: allSources);
              }
            } else if (foundContent != null) {
              // Fallback: Create a source from just the content (e.g. Calculator result)
              final source = SourceItem(
                title: tool.name,
                url: '',
                description: foundContent,
                thumbnail: '',
                source: tool.name,
                domain: tool.name,
              );
              final newSources = List<SourceItem>.from(currentData.sources)
                ..add(source);
              currentData = currentData.copyWith(sources: newSources);
            }
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
