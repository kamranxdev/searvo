# Multi-Provider Support

Searvo supports multiple LLM (Large Language Model) providers, giving you flexibility to choose the best model for your needs based on cost, performance, and privacy requirements.

## Supported Providers

### 1. OpenAI

The most popular LLM provider with powerful models.

**Models:**
- GPT-4 Turbo
- GPT-4
- GPT-3.5 Turbo
- GPT-3.5

**Strengths:**
- High-quality responses
- Fast inference
- Excellent reasoning
- Good code generation

**Best For:**
- Professional use
- Complex queries
- Code assistance
- General knowledge

**Pricing:**
- Pay per token
- GPT-4: ~$0.03-0.06 per 1K tokens
- GPT-3.5: ~$0.001-0.002 per 1K tokens

**Setup:**
```
1. Get API key from platform.openai.com
2. Enter in Settings → LLM Provider
3. Choose model
4. Start searching
```

### 2. Google (Gemini)

Google's latest LLM models.

**Models:**
- Gemini Pro
- Gemini Pro Vision
- Gemini Ultra (coming soon)

**Strengths:**
- Fast responses
- Multimodal (text + images)
- Cost-effective
- Good context window

**Best For:**
- Budget-conscious users
- Fast queries
- Multimodal tasks
- High volume use

**Pricing:**
- Free tier available
- Pro: ~$0.00025 per 1K tokens
- Very cost-effective

**Setup:**
```
1. Get API key from makersuite.google.com
2. Enter in Settings → LLM Provider
3. Select Gemini Pro
4. Start searching
```

### 3. Anthropic (Claude)

Known for helpful, harmless, and honest responses.

**Models:**
- Claude 3 Opus
- Claude 3 Sonnet
- Claude 3 Haiku
- Claude 2

**Strengths:**
- Large context window (100K+ tokens)
- Excellent analysis
- Safety-focused
- Long-form content

**Best For:**
- Deep research
- Document analysis
- Long conversations
- Detailed explanations

**Pricing:**
- Opus: ~$0.015-0.075 per 1K tokens
- Sonnet: ~$0.003-0.015 per 1K tokens
- Haiku: ~$0.00025-0.00125 per 1K tokens

**Setup:**
```
1. Get API key from console.anthropic.com
2. Enter in Settings → LLM Provider
3. Choose Claude model
4. Start searching
```

### 4. Ollama (Local)

Run LLMs locally on your own hardware.

**Models:**
- Llama 2 (7B, 13B, 70B)
- Mistral (7B)
- CodeLlama
- Neural-Chat
- Many more via ollama.ai/library

**Strengths:**
- Complete privacy
- No API costs
- Offline capability
- Full control

**Best For:**
- Privacy-focused users
- Offline use
- Development/testing
- Cost-free operation

**Pricing:**
- FREE! (just hardware costs)

**Requirements:**
- 8GB+ RAM for 7B models
- 16GB+ RAM for 13B models
- 32GB+ RAM for 70B models

**Setup:**
```bash
# Install Ollama
curl https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama2

# Configure in Searvo
1. Settings → LLM Provider → Ollama
2. Base URL: http://localhost:11434
3. Model: llama2
4. Start searching
```

### 5. OpenRouter

Access 100+ models through one API.

**Available Models:**
- OpenAI models
- Anthropic models
- Google models
- Meta Llama
- Mistral
- And many more...

**Strengths:**
- One API for many models
- Competitive pricing
- Fallback options
- Model comparison

**Best For:**
- Trying different models
- Model flexibility
- Cost optimization
- Single API key management

**Pricing:**
- Varies by model
- Often cheaper than direct
- Pay only for usage

**Setup:**
```
1. Get API key from openrouter.ai
2. Enter in Settings → LLM Provider
3. Choose from 100+ models
4. Start searching
```

## Comparison

| Provider | Cost | Speed | Quality | Context | Privacy |
|----------|------|-------|---------|---------|---------|
| OpenAI | $$$ | Fast | Excellent | 8-128K | Cloud |
| Google | $ | Very Fast | Good | 32K | Cloud |
| Anthropic | $$ | Fast | Excellent | 100K | Cloud |
| Ollama | FREE | Varies | Good | Varies | Local |
| OpenRouter | Varies | Fast | Varies | Varies | Cloud |

## Configuration

### Adding a Provider

1. **Navigate to Settings**
   - Open Settings
   - Select "LLM Provider Settings"

2. **Choose Provider**
   - Select from dropdown
   - Each has unique configuration

3. **Enter Credentials**

   **For API-based providers:**
   ```
   Provider: OpenAI
   API Key: sk-...
   Base URL: (optional)
   Model: gpt-4-turbo-preview
   ```

   **For Ollama:**
   ```
   Provider: Ollama
   Base URL: http://localhost:11434
   Model: llama2
   ```

4. **Test Connection**
   - Use built-in test feature
   - Verifies credentials
   - Checks model availability

5. **Save Configuration**
   - Settings saved securely
   - Ready to use

### Switching Providers

Switch providers anytime:

