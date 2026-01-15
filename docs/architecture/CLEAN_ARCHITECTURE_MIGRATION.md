# Clean Architecture Migration Guide

## Overview

This document outlines the migration strategy from the current Provider-based architecture to Clean Architecture with flutter_bloc, Dartz, and GetIt dependency injection.

## Current State

The codebase currently uses:
- **State Management**: Provider with ChangeNotifier
- **Architecture**: Feature-first organization with services and providers
- **Dependency Management**: Singleton pattern with factory constructors
- **Error Handling**: Try-catch blocks with custom error handling utilities

## Target Architecture

### Clean Architecture Layers

```
lib/
├── core/                          # Shared/common code
│   ├── error/                     # Error handling, failures, exceptions
│   │   ├── failures.dart          # Failure classes for domain layer
│   │   └── exceptions.dart        # Exception classes for data layer
│   ├── usecases/                  # Base use case class
│   │   └── usecase.dart
│   ├── utils/                     # Utility functions and extensions
│   │   └── either_extensions.dart # Dartz Either extensions
│   └── di/                        # Dependency injection
│       └── injection_container.dart # GetIt service locator
├── features/                      # All app features
│   ├── feature_name/              # Single feature
│   │   ├── data/                  # Data layer
│   │   │   ├── datasources/       # Remote and local data sources
│   │   │   ├── models/            # DTOs and data models (with Freezed)
│   │   │   └── repositories/      # Repository implementations
│   │   ├── domain/                # Domain layer (pure Dart)
│   │   │   ├── entities/          # Business objects (with Freezed)
│   │   │   ├── repositories/      # Repository interfaces
│   │   │   └── usecases/          # Business logic use cases
│   │   └── presentation/          # Presentation layer
│   │       ├── bloc/              # Bloc/Cubit state management
│   │       │   ├── feature_bloc.dart
│   │       │   ├── feature_event.dart
│   │       │   └── feature_state.dart
│   │       ├── pages/             # Screen widgets
│   │       └── widgets/           # Feature-specific widgets
```

### Technology Stack

#### Dependencies Added
```yaml
# State management
flutter_bloc: ^8.1.6
equatable: ^2.0.5

# Functional programming
dartz: ^0.10.1

# Dependency injection
get_it: ^8.0.2

# Immutable state classes
freezed_annotation: ^2.4.4
freezed: ^2.5.7
json_annotation: ^4.9.0
json_serializable: ^6.8.0

# Testing
bloc_test: ^9.1.7
mockito: ^5.4.4
```

## Migration Strategy

### Phase 1: Setup (Completed ✅)

1. ✅ Add required dependencies to `pubspec.yaml`
2. ✅ Create core base classes:
   - Failure classes in `core/error/failures.dart`
   - Exception classes in `core/error/exceptions.dart`
   - UseCase base class in `core/usecases/usecase.dart`
   - Either extensions in `core/utils/either_extensions.dart`
3. ✅ Set up GetIt dependency injection container
4. ✅ Initialize GetIt in `main.dart`

### Phase 2: Pilot Feature Migration - Weather (Completed ✅)

The **weather** feature was chosen as the pilot because:
- It's relatively simple with no complex state management
- It has clear boundaries (models, services)
- It demonstrates all Clean Architecture layers

#### Weather Feature Migration Steps:

**1. Domain Layer (Pure Dart)**
   - ✅ Created `WeatherEntity` (domain entity with Freezed)
   - ✅ Created `WeatherRepository` interface
   - ✅ Created use cases:
     - `GetWeather` - Fetch weather with validation
     - `ClearWeatherCache` - Clear cached data

**2. Data Layer**
   - ✅ Created `WeatherModel` with Freezed (DTO for API/cache)
   - ✅ Created `WeatherRemoteDataSource` (API calls)
   - ✅ Created `WeatherLocalDataSource` (caching)
   - ✅ Created `WeatherRepositoryImpl` (repository implementation)
   - Implements error handling with Either<Failure, Success>
   - Maps exceptions to failures
   - Provides fallback data on errors

**3. Presentation Layer**
   - ✅ Created Bloc with:
     - `WeatherEvent` (union types with Freezed)
     - `WeatherState` (union types with Freezed)
     - `WeatherBloc` (event handlers)
   - State transitions: initial → loading → loaded/error
   - Handles refresh and cache clearing

**4. Dependency Injection**
   - ✅ Registered all weather dependencies in GetIt
   - ✅ Proper dependency chain: Bloc → Use Cases → Repository → Data Sources

### Phase 3: Feature-by-Feature Migration (Next Steps)

Recommended migration order (from simple to complex):

