/// Onboarding feature - Setup wizard and initial configuration
/// 
/// This module provides a smooth onboarding experience for new users,
/// guiding them through essential configuration like AI provider setup.
/// 
/// Usage:
/// ```dart
/// import 'package:searvo/features/onboarding/onboarding.dart';
/// 
/// // Check if setup is needed
/// if (SetupService().needsSetup) {
///   // Show setup wizard
/// }
/// ```

library;

// Services
export 'services/setup_service.dart';

// Models
export 'models/setup_models.dart';

// Screens
export 'screens/setup_wizard_screen.dart';

// Widgets
export 'widgets/setup_step_indicator.dart';
export 'widgets/steps/welcome_step.dart';
export 'widgets/steps/provider_selection_step.dart';
export 'widgets/steps/api_key_step.dart';
export 'widgets/steps/completion_step.dart';
