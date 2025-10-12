<div align="center">

# Searvo - Proprietary Version

### AI-Powered Search with RAG Capabilities

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8+-0175C2.svg)](https://dart.dev)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](docs/development/contributing.md)

<p align="center">
  <strong>Open-source • Privacy-First • Multi-Platform</strong>
</p>

[Features](#features) • [Quick Start](#quick-start) • [Documentation](docs/) • [Contributing](docs/development/contributing.md)

</div>

---

## 🌟 What is Searvo?

Searvo is an open-source Flutter application that transforms web search into an intelligent conversation. By combining traditional search engines with advanced Large Language Models (LLMs) and RAG (Retrieval-Augmented Generation), Searvo provides comprehensive, contextual answers backed by real web sources.

**Built by the community, for the community** - with complete transparency and privacy control.

## ✨ Features

### 🤖 AI-Powered Search
- **RAG Pipeline** - Retrieves web content and generates intelligent responses
- **Multi-Source Analysis** - Combines information from multiple web sources
- **Conversational Context** - Maintains conversation history for follow-up questions
- **Source Citations** - Every answer includes links to original sources

### 🗣️ Voice Interaction
- **Voice Input** - Ask questions naturally using speech
- **Voice Output** - Hear responses read aloud with TTS
- **Hands-Free Mode** - Complete voice-only operation
- **Multi-Language** - Support for multiple languages

### 🔌 Multi-Provider LLM Support
Choose your preferred AI provider:
- **OpenAI** (GPT-3.5, GPT-4)
- **Google** (Gemini Pro)
- **Anthropic** (Claude 3)
- **Ollama** (Local, privacy-first)
- **OpenRouter** (100+ models)

### 🌐 Advanced Search
- **@Mentions** - Target specific sites (`@github`, `@youtube`, etc.)
- **Web Scraping** - Full content extraction for comprehensive analysis
- **Multi-Query** - Combine multiple searches
- **Context-Aware** - Understands follow-up questions

### 🎨 Beautiful & Responsive
- **Modern UI** - Clean, intuitive interface
- **Dark/Light Themes** - Easy on the eyes
- **Cross-Platform** - Android, iOS, Web, Linux, macOS, Windows
- **Responsive Design** - Adapts to any screen size

## 🚀 Quick Start

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.8.0 or higher
- [Dart](https://dart.dev/get-dart) 3.8.0 or higher

### Installation

```bash
# Clone the repository
git clone https://github.com/kamranxdev/searvo-community.git
cd searvo-community

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### First-Time Setup

1. **Launch Searvo** on your platform
2. **Configure LLM Provider** in Settings
   - Choose a provider (OpenAI, Google, Anthropic, Ollama, or OpenRouter)
   - Enter your API key (or use Ollama for free local AI)
3. **Start Searching!** 🎉

> 💡 **Tip**: Start with [Ollama](https://ollama.ai/) for free local AI, or try [Google Gemini](https://makersuite.google.com/) for generous free tier.

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Supported | API 21+ |
| iOS | ✅ Supported | iOS 12+ |
| Web | ✅ Supported | All modern browsers |
| Linux | ⚠️ Partially | GTK 3.0+ |
| macOS | ✅ Supported | 10.14+ |
| Windows | ✅ Supported | Windows 10+ |

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](docs/) directory:

### Getting Started
- **[Overview](docs/getting-started/overview.md)** - Introduction and concepts
- **[Installation](docs/getting-started/installation.md)** - Detailed setup guide
- **[Configuration](docs/getting-started/configuration.md)** - Configure LLM providers

### Features
- **[AI Search](docs/features/ai-search.md)** - RAG-powered search
- **[Voice Interaction](docs/features/voice-interaction.md)** - Voice features
- **[Web Scraping](docs/features/web-scraping.md)** - Content extraction
- **[Multi-Provider Support](docs/features/multi-provider-support.md)** - LLM providers

### Architecture
- **[Project Structure](docs/architecture/project-structure.md)** - Code organization
- **[Core Systems](docs/architecture/core-systems.md)** - Technical details

### Development
- **[Contributing Guide](docs/development/contributing.md)** - How to contribute
- **[Code Style](docs/development/code-style.md)** - Coding standards

## 🤝 Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

**Quick Links:**
- [Contributing Guide](docs/development/contributing.md)
- [Good First Issues](https://github.com/kamranxdev/searvo-community/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
- [Feature Requests](https://github.com/kamranxdev/searvo-community/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

## � Privacy & Security

Searvo is designed with privacy as a core principle:

- ✅ **Local Storage** - All data stored on your device
- ✅ **No Tracking** - Zero analytics or telemetry
- ✅ **API Control** - You manage your own API keys
- ✅ **Open Source** - Transparent, auditable code
- ✅ **No Account Required** - Use immediately

**Data Flow:** Your queries → Your chosen LLM provider (with your API key) → Back to you. No intermediary, no Searvo servers.

## 🛠️ Tech Stack

- **Framework**: Flutter 3.8+
- **Language**: Dart 3.8+
- **State Management**: Provider
- **Routing**: GoRouter
- **LLM Integration**: LangChain
- **Storage**: SharedPreferences
- **Voice**: speech_to_text, flutter_tts

## 🌐 Community

Join our growing community:

- 💬 **[GitHub Discussions](https://github.com/kamranxdev/searvo-community/discussions)** - Ask questions, share ideas
- 🐛 **[Issue Tracker](https://github.com/kamranxdev/searvo-community/issues)** - Report bugs, request features
- 💭 **[Discord](https://discord.gg/Bq67m6NYaa)** - Real-time chat

## 📜 License

Searvo is open-source software licensed under the [MIT License](LICENSE).

## 🙏 Acknowledgments

Searvo is built with these amazing open-source projects:
- [Flutter](https://flutter.dev/) - UI framework
- [LangChain](https://www.langchain.com/) - LLM orchestration
- [SearXNG](https://github.com/searxng/searxng) - Privacy-respecting metasearch

## � Roadmap

- [ ] Local Search History
- [ ] Collaborative collections
- [ ] Browser extension
- [ ] Mobile widget support
- [ ] Advanced analytics
- [ ] Plugin system

See our [GitHub Projects](https://github.com/kamranxdev/searvo-community/projects) for detailed progress.

## 📧 Contact

- **Project Maintainer**: [kamranxdev](https://github.com/kamranxdev)
- **Email**: [Create an issue](https://github.com/kamranxdev/searvo-community/issues/new)
- **Website**: Coming soon!

---

<div align="center">

**Made with ❤️ by the open-source community**

[⭐ Star this repo](https://github.com/kamranxdev/searvo-community) • [🐛 Report Bug](https://github.com/kamranxdev/searvo-community/issues) • [💡 Request Feature](https://github.com/kamranxdev/searvo-community/issues)

</div>

