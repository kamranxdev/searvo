import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:searvo/core/theme/theme.dart';

/// A beautiful step indicator widget for the setup wizard
/// Shows progress through the onboarding steps with smooth animations
/// Responsive design adapts to different screen sizes
class SetupStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final bool isCompact;

  const SetupStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildMobileIndicator(context);
    }
    return _buildDesktopIndicator(context);
  }

  Widget _buildMobileIndicator(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: List.generate(totalSteps, (index) {
                final isActive = index <= currentStep;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(
                      right: index < totalSteps - 1 ? 4.0 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${currentStep + 1}/$totalSteps',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'Roboto', // Ensuring a clean font
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopIndicator(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Responsive sizing
    const dotWidth = 32.0;
    const dotHeight = 10.0;
    const inactiveDotWidth = 10.0;
    const spacing = 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isActive ? dotWidth : inactiveDotWidth,
              height: dotHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(dotHeight / 2),
                color: isActive
                    ? colorScheme.primary
                    : isCompleted
                    ? colorScheme.primary.withOpacity(0.6)
                    : colorScheme.surfaceContainerHighest,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),

            // Spacing between dots (except after last)
            if (index < totalSteps - 1) const SizedBox(width: spacing),
          ],
        );
      }),
    );
  }
}

/// Detailed step indicator with labels
class DetailedStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<StepInfo> steps;

  const DetailedStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SizedBox(
      height: 80.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step circle with number
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: isActive ? 48.w : 40.w,
                        height: isActive ? 48.h : 40.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? colorScheme.primary
                              : isCompleted
                              ? colorScheme.primary.withOpacity(0.15)
                              : colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isActive
                                ? colorScheme.primary
                                : isCompleted
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.3),
                            width: isCompleted ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  color: colorScheme.primary,
                                  size: 20.sp,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        child: Text(
                          step.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Connector line (except after last)
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.h,
                      margin: EdgeInsets.only(bottom: 28.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isCompleted
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            index < currentStep - 1 || isCompleted
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Information about a setup step
class StepInfo {
  final String label;
  final IconData? icon;

  const StepInfo({required this.label, this.icon});
}