1. Open Settings
2. Select different provider
3. Enter credentials
4. Existing searches preserved

### Multiple Configurations

Save multiple provider configs:
- Different API keys
- Different models
- Quick switching
- Comparison testing

## Model Selection

### Choosing the Right Model

**For Speed:**
- GPT-3.5 Turbo
- Gemini Pro
- Claude Haiku
- Mistral 7B (Ollama)

**For Quality:**
- GPT-4 Turbo
- Claude 3 Opus
- GPT-4
- Llama 2 70B (Ollama)

**For Cost:**
- Gemini Pro (cheapest cloud)
- Ollama (free local)
- Claude Haiku
- GPT-3.5 Turbo

**For Privacy:**
- Ollama (local only)
- Self-hosted options
- Private API instances

**For Long Context:**
- Claude 3 (100K tokens)
- GPT-4 Turbo (128K tokens)
- Gemini Pro (32K tokens)

### Model Parameters

Configure model behavior:

```yaml
Temperature: 0.0 - 1.0
  - 0.0: Deterministic
  - 0.5: Balanced
  - 1.0: Creative

Max Tokens: 100 - 4000
  - Controls response length
  - Higher = longer responses
  - Costs more

Top P: 0.0 - 1.0
  - Nucleus sampling
  - Usually 1.0 or 0.95

Frequency Penalty: -2.0 - 2.0
  - Reduces repetition
  - Usually 0.0 - 0.3
```

## Cost Management

### Token Usage

Monitor your spending:

```
Current Session:
- Provider: OpenAI
- Model: GPT-4
- Tokens Used: 12,453
- Estimated Cost: $0.37

This Month:
- Total Tokens: 234,567
- Estimated Cost: $7.02
```

### Cost Controls

Set spending limits:

**Token Limits:**
- Max tokens per search
- Daily token limit
- Monthly budget

**Auto-Switch:**
- Fallback to cheaper model
- Switch when limit reached
- Alert before switching

### Cost Optimization

Tips to reduce costs:

1. **Use cheaper models** for simple queries
2. **Enable caching** to avoid repeated requests
3. **Limit context window** size
4. **Use Ollama** for development/testing
5. **Monitor usage** regularly

## Performance

### Response Times

Typical response times:

| Provider | Model | Speed |
|----------|-------|-------|
| OpenAI | GPT-3.5 | 1-2s |
| OpenAI | GPT-4 | 3-5s |
| Google | Gemini | 1-2s |
| Anthropic | Claude 3 | 2-4s |
| Ollama | 7B | 2-10s |
| Ollama | 13B | 5-20s |

*Times vary based on hardware and network*

### Optimization

Improve performance:

**For Cloud Providers:**
- Choose closer regions
- Use faster models
- Enable HTTP/2
- Increase timeout

**For Ollama:**
- Use GPU acceleration
- Smaller models (7B)
- Optimize memory
- Use quantized models

## Privacy & Security

### API Key Security

Searvo protects your keys:
- Encrypted storage
- Never logged
- Not transmitted elsewhere
- User-controlled

### Data Privacy

| Provider | Data Handling | Storage |
|----------|---------------|---------|
| OpenAI | 30-day retention | Cloud |
| Google | As per policy | Cloud |
| Anthropic | Not used for training | Cloud |
| Ollama | Fully local | Local |

### Privacy Tips

1. **Use Ollama** for sensitive queries
2. **Read provider policies** before use
3. **Clear API keys** when not needed
4. **Monitor API logs** at provider
5. **Use separate keys** for testing

## Troubleshooting

### Connection Issues

**Problem**: "Connection Failed"

**Solutions:**
- Check internet connection
- Verify API key
- Check base URL
- Try different endpoint
- Check firewall

### Authentication Errors

**Problem**: "Invalid API Key"

**Solutions:**
- Verify key is correct
- Check for extra spaces
- Ensure key not expired
- Check account status
- Generate new key

### Model Errors

**Problem**: "Model Not Found"

**Solutions:**
- Check model name spelling
- Verify model access
- Try different model
- Check API tier
- Contact provider

### Ollama Issues

**Problem**: Ollama not responding

**Solutions:**
```bash
# Check Ollama is running
ollama list

# Restart Ollama
ollama serve

# Pull model again
ollama pull llama2

# Check logs
journalctl -u ollama
```

## Best Practices

1. **Start with Free** - Try Ollama or Gemini first
2. **Test Models** - Compare before committing
3. **Monitor Costs** - Track token usage
4. **Use Right Model** - Match model to task
5. **Keep Keys Secure** - Rotate regularly

## Future Support

Coming soon:

- 🤖 More providers (HuggingFace, Cohere)
- 🔄 Automatic model selection
- 📊 Cost analytics dashboard
- 🎯 Model recommendation engine
- 🔌 Custom provider plugins

## Next Steps

- [Configuration Guide](../getting-started/configuration.md) - Detailed setup
- [AI Search](ai-search.md) - Use your configured provider
- [API Reference](../api/llm-providers.md) - Technical details
