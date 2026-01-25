import 'package:flutter/material.dart';

/// Represents a single setup step in the onboarding wizard
class SetupStep {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isRequired;
  final bool Function()? isComplete;

  const SetupStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isRequired = false,
    this.isComplete,
  });
}

/// Represents an AI provider option during setup
class AIProviderOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String? logoAsset;
  final bool requiresApiKey;
  final bool requiresBaseUrl;
  final String? apiKeyHint;
  final String? apiKeyPlaceholder;
  final String? getKeyUrl;
  final List<String> features;

  const AIProviderOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.logoAsset,
    this.requiresApiKey = true,
    this.requiresBaseUrl = false,
    this.apiKeyHint,
    this.apiKeyPlaceholder,
    this.getKeyUrl,
    this.features = const [],
  });

  static List<AIProviderOption> get allProviders => [
    const AIProviderOption(
      id: 'openrouter',
      name: 'OpenRouter',
      description: 'Access multiple AI models',
      icon: Icons.hub,
      requiresApiKey: true,
      apiKeyHint: 'Enter your OpenRouter API key',
      apiKeyPlaceholder: 'sk-or-...',
      getKeyUrl: 'https://openrouter.ai/keys',
      features: ['100+ models', 'Pay per use', 'No subscription'],
    ),
    const AIProviderOption(
      id: 'openai',
      name: 'OpenAI',
      description: 'Industry standard models',
      icon: Icons.bolt,
      requiresApiKey: true,
      apiKeyHint: 'Enter your OpenAI API key',
      apiKeyPlaceholder: 'sk-...',
      getKeyUrl: 'https://platform.openai.com/api-keys',
      features: ['GPT-4 & GPT-3.5', 'Reliable', 'Fast'],
    ),
    const AIProviderOption(
      id: 'google',
      name: 'Google Gemini',
      description: 'Google\'s latest AI models',
      icon: Icons.search,
      requiresApiKey: true,
      apiKeyHint: 'Enter your Google AI API key',
      apiKeyPlaceholder: 'AIzaSy...',
      getKeyUrl: 'https://aistudio.google.com/app/apikey',
      features: ['Gemini Pro', 'Fast & Capable', 'Multimodal'],
    ),
    const AIProviderOption(
      id: 'anthropic',
      name: 'Anthropic Claude',
      description: 'Safe and steerable AI',
      icon: Icons.psychology,
      requiresApiKey: true,
      apiKeyHint: 'Enter your Anthropic API key',
      apiKeyPlaceholder: 'sk-ant...',
      getKeyUrl: 'https://console.anthropic.com/settings/keys',
      features: ['Claude 3.5 Sonnet', 'Great reasoning', 'Large context'],
    ),
    const AIProviderOption(
      id: 'ollama',
      name: 'Ollama (Local)',
      description: 'Run AI locally on your machine',
      icon: Icons.computer,
      requiresApiKey: false,
      requiresBaseUrl: true,
      apiKeyHint: 'Enter your Ollama server URL',
      apiKeyPlaceholder: 'http://localhost:11434',
      getKeyUrl: 'https://ollama.com',
      features: ['Free & private', 'Llama 3.2', 'No API key needed'],
    ),
  ];
}

/// State for the setup wizard
class SetupWizardState {
  final int currentStep;
  final String? selectedProvider;
  final Map<String, String> apiKeys;
  final bool isLoading;
  final String? errorMessage;

  const SetupWizardState({
    this.currentStep = 0,
    this.selectedProvider,
    this.apiKeys = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  SetupWizardState copyWith({
    int? currentStep,
    String? selectedProvider,
    Map<String, String>? apiKeys,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SetupWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      apiKeys: apiKeys ?? this.apiKeys,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
