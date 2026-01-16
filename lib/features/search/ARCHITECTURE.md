# Search Feature Architecture

## Overview
The `search` feature has been refactored to follow **Clean Architecture** principles, improving scalability, testability, and maintainability. This structure aligns with `features/history` key principles.

## Directory Structure

### `domain/` (Business Logic)
Contains the core business logic, independent of UI or Data layers.
- **`entities/`**: Plain Dart objects representing business concepts (e.g., `MessageData`, `SearchIntent`, `RagDocument`).
- **`repositories/`**: Interfaces (abstract classes) defining the contract for data operations.
- **`usecases/`**: Classes encapsulating specific business rules/actions (e.g., `PerformSearchUseCase`).

### `data/` (Data Access)
Implements the interfaces defined in the Domain layer.
- **`datasources/`**: Low-level data access (e.g., `SearXNGService` - to be migrated here, `DriftDB`).
- **`models/`**: DTOs (Data Transfer Objects) that extend Entities and handle JSON/DB serialization.
- **`repositories/`**: Implementations of Domain Repositories.

### `presentation/` (UI & State)
Handles the user interface and state management.
- **`bloc/`**: State management using BLoC pattern (e.g., `SearchBloc`).
- **`pages/`**: Full screen widgets.
- **`widgets/`**: Reusable UI components.

## RAG Sub-feature
The `rag` module contains specialized logic for Retrieval Augmented Generation.
- **`domain/`**: RAG-specific entities (`RagDocument`, `ContextChunk`) and logic.
- **`services/`**: specialized services for RAG orchestration (to be migrated to `domain/usecases` or `data/datasources`).

## Refactoring Status & Naming Conventions

### Entities (Completed)
All models have been moved to `domain/entities` and split into granular files to adhere to Single Responsibility Principle.
- `MessageData` -> Split into `message_data.dart`, `source_item.dart`, `video_item.dart`, `attachment_metadata.dart`.
- `RagDocument` -> Split from `rag_models.dart`.
- `SearchIntent`, `SearchMode`, `SearchStep`.

### Pending Migrations (Next Steps)
To fully realize the architecture, the following services should be migrated:

| Current File | Proposed Location | New Name | Status |
|--------------|-------------------|----------|--------|
| `services/search_service.dart` | `domain/usecases/` | `SearchUseCase` (Facade) | Pending |
| `services/searxng_service.dart` | `data/datasources/` | `SearXNGRemoteDataSource` | **Done** (with backward compat) |
| `services/conversation_manager.dart` | `presentation/bloc/` | `ConversationManager` | **Done** (Moved) |
| `rag/services/*` | `rag/domain/services/` | Keep as Domain Services | Pending |

## Naming Guidelines
- **Entities**: Nouns, no suffix (e.g., `Message`).
- **Models**: `NameModel` (e.g., `MessageModel`) extends Entity.
- **Repositories**: `NameRepository` (Interface), `NameRepositoryImpl` (Implementation).
- **Data Sources**: `NameRemoteDataSource`, `NameLocalDataSource`.
- **Use Cases**: `VerbNounUseCase` (e.g., `GetSearchResultsUseCase`).
