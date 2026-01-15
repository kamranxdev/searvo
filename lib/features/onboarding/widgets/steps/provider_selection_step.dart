import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/onboarding/models/setup_models.dart';

/// Provider Selection Step - Second page of the setup wizard
/// Allows users to choose their preferred AI provider
/// Responsive design with grid layout for larger screens
class ProviderSelectionStep extends StatefulWidget {
  final String? selectedProvider;
  final Function(String) onProviderSelected;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final bool isDesktop;
  final bool isTablet;

  const ProviderSelectionStep({
    super.key,
    this.selectedProvider,
    required this.onProviderSelected,
    this.onContinue,
    required this.onBack,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<ProviderSelectionStep> createState() => _ProviderSelectionStepState();
}

class _ProviderSelectionStepState extends State<ProviderSelectionStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
    final providers = AIProviderOption.allProviders;
    
    // Responsive sizing
    final horizontalPadding = widget.isDesktop ? 48.0 : (widget.isTablet ? 32.0 : 32.w);
    final headerPadding = widget.isDesktop ? 48.0 : (widget.isTablet ? 32.0 : 32.w);
    final titleStyle = widget.isDesktop 
        ? textTheme.headlineMedium 
        : textTheme.headlineSmall;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: headerPadding.toDouble()),
            child: Column(
              children: [
                SizedBox(height: widget.isDesktop ? 24.0 : 16.h),
                Text(
                  'Choose AI Provider',
                  style: titleStyle?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: widget.isDesktop ? 12.0 : 8.h),
                Text(
                  'Select your preferred AI model provider',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: widget.isDesktop ? 32.0 : 24.h),

          // Provider list - responsive layout
          Expanded(
            child: widget.isDesktop || widget.isTablet
                ? _buildGridLayout(providers, colorScheme, horizontalPadding)
                : _buildListLayout(providers, colorScheme, horizontalPadding),
          ),

          // Bottom actions
          _buildBottomActions(colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildGridLayout(
    List<AIProviderOption> providers,
    ColorScheme colorScheme,
    double padding,
  ) {
    final crossAxisCount = widget.isDesktop ? 2 : 2;
    
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: widget.isDesktop ? 2.0 : 1.8,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final isSelected = widget.selectedProvider == provider.id;

        return _ProviderCard(
          provider: provider,
          isSelected: isSelected,
          onTap: () => widget.onProviderSelected(provider.id),
          isCompact: true,
        );
      },
    );
  }
  
  Widget _buildListLayout(
    List<AIProviderOption> providers,
    ColorScheme colorScheme,
    double padding,
  ) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: padding.toDouble()),
      itemCount: providers.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final provider = providers[index];
        final isSelected = widget.selectedProvider == provider.id;

        return _ProviderCard(
          provider: provider,
          isSelected: isSelected,
          onTap: () => widget.onProviderSelected(provider.id),
          isCompact: false,
        );
      },
    );
  }
  
  Widget _buildBottomActions(ColorScheme colorScheme) {
    final padding = widget.isDesktop ? 32.0 : 24.w;
    final buttonPaddingH = widget.isDesktop ? 28.0 : 24.w;
    final buttonPaddingV = widget.isDesktop ? 14.0 : 12.h;
    
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
        child: Row(
          children: [
            // Back button
            TextButton.icon(
              onPressed: widget.onBack,
              icon: Icon(Icons.arrow_back_rounded, size: widget.isDesktop ? 18 : 18.sp),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),

            const Spacer(),

            // Continue button
            FilledButton(
              onPressed: widget.onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: widget.onContinue != null
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: widget.onContinue != null
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPaddingH.toDouble(),
                  vertical: buttonPaddingV.toDouble(),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.isDesktop ? 10 : 12.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Continue'),
                  SizedBox(width: widget.isDesktop ? 8 : 8.w),
                  Icon(Icons.arrow_forward_rounded, size: widget.isDesktop ? 18 : 18.sp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final AIProviderOption provider;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  const _ProviderCard({
    required this.provider,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    // Responsive sizing
    final padding = isCompact ? 14.0 : 16.w;
    final iconSize = isCompact ? 48.0 : 52.w;
    final iconFontSize = isCompact ? 24.0 : 26.sp;
    final titleFontSize = isCompact ? 15.0 : 16.sp;
    final descFontSize = isCompact ? 12.0 : 13.sp;
    final tagFontSize = isCompact ? 10.0 : 11.sp;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(padding.toDouble()),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(isCompact ? 14 : 16.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isCompact 
            ? _buildCompactLayout(colorScheme, iconSize, iconFontSize, titleFontSize, descFontSize)
            : _buildFullLayout(colorScheme, iconSize, iconFontSize, titleFontSize, descFontSize, tagFontSize),
      ),
    );
  }
  
  Widget _buildCompactLayout(
    ColorScheme colorScheme,
    double iconSize,
    double iconFontSize,
    double titleFontSize,
    double descFontSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                provider.icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: iconFontSize,
              ),
            ),
            const Spacer(),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              provider.name,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (!provider.requiresApiKey) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'Free',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          provider.description,
          style: TextStyle(
            fontSize: descFontSize,
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildFullLayout(
    ColorScheme colorScheme,
    double iconSize,
    double iconFontSize,
    double titleFontSize,
    double descFontSize,
    double tagFontSize,
  ) {
    return Row(
      children: [
        // Icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: iconSize.toDouble(),
          height: iconSize.toDouble(),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.15)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            provider.icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: iconFontSize.toDouble(),
          ),
        ),

        SizedBox(width: 16.w),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    provider.name,
                    style: TextStyle(
                      fontSize: titleFontSize.toDouble(),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (!provider.requiresApiKey) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Free',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                provider.description,
                style: TextStyle(
                  fontSize: descFontSize.toDouble(),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8.h),
              // Feature tags
              Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: provider.features.take(3).map((feature) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: tagFontSize.toDouble(),
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Selection indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check_rounded,
                  color: colorScheme.onPrimary,
                  size: 16.sp,
                )
              : null,
        ),
      ],
    );
  }
}
