import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:searvo/features/search/models/message_data.dart';
import 'package:searvo/features/search/models/search_step.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReasoningWidget extends StatefulWidget {
  final MessageGenerationState state;
  final List<SourceItem> sources;
  final List<SearchStep> steps;
  final String? activeDetail;
  final bool isGenerating;

  const ReasoningWidget({
    super.key,
    required this.state,
    this.sources = const [],
    this.steps = const [],
    this.activeDetail,
    this.isGenerating = false,
  });

  @override
  State<ReasoningWidget> createState() => _ReasoningWidgetState();
}

class _ReasoningWidgetState extends State<ReasoningWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _expandController.value = 1.0;

    // Auto-collapse logic can be added here if needed,
    // but user requested a design similar to the image which usually stays accessible.
  }

  @override
  void didUpdateWidget(ReasoningWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-expand if we start generating
    if (widget.isGenerating && !oldWidget.isGenerating) {
      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
          _expandController.forward();
        });
      }
    }

    // Auto-collapse if we finished generating (moved to streaming or completed)
    // and previously were generating/searching
    final wasGenerating =
        oldWidget.state == MessageGenerationState.searching ||
        oldWidget.state == MessageGenerationState.generating;
    final isDone =
        widget.state == MessageGenerationState.streaming ||
        widget.state == MessageGenerationState.completed;

    if (wasGenerating && isDone) {
      if (_isExpanded) {
        // Subtle delay before collapsing to let user see "Synthesizing" briefly?
        // Or immediate. Perplexity is immediate/smooth.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isExpanded) {
            setState(() {
              _isExpanded = false;
              _expandController.reverse();
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = SearchTheme.colors(context);
    final completedSteps = _calculateCompletedSteps();

    // Determine header text
    String headerText;
    if (widget.isGenerating) {
      if (widget.activeDetail != null) {
        headerText = widget.activeDetail!;
      } else {
        headerText = _getCurrentStatusText();
      }
    } else {
      headerText = 'Thought Process ($completedSteps steps)';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _isExpanded
                  ? colors.surfaceContainerHighest.withValues(alpha: 0.2)
                  : Colors.transparent,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isGenerating
                          ? colors.primary.withValues(alpha: 0.1)
                          : colors.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: widget.isGenerating
                        ? Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: colors.primary,
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(duration: 2000.ms)
                              .shimmer(
                                duration: 1000.ms,
                                color: colors.secondary,
                              )
                        : Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: colors.secondary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reasoning',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          headerText,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colors.outline.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Searching/Refining Logic (from ProcessingIndicator)
                    _buildInternalStep(
                      label: 'Searching for resources',
                      description: widget.sources.isNotEmpty
                          ? 'Found ${widget.sources.length} sources'
                          : null,
                      isCompleted:
                          widget.sources.isNotEmpty ||
                          widget.state == MessageGenerationState.generating ||
                          widget.state == MessageGenerationState.streaming ||
                          widget.state == MessageGenerationState.completed,
                      isActive:
                          widget.state == MessageGenerationState.searching,
                      colors: colors,
                      index: 0,
                    ),

                    // 2. Reasoning Steps (Dynamic)
                    ...widget.steps.asMap().entries.map(
                      (entry) => _buildReasoningStep(
                        entry.value,
                        colors,
                        entry.key + 1,
                      ),
                    ),

                    // 3. Synthesizing (Optional final step)
                    if (widget.state == MessageGenerationState.streaming ||
                        widget.state == MessageGenerationState.completed)
                      _buildInternalStep(
                        label: 'Synthesizing response',
                        isCompleted:
                            widget.state == MessageGenerationState.completed,
                        isActive:
                            widget.state == MessageGenerationState.streaming,
                        colors: colors,
                        index: widget.steps.length + 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentStatusText() {
    if (widget.state == MessageGenerationState.searching)
      return 'Searching knowledge base...';
    if (widget.state == MessageGenerationState.generating)
      return 'Analyzing information...';
    if (widget.state == MessageGenerationState.streaming)
      return 'Formulating response...';
    return 'Completed';
  }

  int _calculateCompletedSteps() {
    int count = 0;
    // Search completed?
    if (widget.sources.isNotEmpty ||
        widget.state != MessageGenerationState.searching)
      count++;

    // Reasoning completed?
    count += widget.steps.where((s) => s.isCompleted).length;

    // Synthesize completed?
    if (widget.state == MessageGenerationState.completed) count++;

    return count;
  }

  Widget _buildInternalStep({
    required String label,
    String? description,
    required bool isCompleted,
    required bool isActive,
    required SearchColors colors,
    required int index,
  }) {
    return _buildStepLayout(
      label: label,
      description: description,
      isActive: isActive,
      isCompleted: isCompleted,
      isFailed: false,
      colors: colors,
      index: index,
      showDuration: false,
    );
  }

  Widget _buildReasoningStep(SearchStep step, SearchColors colors, int index) {
    return _buildStepLayout(
      label: step.title,
      description: step.description,
      isActive: step.isInProgress,
      isCompleted: step.isCompleted,
      isFailed: step.isFailed,
      colors: colors,
      index: index,
      showDuration: step.isCompleted && step.duration.inMilliseconds > 0,
      durationMs: step.duration.inMilliseconds,
    );
  }

  Widget _buildStepLayout({
    required String label,
    String? description,
    required bool isActive,
    required bool isCompleted,
    required bool isFailed,
    required SearchColors colors,
    required int index,
    bool showDuration = false,
    int durationMs = 0,
  }) {
    Color iconColor;
    IconData iconData;
    Color textColor = colors.onSurfaceVariant;
    FontWeight fontWeight = FontWeight.normal;

    if (isActive) {
      iconColor = colors.primary;
      textColor = colors.onSurface;
      fontWeight = FontWeight.w600;
      iconData = Icons.circle; // Assigned placeholder
    } else if (isFailed) {
      iconColor = colors.error;
      iconData = Icons.error_outline_rounded;
    } else if (isCompleted) {
      iconColor = colors.primary;
      iconData = Icons.check_circle_rounded;
    } else {
      iconColor = colors.outline.withValues(alpha: 0.3);
      iconData = Icons.circle_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector/icon
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isActive
                        ? SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: colors.primary,
                            ),
                          )
                        : Icon(iconData, size: 14, color: iconColor),
                  ),
                ),
                // Vertical line if not last (simplified, not strictly implemented here but could be added)
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: fontWeight,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (showDuration)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${durationMs}ms",
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
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
