import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';

class TooltipData {
  final String title;
  final String subtitle;
  final String? description;
  final String? badge;

  const TooltipData({
    required this.title,
    required this.subtitle,
    this.description,
    this.badge,
  });
}

class SearchBoxModeTooltip extends StatefulWidget {
  final TooltipData? data;
  final bool isVisible;

  const SearchBoxModeTooltip({
    super.key,
    this.data,
    required this.isVisible,
  });

  @override
  State<SearchBoxModeTooltip> createState() => _SearchBoxModeTooltipState();
}

class _SearchBoxModeTooltipState extends State<SearchBoxModeTooltip>
    with TickerProviderStateMixin {
  late AnimationController _visibilityController;
  late AnimationController _contentController;
  
  late Animation<double> _visibilityAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    
    _visibilityController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _visibilityAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOutCubic,
    );
    
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );
    
    if (widget.isVisible) {
      _visibilityController.forward();
      _contentController.forward();
    }
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    _contentController.dispose();
    super.dispose();
  }

    @override
  void didUpdateWidget(SearchBoxModeTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle visibility changes
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _visibilityController.forward();
        _contentController.forward();
      } else {
        _visibilityController.reverse();
        _contentController.reverse();
      }
    }
    
    // Handle content changes
    if (widget.data != oldWidget.data && widget.data != null) {
      _contentController.reset();
      _contentController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    if (widget.data == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _visibilityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _visibilityAnimation.value,
          child: Transform.scale(
            scale: 0.8 + (_visibilityAnimation.value * 0.2),
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _contentAnimation.value,
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row with optional badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.data!.title,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.data!.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.data!.badge!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Text(
                          widget.data!.subtitle,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        
                        // Conditional Divider and Description
                        if (widget.data!.description != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          
                          // Description
                          Text(
                            widget.data!.description!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

