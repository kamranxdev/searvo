# Code Style Guide

This document outlines the coding standards and best practices for Searvo development.

## Dart Code Style

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) with these additional conventions:

### File Organization

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Package imports (alphabetically)
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// 4. Relative imports (from this package)
import '../models/search_result.dart';
import '../services/search_service.dart';
import 'widgets/search_bar.dart';
```

### Naming Conventions

**Files:**
```
✅ search_service.dart
✅ llm_provider.dart
✅ rag_provider.dart

❌ SearchService.dart
❌ LLMProvider.dart
```

**Classes:**
```dart
✅ class SearchService { }
✅ class LLMProvider extends ChangeNotifier { }
✅ class SearchResult { }

❌ class searchService { }
❌ class Search_Service { }
```

**Variables & Functions:**
```dart
✅ String userName;
✅ Future<void> fetchResults() async { }
✅ final searchQuery = 'example';

❌ String UserName;
❌ String user_name;
```

**Constants:**
```dart
✅ const int maxRetries = 3;
✅ const String apiBaseUrl = 'https://api.example.com';

// For truly constant values, use uppercase
✅ const double PI = 3.14159;
```

**Private Members:**
```dart
✅ String _privateVariable;
✅ void _privateMethod() { }
✅ class _PrivateClass { }
```

### Code Formatting

**Line Length:**
- Maximum 80 characters (enforced by formatter)
- Break long lines appropriately

**Indentation:**
- Use 2 spaces (not tabs)
- Let `flutter format` handle it

**Braces:**
```dart
✅ Good
if (condition) {
  doSomething();
}

✅ Also acceptable for single line
if (condition) doSomething();

❌ Avoid
if (condition)
{
  doSomething();
}
```

### Documentation Comments

**Classes:**
```dart
/// A service for managing search operations.
///
/// This service handles web scraping, query processing,
/// and result caching for search functionality.
class SearchService {
  // ...
}
```

**Methods:**
```dart
/// Searches the web for the given [query].
///
/// Returns a list of [SearchResult] objects. Throws a
/// [SearchException] if the request fails.
///
/// Example:
/// ```dart
/// final results = await searchService.search('flutter');
/// print('Found ${results.length} results');
/// ```
Future<List<SearchResult>> search(String query) async {
  // ...
}
```

**Parameters:**
```dart
/// Creates a new search result.
///
/// The [title] and [url] are required. The [snippet]
/// provides a preview of the content.
SearchResult({
  required this.title,
  required this.url,
  this.snippet,
});
```

### Error Handling

**Try-Catch:**
```dart
✅ Good - Specific error handling
try {
  final result = await fetchData();
  return result;
} on SocketException catch (e) {
  throw NetworkException('No internet connection: $e');
} on FormatException catch (e) {
  throw ParseException('Invalid data format: $e');
} catch (e) {
  throw SearchException('Unexpected error: $e');
}

❌ Avoid - Silent failures
try {
  await fetchData();
} catch (e) {
  // Do nothing
}
```

**Validation:**
```dart
✅ Early returns
Future<void> processQuery(String? query) async {
  if (query == null || query.isEmpty) {
    throw ArgumentError('Query cannot be empty');
  }
  
  // Continue processing
}
```

### Async/Await

**Always use async/await over .then():**
```dart
✅ Good
Future<String> fetchData() async {
  final response = await http.get(url);
  return response.body;
}

❌ Avoid
Future<String> fetchData() {
  return http.get(url).then((response) => response.body);
}
```

**Use Future.wait for parallel operations:**
```dart
✅ Parallel execution
final results = await Future.wait([
  fetchUsers(),
  fetchPosts(),
  fetchComments(),
]);

❌ Sequential execution
final users = await fetchUsers();
final posts = await fetchPosts();
final comments = await fetchComments();
```

### Null Safety

**Prefer non-nullable:**
```dart
✅ Good
String name;        // Non-nullable
String? nickname;   // Nullable when needed

❌ Avoid unnecessary nullability
String? name;       // If it's always present
```

**Null-aware operators:**
```dart
✅ Use appropriate operators
final length = name?.length ?? 0;
final greeting = name ?? 'Guest';
value ??= defaultValue;

