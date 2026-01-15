# Clean Architecture Migration Guide

## Overview
This document tracks the migration from Provider pattern to Clean Architecture with flutter_bloc, Dartz, GetIt, and Freezed.

## Migration Status

### Core Infrastructure ✅
- [x] Remove Provider dependency from pubspec.yaml
- [x] Created Failure classes with Equatable in `core/error/failures.dart`
- [x] Created Exception classes in `core/error/exceptions.dart`
- [x] Created UseCase base classes in `core/usecases/usecase.dart`
- [x] Created Either extensions in `core/utils/either_extensions.dart`
- [x] Created BlocObserver in `core/utils/bloc_observer.dart`
- [x] Created NetworkInfo abstraction in `core/network/network_info.dart`
- [x] Created DI container in `core/di/injection_container.dart`

### Features Migration

#### Auth Feature
- [ ] Create domain layer (entities, repository interfaces, use cases)
- [ ] Create data layer (data sources, models, repository implementation)
- [ ] Create presentation layer (Bloc/Cubit with Freezed states/events)
- [ ] Register dependencies in DI container
- [ ] Update UI to use BlocBuilder/BlocListener

#### Settings Feature
- [ ] Restructure to Clean Architecture layers
- [ ] Create domain layer
- [ ] Create data layer
- [ ] Migrate from ChangeNotifier to Cubit
- [ ] Register dependencies

#### LLM Feature
- [ ] Restructure to Clean Architecture layers
- [ ] Create domain layer
- [ ] Create data layer
- [ ] Migrate from ChangeNotifier to Bloc
- [ ] Register dependencies

#### Search Feature
- [ ] Restructure to Clean Architecture layers
- [ ] Create domain layer
- [ ] Create data layer
- [ ] Migrate from ChangeNotifier to Bloc
- [ ] Register dependencies

#### RAG Feature
- [ ] Restructure to Clean Architecture layers
- [ ] Create domain layer
- [ ] Create data layer
- [ ] Migrate from ChangeNotifier to Bloc
- [ ] Register dependencies

#### History Feature
- [ ] Restructure to Clean Architecture layers
- [ ] Create domain layer
- [ ] Create data layer
- [ ] Migrate from ChangeNotifier to Bloc
- [ ] Register dependencies

#### Discover Feature
- [ ] Restructure to Clean Architecture layers
- [ ] Create domain layer
- [ ] Create data layer
- [ ] Migrate from ChangeNotifier to Cubit
- [ ] Register dependencies

### Main App Updates
- [ ] Update main.dart to use GetIt instead of MultiProvider
- [ ] Set up BlocObserver
- [ ] Initialize dependency injection
- [ ] Update router to inject Blocs/Cubits

### Testing
- [ ] Update tests to use mockito for repository mocks
- [ ] Add bloc_test for state testing
- [ ] Ensure all features work correctly
- [ ] Run flutter analyze

## Directory Structure

Each feature should follow this structure:

```
lib/features/feature_name/
├── data/
│   ├── datasources/
│   │   ├── feature_remote_datasource.dart
│   │   └── feature_local_datasource.dart
│   ├── models/
│   │   └── feature_model.dart
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── usecases/
│       ├── get_feature.dart
│       └── update_feature.dart
└── presentation/
    ├── bloc/
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    ├── pages/
    │   └── feature_page.dart
    └── widgets/
        └── feature_widget.dart
```

## Code Patterns

### State with Freezed
```dart
@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState.initial() = _Initial;
  const factory FeatureState.loading() = _Loading;
  const factory FeatureState.loaded(Entity data) = _Loaded;
  const factory FeatureState.error(Failure failure) = _Error;
}
```

### Repository Interface (Domain Layer)
```dart
abstract class FeatureRepository {
  Future<Either<Failure, Entity>> getEntity(String id);
  Future<Either<Failure, Unit>> saveEntity(Entity entity);
}
```

### Repository Implementation (Data Layer)
```dart
class FeatureRepositoryImpl implements FeatureRepository {
  final FeatureRemoteDataSource remoteDataSource;
  final FeatureLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, Entity>> getEntity(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.getEntity(id);
        await localDataSource.cacheEntity(model);
        return Right(model.toEntity());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final model = await localDataSource.getEntity(id);
        return Right(model.toEntity());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
```

### Use Case
```dart
class GetEntity extends UseCase<Entity, String> {
  final FeatureRepository repository;

  GetEntity(this.repository);

  @override
  Future<Either<Failure, Entity>> call(String id) async {
    return await repository.getEntity(id);
  }
}
```

### Bloc
```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final GetEntity getEntity;

  FeatureBloc({required this.getEntity}) 
      : super(const FeatureState.initial()) {
    on<_GetEntity>(_onGetEntity);
  }

  Future<void> _onGetEntity(
    _GetEntity event,
    Emitter<FeatureState> emit,
  ) async {
    emit(const FeatureState.loading());
    final result = await getEntity(event.id);
    result.fold(
      (failure) => emit(FeatureState.error(failure)),
      (entity) => emit(FeatureState.loaded(entity)),
    );
  }
}
```

### UI with BlocBuilder
```dart
BlocBuilder<FeatureBloc, FeatureState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      loaded: (data) => DataWidget(data: data),
      error: (failure) => ErrorWidget(message: failure.message),
    );
  },
)
```

## Next Steps
1. Complete Settings feature migration as proof of concept
2. Document lessons learned
3. Apply to remaining features
4. Update main.dart
5. Run tests and verify
