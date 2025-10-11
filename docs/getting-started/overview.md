# Overview

Welcome to Searvo - an open-source, AI-powered search application built with Flutter. Searvo combines the power of modern LLMs (Large Language Models) with advanced RAG (Retrieval-Augmented Generation) capabilities to provide intelligent, conversational search experiences.

## What is Searvo?

Searvo is more than just a search engine. It's an intelligent research assistant that:

- 🔍 **Understands context** - Maintains conversation history for follow-up questions
- 🤖 **AI-powered responses** - Uses LLMs to synthesize information from multiple sources
- 🗣️ **Voice-enabled** - Speak your queries and hear responses
- 🌐 **Web scraping** - Extracts full content from web pages for comprehensive analysis
-  **Privacy-first** - All data stored locally, you control your API keys
- 🎨 **Beautiful UI** - Modern, responsive design across all platforms

## Key Features

### 1. AI-Powered Search (RAG)

Searvo uses Retrieval-Augmented Generation (RAG) to provide accurate, contextual answers:

1. **Query Understanding** - Analyzes your question to understand intent
2. **Web Search** - Searches the web using SearXNG for relevant sources
3. **Content Extraction** - Scrapes full content from search results
4. **AI Synthesis** - LLM analyzes content and generates comprehensive answers
5. **Source Citation** - Provides links to original sources

**Example:**
```
You: "What are the latest developments in quantum computing?"
Searvo: [Searches web, analyzes articles, synthesizes information]
       "Recent advances in quantum computing include..."
       [Shows source links]
```

### 2. Multi-Provider LLM Support

Choose from multiple AI providers based on your needs:

| Provider | Best For | Cost |
|----------|----------|------|
| **OpenAI** | High-quality responses, GPT-4 | Paid API |
| **Google Gemini** | Fast, cost-effective | Paid API |
| **Anthropic Claude** | Long context, analysis | Paid API |
| **Ollama** | Privacy, no API costs | Free (local) |
| **OpenRouter** | Access to 100+ models | Paid API |

### 3. Voice Interaction

Natural voice conversations with your search assistant:

- **Voice Input** - Speak your questions naturally
- **Voice Output** - Hear responses read aloud
- **Continuous Conversation** - Hands-free interaction
- **Multi-language Support** - Works in multiple languages

### 4. Advanced Features

#### Website-Specific Search

Use @mentions for targeted searches:
- `@youtube machine learning` - Search YouTube
- `@github flutter packages` - Search GitHub
- `@wiki quantum physics` - Search Wikipedia

#### Multi-Search

Ask questions that combine multiple sources:
```
"Compare @github trending repos with @hackernews top stories"
```

#### Context-Aware Follow-ups

Searvo remembers conversation context:
```
You: "Tell me about Mars"
Searvo: [Provides information about Mars]
You: "What about its moons?"
Searvo: [Understands "its" refers to Mars]
```

## Architecture Overview

Searvo is built with a clean, modular architecture:

```
searvo/
├── lib/
│   ├── core/              # Core functionality
│   │   ├── config/        # App configuration
│   │   ├── routing/       # Navigation and routing
│   │   ├── theme/         # Theme and styling
│   │   └── utils/         # Utility functions
│   ├── features/          # Feature modules
│   │   ├── home/          # Home screen
│   │   ├── search/        # Search functionality
│   │   ├── llm/           # LLM integration
│   │   ├── voice/         # Voice features
│   │   ├── settings/      # Settings management
│   │   └── weather/       # Weather integration
│   └── shared/            # Shared components
│       ├── navigation/    # Navigation widgets
│       └── widgets/       # Reusable widgets
```

### Technology Stack

- **Framework**: Flutter 3.8+
- **Language**: Dart 3.8+
- **State Management**: Provider pattern
- **Routing**: GoRouter
- **LLM Integration**: LangChain packages
- **Storage**: SharedPreferences
- **HTTP**: http package
- **Voice**: speech_to_text, flutter_tts

## Use Cases

### Research & Learning
- Academic research
- Technical documentation exploration
- Learning new topics with context

### Professional Use
- Market research
- Competitive analysis
- Technical problem-solving
- Documentation exploration

### Personal Use
- Travel planning
- Shopping research
- General knowledge queries

