import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../core/theme/theme.dart';

/// Authentication screen with Google Sign-In
/// Provides a secure and user-friendly authentication experience
/// Uses LayoutBuilder for responsive design across mobile, tablet, and desktop
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAuth();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initAuth() async {
    await _authService.initialize();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final user = await _authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (user != null) {
      // Navigate to home screen on successful sign-in
      context.go('/');
    } else if (_authService.errorMessage != null) {
      // Show error message
      _showErrorSnackBar(_authService.errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  // Helper method to create consistent subtitle with tagline
  Widget _buildSubtitleRichText({TextAlign textAlign = TextAlign.start, bool isMobile = false}) {
    final theme = Theme.of(context);

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: isMobile
            ? theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w400,
                height: 1.5,
              )
            : theme.textTheme.titleLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
        children: [
          const TextSpan(
            text: '🇮🇳 India\'s Premier AI-Powered Search Engine',
          ),
          TextSpan(
            text: isMobile
                ? '\nYour intelligent search companion'
                : ' - Your intelligent companion for discovering, organizing, and syncing across multiple search engines.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine device type based on width
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

          if (isDesktop) {
            return _buildDesktopLayout(context);
          } else if (isTablet) {
            return _buildTabletLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  // Desktop Layout - Split screen design
  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Row(
      children: [
        // Left Side - Branding & Features
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withOpacity(0.1),
                  colorScheme.surface.withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Brand
                  Row(
                    children: [
                      const AppLogo(
                        size: 40,
                        withBackground: true,
                        backgroundOpacity: 0.15,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Searvo',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Goldman',
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),

                  // Main Heading
                  Text(
                    'Your Intelligent\nSearch Companion',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subtitle
                  _buildSubtitleRichText(),
                  const SizedBox(height: 48),

                  // Features List
                  _buildDesktopFeature(
                    context,
                    icon: Icons.search_rounded,
                    title: 'Smart Search',
                    description: 'AI-powered search with multiple engines for comprehensive results',
                  ),
                  const SizedBox(height: 32),
                  _buildDesktopFeature(
                    context,
                    icon: Icons.library_books_rounded,
                    title: 'Personal Library',
                    description: 'Save and organize your searches with intelligent categorization',
                  ),
                  const SizedBox(height: 32),
                  _buildDesktopFeature(
                    context,
                    icon: Icons.sync_rounded,
                    title: 'Sync Across Devices',
                    description: 'Access your data anywhere, anytime, on any device',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Side - Auth Form
        Expanded(
          flex: 4,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 48.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to continue to Searvo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 64),

                          // Google Sign-In Button
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _buildDesktopGoogleButton(context, isDark),
                          const SizedBox(height: 48),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.dividerColor)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Secure Authentication',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: theme.dividerColor)),
                            ],
                          ),
                          const SizedBox(height: 48),

                          // Security Features
                          _buildSecurityBadge(
                            context,
                            icon: Icons.security_rounded,
                            text: 'End-to-end encryption',
                          ),
                          const SizedBox(height: 16),
                          _buildSecurityBadge(
                            context,
                            icon: Icons.verified_user_rounded,
                            text: 'Verified & secure authentication',
                          ),
                          const SizedBox(height: 16),
                          _buildSecurityBadge(
                            context,
                            icon: Icons.privacy_tip_rounded,
                            text: 'Your privacy is our priority',
                          ),
                          const SizedBox(height: 48),

                          // Terms
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(text: 'By continuing, you agree to our '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: '\nand '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.go('/privacy-policy'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Tablet Layout - Similar to mobile but with more spacing
  Widget _buildTabletLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 48.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surface.withOpacity(0.2),
                            colorScheme.surface.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: AppLogo(size: 60),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Welcome Text
                    Text(
                      'Welcome to Searvo',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Goldman',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    _buildSubtitleRichText(textAlign: TextAlign.center),
                    const SizedBox(height: 44),

                    // Features List
                    _buildTabletFeatureItem(
                      context,
                      icon: Icons.search_rounded,
                      title: 'Smart Search',
                      description: 'AI-powered search with multiple engines',
                    ),
                    const SizedBox(height: 20),
                    _buildTabletFeatureItem(
                      context,
                      icon: Icons.library_books_rounded,
                      title: 'Personal Library',
                      description: 'Save and organize your searches',
                    ),
                    const SizedBox(height: 20),
                    _buildTabletFeatureItem(
                      context,
                      icon: Icons.sync_rounded,
                      title: 'Sync Across Devices',
                      description: 'Access your data anywhere',
                    ),
                    const SizedBox(height: 56),

                    // Google Sign-In Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : _buildTabletGoogleButton(context, isDark),
                    const SizedBox(height: 32),

                    // Privacy Policy and Terms
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: '\nand '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.go('/privacy-policy'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile Layout - Optimized for small screens
  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surface.withOpacity(0.2),
                          colorScheme.surface.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: AppLogo(size: 80.w),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Welcome Text
                  Text(
                    'Welcome to Searvo',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Goldman',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),

                  // Subtitle
                  _buildSubtitleRichText(textAlign: TextAlign.center, isMobile: true),
                  SizedBox(height: 32.h),

                  // Features List
                  _buildMobileFeatureItem(
                    context,
                    icon: Icons.search_rounded,
                    title: 'Smart Search',
                    description: 'AI-powered search with multiple engines',
                  ),
                  SizedBox(height: 16.h),
                  _buildMobileFeatureItem(
                    context,
                    icon: Icons.library_books_rounded,
                    title: 'Personal Library',
                    description: 'Save and organize your searches',
                  ),
                  SizedBox(height: 16.h),
                  _buildMobileFeatureItem(
                    context,
                    icon: Icons.sync_rounded,
                    title: 'Sync Across Devices',
                    description: 'Access your data anywhere',
                  ),
                  SizedBox(height: 48.h),

                  // Google Sign-In Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : _buildMobileGoogleButton(context, isDark),
                  SizedBox(height: 24.h),

                  // Privacy Policy and Terms
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.go('/privacy-policy'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Desktop Feature Widget
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: colorScheme.onSurface,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tablet Feature Widget
  Widget _buildTabletFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Feature Widget
  Widget _buildMobileFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
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
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Google Sign-In Button
  Widget _buildDesktopGoogleButton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : theme.primaryColor).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/google_logo.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.g_mobiledata_rounded,
                    size: 32,
                    color: isDark ? theme.primaryColor : Colors.white,
                  );
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Continue with Google',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isDark ? theme.primaryColor : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tablet Google Sign-In Button
  Widget _buildTabletGoogleButton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? Colors.white : theme.primaryColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      child: InkWell(
        onTap: _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/google_logo.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.g_mobiledata_rounded,
                    size: 32,
                    color: isDark ? theme.primaryColor : Colors.white,
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isDark ? theme.primaryColor : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Google Sign-In Button
  Widget _buildMobileGoogleButton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? Colors.white : theme.primaryColor,
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      child: InkWell(
        onTap: _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/google_logo.png',
                width: 24.w,
                height: 24.w,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.g_mobiledata_rounded,
                    size: 32.sp,
                    color: isDark ? theme.primaryColor : Colors.white,
                  );
                },
              ),
              SizedBox(width: 12.w),
              Text(
                'Continue with Google',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? theme.primaryColor : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Security Badge Widget for Desktop
  Widget _buildSecurityBadge(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
