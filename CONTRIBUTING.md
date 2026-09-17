# Contributing to Searvo

👍 **First off, thank you for considering contributing to Searvo!** 

Searvo is an open-source, privacy-first AI search engine and autonomous agent platform. We are building this project in the open, by the community and for the community. Whether you write Flutter/Dart, Python/FastAPI, work on DevOps/Docker, design beautiful UI/UX, or improve documentation and translations, your contributions are warmly welcomed!

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Monorepo Overview](#monorepo-overview)
- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
  - [Frontend Development (Flutter)](#1-frontend-development-flutter)
  - [Backend Development (Python / FastAPI)](#2-backend-development-python--fastapi)
  - [Full-Stack Development (Docker Compose)](#3-full-stack-development-docker-compose)
- [Coding Guidelines & Standards](#coding-guidelines--standards)
  - [Flutter / Dart Standards](#flutter--dart-standards)
  - [Python / FastAPI Standards](#python--fastapi-standards)
- [Git Commit & Pull Request Workflow](#git-commit--pull-request-workflow)
  - [Monorepo Commit Scopes](#monorepo-commit-scopes)
  - [Pull Request Checklist](#pull-request-checklist)
- [Recognition & Community](#recognition--community)

---

## Code of Conduct

Searvo is committed to fostering an open, inclusive, and harassment-free environment for all participants. By participating, you agree to abide by our **[Code of Conduct](CODE_OF_CONDUCT.md)**.

---

## Monorepo Overview

Searvo is maintained as a single monorepo:

| Component | Directory | Stack | Description |
|---|---|---|---|
| **Frontend Client** | `lib/` | Flutter 3.8+, Dart | Cross-platform app (Android, iOS, Web, macOS, Windows, Linux) |
| **Backend API** | `backend/` | Python 3.10+, FastAPI, LiteLLM | Autonomous agent orchestration, RAG, SSE streaming, document processing |
| **Vector Database** | `docker-compose.yaml` | Qdrant | Vector embeddings storage & semantic search for RAG |
| **Metasearch** | `searxng/` | SearXNG | Privacy-respecting metasearch engine proxy |
| **Documentation** | `docs/` | Markdown | In-depth architecture, API references, and guides |

---

## Ways to Contribute

### 1. 🐛 Report Bugs
- Search [existing issues](https://github.com/kamranxdev/searvo/issues) first to prevent duplicates.
- Use our [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md).
- Specify whether the issue is in the **Frontend**, **Backend**, or **Infrastructure**, and include logs, screenshots, and reproduction steps.

### 2. 💡 Propose Features & New Agent Tools
- We love new ideas! Check the [Feature Requests](https://github.com/kamranxdev/searvo/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement) tab.
- Want to add a new backend tool for the agent (e.g. GitHub search, Reddit search, financial analysis)? Let's discuss it in an issue!

### 3. 🎨 Frontend Contributions (Flutter / Dart)
- Implement UI improvements and animations.
- Refactor and extend Clean Architecture modules in `lib/features/`.
- Enhance accessibility (a11y), responsive layouts, and multi-language support.

### 4. 🧠 Backend & AI Contributions (Python / FastAPI)
- Expand autonomous reasoning tools in `backend/app/services/tools/`.
- Optimize RAG chunking, hybrid search, and context compression.
- Improve Server-Sent Events (SSE) streaming reliability and error handling.
- Add support for new local or cloud LLM providers via LiteLLM.

### 5. 📝 Documentation & Tutorials
- Fix typos, improve explanations, add code examples, or translate documentation.
- Write tutorials on self-hosting Searvo or integrating custom tools.

---

## Development Setup

### 1. Frontend Development (Flutter)

#### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.8.0 or higher
- [Dart SDK](https://dart.dev/get-dart) 3.8.0 or higher
- Android Studio / Xcode / VS Code with Flutter extensions

#### Setup Steps
```bash
# 1. Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/searvo.git
cd searvo

# 2. Fetch Flutter packages
flutter pub get

# 3. Launch on your desired target
flutter run

# To run on Web:
flutter run -d chrome

# 4. Verify code health
flutter analyze
flutter test
```

> 💡 **Connecting to Local Backend**: By default, the Flutter app connects to `http://localhost:8000` (or `http://10.0.2.2:8000` on Android emulator). Ensure your backend or Docker containers are running.

---

### 2. Backend Development (Python / FastAPI)

#### Prerequisites
- Python 3.10 or higher
- `pip` and `python3-venv`

#### Setup Steps
```bash
# 1. Navigate to backend folder
cd backend

# 2. Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate       # On Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up environment variables
cp .env.example .env
# Edit .env with your LLM API keys (e.g., OPENAI_API_KEY or GEMINI_API_KEY)

# 5. Start the development server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API documentation will be available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

### 3. Full-Stack Development (Docker Compose)

The easiest way to run the entire backend stack (FastAPI API + Qdrant Vector DB + SearXNG + Caddy) is Docker Compose:

```bash
# From the project root
cp backend/.env.example backend/.env
docker compose up -d

# Check container status
docker compose ps

# View backend logs
docker compose logs -f api
```

---

## Coding Guidelines & Standards

### Flutter / Dart Standards
- Follow the official [Effective Dart Style Guide](https://dart.dev/guides/language/effective-dart).
- Maintain **Clean Architecture** patterns: keep UI (`presentation/`), business logic (`domain/`), and API/storage (`data/`) cleanly separated.
- Run `dart format .` before committing.
- Ensure all linter diagnostics pass: `flutter analyze`.

### Python / FastAPI Standards
- Follow [PEP 8](https://peps.python.org/pep-0008/) style standards.
- Use explicit type annotations for function signatures and Pydantic models.
- Handle asynchronous I/O with `async`/`await` for non-blocking operations.
- Avoid committing secrets or hardcoded API keys. Use `backend/app/config.py` and `.env`.

---

## Git Commit & Pull Request Workflow

### Monorepo Commit Scopes
We use [Conventional Commits](https://www.conventionalcommits.org/) with component scopes to make monorepo history easy to read:

- `feat(frontend): add voice search waveform animation`
- `feat(backend): add DuckDuckGo fallback search tool`
- `fix(agent): handle empty context gracefully in RAG pipeline`
- `fix(ui): correct dark mode contrast on citation badges`
- `chore(docker): update Qdrant image to latest stable`
- `docs(readme): update contributing and setup instructions`

### Pull Request Checklist
1. **Branch Naming**: Use descriptive branch names:
   - `feature/backend-new-tool`
   - `fix/frontend-search-overflow`
   - `docs/clarify-docker-setup`
2. **Self-Review**: Review your own diff before opening the PR.
3. **Tests**: Ensure existing tests pass and add new tests where applicable (`flutter test`).
4. **Documentation**: Update relevant docs or docstrings if your change modifies user behavior or API endpoints.
5. **Fill the PR Template**: Detail what changed, why, and how it was tested.

---

## Recognition & Community

Every contributor matters! When your pull request is merged:
- You will be added to **[CONTRIBUTORS.md](CONTRIBUTORS.md)**.
- You will be highlighted in our release notes.
- You earn our eternal gratitude and become an essential part of Searvo's journey! 🚀

### Questions & Discussions
- 💬 **[GitHub Discussions](https://github.com/kamranxdev/searvo/discussions)**
- 🐛 **[GitHub Issues](https://github.com/kamranxdev/searvo/issues)**
- 💭 **[Discord Community](https://discord.gg/Bq67m6NYaa)**

---

**Thank you for helping make Searvo the best open-source AI search experience! 💙**