## Privacy & Security

Searvo is designed with privacy in mind:

- ✅ **Local storage** - All data stored on your device
- ✅ **No tracking** - No analytics or user tracking
- ✅ **API key control** - You manage your own API keys
- ✅ **Open source** - Code is transparent and auditable
- ✅ **No account required** - Use immediately without signing up

### Data Flow

1. **Your query** → Stored locally
2. **Search request** → SearXNG (privacy-respecting)
3. **Web scraping** → Direct to websites
4. **LLM request** → Your configured provider (with your API key)
5. **Response** → Stored locally

Searvo never sends your data to any Searvo servers because there are none!

## Platform Support

Searvo runs on all major platforms:

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Linux** (GTK)
- ✅ **macOS** (10.14+)
- ✅ **Windows** (Windows 10+)

## Getting Started

Ready to start? Follow these steps:

1. **[Install Searvo](installation.md)** - Set up the development environment
2. **[Configure Providers](configuration.md)** - Set up your LLM provider
3. **[Explore Features](../features/ai-search.md)** - Learn about search features
4. **[Contribute](../development/contributing.md)** - Help improve Searvo

## Community & Support

Join our growing community:

- 💬 **[GitHub Discussions](https://github.com/kamranxdev/searvo-community/discussions)** - Ask questions, share ideas
- 🐛 **[Issue Tracker](https://github.com/kamranxdev/searvo-community/issues)** - Report bugs, request features
- 💭 **[Discord](https://discord.gg/Bq67m6NYaa)** - Real-time chat with developers and users

## Contributing

Searvo is built by the community, for the community. We welcome contributions!

- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 💻 Submit pull requests

See our [Contributing Guide](../development/contributing.md) for details.

## License

Searvo is open-source software licensed under the [MIT License](../../LICENSE).

## What's Next?

- **[Installation Guide](installation.md)** - Get Searvo running
- **[Configuration Guide](configuration.md)** - Set up your preferences
- **[AI Search Features](../features/ai-search.md)** - Learn advanced search techniques
- **[Architecture Guide](../architecture/project-structure.md)** - Understand the codebase


## What is Searvo?

Searvo is an open-source Flutter-based AI-powered search application with advanced RAG (Retrieval-Augmented Generation) capabilities. The app provides conversational search with voice-enabled interactions, intelligent query understanding, multi-type search capabilities, and comprehensive web scraping for full-context AI responses.

Built by the community, for the community - Searvo puts you in control of your search experience with privacy-first design and transparent, open-source code.

## 🚀 Key Features

### Advanced Search Capabilities
- **Multi-Type Search**: General, News, Scholar, Shopping, Images, and Videos
- **Recency Filters**: Day, Week, Month, Year temporal filtering
- **Query Analysis**: Automatic intent detection and complexity assessment
- **Sub-Query Decomposition**: Break down complex queries automatically
- **Web Scraping**: Extract full article content (1000s of words vs snippets)
- **PDF Extraction**: Extract text from PDF documents
- **Multiple Providers**: SearXNG, SerpAPI support

### AI-Powered Features
- **RAG Pipeline**: Advanced Retrieval-Augmented Generation with context-aware responses
- **Context Fusion**: Intelligent context building from multiple sources
- **Citation Management**: Automatic source attribution and verification
- **LLM Integration**: OpenAI, Google, Anthropic, Ollama support
- **Streaming Responses**: Real-time answer generation

### User Experience
- Voice input helpers and diagnostics
- Search UI and search results screens
- Message-based UI
- Settings and theming (dark/light modes)
- Performance tracking and metrics

### Developer-Friendly
- Clean API design with comprehensive documentation
- Type-safe implementations
- Performance metrics tracking
- Complete usage examples

## 🎯 Why Searvo?

Searvo is built with privacy and transparency in mind:

- **🔓 Open Source**: Full transparency - inspect, modify, and contribute to the code
- **🔒 Privacy-First**: No tracking, no data collection without consent
- **🚀 Self-Hosted Option**: Run your own search infrastructure with SearXNG
- **🤖 AI Integration**: Bring your own API keys for AI features
- **📱 Cross-Platform**: Works on Android, iOS, Web, Desktop
- **⚡ Fast & Efficient**: Optimized for performance and battery life

Unlike proprietary search apps, Searvo gives you control over your data and search experience.

## Prerequisites

- Flutter SDK (stable) — follow the official install guide: https://docs.flutter.dev/get-started/install
- Platform toolchains for your target(s):
	- Android: Android SDK, platform tools, emulator or device
	- iOS (macOS only): Xcode and CocoaPods
	- Web: Chrome (or other supported browser)

Verify your environment:

```bash
# show flutter version and environment info
flutter --version
flutter doctor -v
```

## Quick Start

1. **Clone the repository:**
```bash
git clone https://github.com/kamranxdev/searvo-community.git
cd searvo-community
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Configure API Keys (Optional):**
   
   Searvo works without API keys for basic search functionality. For enhanced AI features, configure API keys in the app settings:
   
   - **OpenAI API Key**: For GPT models
   - **Google AI API Key**: For Gemini models  
   - **Anthropic API Key**: For Claude models
   - **OpenRouter API Key**: For access to multiple AI models
   - **SerpAPI Key**: For enhanced web search results

4. **Run the app:**
```bash
# List available devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device-id>
```

5. **Run tests:**
```bash
flutter test
```

6. **Code quality:**
```bash
flutter analyze
flutter format .
```

## Building

- Android (release APK):

```bash
flutter build apk --release
```

- Android (release AAB for Google Play Store):

```bash
flutter build appbundle --release
```

- iOS (macOS only):

```bash
flutter build ios --release
```

- Web:

```bash
flutter build web
```

## Project layout (important paths)

- `lib/` — main application code and UI widgets
	- `main.dart` — app entrypoint
	- `components/` — smaller UI and helpers
	- `core/` — app-level configuration, routing, services (e.g., `app_config.dart`, `app_router.dart`)
	- `screens/` — top-level screens for navigation
	- `services/` — background services like `weather_service.dart`, `cache_manager.dart`
	- `widgets/` — reusable widgets
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` — platform directories generated by Flutter
- `test/` — unit and widget tests

## Development notes and tips

- Keep platform-specific credentials and secrets out of the repository. Use environment variables or secure storage.
- When adding native plugins, follow the plugin's install instructions and re-run `flutter pub get`.
- Prefer small, focused commits and include test updates when changing public behavior.

## Contributing

We welcome contributions from the community! Here's how you can help:

### Ways to Contribute
- 🐛 **Bug Reports**: Found a bug? [Open an issue](https://github.com/kamranxdev/searvo-community/issues/new?template=bug_report.md)
- ✨ **Feature Requests**: Have an idea? [Suggest it here](https://github.com/kamranxdev/searvo-community/issues/new?template=feature_request.md)
- 💻 **Code Contributions**: See our [Contributing Guide](CONTRIBUTING.md)
- 📖 **Documentation**: Help improve docs and examples
- 🧪 **Testing**: Add tests or report test failures

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes and add tests
4. Ensure all tests pass: `flutter test`
5. Format code: `flutter format .`
6. Submit a pull request

### Code Guidelines
- Follow Flutter's [style guide](https://flutter.dev/docs/development/tools/formatting)
- Write tests for new features
- Update documentation for API changes
- Keep commits focused and descriptive

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The MIT License allows you to:
- ✅ Use commercially
- ✅ Modify and distribute
- ✅ Use privately
- ✅ Include in your own projects

Just include the original copyright notice in any copy of the software.

## 🤝 Community & Support

- 📧 **Discussions**: Join community discussions on [GitHub Discussions](https://github.com/kamranxdev/searvo-community/discussions)
- 💬 **Discord**: Chat with the community on our [Discord server](https://discord.gg/Bq67m6NYaa)
- 🐛 **Issues**: Report bugs or request features on [GitHub Issues](https://github.com/kamranxdev/searvo-community/issues)
- 📖 **Documentation**: Full documentation available at [docs.searvo.app](https://docs.searvo.app)

## 📊 Project Status

Searvo is actively maintained and open for contributions. Current focus areas:

- 🔍 **Search Quality**: Improving search result relevance and speed
- 🤖 **AI Integration**: Adding support for more LLM providers
- 📱 **Platform Support**: Expanding to more platforms and devices
- 🎨 **UI/UX**: Enhancing user experience and accessibility
- 🔒 **Privacy**: Ensuring user data protection and transparency

### Recent Updates
- ✅ Removed proprietary dependencies (Firebase, authentication)
- ✅ Open-sourced core search functionality
- ✅ Added comprehensive API key management
- ✅ Improved documentation and setup instructions
- 🚧 Working on: Enhanced offline capabilities, more AI providers

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Open-source community for inspiration and tools
- Contributors who help make Searvo better

## Advanced Search Features

Searvo now includes advanced search capabilities that rival Perplexity AI's quality. These features provide comprehensive query understanding, full-context extraction, and multi-source intelligence.

### 1. Multi-Type Search

Search across different content types with specialized handling:

```dart
import 'package:searvo/services/search/search_service.dart';
import 'package:searvo/services/search/provider/base_search_provider.dart';

final searchService = SearchService();
await searchService.initialize();

// News search with recency filter
final news = await searchService.searchByType(
  query: "AI developments",
  searchType: SearchType.news,
  recency: SearchRecency.day,
  maxResults: 20,
);

// Academic papers
final papers = await searchService.searchByType(
  query: "machine learning research",
  searchType: SearchType.scholar,
);

// Shopping and product reviews
final products = await searchService.searchByType(
  query: "best laptops 2024",
  searchType: SearchType.shopping,
);

// Image discovery
final images = await searchService.searchByType(
  query: "quantum physics visualization",
  searchType: SearchType.images,
);
```

**Available Search Types:**
- `SearchType.general` - Comprehensive web search
- `SearchType.news` - Latest news articles
- `SearchType.scholar` - Academic papers and research
- `SearchType.shopping` - Products, reviews, prices
- `SearchType.images` - Image discovery
- `SearchType.videos` - Video content

**Recency Filters:**
- `SearchRecency.any` - No time restriction
- `SearchRecency.day` - Last 24 hours
- `SearchRecency.week` - Last 7 days
- `SearchRecency.month` - Last 30 days
- `SearchRecency.year` - Last year

### 2. Query Analysis

Automatic intent detection, complexity assessment, and sub-query generation:

```dart
final analysis = searchService.analyzeQuery(
  "Compare Python vs JavaScript for web development in 2024",
);

print('Intent: ${analysis.intentType}');
// Output: comparison

print('Complexity: ${analysis.complexity['level']}');
// Output: high

print('Sub-queries: ${analysis.subQueries}');
// Output: ["Python web development 2024", "JavaScript web development 2024"]

print('Suggested types: ${analysis.suggestedSearchTypes}');
// Output: [SearchType.general, SearchType.news]

print('Keywords: ${analysis.keywords}');
print('Entities: ${analysis.entities}');
```

**Intent Types Detected:**
- `informational` - Seeking knowledge or facts
- `comparison` - Comparing multiple items
- `how-to` - Step-by-step instructions
- `definition` - Word or concept definitions
- `temporal` - Time-sensitive queries
- `local` - Location-based queries
- `transactional` - Purchase or action intents

### 3. Web Scraping

Extract full article content instead of just snippets (150-200 characters). This dramatically improves AI answer quality:

```dart
// Scrape a single URL
final content = await searchService.scrapeUrl(
  url: "https://example.com/article",
  includeImages: true,
  includeLinks: true,
);

print('Title: ${content.title}');
print('Author: ${content.author}');
print('Content: ${content.content}'); // Full article text (1000s of words)
print('Images: ${content.images.length}');
print('Links: ${content.links.length}');
print('Published: ${content.publishDate}');

// Scrape multiple URLs in parallel
final urls = [
  "https://example1.com/article",
  "https://example2.com/article",
  "https://example3.com/article",
];

final contents = await searchService.scrapeMultipleUrls(
  urls,
  maxConcurrent: 3,  // Control parallel requests
);

for (final content in contents) {
  print('${content.url}: ${content.content.length} characters');
}
```

**Benefits:**
- Extract 1000s of words vs 150-200 character snippets
- Get article metadata (author, publish date, description)
- Include images and links for richer context
- Batch processing with rate limiting

### 4. PDF Extraction

Extract text from PDF documents for research and documentation:

```dart
final pdfContent = await searchService.extractPdfContent(
  "https://example.com/research-paper.pdf",
);

print('Pages: ${pdfContent.pageCount}');
print('Text: ${pdfContent.text}');
print('Metadata: ${pdfContent.metadata}');
```

### 5. AI-Powered Answers with Full Context

Generate comprehensive answers using the enhanced search pipeline:

```dart
final answer = await searchService.generateSearchResponse(
  "What are the differences between transformers and LSTMs in deep learning?",
  maxSearchResults: 25,           // More results for better coverage
  maxRelevantDocuments: 12,       // Top documents for context
  enableQueryEnhancement: true,   // Auto-enhance vague queries
);

print('Answer: ${answer.answer}');
print('Sources used: ${answer.sources.length}');
print('Citations: ${answer.citedSources}');
print('Related questions: ${answer.relatedQuestions}');
print('Confidence: ${answer.metadata?['confidence']}');
```

**The Complete Pipeline:**

```
User Query
    ↓
Query Analyzer (Intent, Complexity, Sub-queries)
    ↓
Multi-Type Search (News, Scholar, Images, etc.)
    ↓
Document Ranking (Multi-signal scoring)
    ↓
Web Scraping (Full content from top URLs)
    ↓
Context Fusion (Optimal context building)
    ↓
LLM Generation (AI-powered answer)
    ↓
Citation Validation
    ↓
Final Response
```

### 6. Complete Examples

Check out comprehensive examples in:
- `lib/services/search/search_examples.dart` - Complete usage examples

### 7. Search Provider Configuration

All two search providers support the new features:

**SearXNG (Self-Hosted):**
```dart
// Configure in app settings
// Supports: all search types with category mapping
// Endpoint: http://your-searxng-instance.com
```

**SerpAPI (Requires API Key):**
```dart
// Configure API key in environment
// Supports: all search types via Google services
// Best coverage but requires subscription
```

### Performance and Metrics

The system tracks performance metrics:

```dart
final status = searchService.getStatus();
print('Success rate: ${status['statistics']['successRate']}');
print('Total searches: ${status['statistics']['totalSearches']}');
print('Active provider: ${status['activeProvider']}');
print('Cached results: ${status['cacheHitRate']}');
```

## RAG System Architecture

Searvo implements a sophisticated Retrieval-Augmented Generation (RAG) system for providing context-aware search responses. The system follows best practices for prompt engineering to ensure high-quality, accurate answers.

### Components

- **Search Aggregator** (`lib/services/search/search_aggregator.dart`): Aggregates results from multiple search providers
- **Document Ranker** (`lib/services/search/document_ranker.dart`): Ranks and filters search results by relevance
- **Context Fusion** (`lib/services/search/context_fusion.dart`): Fuses relevant document chunks into coherent context
- **Prompt Engineer** (`lib/services/search/prompt_engineer.dart`): Applies advanced prompting techniques based on web search model best practices
- **Citation Manager** (`lib/services/search/citation_manager.dart`): Manages source citations and references
- **RAG Orchestrator** (`lib/services/search/rag_orchestrator.dart`): Coordinates the entire RAG pipeline

### Prompt Engineering Features

The system incorporates prompting guidelines inspired by advanced web search models:

- **System Prompts**: Clear instructions for factual, cited responses
- **Context-Aware User Prompts**: Structured prompts that include search results with proper formatting
- **Query Validation**: Checks for query specificity and provides improvement suggestions
- **Query Enhancement**: Automatically improves vague queries for better search results
- **Fallback Handling**: Graceful degradation when search results are insufficient

### Best Practices Implemented

- Be specific and contextual in prompts
- Avoid few-shot prompting that could confuse search
- Structure prompts to guide toward relevant content
- Include clear instructions for source citation
- Prevent hallucination by requiring context-based answers

### Usage

```dart
final orchestrator = RAGOrchestrator();

// Validate query quality
final validation = orchestrator.validateQuery('What is AI?');
if (!validation['isValid']) {
  print('Suggestions: ${validation['suggestions']}');
}

// Enhance query if needed
final enhancedQuery = orchestrator.enhanceQuery('AI');

// Generate RAG response
final response = await orchestrator.generateRAGResponse(enhancedQuery);
```