// Discover Feature Barrel File
// This file exports all the public APIs of the discover feature

// Domain
export 'domain/entities/article.dart';
export 'domain/repositories/discover_repository.dart';
export 'domain/usecases/get_articles.dart';

// Data
export 'data/models/article_model.dart';
export 'data/repositories/discover_repository_impl.dart';
export 'data/datasources/discover_remote_datasource.dart';

// Presentation
export 'presentation/cubit/discover_cubit.dart';
export 'presentation/cubit/discover_state.dart';

// Screens
export 'screens/discover_screen.dart';

// Theme
export 'theme/discover_theme.dart';

// Widgets
export 'widgets/major_news_card.dart';
export 'widgets/small_news_card.dart';
export 'widgets/editorial_hero_card.dart';
export 'widgets/editorial_article_card.dart';
export 'widgets/editorial_compact_card.dart';

// Dependency Injection
export 'di/discover_dependencies.dart';