1. **discover** - Similar to weather, simple data fetching
2. **voice** - Service-heavy, good for testing service migration
3. **llm** - Medium complexity, multi-provider pattern
4. **settings** - State-heavy but straightforward
5. **auth** - Critical feature, migrate carefully
6. **history** - Database interactions, complex sync logic
7. **search** - Most complex, RAG pipeline, multiple integrations

### Migration Checklist Per Feature

For each feature, follow these steps:

#### Domain Layer
- [ ] Create entity classes with Freezed
- [ ] Define repository interface (abstract class)
- [ ] Create use cases for each business operation
- [ ] Each use case should:
  - Extend `UseCase<ReturnType, Params>`
  - Implement call() returning `Either<Failure, ReturnType>`
  - Handle input validation

#### Data Layer
- [ ] Create model classes with Freezed and json_serializable
- [ ] Add `toEntity()` and `fromEntity()` methods
- [ ] Create remote data source interface and implementation
- [ ] Create local data source interface and implementation (if needed)
- [ ] Create repository implementation:
  - Implement domain repository interface
  - Coordinate between data sources
  - Map exceptions to failures using try-catch
  - Return `Either<Failure, Success>`

#### Presentation Layer
- [ ] Create event class with Freezed unions
- [ ] Create state class with Freezed unions
  - Include: initial, loading, loaded, error states
- [ ] Create Bloc/Cubit:
  - Inject use cases via constructor
  - Handle each event type
  - Emit appropriate states
  - Use developer.log for logging

#### Dependency Injection
- [ ] Create feature initialization function in `injection_container.dart`
- [ ] Register data sources (lazy singleton)
- [ ] Register repository (lazy singleton)
- [ ] Register use cases (lazy singleton)
- [ ] Register Bloc (factory - new instance each time)

#### UI Layer
- [ ] Wrap screen with `BlocProvider`
- [ ] Use `BlocBuilder` for state-based UI
- [ ] Use `BlocListener` for side effects (navigation, dialogs)
- [ ] Use `context.read<Bloc>()` to dispatch events
- [ ] Handle all state cases with `state.maybeWhen()`

## Code Generation

After creating/modifying Freezed classes, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Testing Strategy

### Unit Tests

**Domain Layer (Priority: High)**
```dart
// Test use cases
test('should validate coordinates', () async {
  // Given
  final params = GetWeatherParams(latitude: 100, longitude: 0);
  
  // When
  final result = await useCase(params);
  
  // Then
  expect(result.isLeft, true);
  result.fold(
    (failure) => expect(failure, isA<ValidationFailure>()),
    (_) => fail('Should return failure'),
  );
});
```

**Data Layer (Priority: High)**
```dart
// Test repository
test('should return weather entity when call succeeds', () async {
  // Arrange
  when(mockRemoteDataSource.getWeather(any, any))
      .thenAnswer((_) async => tWeatherModel);
  
  // Act
  final result = await repository.getWeather(0, 0);
  
  // Assert
  expect(result, equals(Right(tWeatherEntity)));
});
```

**Presentation Layer (Priority: Medium)**
```dart
// Test Bloc with bloc_test
blocTest<WeatherBloc, WeatherState>(
  'emits [loading, loaded] when GetWeather succeeds',
  build: () {
    when(() => mockGetWeather(any))
        .thenAnswer((_) async => Right(tWeatherEntity));
    return weatherBloc;
  },
  act: (bloc) => bloc.add(
    WeatherEvent.getWeather(latitude: 0, longitude: 0),
  ),
  expect: () => [
    const WeatherState.loading(),
    WeatherState.loaded(
      weather: tWeatherEntity,
      latitude: 0,
      longitude: 0,
    ),
  ],
);
```

## Key Patterns and Best Practices

### 1. Either for Error Handling

```dart
// Instead of try-catch returning objects directly
// OLD:
Future<Weather> getWeather() async {
  try {
    return await api.fetchWeather();
  } catch (e) {
    throw Exception(e);
  }
}

// NEW:
Future<Either<Failure, WeatherEntity>> getWeather() async {
  try {
    final result = await remoteDataSource.getWeather();
    return Right(result.toEntity());
  } on ServerException {
    return Left(ServerFailure());
  } on NetworkException {
    return Left(NetworkFailure());
  }
}
```

### 2. Freezed Unions for Type-Safe States

```dart
// Type-safe state handling
state.maybeWhen(
  loading: () => CircularProgressIndicator(),
  loaded: (weather, lat, lng) => WeatherDisplay(weather: weather),
  error: (message, fallback) => ErrorWidget(message: message),
  orElse: () => SizedBox(),
);
```

