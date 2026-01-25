# Searvo AI Copilot Instructions

## Project Overview
Searvo is a cross-platform Flutter app (Android, iOS, Web, Linux, macOS, Windows) that combines traditional search with AI-powered RAG (Retrieval-Augmented Generation). It integrates SearXNG metasearch engine with multiple LLM providers (OpenAI, Google Gemini, Anthropic Claude, Ollama, OpenRouter) for intelligent, conversational search with voice capabilities.

## Architecture

### Feature-First Structure
All features live under `lib/features/` with self-contained modules:
- `auth/` - Firebase Authentication, Google Sign-In
- `search/` - Core search UI, SearXNG integration, RAG pipeline
- `llm/` - Multi-provider LLM abstraction layer
- `history/` - Hybrid local (Drift/SQLite) + cloud (Firestore) conversation sync
- `voice/` - Speech-to-text and text-to-speech
- `discover/` - News article discovery
- `settings/` - App configuration, LLM provider management
- `weather/` - Weather integration

Each feature follows: `providers/` (state), `services/` (business logic), `screens/` (UI), `widgets/` (components), `models/` (data)

### State Management Pattern
Uses **Provider** pattern exclusively. All providers extend `ChangeNotifier`:
```dart
class SearchProvider extends ChangeNotifier {
  final SearchService _searchService = SearchService();
  // State + notifyListeners()
}
```
Access via `Provider.of<T>(context)` or `context.watch<T>()`. Providers registered in `main.dart` `MultiProvider`.

### Service Layer
Services are singletons with `_instance` pattern:
```dart
class SearXNGService {
  static final SearXNGService _instance = SearXNGService._internal();
  factory SearXNGService() => _instance;
  SearXNGService._internal();
}
```
Initialize services in `main()` before `runApp()` - see startup sequence in [main.dart](lib/main.dart).

