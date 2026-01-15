import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/common/widgets/app_logo.dart';

/// Welcome step - First page of the setup wizard
/// Introduces the app and its features
/// Responsive design with layouts for desktop, tablet, and mobile
class WelcomeStep extends StatefulWidget {
  final VoidCallback onGetStarted;
  final bool isDesktop;
  final bool isTablet;

  const WelcomeStep({
    super.key,
    required this.onGetStarted,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    
    // Responsive sizing
    final horizontalPadding = widget.isDesktop ? 48.0 : (widget.isTablet ? 40.0 : 32.w);
    final logoSize = widget.isDesktop ? 140.0 : (widget.isTablet ? 130.0 : 120.w);
    final logoIconSize = widget.isDesktop ? 70.0 : (widget.isTablet ? 65.0 : 60.0);
    final titleStyle = widget.isDesktop 
        ? textTheme.headlineLarge 
        : (widget.isTablet ? textTheme.headlineMedium : textTheme.headlineMedium);
    final verticalSpacing = widget.isDesktop ? 40.0 : (widget.isTablet ? 36.0 : 32.h);
    final featureSpacing = widget.isDesktop ? 20.0 : (widget.isTablet ? 18.0 : 16.h);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding.toDouble()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: widget.isDesktop ? 60.0 : 40.h),

          // Logo with animation - only show if not desktop (desktop has branding panel)
          if (!widget.isDesktop) ...[
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: logoSize.toDouble(),
                  height: logoSize.toDouble(),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.15),
                        colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AppLogo(
                      size: logoIconSize.toDouble(),
                      withBackground: false,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: verticalSpacing.toDouble()),
          ],

          // Welcome text
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    widget.isDesktop ? 'Let\'s Get Started' : 'Welcome to Searvo',
                    style: titleStyle?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Goldman',
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: widget.isDesktop ? 20.0 : 16.h),
                  Text(
                    widget.isDesktop 
                        ? 'Follow the steps below to configure your AI search assistant'
                        : 'Your AI-powered search companion',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: widget.isDesktop ? 56.0 : 48.h),

          // Feature highlights - responsive layout
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: widget.isDesktop || widget.isTablet
                  ? _buildHorizontalFeatures(colorScheme, featureSpacing)
                  : _buildVerticalFeatures(colorScheme, featureSpacing),
            ),
          ),

          SizedBox(height: widget.isDesktop ? 56.0 : 48.h),

          // Get Started button
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: widget.isDesktop ? 280.0 : double.infinity,
                height: widget.isDesktop ? 52.0 : 56.h,
                child: FilledButton(
                  onPressed: widget.onGetStarted,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(widget.isDesktop ? 12 : 16.r),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: widget.isDesktop ? 15 : 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: widget.isDesktop ? 8 : 8.w),
                      Icon(Icons.arrow_forward_rounded, size: widget.isDesktop ? 20 : 20.sp),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: widget.isDesktop ? 20.0 : 16.h),

          // Setup info
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Quick setup takes about 2 minutes',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: widget.isDesktop ? 60.0 : 40.h),
        ],
      ),
    );
  }
  
  Widget _buildHorizontalFeatures(ColorScheme colorScheme, double spacing) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: [
        _FeatureItem(
          icon: Icons.search_rounded,
          title: 'Intelligent Search',
          description: 'AI-enhanced results from multiple sources',
          colorScheme: colorScheme,
          isCompact: widget.isDesktop,
        ),
        _FeatureItem(
          icon: Icons.psychology_rounded,
          title: 'Multiple AI Providers',
          description: 'OpenAI, Google Gemini, Claude & more',
          colorScheme: colorScheme,
          isCompact: widget.isDesktop,
        ),
        _FeatureItem(
          icon: Icons.mic_rounded,
          title: 'Voice Interaction',
          description: 'Speak your queries naturally',
          colorScheme: colorScheme,
          isCompact: widget.isDesktop,
        ),
      ],
    );
  }
  
  Widget _buildVerticalFeatures(ColorScheme colorScheme, double spacing) {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.search_rounded,
          title: 'Intelligent Search',
          description: 'AI-enhanced results from multiple sources',
          colorScheme: colorScheme,
        ),
        SizedBox(height: spacing),
        _FeatureItem(
          icon: Icons.psychology_rounded,
          title: 'Multiple AI Providers',
          description: 'OpenAI, Google Gemini, Claude & more',
          colorScheme: colorScheme,
        ),
        SizedBox(height: spacing),
        _FeatureItem(
          icon: Icons.mic_rounded,
          title: 'Voice Interaction',
          description: 'Speak your queries naturally',
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;
  final int delay;
  final bool isCompact;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
    this.delay = 0,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final containerWidth = isCompact ? 200.0 : double.infinity;
    final padding = isCompact ? 14.0 : 16.w;
    final iconContainerSize = isCompact ? 44.0 : 48.w;
    final iconSize = isCompact ? 22.0 : 24.sp;
    final titleFontSize = isCompact ? 14.0 : 15.sp;
    final descFontSize = isCompact ? 12.0 : 13.sp;
    
    return Container(
      width: isCompact ? containerWidth : null,
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16.r),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: isCompact 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: iconSize.toDouble(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize.toDouble(),
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: descFontSize.toDouble(),
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: iconContainerSize.toDouble(),
                  height: iconContainerSize.toDouble(),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: iconSize.toDouble(),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize.toDouble(),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: descFontSize.toDouble(),
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