### 3. Dependency Injection with GetIt

```dart
// Instead of singletons
// OLD:
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
}

// NEW:
// Register in injection_container.dart
getIt.registerFactory(() => WeatherBloc(getWeather: getIt()));

// Use in widget
BlocProvider(
  create: (context) => getIt<WeatherBloc>(),
  child: WeatherScreen(),
)
```

### 4. Use Cases for Business Logic

```dart
// Encapsulate business logic in use cases
class GetWeather implements UseCase<WeatherEntity, GetWeatherParams> {
  final WeatherRepository repository;

  GetWeather(this.repository);

  @override
  Future<Either<Failure, WeatherEntity>> call(GetWeatherParams params) async {
    // Validate inputs
    if (params.latitude.abs() > 90) {
      return Left(ValidationFailure('Invalid latitude'));
    }
    
    // Delegate to repository
    return await repository.getWeather(params.latitude, params.longitude);
  }
}
```

### 5. Separation of Models and Entities

```dart
// Data layer model (DTO)
@freezed
class WeatherModel with _$WeatherModel {
  factory WeatherModel.fromJson(Map<String, dynamic> json) => ...;
  WeatherEntity toEntity() => ...;
}

// Domain layer entity (business object)
@freezed
class WeatherEntity with _$WeatherEntity {
  // Domain-specific methods
  String get windDirectionCompass => ...;
}
```

## Coexistence Strategy

During migration, both architectures will coexist:

1. **Provider-based features** - Continue working as before
2. **Bloc-based features** - Use new Clean Architecture

### In main.dart:

```dart
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      // Existing Provider-based features
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      // ... other providers
    ],
    child: MaterialApp.router(
      // ... app configuration
    ),
  );
}

// Use BlocProvider for new features in specific screens
class WeatherScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<WeatherBloc>()
        ..add(WeatherEvent.getWeather(latitude: 0, longitude: 0)),
      child: WeatherView(),
    );
  }
}
```

## Benefits of Migration

### Testability
- Pure domain layer with no Flutter dependencies
- Easy to mock with interfaces
- Use cases are simple, testable units

### Maintainability
- Clear separation of concerns (domain, data, presentation)
- Each layer has specific responsibilities
- Changes in one layer don't affect others

### Scalability
- Features are independent modules
- Easy to add new features following the same pattern
- Team members can work on different features without conflicts

### Type Safety
- Freezed unions prevent invalid state combinations
- Either type forces explicit error handling
- Compiler catches more errors at build time

### Error Handling
- Explicit error states with detailed failure information
- Functional approach with Either eliminates throwing exceptions
- Predictable error flow from data source to UI

## Common Pitfalls to Avoid

1. **Don't put Flutter dependencies in domain layer**
   - Domain should be pure Dart
   - No imports from `package:flutter`

2. **Don't bypass use cases**
   - Always go through use cases, even for simple operations
   - They centralize business logic and validation

3. **Don't create circular dependencies**
   - Respect the dependency rule: Presentation → Domain ← Data
   - Never import from presentation in domain/data

4. **Don't forget to register dependencies**
   - All classes should be registered in GetIt
   - Prefer lazy singletons for stateless services
   - Use factories for stateful Blocs

5. **Don't mix old and new patterns in the same feature**
   - Migrate entire features, not partial implementations
   - Keep boundaries clear

## Migration Progress Tracking

Use this checklist to track migration progress:

- [x] Phase 1: Setup and base classes
- [x] Phase 2: Pilot feature (weather)
- [ ] Phase 3: Discover feature
- [ ] Phase 4: Voice feature
- [ ] Phase 5: LLM feature
- [ ] Phase 6: Settings feature
- [ ] Phase 7: Auth feature
- [ ] Phase 8: History feature
- [ ] Phase 9: Search feature (most complex)
- [ ] Phase 10: Remove old Provider-based code
- [ ] Phase 11: Update documentation

## Resources

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [flutter_bloc Documentation](https://bloclibrary.dev/)
- [Dartz Documentation](https://pub.dev/packages/dartz)
- [GetIt Documentation](https://pub.dev/packages/get_it)
- [Freezed Documentation](https://pub.dev/packages/freezed)

## Next Steps

1. Run code generation for weather feature:
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. Test the weather feature with new architecture

3. Choose the next feature to migrate (recommend: discover)

4. Follow the migration checklist for that feature

5. Write tests for migrated features

6. Update this document with lessons learned

---

**Last Updated**: December 28, 2025
**Migration Status**: Phase 2 Complete (Weather Feature)
**Next Feature**: Discover or Voice
