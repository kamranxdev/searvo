import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'settings_card.dart';

class EmbeddingSettingsPanel extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;

  const EmbeddingSettingsPanel({
    super.key,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<EmbeddingSettingsPanel> createState() => _EmbeddingSettingsPanelState();
}

class _EmbeddingSettingsPanelState extends State<EmbeddingSettingsPanel> {
  final LLMSettingsService _llmSettings = LLMSettingsService();
  LLMProviderType? _selectedEmbeddingProvider;

  @override
  void initState() {
    super.initState();
    _selectedEmbeddingProvider =
        _llmSettings.getActiveEmbeddingProvider() ??
        _llmSettings
            .getActiveProvider(); // Default to chat provider if no embedding provider set
  }

  @override
  Widget build(BuildContext context) {
    final providerStatus = _llmSettings.getProviderStatus();
    final providerNames = _llmSettings.getProviderDisplayNames();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Embedding Provider Settings',
          subtitle:
              'Configure your embedding models for vector search and semantic analysis',
        ),
        const SizedBox(height: 24),

        // Active Embedding Provider Selection
        _buildEmbeddingProviderSelector(context, providerStatus, providerNames),

        const SizedBox(height: 32),

        // OpenAI Embedding Settings
        if (_selectedEmbeddingProvider == LLMProviderType.openai)
          _buildOpenAIEmbeddingSettings(
            context,
            providerStatus[LLMProviderType.openai] ?? false,
          ),

        // Google Embedding Settings
        if (_selectedEmbeddingProvider == LLMProviderType.google)
          _buildGoogleEmbeddingSettings(
            context,
            providerStatus[LLMProviderType.google] ?? false,
          ),

        // Ollama Embedding Settings
        if (_selectedEmbeddingProvider == LLMProviderType.ollama)
          _buildOllamaEmbeddingSettings(
            context,
            providerStatus[LLMProviderType.ollama] ?? false,
          ),
      ],
    );
  }

  Widget _buildEmbeddingProviderSelector(
    BuildContext context,
    Map<LLMProviderType, bool> providerStatus,
    Map<LLMProviderType, String> providerNames,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Embedding Provider',
          style: SettingsTheme.settingTitle(context),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: settingsColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: settingsColors.border),
          ),
          child: Column(
            children: LLMProviderType.values.map((provider) {
              final isConfigured = providerStatus[provider] ?? false;
              final isSelected = _selectedEmbeddingProvider == provider;
              final name = providerNames[provider] ?? provider.name;

              return ListTile(
                leading: Radio<LLMProviderType>(
                  value: provider,
                  groupValue: _selectedEmbeddingProvider,
                  onChanged: isConfigured
                      ? (value) {
                          setState(() {
                            _selectedEmbeddingProvider = value;
                          });
                          if (value != null) {
                            _llmSettings.setActiveEmbeddingProvider(value);
                          }
                        }
                      : null,
                  activeColor: settingsColors.accent,
                ),
                title: Row(
                  children: [
                    Text(
                      '$name Embeddings',
                      style: TextStyle(
                        color: isConfigured
                            ? settingsColors.text
                            : settingsColors.subtitle,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isConfigured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Ready',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: settingsColors.subtitle.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Not Configured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: settingsColors.subtitle,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  _getEmbeddingProviderDescription(provider),
                  style: TextStyle(
                    fontSize: 12,
                    color: settingsColors.subtitle.withOpacity(0.6),
                  ),
                ),
                enabled: isConfigured,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getEmbeddingProviderDescription(LLMProviderType provider) {
    switch (provider) {
      case LLMProviderType.openai:
        return 'High-quality embeddings for semantic search and analysis';
      case LLMProviderType.google:
        return 'Google\'s embedding models with multilingual support';
      case LLMProviderType.ollama:
        return 'Local embedding models running on your machine';
      case LLMProviderType.openrouter:
        return 'Access various open-source embedding models via OpenRouter';
      case LLMProviderType.anthropic:
        return 'Anthropic\'s Claude models for advanced language understanding';
    }
  }

  Widget _buildOpenAIEmbeddingSettings(
    BuildContext context,
    bool isConfigured,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.memory, size: 20, color: settingsColors.text),
            const SizedBox(width: 8),
            Text(
              'OpenAI Embedding Configuration',
              style: SettingsTheme.settingTitle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isConfigured) ...[
          _buildModelSelector(
            context,
            'OpenAI Embedding Model',
            _llmSettings.getOpenAIEmbeddingModel(),
            _llmSettings.getAvailableOpenAIEmbeddingModels(),
            (model) {
              _llmSettings.setOpenAIEmbeddingModel(model);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildModelInfo(context, _llmSettings.getOpenAIEmbeddingModel()),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: settingsColors.inputBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: settingsColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: settingsColors.subtitle,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'OpenAI API key is required. Please configure it in the AI Providers tab first.',
                    style: TextStyle(
                      color: settingsColors.subtitle,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGoogleEmbeddingSettings(
    BuildContext context,
    bool isConfigured,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.memory, size: 20, color: settingsColors.text),
            const SizedBox(width: 8),
            Text(
              'Google Embedding Configuration',
              style: SettingsTheme.settingTitle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isConfigured) ...[
          _buildModelSelector(
            context,
            'Google Embedding Model',
            _llmSettings.getGoogleEmbeddingModel(),
            _llmSettings.getAvailableGoogleEmbeddingModels(),
            (model) {
              _llmSettings.setGoogleEmbeddingModel(model);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildModelInfo(context, _llmSettings.getGoogleEmbeddingModel()),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: settingsColors.inputBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: settingsColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: settingsColors.subtitle,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Google AI API key is required. Please configure it in the AI Providers tab first.',
                    style: TextStyle(
                      color: settingsColors.subtitle,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOllamaEmbeddingSettings(
    BuildContext context,
    bool isConfigured,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.memory, size: 20, color: settingsColors.text),
            const SizedBox(width: 8),
            Text(
              'Ollama Embedding Configuration',
              style: SettingsTheme.settingTitle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildModelSelector(
          context,
          'Ollama Embedding Model',
          _llmSettings.getOllamaEmbeddingModel(),
          _llmSettings.getAvailableOllamaEmbeddingModels(),
          (model) {
            _llmSettings.setOllamaEmbeddingModel(model);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        _buildModelInfo(context, _llmSettings.getOllamaEmbeddingModel()),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.download, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Make sure to pull the embedding model in Ollama first:\n'
                  'ollama pull ${_llmSettings.getOllamaEmbeddingModel()}',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelector(
    BuildContext context,
    String label,
    String currentModel,
    List<String> availableModels,
    Function(String) onChanged,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SettingsTheme.inputLabel(context)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentModel,
          decoration: InputDecoration(
            filled: true,
            fillColor: settingsColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: settingsColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: settingsColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: settingsColors.accent, width: 2),
            ),
          ),
          dropdownColor: settingsColors.inputBackground,
          items: availableModels.map((model) {
            return DropdownMenuItem<String>(
              value: model,
              child: Text(model, style: SettingsTheme.inputText(context)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildModelInfo(BuildContext context, String model) {
    final settingsColors = SettingsTheme.colors(context);
    final info = _getModelInfo(model);
    if (info.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: settingsColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: settingsColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: settingsColors.subtitle.withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              info,
              style: TextStyle(
                color: settingsColors.subtitle.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModelInfo(String model) {
    final modelInfo = {
      'text-embedding-ada-002':
          'OpenAI\'s most popular embedding model. 1536 dimensions, good for most use cases.',
      'text-embedding-3-small':
          'OpenAI\'s latest small embedding model. Faster and more efficient than ada-002.',
      'text-embedding-3-large':
          'OpenAI\'s largest embedding model. Best performance for complex tasks.',
      'text-embedding-004':
          'Google\'s latest embedding model with improved performance and multilingual support.',
      'embedding-001':
          'Google\'s general-purpose embedding model for text similarity and semantic search.',
      'all-minilm':
          'Lightweight embedding model, good for general text similarity tasks.',
      'nomic-embed-text':
          'High-quality open-source embedding model with good performance.',
      'mxbai-embed-large':
          'Large embedding model with excellent semantic understanding.',
      'snowflake-arctic-embed':
          'High-performance embedding model optimized for retrieval tasks.',
      'bge-base':
          'Base version of BGE (Beijing Academy of Artificial Intelligence) embedding model.',
      'bge-large':
          'Large version of BGE embedding model with superior performance.',
    };

    return modelInfo[model] ?? '';
  }
}
