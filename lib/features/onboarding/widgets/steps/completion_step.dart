import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:searvo/core/theme/theme.dart';

/// Completion Step - Final page of the setup wizard
/// Celebrates successful setup and provides next steps
/// Responsive design with layouts for desktop, tablet, and mobile
class CompletionStep extends StatefulWidget {
  final String? selectedProvider;
  final bool isConfigured;
  final VoidCallback onComplete;
  final VoidCallback onAddMore;
  final bool isLoading;
  final bool isDesktop;
  final bool isTablet;

  const CompletionStep({
    super.key,
    this.selectedProvider,
    this.isConfigured = false,
    required this.onComplete,
    required this.onAddMore,
    this.isLoading = false,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<CompletionStep> createState() => _CompletionStepState();
}

class _CompletionStepState extends State<CompletionStep>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _celebrationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Trigger celebration if configured
    if (widget.isConfigured) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showCelebration = true);
          _celebrationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    
    // Responsive sizing
    final horizontalPadding = widget.isDesktop ? 48.0 : (widget.isTablet ? 40.0 : 32.w);
    final iconSize = widget.isDesktop ? 100.0 : (widget.isTablet ? 110.0 : 120.w);
    final iconFontSize = widget.isDesktop ? 48.0 : (widget.isTablet ? 52.0 : 56.sp);
    final titleStyle = widget.isDesktop 
        ? textTheme.headlineMedium 
        : textTheme.headlineMedium;
    final buttonWidth = widget.isDesktop ? 280.0 : double.infinity;
    final buttonHeight = widget.isDesktop ? 52.0 : 56.h;

    return Stack(
      children: [
        // Main content
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding.toDouble()),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: widget.isDesktop ? 60.0 : 40.h),

