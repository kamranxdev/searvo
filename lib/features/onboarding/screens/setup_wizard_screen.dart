import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/common/widgets/app_logo.dart';
import 'package:searvo/features/onboarding/models/setup_models.dart';
import 'package:searvo/features/onboarding/services/setup_service.dart';
import 'package:searvo/features/onboarding/widgets/setup_step_indicator.dart';
import 'package:searvo/features/onboarding/widgets/steps/welcome_step.dart';
import 'package:searvo/features/onboarding/widgets/steps/provider_selection_step.dart';
import 'package:searvo/features/onboarding/widgets/steps/api_key_step.dart';
import 'package:searvo/features/onboarding/widgets/steps/completion_step.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';

/// Setup Wizard Screen - A beautiful PageView-based onboarding flow
/// Guides users through essential configuration after authentication
/// Responsive design with layouts for desktop, tablet, and mobile
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final SetupService _setupService = SetupService();
  final LLMSettingsService _llmSettings = LLMSettingsService();
  
  // Responsive breakpoints
  static const double _desktopBreakpoint = 900;
  static const double _tabletBreakpoint = 600;
  
  int _currentPage = 0;
  final int _totalPages = 4;
  
  // State
  String? _selectedProvider;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Text controllers for API key input
  final TextEditingController _apiKeyController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
  
  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }
  
  void _onProviderSelected(String providerId) {
    setState(() {
      _selectedProvider = providerId;
      _errorMessage = null;
      _apiKeyController.clear();
    });
  }
  
  Future<void> _saveApiKey(String apiKey) async {
    if (_selectedProvider == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      bool success = false;
      
      switch (_selectedProvider) {
        case 'openai':
          success = await _llmSettings.setOpenAIApiKey(apiKey);
          break;
        case 'google':
          success = await _llmSettings.setGoogleApiKey(apiKey);
          break;
        case 'anthropic':
          success = await _llmSettings.setAnthropicApiKey(apiKey);
          break;
        case 'openrouter':
          success = await _llmSettings.setOpenRouterApiKey(apiKey);
          break;
        case 'ollama':
          success = await _llmSettings.setOllamaBaseUrl(apiKey);
          break;
      }
      
      if (success) {
        // Set as active provider
        await _llmSettings.setActiveProviderByName(_selectedProvider!);
        await _llmSettings.initializeLLMManager();
        _nextPage();
      } else {
        setState(() {
          _errorMessage = 'Failed to save configuration. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);
    
    await _setupService.completeSetup();
    
    if (mounted) {
      // Navigate to home
      context.go('/');
    }
  }
  
  Future<void> _skipSetup() async {
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Setup?'),
        content: const Text(
          'You can configure AI providers later in Settings. '
          'Some features may not work until you set up at least one provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    
    if (shouldSkip == true) {
      await _setupService.skipSetup();
      if (mounted) {
        context.go('/');
      }
    }
  }
  
  AIProviderOption? get _selectedProviderOption {
    if (_selectedProvider == null) return null;
    return AIProviderOption.allProviders.firstWhere(
      (p) => p.id == _selectedProvider,
      orElse: () => AIProviderOption.allProviders.first,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
                final isTablet = constraints.maxWidth >= _tabletBreakpoint &&
                    constraints.maxWidth < _desktopBreakpoint;
                
                if (isDesktop) {
                  return _buildDesktopLayout(context, colorScheme);
                } else if (isTablet) {
                  return _buildTabletLayout(context, colorScheme);
                } else {
                  return _buildMobileLayout(context, colorScheme);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
  
  /// Desktop Layout - Split screen with branding on left, wizard on right
  Widget _buildDesktopLayout(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        // Left side - Branding panel
        Expanded(
          flex: 5,
          child: _buildBrandingPanel(context, colorScheme, isDesktop: true),
        ),
        
        // Right side - Wizard content
        Expanded(
          flex: 5,
          child: Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                _buildHeader(colorScheme, isCompact: false),
                Expanded(
                  child: _buildWizardPageView(isDesktop: true, isTablet: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Tablet Layout - Centered content with max width constraint
  Widget _buildTabletLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildHeader(colorScheme, isCompact: false),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildWizardPageView(isDesktop: false, isTablet: true),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Mobile Layout - Full width content
  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildHeader(colorScheme, isCompact: true),
        Expanded(
          child: _buildWizardPageView(isDesktop: false, isTablet: false),
        ),
      ],
    );
  }
  
  /// Branding panel for desktop layout
  Widget _buildBrandingPanel(
    BuildContext context, 
    ColorScheme colorScheme,
    {required bool isDesktop}
  ) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: const Center(
                child: AppLogo(size: 48, withBackground: false),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Title
            Text(
              'Setup Your\nAI Assistant',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Goldman',
                height: 1.2,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Subtitle
            Text(
              'Configure your preferred AI provider to unlock powerful search capabilities.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.6,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Features
            _buildDesktopFeature(
              context,
              icon: Icons.search_rounded,
              title: 'Intelligent Search',
              description: 'AI-enhanced results from multiple sources',
            ),
            const SizedBox(height: 24),
            _buildDesktopFeature(
              context,
              icon: Icons.psychology_rounded,
              title: 'Multiple Providers',
              description: 'OpenAI, Gemini, Claude, and more',
            ),
            const SizedBox(height: 24),
            _buildDesktopFeature(
              context,
              icon: Icons.security_rounded,
              title: 'Privacy First',
              description: 'Your data stays secure and private',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDesktopFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Wizard PageView with step content
  Widget _buildWizardPageView({required bool isDesktop, required bool isTablet}) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
          _errorMessage = null;
        });
      },
      children: [
        // Step 1: Welcome
        WelcomeStep(
          onGetStarted: _nextPage,
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        
        // Step 2: Provider Selection
        ProviderSelectionStep(
          selectedProvider: _selectedProvider,
          onProviderSelected: _onProviderSelected,
          onContinue: _selectedProvider != null ? _nextPage : null,
          onBack: _previousPage,
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        
        // Step 3: API Key Entry
        ApiKeyStep(
          provider: _selectedProviderOption,
          controller: _apiKeyController,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onSave: _saveApiKey,
          onBack: _previousPage,
          onSkip: () {
            // Skip API key and go to completion
            _goToPage(3);
          },
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        
        // Step 4: Completion
        CompletionStep(
          selectedProvider: _selectedProviderOption?.name,
          isConfigured: _setupService.hasMinimumRequirements,
          onComplete: _completeSetup,
          onAddMore: () => _goToPage(1),
          isLoading: _isLoading,
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
      ],
    );
  }
  
  Widget _buildHeader(ColorScheme colorScheme, {bool isCompact = false}) {
    final padding = isCompact 
        ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    
    return Padding(
      padding: padding,
      child: Row(
        children: [
          // Step indicator
          Expanded(
            child: SetupStepIndicator(
              currentStep: _currentPage,
              totalSteps: _totalPages,
              isCompact: isCompact,
            ),
          ),
          
          // Skip button (only show on first 3 pages)
          if (_currentPage < 3)
            TextButton(
              onPressed: _skipSetup,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
