# Contributing to Searvo

👍 First off, thank you for considering contributing to Searvo! 

We love to receive contributions from our community! There are many ways to contribute, from writing tutorials or blog posts, improving the documentation, submitting bug reports and feature requests, or writing code.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Quick Start](#quick-start)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/searvo.git`
3. Create a branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Run tests: `flutter test`
6. Commit: `git commit -m "feat: add my feature"`
7. Push: `git push origin feature/my-feature`
8. Create a Pull Request

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check the existing issues. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed**
- **Explain which behavior you expected to see**
- **Include screenshots if possible**
- **Include your environment details** (OS, Flutter version, etc.)

### 💡 Suggesting Features

Feature suggestions are tracked as GitHub issues. When creating a feature suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested feature**
- **Explain why this feature would be useful**
- **Include mockups or examples if applicable**

### 💻 Contributing Code

1. Look for issues labeled `good first issue` or `help wanted`
2. Comment on the issue to let others know you're working on it
3. Follow our development setup guide
4. Make your changes following our style guidelines
5. Write or update tests as needed
6. Update documentation as needed
7. Submit a pull request

## Development Setup

### Prerequisites

- Flutter 3.8.0 or higher
- Dart 3.8.0 or higher
- Git

### Setup Steps

```bash
# Clone the repository
git clone https://github.com/kamranxdev/searvo.git
cd searvo

# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run linter
flutter analyze

# Format code
flutter format .
```

For detailed setup instructions, see our [Installation Guide](docs/getting-started/installation.md).

## Pull Request Process

1. **Update Documentation** - Update the README.md or docs with details of changes if needed
2. **Follow Code Style** - Ensure your code follows our [Code Style Guide](docs/development/code-style.md)
3. **Write Tests** - Add tests for new features
4. **Update Changelog** - Add your changes to CHANGELOG.md (if applicable)
5. **One Feature Per PR** - Keep pull requests focused on a single feature or fix
6. **Descriptive PR Title** - Use conventional commit format (e.g., `feat: add voice search`)
7. **Detailed Description** - Explain what changes you made and why
8. **Link Issues** - Reference any related issues

### PR Title Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test changes
- `chore:` - Build/tooling changes

Examples:
- `feat: add Ollama provider support`
- `fix: resolve voice input crash on Android`
- `docs: update installation guide`

## Style Guidelines

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests after the first line

### Dart Code Style

- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter format` before committing
- Fix all linter warnings (`flutter analyze`)
- Use meaningful variable and function names
- Add comments for complex logic
- Write documentation comments for public APIs

See our detailed [Code Style Guide](docs/development/code-style.md).

### Documentation Style

- Use clear, concise language
- Include code examples where appropriate
- Keep line length reasonable (80-100 characters)
- Use proper Markdown formatting
- Check spelling and grammar

## Testing

- Write tests for new features
- Ensure all tests pass before submitting PR
- Aim for good test coverage
- Include both unit and widget tests where appropriate

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/search/search_service_test.dart
```

## Community

- 💬 [GitHub Discussions](https://github.com/kamranxdev/searvo/discussions) - Ask questions, share ideas
- 🐛 [Issue Tracker](https://github.com/kamranxdev/searvo/issues) - Report bugs, request features
- 💭 [Discord](https://discord.gg/Bq67m6NYaa) - Real-time chat with the community

## Recognition

Contributors will be:
- Listed in our CONTRIBUTORS.md file
- Credited in release notes
- Mentioned in project updates
- Part of our amazing community! 🎉

## Questions?

Don't hesitate to ask! Create a discussion or reach out on Discord. We're here to help!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to Searvo! 💙**
