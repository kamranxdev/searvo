import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import '../entities/search_intent.dart';

class IntentClassifier {
  final LLMProviderManager _llmManager;

  IntentClassifier({LLMProviderManager? llmManager})
    : _llmManager = llmManager ?? LLMProviderManager();

  /// Determine intent using hybrid approach detailed in implementation plan.
  Future<SearchIntent> classify(String query) async {
    // 1. Fast Path: Heuristics & Keywords
    final heuristicIntent = _classifyByHeuristics(query);
    if (heuristicIntent != null) {
      return heuristicIntent;
    }

    // 2. Slow Path: LLM Router (Only for ambiguous complex queries)
    // For now, to keep it fast, we will rely heavily on improved heuristics
    // and only use LLM if absolutely necessary or in "Research Mode"
    // (Implementation of LLM router deferred to next optimization phase to ensure responsiveness)

    return SearchIntent.general;
  }

  SearchIntent? _classifyByHeuristics(String query) {
    final lower = query.toLowerCase();

    // Visual
    if (_matches(lower, [
      'image',
      'photo',
      'picture',
      'drawing',
      'logo',
      'video',
      'youtube',
      'clip',
      'watch',
    ])) {
      print('DEBUG: Matched Visual');
      return SearchIntent.visual;
    }

    // Coding
    if (_matches(lower, [
      'code',
      'function',
      'class',
      'method',
      'api',
      'sdk',
      'library',
      'flutter',
      'dart',
      'java',
      'golang',
      'cpp',
      'python',
      'javascript',
      'react',
      'error',
      'exception',
      'stack trace',
      'debug',
      'compile',
      'runtime',
      'variable',
      'syntax',
      'script',
    ])) {
      return SearchIntent.coding;
    }

    // Academic
    if (_matches(lower, [
      'paper',
      'study',
      'research',
      'thesis',
      'doi',
      'journal',
      'abstract',
      'methodology',
      'citation',
      'bibliography',
    ])) {
      return SearchIntent.academic;
    }

    // News
    if (_matches(lower, [
      'news',
      'latest',
      'today',
      'headline',
      'breaking',
      'update',
      'happened',
    ])) {
      return SearchIntent.news;
    }

    // Shopping
    if (_matches(lower, [
      'price',
      'buy',
      'cost',
      'shop',
      'store',
      'amazon',
      'ebay',
      'cheap',
      'deal',
    ])) {
      return SearchIntent.shopping;
    }

    // Maps
    if (_matches(lower, [
      'where is',
      'weather', // Added weather
      'location',
      'map',
      'directions',
      'near me',
      'restaurant',
      'cafe',
    ])) {
      return SearchIntent.map;
    }

    return null; // Default to general
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
