/// Context window configuration for different LLM providers and models
/// 
/// Modern LLMs have significantly larger context windows than older models.
/// This configuration ensures optimal context usage while maintaining compatibility.
class ContextWindowConfig {
  /// Get the maximum context length (in characters) for a given provider and model
  /// 
  /// Note: Character count is approximate. Generally:
  /// - 1 token ≈ 4 characters for English text
  /// - We use conservative estimates to avoid truncation
  static int getMaxContextLength(String provider, String model) {
    final providerLower = provider.toLowerCase();
    final modelLower = model.toLowerCase();

    // OpenAI Models
    if (providerLower.contains('openai')) {
      if (modelLower.contains('gpt-4o')) return 100000; // 128k tokens → ~100k chars (conservative)
      if (modelLower.contains('gpt-4-turbo')) return 100000; // 128k tokens
      if (modelLower.contains('gpt-4')) return 24000; // 32k tokens → ~24k chars
      if (modelLower.contains('gpt-3.5-turbo-16k')) return 12000; // 16k tokens
      if (modelLower.contains('gpt-3.5')) return 12000; // 16k tokens (newer versions)
      return 12000; // Default for OpenAI
    }

    // Google (Gemini) Models
    if (providerLower.contains('google') || providerLower.contains('gemini')) {
      if (modelLower.contains('gemini-2.0')) return 800000; // 1M tokens → ~800k chars
      if (modelLower.contains('gemini-1.5-pro')) return 800000; // 1M-2M tokens
      if (modelLower.contains('gemini-1.5-flash')) return 800000; // 1M tokens
      if (modelLower.contains('gemini-2.5-flash')) return 800000; // 1M tokens
      if (modelLower.contains('gemini-pro')) return 24000; // 32k tokens
      return 800000; // Default for modern Gemini (very large context)
    }

    // Anthropic (Claude) Models
    if (providerLower.contains('anthropic') || providerLower.contains('claude')) {
      if (modelLower.contains('claude-3')) return 160000; // 200k tokens → ~160k chars
      if (modelLower.contains('claude-2.1')) return 160000; // 200k tokens
      if (modelLower.contains('claude-2')) return 80000; // 100k tokens
      return 160000; // Default for Claude 3
    }

    // Ollama (Local Models) - More conservative due to hardware constraints
    if (providerLower.contains('ollama')) {
      // Larger models with good context support
      if (modelLower.contains('llama3.1') || modelLower.contains('llama-3.1')) {
        if (modelLower.contains('70b') || modelLower.contains('405b')) return 100000; // 128k tokens
        return 100000; // 128k tokens for Llama 3.1
      }
      if (modelLower.contains('llama3.2') || modelLower.contains('llama-3.2')) return 100000; // 128k tokens
      if (modelLower.contains('qwen2.5')) return 100000; // 128k tokens
      if (modelLower.contains('mistral-nemo')) return 100000; // 128k tokens
      if (modelLower.contains('gemma2')) return 64000; // 8k tokens → conservative for local
      
      // Medium context models
      if (modelLower.contains('llama3') || modelLower.contains('llama-3')) return 24000; // 8k tokens
      if (modelLower.contains('mistral')) return 24000; // 32k tokens (some versions)
      if (modelLower.contains('mixtral')) return 24000; // 32k tokens
      if (modelLower.contains('phi')) return 32000; // 4k-8k tokens
      
      // Smaller models - conservative
      if (modelLower.contains('tinyllama')) return 8000; // 2k tokens
      if (modelLower.contains('orca')) return 8000; // 2k tokens
      
      return 24000; // Default for Ollama (conservative for hardware)
    }

    // OpenRouter - depends on underlying model, use conservative default
    if (providerLower.contains('openrouter')) {
      // OpenRouter forwards to various models, check the model name
      if (modelLower.contains('claude-3')) return 160000;
      if (modelLower.contains('gpt-4o')) return 100000;
      if (modelLower.contains('gemini')) return 800000;
      return 24000; // Conservative default
    }

    // Default fallback for unknown providers
    return 24000;
  }

  /// Get recommended context length based on complexity
  /// This provides adaptive context sizing based on query complexity
  static int getRecommendedContextLength(
    String provider,
    String model,
    String complexity,
  ) {
    final maxContext = getMaxContextLength(provider, model);
    
    switch (complexity.toLowerCase()) {
      case 'simple':
        // Simple queries need less context
        return (maxContext * 0.3).toInt().clamp(8000, maxContext);
      
      case 'moderate':
        // Moderate queries need medium context
        return (maxContext * 0.5).toInt().clamp(16000, maxContext);
      
      case 'complex':
        // Complex queries need more context
        return (maxContext * 0.75).toInt().clamp(24000, maxContext);
      
      case 'very_complex':
        // Very complex queries need maximum context
        return maxContext;
      
      default:
        // Default to moderate
        return (maxContext * 0.5).toInt().clamp(16000, maxContext);
    }
  }

  /// Check if a provider/model supports large context windows (>50k chars)
  static bool supportsLargeContext(String provider, String model) {
    return getMaxContextLength(provider, model) > 50000;
  }

  /// Get chunk size recommendation based on context window
  static int getRecommendedChunkSize(String provider, String model) {
    final maxContext = getMaxContextLength(provider, model);
    
    if (maxContext >= 100000) return 4000; // Large context: bigger chunks
    if (maxContext >= 50000) return 3000;  // Medium-large: medium-big chunks
    if (maxContext >= 24000) return 2000;  // Medium: standard chunks
    return 1500; // Small context: smaller chunks
  }

  /// Get max content per document based on context window
  static int getMaxContentPerDocument(String provider, String model) {
    final maxContext = getMaxContextLength(provider, model);
    
    // Allow each document to use up to 20% of available context
    // This ensures good source diversity (5+ sources minimum)
    return (maxContext * 0.2).toInt().clamp(4000, 40000);
  }

  /// Get provider-specific optimization notes
  static String getOptimizationNotes(String provider) {
    final providerLower = provider.toLowerCase();
    
    if (providerLower.contains('ollama')) {
      return 'Local model - context size may be limited by available RAM. '
             'Monitor performance and reduce context if experiencing slowdowns.';
    }
    
    if (providerLower.contains('google') || providerLower.contains('gemini')) {
      return 'Gemini supports very large context windows (up to 1M tokens). '
             'Excellent for processing multiple long documents simultaneously.';
    }
    
    if (providerLower.contains('anthropic') || providerLower.contains('claude')) {
      return 'Claude 3 supports 200k token context. Great for comprehensive analysis '
             'with many sources.';
    }
    
    if (providerLower.contains('openai')) {
      return 'GPT-4 Turbo and GPT-4o support 128k tokens. Suitable for most search tasks.';
    }
    
    return 'Context window varies by model. Check model documentation for details.';
  }
}