## RAG Pipeline Architecture
Located in `lib/features/search/rag/services/`:
- **orchestration/** - `RAGOrchestrator` coordinates the full pipeline
- **data_ingestion/** - Web scrapers, PDF extractors, attachment processors
- **query_processing/** - `QueryAnalyzer` for query intent detection
- **document_processing/** - Chunking, embedding, retrieval
- **citation/** - Source attribution and citation generation

RAG flow: Query → Analyze → Scrape/Retrieve → Process Documents → Generate with LLM → Add Citations

## Key Patterns

### @Mention System
Search supports `@github`, `@youtube`, etc. for site-specific queries. Configured via `SettingsService.getWebsiteMappings()`. The `RichTextEditingController` in [rich_text_editing_controller.dart](lib/shared/widgets/rich_text_editing_controller.dart) handles mention highlighting and validation.

### Adaptive Searching
The search system uses "adaptive searching" to automatically determine the best retrieval strategy based on the query complexity and context. It dynamically adjusts RAG depth and scraping behavior without requiring manual mode selection.

### Message Branching
Conversations use `MessageBranchManager` to support multi-path branching - users can explore different conversation directions. See [message_branch_model.dart](lib/features/search/models/message_branch_model.dart).

### Hybrid Sync
`ConversationSyncService` provides local-first storage with optional cloud backup:
- Local: Drift/SQLite database (`ConversationDatabaseService`)
- Cloud: Firestore (`ConversationCloudService`)
- Privacy-first: cloud sync is opt-in

## Routing
Uses **go_router** with declarative routes in [app_router.dart](lib/core/routing/app_router.dart):
- Auth guard redirects unauthenticated users
- Deep linking support for `/search/:id` conversations
- Bottom nav indices: home=0, discover=1, history=2, settings=3

## Development Commands

### Run Development Environment
```bash
# All platforms
flutter pub get
flutter run -d <platform>

# Linux with SearXNG (Docker required)
./linux.sh dev

# Android with scripts
./android.sh
```

### Testing & Building
```bash
flutter test                    # Run tests
flutter analyze                 # Lint check
flutter build <platform>        # Production build
```

### SearXNG Backend
Run via Docker Compose for local development:
```bash
docker-compose up -d
# SearXNG available at http://localhost:4000
```
Configure SearXNG URL in Settings or via `SearXNGService.initialize(baseUrl: '...')`.

## LLM Provider Integration
All providers implement `BaseLLMProvider` interface. Configure in Settings screen:
1. Select provider via `LLMProviderManager.setActiveProvider()`
2. API keys stored in SharedPreferences
3. Models are provider-specific strings (e.g., `gpt-4`, `gemini-pro`, `claude-3-opus`)

Ollama is the local/free option - no API key required, just `baseUrl` configuration.

## Theme System
Central theme management via `ThemeManager` singleton:
- Access: `ThemeManager().setDarkMode()`, `ThemeManager().themeMode`
- Config: [app_theme_config.dart](lib/core/theme/app_theme_config.dart)
- Extensions: `context.isDark`, `context.primaryColor` via [theme_extensions.dart](lib/core/theme/theme_extensions.dart)

Import all theme utilities via `import 'package:searvo/core/theme/theme.dart';`

## Common Pitfalls

### Initialization Order Matters
Services must initialize before providers use them. Check `main()` for proper sequence:
```dart
await Firebase.initializeApp();
await AuthService().initialize();
await SettingsService().initialize();
await ThemeManager().initialize();
// Then create providers
```

### Avoid Direct HTTP Calls
Use `SearXNGService` for search queries, not raw HTTP. It handles configuration, timeouts, error handling.

### Voice Permissions
Voice features require runtime permissions. Always check via `permission_handler` before using `VoiceService`.

### Responsive Design
Use `flutter_screenutil` for responsive sizing: `20.w`, `30.h`, `14.sp` for width, height, font size.

## Firebase Configuration
- Credentials: [firebase_options.dart](lib/firebase_options.dart) (generated via FlutterFire CLI)
- Auth: Google Sign-In + Firebase Auth (configured per platform)
- Firestore: Conversation history sync (optional, privacy-controlled)

## Contributing
Follow conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`. See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines. Run `flutter analyze` before submitting PRs.

## Flutter Development Best Practices

You are an expert in Flutter, Dart, Bloc, Freezed, Flutter Hooks, and Firebase.

### Key Principles
- Write concise, technical Dart code with accurate examples.
- Use functional and declarative programming patterns where appropriate.
- Prefer composition over inheritance.
- Use descriptive variable names with auxiliary verbs (e.g., isLoading, hasError).
- Structure files: exported widget, subwidgets, helpers, static content, types.

### Dart/Flutter Conventions
- Use const constructors for immutable widgets.
- Leverage Freezed for immutable state classes and unions.
- Use arrow syntax for simple functions and methods.
- Prefer expression bodies for one-line getters and setters.
- Use trailing commas for better formatting and diffs.

### Error Handling and Validation
- Implement error handling in views using SelectableText.rich instead of SnackBars.
- Display errors in SelectableText.rich with red color for visibility.
- Handle empty states within the displaying screen.
- Manage error handling and loading states within Cubit states.

### Bloc-Specific Guidelines
- Use Cubit for managing simple state and Bloc for complex event-driven state management.
- Extend states with Freezed for immutability.
- Use descriptive and meaningful event names for Bloc.
- Handle state transitions and side effects in Bloc's mapEventToState.
- Prefer context.read() or context.watch() for accessing Cubit/Bloc states in widgets.

### Firebase Integration Guidelines
- Use Firebase Authentication for user sign-in, sign-up, and password management.
- Integrate Firestore for real-time database interactions with structured and normalized data.
- Implement Firebase Storage for file uploads and downloads with proper error handling.
- Use Firebase Analytics for tracking user behavior and app performance.
- Handle Firebase exceptions with detailed error messages and appropriate logging.
- Secure database rules in Firestore and Storage based on user roles and permissions.

### Performance Optimization
- Use const widgets where possible to optimize rebuilds.
- Implement list view optimizations (e.g., ListView.builder).
- Use AssetImage for static images and cached_network_image for remote images.
- Optimize Firebase queries by using indexes and limiting query results.

### Key Conventions
1. Use GoRouter or auto_route for navigation and deep linking.
2. Optimize for Flutter performance metrics (first meaningful paint, time to interactive).
3. Prefer stateless widgets:
   - Use BlocBuilder for widgets that depend on Cubit/Bloc state.
   - Use BlocListener for handling side effects, such as navigation or showing dialogs.

### UI and Styling
- Use Flutter's built-in widgets and create custom widgets.
- Implement responsive design using LayoutBuilder or MediaQuery.
- Use themes for consistent styling across the app.
- Use Theme.of(context).textTheme.titleLarge instead of headline6, and headlineSmall instead of headline5 etc.

### Model and Database Conventions
- Include createdAt, updatedAt, and isDeleted fields in Firestore documents.
- Use @JsonSerializable(fieldRename: FieldRename.snake) for models.
- Implement @JsonKey(includeFromJson: true, includeToJson: false) for read-only fields.

### Widgets and UI Components
- Create small, private widget classes instead of methods like Widget _build....
- Implement RefreshIndicator for pull-to-refresh functionality.
- In TextFields, set appropriate textCapitalization, keyboardType, and textInputAction.
- Always include an errorBuilder when using Image.network.

### Miscellaneous
- Use log instead of print for debugging.
- Use BlocObserver for monitoring state transitions during debugging.
- Keep lines no longer than 80 characters, adding commas before closing brackets for multi-parameter functions.
- Use @JsonValue(int) for enums that go to the database.

### Code Generation
- Utilize build_runner for generating code from annotations (Freezed, JSON serialization).
- Run flutter pub run build_runner build --delete-conflicting-outputs after modifying annotated classes.

### Documentation
- Document complex logic and non-obvious code decisions.
- Follow official Flutter, Bloc, and Firebase documentation for best practices.

Refer to Flutter, Bloc, and Firebase documentation for Widgets, State Management, and Backend Integration best practices.

---

## Recommended Future Direction

**Note:** The following represents architectural patterns being considered for future refactoring. The current codebase uses Provider pattern (not flutter_bloc) and feature-first organization without strict Clean Architecture layers. These recommendations should guide major architectural improvements rather than day-to-day development.

### Core Principles

#### Clean Architecture
- Strictly adhere to the Clean Architecture layers: Presentation, Domain, and Data
- Follow the dependency rule: dependencies always point inward
- Domain layer contains entities, repositories (interfaces), and use cases (pure Dart, no Flutter dependencies)
- Data layer implements repositories and contains data sources and models
- Presentation layer contains UI components, blocs, and view models
- Use proper abstractions with interfaces/abstract classes for each component
- Every feature should follow this layered architecture pattern

#### Feature-First Organization
- Organize code by features instead of technical layers
- Each feature is a self-contained module with its own implementation of all layers
- Core or shared functionality goes in a separate 'core' directory
- Features should have minimal dependencies on other features
- Maintain consistent directory structure across all features

#### flutter_bloc Implementation Principles
- Use Bloc for complex event-driven logic and Cubit for simpler state management
- Implement properly typed Events and States for each Bloc
- Use Freezed for immutable state and union types
- Create granular, focused Blocs for specific feature segments
- Handle loading, error, and success states explicitly
- Avoid business logic in UI components
- Use BlocProvider for dependency injection of Blocs
- Implement BlocObserver for logging and debugging
- Separate event handling from UI logic

#### Dependency Injection
- Use GetIt as a service locator for dependency injection
- Register dependencies by feature in separate files
- Implement lazy initialization where appropriate
- Use factories for transient objects and singletons for services
- Create proper abstractions that can be easily mocked for testing

### Coding Standards

#### State Management Best Practices
- States should be immutable using Freezed
- Use union types for state representation (initial, loading, success, error)
- Emit specific, typed error states with failure details
- Keep state classes small and focused
- Use copyWith for state transitions
- Handle side effects with BlocListener
- Prefer BlocBuilder with buildWhen for optimized rebuilds

#### Error Handling Standards
- Use Either<Failure, Success> from Dartz for functional error handling
- Create custom Failure classes for domain-specific errors
- Implement proper error mapping between layers
- Centralize error handling strategies
- Provide user-friendly error messages
- Log errors for debugging and analytics

#### Repository Pattern Standards
- Repositories act as a single source of truth for data
- Implement caching strategies when appropriate
- Handle network connectivity issues gracefully
- Map data models to domain entities
- Create proper abstractions with well-defined method signatures
- Handle pagination and data fetching logic

#### Testing Strategy
- Write unit tests for domain logic, repositories, and Blocs
- Implement integration tests for features
- Create widget tests for UI components
- Use mocks for dependencies with mockito or mocktail
- Follow Given-When-Then pattern for test structure
- Aim for high test coverage of domain and data layers
- Test Bloc state transitions with bloc_test package

#### Performance Considerations
- Use const constructors for immutable widgets
- Implement efficient list rendering with ListView.builder
- Minimize widget rebuilds with proper state management
- Use computation isolation for expensive operations with compute()
- Implement pagination for large data sets
- Cache network resources appropriately
- Profile and optimize render performance

#### Code Quality Standards
- Use lint rules with flutter_lints package
- Keep functions small and focused (under 30 lines)
- Apply SOLID principles throughout the codebase
- Use meaningful naming for classes, methods, and variables
- Document public APIs and complex logic
- Implement proper null safety
- Use value objects for domain-specific types

### Clean Architecture Migration

#### Target Architecture Layers
- **Domain Layer**: Entities, repository interfaces, and use cases (pure Dart, no Flutter dependencies)
- **Data Layer**: Repository implementations, data sources (remote/local), and data models/DTOs
- **Presentation Layer**: UI components, state management (Bloc/Cubit), and view models
- **Dependency Rule**: All dependencies point inward (Presentation → Domain ← Data)

#### Proposed Directory Structure
```
lib/
├── core/                          # Shared/common code
│   ├── error/                     # Error handling, failures
│   ├── network/                   # Network utilities, interceptors
│   ├── utils/                     # Utility functions and extensions
│   └── widgets/                   # Reusable widgets
├── features/                      # All app features
│   ├── feature_a/                 # Single feature
│   │   ├── data/                  # Data layer
│   │   │   ├── datasources/       # Remote and local data sources
│   │   │   ├── models/            # DTOs and data models
│   │   │   └── repositories/      # Repository implementations
│   │   ├── domain/                # Domain layer
│   │   │   ├── entities/          # Business objects
│   │   │   ├── repositories/      # Repository interfaces
│   │   │   └── usecases/          # Business logic use cases
│   │   └── presentation/          # Presentation layer
│   │       ├── bloc/              # Bloc/Cubit state management
│   │       ├── pages/             # Screen widgets
│   │       └── widgets/           # Feature-specific widgets
└── main.dart
```

### flutter_bloc State Management

**Migration from Provider to flutter_bloc:**
- Replace `ChangeNotifier` providers with Bloc/Cubit
- Use Bloc for complex event-driven logic, Cubit for simpler state management
- Implement typed Events and States with Freezed for immutability
- Create focused, granular Blocs for specific feature segments

#### State Definition with Freezed
```dart
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(User user) = _Loaded;
  const factory UserState.error(Failure failure) = _Error;
}
```

#### Event Definition
```dart
@freezed
class UserEvent with _$UserEvent {
  const factory UserEvent.getUser(String id) = _GetUser;
  const factory UserEvent.refreshUser() = _RefreshUser;
}
```

#### Bloc Implementation
```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUser getUser;
  String? currentUserId;

  UserBloc({required this.getUser}) : super(const UserState.initial()) {
    on<_GetUser>(_onGetUser);
    on<_RefreshUser>(_onRefreshUser);
  }

  Future<void> _onGetUser(_GetUser event, Emitter<UserState> emit) async {
    currentUserId = event.id;
    emit(const UserState.loading());
    final result = await getUser(event.id);
    result.fold(
      (failure) => emit(UserState.error(failure)),
      (user) => emit(UserState.loaded(user)),
    );
  }

  Future<void> _onRefreshUser(_RefreshUser event, Emitter<UserState> emit) async {
    if (currentUserId != null) {
      emit(const UserState.loading());
      final result = await getUser(currentUserId!);
      result.fold(
        (failure) => emit(UserState.error(failure)),
        (user) => emit(UserState.loaded(user)),
      );
    }
  }
}
```

### Dartz Functional Error Handling

**Replace try-catch with Either<Failure, Success>:**
- Left represents failure case, Right represents success case
- Create base Failure class with specific error type extensions
- Use pattern matching with `fold()` for handling both cases

#### Failure Classes
```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation failed']) : super(message);
}
```

#### Either Extensions
```dart
extension EitherExtensions<L, R> on Either<L, R> {
  R getRight() => (this as Right<L, R>).value;
  L getLeft() => (this as Left<L, R>).value;
  
  Widget when({
    required Widget Function(L failure) failure,
    required Widget Function(R data) success,
  }) {
    return fold(
      (l) => failure(l),
      (r) => success(r),
    );
  }
  
  Either<L, T> flatMap<T>(Either<L, T> Function(R r) f) {
    return fold(
      (l) => Left(l),
      (r) => f(r),
    );
  }
}
```

### Use Case Pattern

**Replace direct service calls with use cases:**
```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class GetUser implements UseCase<User, String> {
  final UserRepository repository;

  GetUser(this.repository);

  @override
  Future<Either<Failure, User>> call(String userId) async {
    return await repository.getUser(userId);
  }
}
```

### Repository Pattern with Clean Architecture

**Separate interface from implementation:**
```dart
// Domain layer - abstract interface
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
  Future<Either<Failure, List<User>>> getUsers();
  Future<Either<Failure, Unit>> saveUser(User user);
}

// Data layer - implementation with data sources
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.getUser(id);
        await localDataSource.cacheUser(remoteUser);
        return Right(remoteUser.toDomain());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localUser = await localDataSource.getLastUser();
        return Right(localUser.toDomain());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  // Other implementations...
}
```

### GetIt Dependency Injection

**Replace singleton pattern with GetIt service locator:**
```dart
final getIt = GetIt.instance;

void initDependencies() {
  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));
  
  // Data sources
  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sharedPreferences: getIt()),
  );
  
  // Repository
  getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(
    remoteDataSource: getIt(),
    localDataSource: getIt(),
    networkInfo: getIt(),
  ));
  
  // Use cases
  getIt.registerLazySingleton(() => GetUser(getIt()));
  
  // Bloc
  getIt.registerFactory(() => UserBloc(getUser: getIt()));
}
```

### UI Layer with BlocBuilder

**Replace Provider.of/context.watch with BlocBuilder:**
```dart
class UserPage extends StatelessWidget {
  final String userId;

  const UserPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserBloc>()
        ..add(UserEvent.getUser(userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<UserBloc>().add(const UserEvent.refreshUser());
              },
            ),
          ],
        ),
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            return state.maybeWhen(
              initial: () => const SizedBox(),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (user) => UserDetailsWidget(user: user),
              error: (failure) => ErrorWidget(failure: failure),
              orElse: () => const SizedBox(),
            );
          },
        ),
      ),
    );
  }
}
```

### Migration Strategy

1. **Phase 1**: Introduce Clean Architecture layers in new features
2. **Phase 2**: Add Dartz Either for error handling in repositories
3. **Phase 3**: Implement use case pattern for complex business logic
4. **Phase 4**: Migrate Provider to flutter_bloc incrementally by feature
5. **Phase 5**: Replace singleton services with GetIt dependency injection
6. **Phase 6**: Add Freezed for immutable state classes

### Testing Improvements

- Unit test domain logic (use cases, entities) in isolation
- Mock repositories with mockito/mocktail for use case tests
- Test Bloc state transitions with bloc_test package
- Write widget tests using BlocProvider.value for mocked states
- Implement integration tests for complete feature flows
- Follow Given-When-Then pattern for test structure
- Aim for high test coverage of domain and data layers

### Benefits of Migration

- **Testability**: Pure domain layer enables easy unit testing
- **Maintainability**: Clear separation of concerns
- **Scalability**: Features are independent and can grow without conflicts
- **Type Safety**: Freezed unions prevent invalid state combinations
- **Error Handling**: Explicit error states with Either type
- **Documentation**: Architecture communicates intent clearly

Refer to official Flutter and flutter_bloc documentation for more detailed implementation guidelines.