                      // Success icon with animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: iconSize.toDouble(),
                          height: iconSize.toDouble(),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.isConfigured
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ]
                                  : [
                                      colorScheme.primary.withOpacity(0.8),
                                      colorScheme.primary,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isConfigured
                                        ? Colors.green
                                        : colorScheme.primary)
                                    .withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isConfigured
                                ? Icons.check_rounded
                                : Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: iconFontSize.toDouble(),
                          ),
                        ),
                      ),

                      SizedBox(height: widget.isDesktop ? 40.0 : 32.h),

                      // Title
                      SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          widget.isConfigured
                              ? "You're All Set!"
                              : 'Almost There!',
                          style: titleStyle?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: widget.isDesktop ? 16.0 : 12.h),

                      // Subtitle
                      SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          widget.isConfigured
                              ? 'Your AI search assistant is ready to go'
                              : 'You can configure AI providers later in Settings',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: widget.isDesktop ? 48.0 : 40.h),

                      // Configuration summary and tips - responsive layout
                      widget.isDesktop || widget.isTablet
                          ? _buildHorizontalCards(colorScheme)
                          : _buildVerticalCards(colorScheme),

                      SizedBox(height: widget.isDesktop ? 48.0 : 40.h),
                    ],
                  ),
                ),
              ),

              // Bottom actions
              _buildBottomActions(colorScheme, buttonWidth, buttonHeight),
            ],
          ),
        ),

        // Confetti/celebration overlay
        if (_showCelebration)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _celebrationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CelebrationPainter(
                      progress: _celebrationController.value,
                      colorScheme: colorScheme,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildHorizontalCards(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isConfigured && widget.selectedProvider != null)
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildConfigSummary(colorScheme),
            ),
          ),
        if (widget.isConfigured && widget.selectedProvider != null)
          const SizedBox(width: 20),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildTipsSection(colorScheme),
          ),
        ),
      ],
    );
  }
  
  Widget _buildVerticalCards(ColorScheme colorScheme) {
    return Column(
      children: [
        // Configuration summary
        if (widget.isConfigured && widget.selectedProvider != null)
          SlideTransition(
            position: _slideAnimation,
            child: _buildConfigSummary(colorScheme),
          ),

        if (widget.isConfigured && widget.selectedProvider != null)
          SizedBox(height: 32.h),

        // Tips section
        SlideTransition(
          position: _slideAnimation,
          child: _buildTipsSection(colorScheme),
        ),
      ],
    );
  }
  
  Widget _buildBottomActions(ColorScheme colorScheme, double buttonWidth, double buttonHeight) {
    final padding = widget.isDesktop ? 32.0 : 24.w;
    
    return Container(
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Main action button
            SizedBox(
              width: buttonWidth,
              height: buttonHeight.toDouble(),
              child: FilledButton(
                onPressed: widget.isLoading ? null : widget.onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.isDesktop ? 12 : 16.r),
                  ),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.isDesktop ? 24 : 24.w,
                        height: widget.isDesktop ? 24 : 24.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Searching',
                            style: TextStyle(
                              fontSize: widget.isDesktop ? 15 : 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: widget.isDesktop ? 8 : 8.w),
                          Icon(Icons.search_rounded, size: widget.isDesktop ? 20 : 20.sp),
                        ],
                      ),
              ),
            ),

            SizedBox(height: widget.isDesktop ? 12 : 12.h),

            // Add more providers button
            TextButton(
              onPressed: widget.onAddMore,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: widget.isDesktop ? 18 : 18.sp),
                  SizedBox(width: widget.isDesktop ? 6 : 6.w),
                  const Text('Add More AI Providers'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSummary(ColorScheme colorScheme) {
    final padding = widget.isDesktop ? 20.0 : 20.w;
    final borderRadius = widget.isDesktop ? 14.0 : 16.r;
    final iconSize = widget.isDesktop ? 20.0 : 20.sp;
    final titleFontSize = widget.isDesktop ? 15.0 : 15.sp;
    final tagFontSize = widget.isDesktop ? 14.0 : 14.sp;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: iconSize.toDouble(),
              ),
              SizedBox(width: widget.isDesktop ? 8 : 8.w),
              Text(
                'AI Provider Configured',
                style: TextStyle(
                  fontSize: titleFontSize.toDouble(),
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isDesktop ? 12 : 12.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isDesktop ? 16 : 16.w,
              vertical: widget.isDesktop ? 8 : 8.h,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(widget.isDesktop ? 16 : 20.r),
            ),
            child: Text(
              widget.selectedProvider ?? 'Unknown',
              style: TextStyle(
                fontSize: tagFontSize.toDouble(),
                fontWeight: FontWeight.w500,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(ColorScheme colorScheme) {
    final padding = widget.isDesktop ? 20.0 : 20.w;
    final borderRadius = widget.isDesktop ? 14.0 : 16.r;
    final iconSize = widget.isDesktop ? 20.0 : 20.sp;
    final titleFontSize = widget.isDesktop ? 15.0 : 15.sp;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: colorScheme.primary,
                size: iconSize.toDouble(),
              ),
              SizedBox(width: widget.isDesktop ? 8 : 8.w),
              Text(
                'Quick Tips',
                style: TextStyle(
                  fontSize: titleFontSize.toDouble(),
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isDesktop ? 16 : 16.h),
          _TipItem(
            icon: Icons.mic_rounded,
            text: 'Use voice input for hands-free searching',
            colorScheme: colorScheme,
            isDesktop: widget.isDesktop,
          ),
          SizedBox(height: widget.isDesktop ? 10 : 10.h),
          _TipItem(
            icon: Icons.alternate_email_rounded,
            text: 'Type @youtube or @github for specific site searches',
            colorScheme: colorScheme,
            isDesktop: widget.isDesktop,
          ),
          SizedBox(height: widget.isDesktop ? 10 : 10.h),
          _TipItem(
            icon: Icons.settings_rounded,
            text: 'Configure more providers in Settings anytime',
            colorScheme: colorScheme,
            isDesktop: widget.isDesktop,
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final bool isDesktop;

  const _TipItem({
    required this.icon,
    required this.text,
    required this.colorScheme,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isDesktop ? 16.0 : 16.sp;
    final fontSize = isDesktop ? 13.0 : 13.sp;
    final spacing = isDesktop ? 10.0 : 10.w;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colorScheme.onSurfaceVariant,
          size: iconSize.toDouble(),
        ),
        SizedBox(width: spacing.toDouble()),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize.toDouble(),
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for celebration particles effect
class _CelebrationPainter extends CustomPainter {
  final double progress;
  final ColorScheme colorScheme;
  final List<_Particle> particles;

  _CelebrationPainter({
    required this.progress,
    required this.colorScheme,
  }) : particles = _generateParticles(colorScheme);

  static List<_Particle> _generateParticles(ColorScheme colorScheme) {
    final random = math.Random(42); // Fixed seed for consistent animation
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.green,
      Colors.amber,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
    ];
    
    return List.generate(50, (index) {
      return _Particle(
        startX: random.nextDouble(),
        startY: -0.1 - random.nextDouble() * 0.2,
        velocityX: (random.nextDouble() - 0.5) * 0.3,
        velocityY: 0.3 + random.nextDouble() * 0.4,
        size: 4 + random.nextDouble() * 8,
        color: colors[random.nextInt(colors.length)],
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 4,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = (particle.startX + particle.velocityX * progress) * size.width;
      final y = (particle.startY + particle.velocityY * progress) * size.height;
      
      // Fade out particles as they fall
      final opacity = (1 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress);
      
      // Draw a small rectangle/confetti piece
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          Radius.circular(particle.size * 0.1),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  _Particle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}