// Null assertion only when certain
final length = name!.length;  // Use sparingly
```

## Flutter-Specific

### Widget Structure

```dart
class SearchCard extends StatelessWidget {
  const SearchCard({
    super.key,
    required this.result,
    this.onTap,
  });

  final SearchResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(result.title),
        subtitle: Text(result.snippet ?? ''),
        onTap: onTap,
      ),
    );
  }
}
```

### State Management (Provider)

```dart
✅ Good - Notifying listeners
class SearchProvider extends ChangeNotifier {
  List<SearchResult> _results = [];
  
  List<SearchResult> get results => _results;
  
  Future<void> search(String query) async {
    _results = await _searchService.search(query);
    notifyListeners();  // Notify after state change
  }
}

✅ Usage
context.watch<SearchProvider>()  // Rebuild on change
context.read<SearchProvider>()   // One-time read
```

### Build Methods

**Keep build methods clean:**
```dart
✅ Good - Extract complex widgets
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
    floatingActionButton: _buildFAB(),
  );
}

Widget _buildAppBar() {
  return AppBar(title: Text('Search'));
}

❌ Avoid - Everything in build
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Search'),
      actions: [
        IconButton(/* lots of code */),
        IconButton(/* lots of code */),
      ],
    ),
    body: Column(
      children: [
        Container(/* lots of code */),
        ListView(/* lots of code */),
      ],
    ),
  );
}
```

## Testing

### Test Structure

```dart
void main() {
  group('SearchService', () {
    late SearchService searchService;

    setUp(() {
      searchService = SearchService();
    });

    tearDown(() {
      searchService.dispose();
    });

    test('returns results for valid query', () async {
      final results = await searchService.search('flutter');
      
      expect(results, isNotEmpty);
      expect(results.first, isA<SearchResult>());
    });

    test('throws error for empty query', () {
      expect(
        () => searchService.search(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

### Widget Tests

```dart
testWidgets('SearchCard displays title and snippet', (tester) async {
  final result = SearchResult(
    title: 'Test Title',
    snippet: 'Test snippet',
    url: 'https://example.com',
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SearchCard(result: result),
      ),
    ),
  );

  expect(find.text('Test Title'), findsOneWidget);
  expect(find.text('Test snippet'), findsOneWidget);
});
```

## Performance

### Avoid Rebuilds

```dart
✅ Use const constructors
const Text('Hello')
const Padding(padding: EdgeInsets.all(8.0))

✅ Extract widgets that don't change
class _Header extends StatelessWidget {
  const _Header();
  
  @override
  Widget build(BuildContext context) {
    return const Text('Fixed Header');
  }
}
```

### Lazy Loading

```dart
✅ Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)

❌ Avoid creating all widgets at once
ListView(
  children: items.map((item) => ListTile(title: Text(item))).toList(),
)
```

## Git Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting
- `refactor:` - Code restructuring
- `test:` - Tests
- `chore:` - Maintenance

**Examples:**
```
feat: add voice search feature
fix: resolve crash on Android 11
docs: update installation guide
refactor: simplify search service
test: add tests for RAG pipeline
chore: update dependencies
```

## Best Practices Summary

1. ✅ **Run formatter** before committing
2. ✅ **Fix linter warnings** - zero warnings policy
3. ✅ **Write tests** for new features
4. ✅ **Document public APIs** with /// comments
5. ✅ **Use const** whenever possible
6. ✅ **Handle errors** gracefully
7. ✅ **Validate inputs** early
8. ✅ **Keep functions small** - single responsibility
9. ✅ **Use meaningful names** - self-documenting code
10. ✅ **Follow existing patterns** in the codebase

## Tools

### Linting

```bash
# Run analyzer
flutter analyze

# Auto-fix issues
dart fix --apply
```

### Formatting

```bash
# Format all files
flutter format .

# Format specific file
flutter format lib/main.dart
```

### Code Metrics

```bash
# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Resources

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Best Practices](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

## Questions?

Ask in [GitHub Discussions](https://github.com/kamranxdev/searvo-community/discussions) or [Discord](https://discord.gg/Bq67m6NYaa).
