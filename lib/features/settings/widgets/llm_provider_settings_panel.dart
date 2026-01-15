import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'api_key_field.dart';
import 'settings_card.dart';

class LLMProviderSettingsPanel extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;

  const LLMProviderSettingsPanel({
    super.key,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<LLMProviderSettingsPanel> createState() =>
      _LLMProviderSettingsPanelState();
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
    final providerStatus = _llmSettings.getProviderStatus();
    final providerNames = _llmSettings.getProviderDisplayNames();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'AI Provider Settings',
          subtitle: 'Configure your AI providers and API keys',
        ),
        const SizedBox(height: 24),

        // Active Provider Selection
        _buildProviderSelector(context, providerStatus, providerNames),

        const SizedBox(height: 32),

        // Provider settings based on screen size
        if (widget.isDesktop)
          _buildDesktopProviderLayout(context, providerStatus)
        else
          _buildMobileProviderLayout(context, providerStatus),
      ],
    );
  }

  Widget _buildDesktopProviderLayout(
    BuildContext context,
    Map<LLMProviderType, bool> providerStatus,
  ) {
    return Column(
      children: [
        // First row: OpenAI and Google
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProviderCard(
                context,
                Icons.psychology,
                'OpenAI Configuration',
                _buildOpenAISettings(
                  context,
                  providerStatus[LLMProviderType.openai] ?? false,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildProviderCard(
                context,
                Icons.auto_awesome,
                'Google Gemini Configuration',
                _buildGoogleSettings(
                  context,
                  providerStatus[LLMProviderType.google] ?? false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Second row: Ollama and OpenRouter
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProviderCard(
                context,
                Icons.computer,
                'Ollama Configuration',
                _buildOllamaSettings(
                  context,
                  providerStatus[LLMProviderType.ollama] ?? false,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildProviderCard(
                context,
                Icons.router,
                'OpenRouter Configuration',
                _buildOpenRouterSettings(
                  context,
                  providerStatus[LLMProviderType.openrouter] ?? false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Third row: Anthropic
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProviderCard(
                context,
                Icons.psychology_alt,
                'Anthropic Claude Configuration',
                _buildAnthropicSettings(
                  context,
                  providerStatus[LLMProviderType.anthropic] ?? false,
                ),
              ),
            ),
            const Expanded(child: SizedBox()), // Empty space for alignment
          ],
        ),
      ],
    );
  }

  Widget _buildMobileProviderLayout(
    BuildContext context,
    Map<LLMProviderType, bool> providerStatus,
  ) {
    return Column(
      children: [
        // OpenAI Settings
        _buildProviderCard(
          context,
          Icons.psychology,
          'OpenAI Configuration',
          _buildOpenAISettings(
            context,
            providerStatus[LLMProviderType.openai] ?? false,
          ),
        ),
        const SizedBox(height: 24),

        // Google Settings
        _buildProviderCard(
          context,
          Icons.auto_awesome,
          'Google Gemini Configuration',
          _buildGoogleSettings(
            context,
            providerStatus[LLMProviderType.google] ?? false,
          ),
        ),
        const SizedBox(height: 24),

        // Ollama Settings
        _buildProviderCard(
          context,
          Icons.computer,
          'Ollama Configuration',
          _buildOllamaSettings(
            context,
            providerStatus[LLMProviderType.ollama] ?? false,
          ),
        ),
        const SizedBox(height: 24),

        // OpenRouter Settings
        _buildProviderCard(
          context,
          Icons.router,
          'OpenRouter Configuration',
          _buildOpenRouterSettings(
            context,
            providerStatus[LLMProviderType.openrouter] ?? false,
          ),
        ),
        const SizedBox(height: 24),

        // Anthropic Settings
        _buildProviderCard(
          context,
          Icons.psychology_alt,
          'Anthropic Claude Configuration',
          _buildAnthropicSettings(
            context,
            providerStatus[LLMProviderType.anthropic] ?? false,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget content,
  ) {
    // Note: colorScheme here is likely still needed for the icon container background if we don't have settings specific one,
    // but better to use context to get settings colors again or pass them.
    // For simplicity, let's get settings colors from context inside.
    final settingsColors = SettingsTheme.colors(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: settingsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: settingsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: settingsColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: settingsColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: SettingsTheme.settingTitle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildProviderSelector(
    BuildContext context,
    Map<LLMProviderType, bool> providerStatus,
    Map<LLMProviderType, String> providerNames,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Provider', style: SettingsTheme.settingTitle(context)),
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
              final isSelected = _selectedProvider == provider;
              final name = providerNames[provider] ?? provider.name;

              return ListTile(
                leading: Radio<LLMProviderType>(
                  value: provider,
                  groupValue: _selectedProvider,
                  onChanged: isConfigured
                      ? (value) {
                          setState(() {
                            _selectedProvider = value;
                          });
                          if (value != null) {
                            _llmSettings.setActiveProvider(value);
                            _llmSettings.initializeLLMManager();
                          }
                        }
                      : null,
                  activeColor: settingsColors.accent,
                ),
                title: Row(
                  children: [
                    Text(
                      name,
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
                enabled: isConfigured,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenAISettings(BuildContext context, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApiKeyField(
          label: 'OpenAI API Key',
          placeholder: 'sk-...',
          description:
              'Your OpenAI API key from https://platform.openai.com/account/api-keys',
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
          context,
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

  Widget _buildGoogleSettings(BuildContext context, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApiKeyField(
          label: 'Google AI API Key',
          placeholder: 'AIza...',
          description:
              'Your Google AI API key from https://aistudio.google.com/app/api-keys',
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
          context,
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

  Widget _buildOllamaSettings(BuildContext context, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          context,
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
          context,
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

  Widget _buildOpenRouterSettings(BuildContext context, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApiKeyField(
          label: 'OpenRouter API Key',
          placeholder: 'sk-or-v1-...',
          description:
              'Your OpenRouter API key from https://openrouter.ai/keys',
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
          context,
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

  Widget _buildAnthropicSettings(BuildContext context, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApiKeyField(
          label: 'Anthropic API Key',
          placeholder: 'sk-ant-...',
          description:
              'Your Anthropic API key from https://console.anthropic.com/settings/keys',
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
          context,
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
    BuildContext context,
    String label,
    String placeholder,
    String description,
    String? value,
    Function(String) onChanged,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SettingsTheme.inputLabel(context)),
        const SizedBox(height: 8),
        TextFormField(
          textDirection: TextDirection.ltr,
          initialValue: value,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: settingsColors.subtitle.withOpacity(0.5),
              fontSize: 14,
            ),
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
          style: SettingsTheme.inputText(context),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: settingsColors.subtitle.withOpacity(0.6),
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
}
