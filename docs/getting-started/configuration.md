# Configuration Guide

This guide covers how to configure Searvo for optimal performance.

## LLM Provider Configuration

Searvo supports multiple LLM (Large Language Model) providers. You need to configure at least one provider to use AI-powered search features.

### Supported Providers

1. **OpenAI** (GPT-3.5, GPT-4, etc.)
2. **Google** (Gemini models)
3. **Anthropic** (Claude models)
4. **Ollama** (Local LLM hosting)
5. **OpenRouter** (Access to multiple models)

### Configuration Steps

1. **Open Settings**
   - Navigate to the Settings screen
   - Select "LLM Provider Settings"

2. **Choose Your Provider**
   - Select from the available providers
   - Each provider has different requirements

3. **Enter API Credentials**
   
   #### OpenAI
   - API Key: Get from [OpenAI Platform](https://platform.openai.com/)
   - Base URL: Default is `https://api.openai.com/v1` (optional)
   - Model: Choose from available models (gpt-4, gpt-3.5-turbo, etc.)

   #### Google (Gemini)
   - API Key: Get from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Model: gemini-pro, gemini-pro-vision, etc.

   #### Anthropic (Claude)
   - API Key: Get from [Anthropic Console](https://console.anthropic.com/)
   - Model: claude-3-opus, claude-3-sonnet, claude-2, etc.

   #### Ollama (Local)
   - Base URL: Default is `http://localhost:11434`
   - Model: Any model you've pulled (llama2, mistral, etc.)
   - Installation: [Install Ollama](https://ollama.ai/)
   
   #### OpenRouter
   - API Key: Get from [OpenRouter](https://openrouter.ai/)
   - Model: Choose from 100+ available models
   - Base URL: `https://openrouter.ai/api/v1`

4. **Test Connection**
   - Use the test feature to verify your configuration
   - Make sure you have an active internet connection (except for Ollama)

### API Key Security

⚠️ **Important**: API keys are stored locally using Flutter's secure storage. Never commit API keys to version control.

- Keys are encrypted at rest
- Keys are not transmitted anywhere except to the respective LLM provider
- You can clear keys anytime from settings

## Search Provider Configuration

Configure the backend search engine for web searches.

### SearXNG (Recommended)

SearXNG is a privacy-respecting metasearch engine.

#### Using Docker (Included)
```bash
docker-compose up -d
```
- Default URL: `http://localhost:8080`

#### Using Public Instance
- Find instances at [searx.space](https://searx.space/)
- Enter the instance URL in Search Provider Settings

#### Configuration in Searvo
1. Go to Settings → Search Provider Settings
2. Enter SearXNG URL
3. Test connection

## Voice Configuration

Configure voice input and output features.

### Voice Input (Speech-to-Text)

1. **Grant Permissions**
   - Android: Microphone permission will be requested on first use
   - iOS: Microphone permission required
   - Desktop: System microphone access needed

2. **Language Settings**
   - Default: System language
   - Customizable in Voice Settings
   - Supports multiple languages

### Voice Output (Text-to-Speech)

1. **TTS Engine**
   - Uses system TTS engine
   - Android: Google TTS recommended
   - iOS: Built-in Siri voices
   - Desktop: System TTS

2. **Voice Settings**
   - Speech rate: Adjust speed of speech
   - Pitch: Adjust voice pitch
   - Volume: Control output volume

## Application Settings

### Theme Settings

- **Light Mode**: Bright, high-contrast interface
- **Dark Mode**: Reduced eye strain for low-light environments
- **System Default**: Follow system theme preferences

### Privacy Settings

- **Auto-save searches**: Save search history automatically
- **Clear history**: Remove all saved searches
- **Anonymous mode**: Don't save any search data

### Advanced Settings

#### Website Mappings

Configure shortcuts for quick site-specific searches using @mentions:

```
@youtube search term → Searches YouTube
@github search term → Searches GitHub
@wiki search term → Searches Wikipedia
```

Add custom mappings in Settings → Advanced → Website Mappings

#### Export/Import Settings

- Export your configuration as JSON
- Import settings on new devices
- Backup your LLM provider configs (without API keys)

## Environment Variables (Optional)

For advanced users, you can set default configurations using environment variables:

```bash
export SEARVO_OPENAI_API_KEY="your-key-here"
export SEARVO_SEARCH_PROVIDER="http://localhost:8080"
export SEARVO_DEFAULT_MODEL="gpt-4"
```

## Configuration Files

Settings are stored in:
- Android: `SharedPreferences`
- iOS: `UserDefaults`
- Desktop/Linux: `~/.local/share/searvo/`
- Desktop/macOS: `~/Library/Application Support/searvo/`
- Desktop/Windows: `%APPDATA%\searvo\`

## Best Practices

1. **Start with Ollama** if you want free, local AI without API costs
2. **Use OpenRouter** for access to multiple models with one API key
3. **Keep API keys secure** - never share them
4. **Test thoroughly** after configuration changes
5. **Monitor API usage** to avoid unexpected costs

## Troubleshooting

### LLM Provider Issues

**Problem**: "API Key Invalid"
- Verify key is correct
- Check key hasn't expired
- Ensure proper formatting (no extra spaces)

**Problem**: "Connection Failed"
- Check internet connection
- Verify base URL is correct
- Check firewall settings

**Problem**: "Model Not Found"
- Verify model name spelling
- Check model availability for your account
- Some models require specific API tiers

### Voice Issues

**Problem**: Voice input not working
- Grant microphone permission
- Check microphone hardware
- Try restarting the app

**Problem**: No audio output
- Check system volume
- Verify TTS engine installed
- Check app audio permissions

## Next Steps

- [Overview](overview.md) - Learn about Searvo's features
- [AI Search](../features/ai-search.md) - Using the search features
- [Voice Interaction](../features/voice-interaction.md) - Voice commands

## Support

Need help? Visit our [GitHub Discussions](https://github.com/kamranxdev/searvo/discussions)
