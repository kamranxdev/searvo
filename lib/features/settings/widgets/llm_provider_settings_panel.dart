import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'api_key_field.dart';
import 'section_header.dart';

class LLMProviderSettingsPanel extends StatefulWidget {
  const LLMProviderSettingsPanel({Key? key}) : super(key: key);

  @override
  State<LLMProviderSettingsPanel> createState() => _LLMProviderSettingsPanelState();
}

class _LLMProviderSettingsPanelState extends State<LLMProviderSettingsPanel> {
  final LLMSettingsService _llmSettings = LLMSettingsService();
  LLMProviderType? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _llmSettings.getActiveProvider();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final providerStatus = _llmSettings.getProviderStatus();
    final providerNames = _llmSettings.getProviderDisplayNames();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'AI Provider Settings',
          description: 'Configure your AI providers and API keys',
        ),
        const SizedBox(height: 24),

        // Active Provider Selection
        _buildProviderSelector(colorScheme, providerStatus, providerNames),
        
        const SizedBox(height: 32),

        // OpenAI Settings
        _buildOpenAISettings(colorScheme, providerStatus[LLMProviderType.openai] ?? false),
        
        const SizedBox(height: 32),

        // Google Settings
        _buildGoogleSettings(colorScheme, providerStatus[LLMProviderType.google] ?? false),
        
        const SizedBox(height: 32),

        // Ollama Settings
        _buildOllamaSettings(colorScheme, providerStatus[LLMProviderType.ollama] ?? false),
        
        const SizedBox(height: 32),

        // OpenRouter Settings
        _buildOpenRouterSettings(colorScheme, providerStatus[LLMProviderType.openrouter] ?? false),
        
        const SizedBox(height: 32),

        // Anthropic Settings
        _buildAnthropicSettings(colorScheme, providerStatus[LLMProviderType.anthropic] ?? false),
      ],
    );
  }

  Widget _buildProviderSelector(
    ColorScheme colorScheme,
    Map<LLMProviderType, bool> providerStatus,
    Map<LLMProviderType, String> providerNames,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Provider',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: LLMProviderType.values.map((provider) {
              final isConfigured = providerStatus[provider] ?? false;
              final isSelected = _selectedProvider == provider;
              final name = providerNames[provider] ?? provider.name;

              return ListTile(
                leading: Radio<LLMProviderType>(
                  value: provider,
                  groupValue: _selectedProvider,
                  onChanged: isConfigured ? (value) {
                    setState(() {
                      _selectedProvider = value;
                    });
                    if (value != null) {
                      _llmSettings.setActiveProvider(value);
                      _llmSettings.initializeLLMManager();
                    }
                  } : null,
                  activeColor: colorScheme.primary,
                ),
                title: Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isConfigured ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isConfigured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Not Configured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                enabled: isConfigured,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenAISettings(ColorScheme colorScheme, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology,
              size: 20,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'OpenAI Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ApiKeyField(
          label: 'OpenAI API Key',
          placeholder: 'sk-...',
          description: 'Your OpenAI API key from https://platform.openai.com/account/api-keys',
          value: _llmSettings.getOpenAIApiKey() ?? '',
          obscuredValue: _llmSettings.getObscuredOpenAIApiKey(),
          onChanged: (value) {
            _llmSettings.setOpenAIApiKey(value);
            setState(() {}); // Refresh UI
          },
          onClear: () {
            _llmSettings.setOpenAIApiKey('');
            setState(() {}); // Refresh UI
          },
        ),
        const SizedBox(height: 16),
        _buildModelSelector(
          colorScheme,
          'OpenAI Model',
          _llmSettings.getOpenAIModel(),
          _llmSettings.getAvailableOpenAIModels(),
          (model) {
            _llmSettings.setOpenAIModel(model);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildGoogleSettings(ColorScheme colorScheme, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Google Gemini Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ApiKeyField(
          label: 'Google AI API Key',
          placeholder: 'AIza...',
          description: 'Your Google AI API key from https://aistudio.google.com/app/api-keys',
          value: _llmSettings.getGoogleApiKey() ?? '',
          obscuredValue: _llmSettings.getObscuredGoogleApiKey(),
          onChanged: (value) {
            _llmSettings.setGoogleApiKey(value);
            setState(() {}); // Refresh UI
          },
          onClear: () {
            _llmSettings.setGoogleApiKey('');
            setState(() {}); // Refresh UI
          },
        ),
        const SizedBox(height: 16),
        _buildModelSelector(
          colorScheme,
          'Gemini Model',
          _llmSettings.getGoogleModel(),
          _llmSettings.getAvailableGoogleModels(),
          (model) {
            _llmSettings.setGoogleModel(model);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildOllamaSettings(ColorScheme colorScheme, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.computer,
              size: 20,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Ollama Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          colorScheme,
          'Base URL',
          '',
          'Ollama server URL (default: http://localhost:11434)',
          null,
          (value) {
            _llmSettings.setOllamaBaseUrl(value);
            setState(() {}); // Refresh UI
          },
        ),
        const SizedBox(height: 16),
        _buildModelSelector(
          colorScheme,
          'Ollama Model',
          _llmSettings.getOllamaModel(),
          _llmSettings.getAvailableOllamaModels(),
          (model) {
            _llmSettings.setOllamaModel(model);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildOpenRouterSettings(ColorScheme colorScheme, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.router,
              size: 20,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'OpenRouter Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ApiKeyField(
          label: 'OpenRouter API Key',
          placeholder: 'sk-or-v1-...',
          description: 'Your OpenRouter API key from https://openrouter.ai/keys',
          value: _llmSettings.getOpenRouterApiKey() ?? '',
          obscuredValue: _llmSettings.getObscuredOpenRouterApiKey(),
          onChanged: (value) {
            _llmSettings.setOpenRouterApiKey(value);
            setState(() {}); // Refresh UI
          },
          onClear: () {
            _llmSettings.setOpenRouterApiKey('');
            setState(() {}); // Refresh UI
          },
        ),
        const SizedBox(height: 16),
        _buildModelSelector(
          colorScheme,
          'OpenRouter Model',
          _llmSettings.getOpenRouterModel(),
          _llmSettings.getAvailableOpenRouterModels(),
          (model) {
            _llmSettings.setOpenRouterModel(model);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildAnthropicSettings(ColorScheme colorScheme, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_alt,
              size: 20,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Anthropic Claude Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ApiKeyField(
          label: 'Anthropic API Key',
          placeholder: 'sk-ant-...',
          description: 'Your Anthropic API key from https://console.anthropic.com/settings/keys',
          value: _llmSettings.getAnthropicApiKey() ?? '',
          obscuredValue: _llmSettings.getObscuredAnthropicApiKey(),
          onChanged: (value) {
            _llmSettings.setAnthropicApiKey(value);
            setState(() {}); // Refresh UI
          },
          onClear: () {
            _llmSettings.setAnthropicApiKey('');
            setState(() {}); // Refresh UI
          },
        ),
        const SizedBox(height: 16),
        _buildModelSelector(
          colorScheme,
          'Claude Model',
          _llmSettings.getAnthropicModel(),
          _llmSettings.getAvailableAnthropicModels(),
          (model) {
            _llmSettings.setAnthropicModel(model);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
    ColorScheme colorScheme,
    String label,
    String placeholder,
    String description,
    String? value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          textDirection: TextDirection.ltr,
          initialValue: value,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelector(
    ColorScheme colorScheme,
    String label,
    String currentModel,
    List<String> availableModels,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentModel,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          dropdownColor: colorScheme.surfaceContainerHighest,
          items: availableModels.map((model) {
            return DropdownMenuItem<String>(
              value: model,
              child: Text(
                model,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
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
}