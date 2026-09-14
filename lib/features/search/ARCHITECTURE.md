# Search Feature Architecture (Client-Side)

## Overview
The `search` feature in Flutter operates as a **Clean Client** interfacing with the dedicated **Python FastAPI Backend (`backend/`)**. 

All heavy operations—including autonomous tool planning, web scraping, SearXNG meta-search, vector embeddings with FastEmbed, Qdrant vector storage, and document chunking—are executed on the backend. The Flutter app focuses on high-performance streaming presentation, generative UI widgets, and conversation management.

## Directory Structure

```
lib/features/search/
  ├── data/
  │   ├── datasources/
  │   │   └── search_data_source.dart   # SSE Stream & HTTP API client for backend
  │   ├── models/
  │   │   ├── search_stream_update.dart        # Real-time event chunks from SSE stream
  │   │   └── search_response_model.dart       # Search results serialization
  │   └── repositories/
  │       └── search_repository_impl.dart      # Clean repository bridging domain to remote API
  ├── domain/
  │   ├── entities/                            # Domain entities (MessageData, SourceItem, etc.)
  │   │   ├── search_stream_status.dart        # Stream lifecycle status enum
  │   │   ├── source_item.dart                 # Web citations & sources
  │   │   ├── message_data.dart                # Completed/in-progress message payload
  │   │   ├── search_step.dart                 # Real-time execution steps
  │   │   ├── tool_widget_data.dart            # Payloads for Generative UI widgets
  │   │   ├── autocomplete_entities.dart       # Search suggestion models
  │   │   ├── search_enums.dart                # Search categories & filters
  │   │   ├── message_branch.dart              # Multi-branch chat conversation state
  │   │   ├── message_branch_manager.dart      # Branch tree traversal
  │   │   ├── message_generation_state.dart    # UI generation status
  │   │   ├── image_item.dart                  # Media results
  │   │   └── video_item.dart                  # Media results
  │   ├── repositories/
  │   │   └── search_repository.dart           # Repository interface
  │   └── usecases/
  │       └── get_autocomplete_suggestions_usecase.dart  # Debounced suggestions usecase
  ├── presentation/
  │   ├── bloc/                                # SearchBloc & ConversationManager
  │   ├── pages/                               # Full-screen search results view
  │   └── widgets/                             # SearchBox, MessageBox, and generative UI widgets
  ├── theme/
  │   └── search_theme.dart                    # Visual styles and colors
  └── di/
      └── search_dependencies.dart             # GetIt dependency injection
```
