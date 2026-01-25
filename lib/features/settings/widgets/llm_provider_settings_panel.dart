import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/llm/services/providers/openrouter.dart';
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
  List<OpenRouterModelInfo> _openRouterModels = [];
  bool _isLoadingModels = false;

  List<String> _openAIModels = [];
  List<String> _googleModels = [];
  List<String> _anthropicModels = [];
  List<String> _ollamaModels = [];
  bool _isLoadingOpenAIModels = false;
  bool _isLoadingGoogleModels = false;
  bool _isLoadingAnthropicModels = false;
  bool _isLoadingOllamaModels = false;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _llmSettings.getActiveProvider();
    _fetchOpenRouterModels();
    _fetchOpenAIModels();
    _fetchGoogleModels();
    _fetchAnthropicModels();
    _fetchOllamaModels();
  }

  Future<void> _fetchOpenAIModels() async {
    setState(() => _isLoadingOpenAIModels = true);
    try {
      final models = await _llmSettings.fetchAvailableOpenAIModels();
      if (mounted) setState(() => _openAIModels = models);
    } catch (e) {
      print('Error fetching OpenAI models: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOpenAIModels = false);
    }
  }

  Future<void> _fetchGoogleModels() async {
    setState(() => _isLoadingGoogleModels = true);
    try {
      final models = await _llmSettings.fetchAvailableGoogleModels();
      if (mounted) setState(() => _googleModels = models);
    } catch (e) {
      print('Error fetching Google models: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGoogleModels = false);
    }
  }

  Future<void> _fetchAnthropicModels() async {
    setState(() => _isLoadingAnthropicModels = true);
    try {
      final models = await _llmSettings.fetchAvailableAnthropicModels();
      if (mounted) setState(() => _anthropicModels = models);
    } catch (e) {
      print('Error fetching Anthropic models: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAnthropicModels = false);
    }
  }

  Future<void> _fetchOllamaModels() async {
    setState(() => _isLoadingOllamaModels = true);
    try {
      final models = await _llmSettings.fetchAvailableOllamaModels();
      if (mounted) setState(() => _ollamaModels = models);
    } catch (e) {
      print('Error fetching Ollama models: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOllamaModels = false);
    }
  }

  Future<void> _fetchOpenRouterModels() async {
    setState(() {
      _isLoadingModels = true;
    });
    try {
      final models = await _llmSettings.fetchOpenRouterModels();
      // Sort models alphabetically by name, or ID if name is empty
      models.sort((a, b) {
        final nameA = a.name.isEmpty ? a.id : a.name;
        final nameB = b.name.isEmpty ? b.id : b.name;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      setState(() {
        _openRouterModels = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      print('Error fetching OpenRouter models: $e');
      setState(() {
        _isLoadingModels = false;
      });
    }
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProviderCard(
                context,
                Icons.bolt,
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
                Icons.search,
                'Google (Gemini) Configuration',
                _buildGoogleSettings(
                  context,
                  providerStatus[LLMProviderType.google] ?? false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProviderCard(
                context,
                Icons.psychology,
                'Anthropic (Claude) Configuration',
                _buildAnthropicSettings(
                  context,
                  providerStatus[LLMProviderType.anthropic] ?? false,
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
            const Expanded(child: SizedBox()), // Spacer for grid alignment
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
        _buildProviderCard(
          context,
          Icons.bolt,
          'OpenAI Configuration',
          _buildOpenAISettings(
            context,
            providerStatus[LLMProviderType.openai] ?? false,
          ),
        ),
        const SizedBox(height: 24),
        _buildProviderCard(
          context,
          Icons.search,
          'Google (Gemini) Configuration',
          _buildGoogleSettings(
            context,
            providerStatus[LLMProviderType.google] ?? false,
          ),
        ),
        const SizedBox(height: 24),
        _buildProviderCard(
          context,
          Icons.psychology,
          'Anthropic (Claude) Configuration',
          _buildAnthropicSettings(
            context,
            providerStatus[LLMProviderType.anthropic] ?? false,
          ),
        ),
        const SizedBox(height: 24),
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
        _buildProviderCard(
          context,
          Icons.computer,
          'Ollama Configuration',
          _buildOllamaSettings(
            context,
            providerStatus[LLMProviderType.ollama] ?? false,
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

  Widget _buildOllamaSettings(BuildContext context, bool isConfigured) {
    return Column(
      children: [
        _buildTextField(
          context,
          'Base URL',
          '',
          'Ollama server URL (default: http://localhost:11434)',
          _llmSettings.getOllamaBaseUrl(),
          (value) async {
            await _llmSettings.setOllamaBaseUrl(value);
            if (value.isNotEmpty) _fetchOllamaModels();
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        if (_isLoadingOllamaModels)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_ollamaModels.isNotEmpty) ...[
          _buildModelSelector(
            context,
            'Reasoning Model',
            _llmSettings.getOllamaReasoningModel(),
            _ollamaModels,
            (model) async {
              await _llmSettings.setOllamaReasoningModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildModelSelector(
            context,
            'Generation Model',
            _llmSettings.getOllamaGenerationModel(),
            _ollamaModels,
            (model) async {
              await _llmSettings.setOllamaGenerationModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
        ] else if (_llmSettings.getOllamaBaseUrl()?.isNotEmpty == true &&
            !_isLoadingOllamaModels)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No models found. Please check connectivity.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
              'Your OpenAI API key from https://platform.openai.com/api-keys',
          value: _llmSettings.getOpenAIApiKey() ?? '',
          obscuredValue: _llmSettings.getObscuredOpenAIApiKey(),
          onChanged: (value) async {
            await _llmSettings.setOpenAIApiKey(value);
            if (value.isNotEmpty) _fetchOpenAIModels();
            setState(() {});
          },
          onClear: () async {
            await _llmSettings.setOpenAIApiKey('');
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        if (_isLoadingOpenAIModels)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_openAIModels.isNotEmpty) ...[
          _buildModelSelector(
            context,
            'Reasoning Model',
            _llmSettings.getOpenAIReasoningModel(),
            _openAIModels,
            (model) async {
              await _llmSettings.setOpenAIReasoningModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildModelSelector(
            context,
            'Generation Model',
            _llmSettings.getOpenAIGenerationModel(),
            _openAIModels,
            (model) async {
              await _llmSettings.setOpenAIGenerationModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
        ] else if (_llmSettings.getOpenAIApiKey()?.isNotEmpty == true &&
            !_isLoadingOpenAIModels)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No models found. Please check your API key.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildGoogleSettings(BuildContext context, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApiKeyField(
          label: 'Google API Key',
          placeholder: 'AIzaSy...',
          description:
              'Your Google AI Studio API key from https://aistudio.google.com/app/apikey',
          value: _llmSettings.getGoogleApiKey() ?? '',
          obscuredValue: _llmSettings.getObscuredGoogleApiKey(),
          onChanged: (value) async {
            await _llmSettings.setGoogleApiKey(value);
            if (value.isNotEmpty) _fetchGoogleModels();
            setState(() {});
          },
          onClear: () async {
            await _llmSettings.setGoogleApiKey('');
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        if (_isLoadingGoogleModels)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_googleModels.isNotEmpty) ...[
          _buildModelSelector(
            context,
            'Reasoning Model',
            _llmSettings.getGoogleReasoningModel(),
            _googleModels,
            (model) async {
              await _llmSettings.setGoogleReasoningModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildModelSelector(
            context,
            'Generation Model',
            _llmSettings.getGoogleGenerationModel(),
            _googleModels,
            (model) async {
              await _llmSettings.setGoogleGenerationModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
        ] else if (_llmSettings.getGoogleApiKey()?.isNotEmpty == true &&
            !_isLoadingGoogleModels)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No models found. Please check your API key.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
          placeholder: 'sk-ant...',
          description:
              'Your Anthropic API key from https://console.anthropic.com/settings/keys',
          value: _llmSettings.getAnthropicApiKey() ?? '',
          obscuredValue: _llmSettings.getObscuredAnthropicApiKey(),
          onChanged: (value) async {
            await _llmSettings.setAnthropicApiKey(value);
            if (value.isNotEmpty) _fetchAnthropicModels();
            setState(() {});
          },
          onClear: () async {
            await _llmSettings.setAnthropicApiKey('');
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        if (_isLoadingAnthropicModels)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_anthropicModels.isNotEmpty) ...[
          _buildModelSelector(
            context,
            'Reasoning Model',
            _llmSettings.getAnthropicReasoningModel(),
            _anthropicModels,
            (model) async {
              await _llmSettings.setAnthropicReasoningModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildModelSelector(
            context,
            'Generation Model',
            _llmSettings.getAnthropicGenerationModel(),
            _anthropicModels,
            (model) async {
              await _llmSettings.setAnthropicGenerationModel(model);
              await _llmSettings.initializeLLMManager();
              setState(() {});
            },
          ),
        ] else if (_llmSettings.getAnthropicApiKey()?.isNotEmpty == true &&
            !_isLoadingAnthropicModels)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No models found. Please check your API key.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildOpenRouterSettings(BuildContext context, bool isConfigured) {
    final settingsColors = SettingsTheme.colors(context);

    // Fallback to empty if fetch fails - we enforce API key for OpenRouter now too for consistency
    final models = _openRouterModels.isNotEmpty
        ? _openRouterModels.map((e) => e.id).toList()
        : <String>[];

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
          onChanged: (value) async {
            await _llmSettings.setOpenRouterApiKey(value);
            if (value.isNotEmpty) {
              _fetchOpenRouterModels(); // Fetch models when API key is set
            }
            if (mounted) setState(() {});
          },
          onClear: () {
            _llmSettings.setOpenRouterApiKey('');
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 16),
        if (_isLoadingModels)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: settingsColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Fetching available models...',
                  style: SettingsTheme.inputText(context),
                ),
              ],
            ),
          ),

        if (models.isNotEmpty) ...[
          // Reasoning Model
          _buildOpenRouterModelSelector(
            context,
            'Reasoning Model',
            _llmSettings.getOpenRouterReasoningModel(),
            (model) async {
              await _llmSettings.setOpenRouterReasoningModel(model);
              await _llmSettings.initializeLLMManager();
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Generation Model
          _buildOpenRouterModelSelector(
            context,
            'Generation Model',
            _llmSettings.getOpenRouterGenerationModel(),
            (model) async {
              await _llmSettings.setOpenRouterGenerationModel(model);
              await _llmSettings.initializeLLMManager();
              if (mounted) setState(() {});
            },
          ),
        ] else if (_llmSettings.hasOpenRouterApiKey() && !_isLoadingModels)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No models found. Please check your API key.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildOpenRouterModelSelector(
    BuildContext context,
    String label,
    String currentModel,
    Function(String) onChanged,
  ) {
    if (_openRouterModels.isEmpty) {
      // Fallback to simple selector if no metadata
      return _buildModelSelector(
        context,
        label,
        currentModel,
        _llmSettings.getAvailableOpenRouterModels(),
        onChanged,
      );
    }

    final settingsColors = SettingsTheme.colors(context);

    // Ensure current model is in list or add it if missing (custom)
    final models = List<OpenRouterModelInfo>.from(_openRouterModels);

    // Check if current model exists in the list (by ID)
    final hasCurrentModel = models.any((m) => m.id == currentModel);

    if (!hasCurrentModel && currentModel.isNotEmpty) {
      // Add placeholder info for current model if not found
      models.insert(
        0,
        OpenRouterModelInfo(
          id: currentModel,
          name: currentModel,
          description: 'Custom',
          contextLength: 0,
          pricing: PromptPricing(prompt: '0', completion: '0'), // Unknown
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SettingsTheme.inputLabel(context)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: models.any((m) => m.id == currentModel) ? currentModel : null,
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
          items: models.map((info) {
            final isFree = info.isFree;
            return DropdownMenuItem<String>(
              value: info.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      info.name.isEmpty ? info.id : info.name,
                      style: SettingsTheme.inputText(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFree)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Free',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
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
          isExpanded: true,
          value: availableModels.contains(currentModel)
              ? currentModel
              : (availableModels.isNotEmpty ? availableModels.first : null),
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
