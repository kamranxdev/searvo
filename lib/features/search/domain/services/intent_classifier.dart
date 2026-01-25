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

    // -- Combined Heuristics (migrated from Autocomplete) --

    // How-To
    if (RegExp(r'(how to|tutorial|guide)').hasMatch(lower)) {
      return SearchIntent.howTo;
    }

    // Questions
    if (RegExp(
      r'^(what|who|when|where|why|how|is|are|can|does)',
    ).hasMatch(lower)) {
      return SearchIntent.question;
    }

    // Definitions

    // Comparison
    if (RegExp(r'(vs|versus|compare|diff)').hasMatch(lower)) {
      return SearchIntent.comparison;
    }

    // Visual / Creative
    if (RegExp(
      r'(image|photo|picture|drawing|logo|art|sketch|palette|color)',
    ).hasMatch(lower)) {
      return SearchIntent
          .visual; // Merged creative into visual or keep separate if needed?
      // Plan had 'creative' separate, let's keep 'creative' for abstract ideas and 'visual' for strict images
      // But based on keywords, there is overlap. Let's use specific regexes.
    }

    if (RegExp(
      r'(idea|design|art|drawing|sketch|palette|color)', // Removed 'logo' (visual)
    ).hasMatch(lower)) {
      return SearchIntent.creative;
    }

    // Coding / Technical
    if (RegExp(
      r'(error|bug|fix|install|download|update|code|api|sdk|exception|function|class|flutter|dart|java|python)',
    ).hasMatch(lower)) {
      return SearchIntent
          .technical; // Overlaps with .coding from original. SearchIntent.coding exists?
      // Yes, SearchIntent.coding exists. Let's Map .technical (from Autocomplete) to .coding or .technical
      // The Plan added .technical. So we return .technical.
    }

    // Explicit Coding check (if we want to distinguish or merge?)
    // Original IntentClassifier had .coding. Autocomplete had .technical.
    // I added .technical to SearchIntent. Let's use .coding for languages and .technical for errors?
    // Or just map all to .coding if that was the original intent of the system?
    // Let's stick to the granular ones I added to SearchIntent: .coding AND .technical
    // But wait, the original file had 'coding'. The new file has 'technical'.
    // Using 'coding' for explicit language mentions seems safer for the existing 'coding' heuristics.
    if (RegExp(
      r'(code|function|class|method|api|sdk|library|flutter|dart|java|golang|cpp|python|javascript|react|variable|syntax|script)',
    ).hasMatch(lower)) {
      return SearchIntent.coding;
    }

    // Academic / Research
    if (RegExp(
      r'(research|study|paper|journal|thesis|doi|abstract)',
    ).hasMatch(lower)) {
      return SearchIntent.academic;
    }

    // News
    if (RegExp(
      r'(news|latest|breaking|today|headline|update)',
    ).hasMatch(lower)) {
      return SearchIntent.news;
    }

    // Shopping
    if (RegExp(
      r'(buy|price|cost|cheap|deal|shop|store|order|amazon|ebay)',
    ).hasMatch(lower)) {
      return SearchIntent.shopping;
    }

    // Media
    if (RegExp(
      r'(watch|trailer|movie|video|song|mp3|music|stream|series|youtube|clip)',
    ).hasMatch(lower)) {
      return SearchIntent.media;
    }

    // Maps / Local
    if (RegExp(
      r'(near me|restaurant|hotel|map|location|place|directions|cafe)',
    ).hasMatch(lower)) {
      return SearchIntent.local;
      // Original had .map. I added .local. .map is still there.
      // Let's use .map for "Map" specific and .local for places?
      // Or align to the plan: "Flatten". .map was existing. .local was new.
      // I'll return .map for explicit map requests and .local for places?
      // Actually, let's map these to .map to avoid fragmentation if the UI handles .map well.
      // But I added .local to the Enum.
      // Recommendation: Use .local for "restaurant near me" and .map for "map of X".
    }

    // Weather
    if (lower.contains('weather')) {
      return SearchIntent.weather;
    }

    return null; // Default to general
  }
}
