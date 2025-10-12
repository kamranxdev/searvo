# Contributing to Searvo

Thank you for your interest in contributing to Searvo! This guide will help you get started with contributing to this open-source project.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:

- Be respectful and considerate
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

## How to Contribute

There are many ways to contribute to Searvo:

### 🐛 Report Bugs

Found a bug? Help us fix it!

1. Check if the bug is already reported in [Issues](https://github.com/kamranxdev/searvo/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots (if applicable)
   - Environment details (OS, Flutter version, etc.)

**Issue Template:**
```markdown
## Bug Description
[Clear description of the bug]

## Steps to Reproduce
1. Go to...
2. Click on...
3. See error...

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- OS: [e.g., Ubuntu 22.04, macOS 13, Windows 11]
- Flutter version: [e.g., 3.8.0]
- Searvo version: [e.g., 1.0.0]

## Screenshots
[If applicable]
```

### 💡 Suggest Features

Have an idea? We'd love to hear it!

1. Check [existing feature requests](https://github.com/kamranxdev/searvo/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. Create a new issue with the "enhancement" label
3. Describe your idea clearly
4. Explain the use case
5. Discuss implementation if you have ideas

### 📝 Improve Documentation

Documentation improvements are always welcome!

- Fix typos or unclear explanations
- Add examples
- Improve existing guides
- Write new tutorials
- Translate documentation

### 💻 Submit Code

Ready to write code? Great!

## Development Setup

### Prerequisites

1. **Flutter SDK** (3.8.0 or higher)
```bash
flutter doctor
```

2. **Git**
```bash
git --version
```

3. **IDE** (VS Code, Android Studio, or IntelliJ)
   - Install Flutter and Dart plugins

### Fork and Clone

1. **Fork the repository**
   - Click "Fork" on [GitHub](https://github.com/kamranxdev/searvo)

2. **Clone your fork**
```bash
git clone https://github.com/YOUR_USERNAME/searvo.git
cd searvo
```

3. **Add upstream remote**
```bash
git remote add upstream https://github.com/kamranxdev/searvo.git
```

### Install Dependencies

```bash
flutter pub get
```

### Create a Branch

Create a new branch for your feature or fix:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

**Branch Naming:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions/changes

## Making Changes

### Code Style

Follow Dart best practices:

1. **Run the linter**
```bash
flutter analyze
```

2. **Format your code**
```bash
flutter format lib/
```

3. **Follow conventions**
   - Use `lowerCamelCase` for variables
   - Use `UpperCamelCase` for classes
   - Use `snake_case` for files
   - Add comments for complex logic
   - Write self-documenting code

### Writing Code

**Good Practices:**

✅ **Do:**
- Write clear, readable code
- Add comments for complex logic
- Follow existing patterns
- Keep functions small and focused
- Use meaningful variable names
- Handle errors gracefully

❌ **Don't:**
- Submit untested code
- Break existing functionality
- Ignore linter warnings
- Hard-code values
- Leave debug prints

**Example - Good Code:**
```dart
/// Fetches search results for the given query.
/// 
/// Returns a list of [SearchResult] objects or throws
/// a [SearchException] if the request fails.
Future<List<SearchResult>> searchWeb(String query) async {
  if (query.isEmpty) {
    throw ArgumentError('Query cannot be empty');
  }
  
  try {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}'),
    );
    
    if (response.statusCode == 200) {
      return _parseResults(response.body);
    } else {
      throw SearchException('Failed to fetch results: ${response.statusCode}');
    }
  } catch (e) {
    throw SearchException('Network error: $e');
  }
}
```

### Testing

1. **Write tests for new features**
```dart
test('searchWeb returns results for valid query', () async {
  final results = await searchService.searchWeb('flutter');
  expect(results, isNotEmpty);
  expect(results.first, isA<SearchResult>());
});
```

2. **Run tests**
```bash
flutter test
```

3. **Check coverage**
```bash
flutter test --coverage
```

### Committing Changes

1. **Stage your changes**
```bash
git add .
```

2. **Commit with a clear message**
```bash
git commit -m "feat: add voice search feature"
```

**Commit Message Format:**
```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Test changes
- `chore:` - Build/tooling changes

**Examples:**
```
feat: add Ollama provider support
fix: resolve voice input crash on Android
docs: update installation guide
refactor: simplify search service
test: add tests for RAG pipeline
```

## Submitting a Pull Request

### Before Submitting

- [ ] Code follows project style guidelines
- [ ] All tests pass
- [ ] No linter warnings
- [ ] Documentation updated (if needed)
- [ ] Commits are well-organized
- [ ] Branch is up to date with main

### Create Pull Request

1. **Push to your fork**
```bash
git push origin feature/your-feature-name
```

2. **Open Pull Request on GitHub**
   - Go to your fork on GitHub
   - Click "Pull Request"
   - Select your branch
   - Fill in the template

**PR Template:**
```markdown
## Description
[Clear description of changes]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring

## Testing
- [ ] Tests pass locally
- [ ] Added new tests
- [ ] Manual testing completed

## Screenshots
[If applicable]

## Related Issues
Closes #123
```

### PR Review Process

1. **Automated checks** run (linting, tests)
2. **Maintainers review** your code
3. **Address feedback** if requested
4. **Get approval** from maintainers
5. **PR is merged** 🎉

### Responding to Feedback

- Be open to suggestions
- Ask questions if unclear
- Make requested changes promptly
- Push new commits to same branch
- Resolve conversations when addressed

## Development Workflow

### Stay Updated

Keep your fork in sync:

```bash
# Fetch upstream changes
git fetch upstream

# Merge into your local main
git checkout main
git merge upstream/main

# Update your fork
git push origin main
```

### Working on Multiple Features

```bash
# Always start from updated main
git checkout main
git pull upstream main

# Create new feature branch
git checkout -b feature/new-feature
```

## Areas for Contribution

### High Priority

- 🐛 Bug fixes (check "good first issue" label)
- 📚 Documentation improvements
- 🧪 Test coverage
- ♿ Accessibility enhancements

### Features

- 🤖 New LLM provider integrations
- 🔍 Search improvements
- 🎨 UI/UX enhancements
- 🌍 Internationalization
- 📱 Platform-specific features

### Advanced

- ⚡ Performance optimizations
- 🏗️ Architecture improvements
- 🔒 Security enhancements
- 🔌 Plugin system

## Getting Help

Need help? We're here!

- 💬 [GitHub Discussions](https://github.com/kamranxdev/searvo/discussions)
- 🐛 [Issue Tracker](https://github.com/kamranxdev/searvo/issues)
- 💭 [Discord Community](https://discord.gg/Bq67m6NYaa)

## Recognition

Contributors are recognized:

- Listed in CONTRIBUTORS.md
- Credited in release notes
- Mentioned in project updates

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Don't hesitate to ask! Create a discussion or reach out on Discord.

Thank you for contributing to Searvo! 🎉
