import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';
import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/domain/entities/image_item.dart';

class WebSearchTool extends AgentTool {
  final SearXNGRemoteDataSource _searxngService;

  WebSearchTool({required SearXNGRemoteDataSource searxngService})
    : _searxngService = searxngService,
      super(
        id: 'web_search',
        name: 'Web Search',
        description:
            'Search the web for information, news, and answers using SearXNG.',
      );

  @override
  Future<bool> get isAvailable async => _searxngService.isConfigured;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {'type': 'string', 'description': 'The search query to execute'},
      'mode': {
        'type': 'string',
        'enum': ['search', 'research', 'study'],
        'description': 'The search mode to use',
      },
      'maxResults': {
        'type': 'integer',
        'description': 'Maximum results to return',
        'default': 10,
      },
    },
    'required': ['query'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    final maxResults = input['maxResults'] as int? ?? 10;
    // Map mode if needed, but primarily we just want search results

    // Execute search
    final response = await _searxngService.search(
      query,
      resultsPerPage: maxResults,
    );

    // Extract media
    final images = <String>[];
    final imageItems = <Map<String, dynamic>>[];
    final videos = <Map<String, dynamic>>[];

    for (final result in response.results) {
      // 1. Extract Images
      // Prioritize high-res image source, fallback to thumbnail if specific image search or good quality
      if (result.imgSrc != null && result.imgSrc!.isNotEmpty) {
        images.add(result.imgSrc!);
        imageItems.add(
          ImageItem(
            title: result.title,
            url: result.imgSrc!,
            thumbnail: result.thumbnailSrc ?? result.thumbnail ?? '',
            source: result.source ?? '',
            domain: Uri.tryParse(result.url)?.host ?? '',
            originalUrl: result.url,
            width: _parseDimension(result.resolution, 0),
            height: _parseDimension(result.resolution, 1),
          ).toMap(),
        );
      } else if (result.thumbnailSrc != null &&
          result.thumbnailSrc!.isNotEmpty) {
        // Only valid thumbnails
        images.add(result.thumbnailSrc!);

        // Add as ImageItem
        imageItems.add(
          ImageItem(
            title: result.title,
            url: result
                .thumbnailSrc!, // Use thumbnail as main image if imgSrc missing
            thumbnail: result.thumbnailSrc!,
            source: result.source ?? '',
            domain: Uri.tryParse(result.url)?.host ?? '',
            originalUrl: result.url,
            // Resolution often not available for thumbnails, or only thumbnail size
            width: null,
            height: null,
          ).toMap(),
        );
      }

      // 2. Extract Videos
      // Check for video indicators: iframe, specific domains, or length
      final lowerUrl = result.url.toLowerCase();
      final isVideoDomain =
          lowerUrl.contains('youtube.com') ||
          lowerUrl.contains('youtu.be') ||
          lowerUrl.contains('vimeo.com') ||
          lowerUrl.contains('dailymotion.com');

      if (result.iframeSrc != null || result.length != null || isVideoDomain) {
        videos.add({
          'url': result.url,
          'title': result.title,
          'description': result.snippet,
          'thumbnail': result.thumbnailSrc ?? result.thumbnail,
          'domain': Uri.tryParse(result.url)?.host ?? '',
          'duration': result.length,
          'publishedDate': result.publishedDate?.toIso8601String(),
          'views': result.views != null
              ? int.tryParse(result.views!.replaceAll(RegExp(r'[^0-9]'), ''))
              : null,
        });
      }
    }

    // Return raw documents for the agent/orchestrator to process
    return {
      'success': true,
      'documents': response.results
          .map(
            (r) => {
              'title': r.title,
              'url': r.url,
              'snippet': r.snippet,
              'source': r.source,
              'publishedDate': r.publishedDate?.toIso8601String(),
              'thumbnail': r.thumbnail,
            },
          )
          .toList(),
      'images': images,
      'imageItems': imageItems,
      'videos': videos,
    };
  }

  /// Helper to parse "WxH" string
  int? _parseDimension(String? resolution, int index) {
    if (resolution == null || !resolution.contains('x')) return null;
    try {
      final parts = resolution.split('x');
      if (parts.length > index) {
        return int.tryParse(parts[index].trim());
      }
    } catch (_) {}
    return null;
  }
}
