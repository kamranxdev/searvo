import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:async';

class StreamingTextWidget extends StatefulWidget {
  final Stream<String>? textStream;
  final String? staticText;
  final TextStyle? style;
  final VoidCallback? onComplete;
  final Function(int)? onCitationTap;
  final List<dynamic>? sources;

  const StreamingTextWidget({
    super.key,
    this.textStream,
    this.staticText,
    this.style,
    this.onComplete,
    this.onCitationTap,
    this.sources,
  });

  @override
  State<StreamingTextWidget> createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<StreamingTextWidget>
    with TickerProviderStateMixin {
  String _currentText = '';
  StreamSubscription<String>? _subscription;
  late AnimationController _waveController;
  bool _hasStartedStreaming = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.textStream != null) {
      _waveController.repeat();
      _listenToStream();
    } else if (widget.staticText == null || widget.staticText!.isEmpty) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(StreamingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // CRITICAL: Check if we got a new stream or switched to static text
    final streamChanged = widget.textStream != oldWidget.textStream;
    final staticTextChanged = widget.staticText != oldWidget.staticText;
    
    if (streamChanged || staticTextChanged) {
      // Reset state when content changes
      _subscription?.cancel();
      _subscription = null;
      
      setState(() {
        _currentText = '';
        _hasStartedStreaming = false;
      });
      
      // Setup new stream if provided
      if (widget.textStream != null) {
        _waveController.repeat();
        _listenToStream();
      } else if (widget.staticText != null && widget.staticText!.isNotEmpty) {
        _waveController.stop();
      } else {
        _waveController.repeat();
      }
    }
  }

  void _listenToStream() {
    if (widget.textStream == null) return;

    _subscription = widget.textStream!.listen(
      (chunk) {
        if (mounted) {
          setState(() {
            if (!_hasStartedStreaming) {
              _hasStartedStreaming = true;
              _waveController.stop();
            }
            _currentText += chunk;
          });
        }
      },
      onDone: () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
      onError: (error) {
        print('Streaming error: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedWave() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_waveController.value + delay) % 1.0;
            final opacity = (1.0 - (animationValue - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 100),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: (widget.style?.fontSize ?? 16) * 1.2,
                    color: widget.style?.color ?? Theme.of(context).colorScheme.primary,
                    height: 1.0,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMarkdownWithCitations(String text) {
    if (widget.onCitationTap == null) {
      return GptMarkdown(text, style: widget.style);
    }

    final segments = _parseTextWithCitations(text);
    
    if (segments.isEmpty) {
      return GptMarkdown(text, style: widget.style);
    }

    return _CitationAwareMarkdown(
      segments: segments,
      style: widget.style,
      onCitationTap: widget.onCitationTap,
      sources: widget.sources,
      context: context,
    );
  }

  List<TextSegment> _parseTextWithCitations(String text) {
    final segments = <TextSegment>[];
    final citationRegex = RegExp(r'\[(\d+)\]');
    
    int lastIndex = 0;
    final matches = citationRegex.allMatches(text);

    for (final match in matches) {
      if (match.start > lastIndex) {
        segments.add(TextSegment(
          text: text.substring(lastIndex, match.start),
          isCitation: false,
        ));
      }

      final citationNumber = int.tryParse(match.group(1) ?? '');
      if (citationNumber != null) {
        segments.add(TextSegment(
          text: match.group(0)!,
          isCitation: true,
          citationNumber: citationNumber,
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      segments.add(TextSegment(
        text: text.substring(lastIndex),
        isCitation: false,
      ));
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Use staticText if provided, otherwise use streaming text
    final textToDisplay = widget.staticText ?? _currentText;

    // Show loading animation only when:
    // 1. No static text provided
    // 2. Haven't started streaming yet
    // 3. No accumulated text
    if (widget.staticText == null && 
        !_hasStartedStreaming && 
        _currentText.isEmpty) {
      return _buildAnimatedWave();
    }

    // If we have empty text (just switched to generating state), show loading
    if (textToDisplay.isEmpty) {
      return _buildAnimatedWave();
    }

    return _buildMarkdownWithCitations(textToDisplay);
  }
}

class TextSegment {
  final String text;
  final bool isCitation;
  final int? citationNumber;

  TextSegment({
    required this.text,
    required this.isCitation,
    this.citationNumber,
  });
}

class _CitationAwareMarkdown extends StatelessWidget {
  final List<TextSegment> segments;
  final TextStyle? style;
  final Function(int)? onCitationTap;
  final List<dynamic>? sources;
  final BuildContext context;

  const _CitationAwareMarkdown({
    required this.segments,
    this.style,
    this.onCitationTap,
    this.sources,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildParagraphs(),
    );
  }

  List<Widget> _buildParagraphs() {
    final widgets = <Widget>[];
    final paragraphs = <List<TextSegment>>[];
    var currentParagraph = <TextSegment>[];

    for (final segment in segments) {
      if (segment.text.contains('\n\n')) {
        final parts = segment.text.split('\n\n');
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].trim().isNotEmpty) {
            currentParagraph.add(TextSegment(
              text: parts[i],
              isCitation: false,
            ));
          }
          if (i < parts.length - 1) {
            if (currentParagraph.isNotEmpty) {
              paragraphs.add(List.from(currentParagraph));
              currentParagraph.clear();
            }
          }
        }
      } else {
        currentParagraph.add(segment);
      }
    }

    if (currentParagraph.isNotEmpty) {
      paragraphs.add(currentParagraph);
    }

    for (final paragraph in paragraphs) {
      widgets.add(_buildParagraph(paragraph));
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildParagraph(List<TextSegment> segments) {
    final spans = <InlineSpan>[];

    for (final segment in segments) {
      if (segment.isCitation && segment.citationNumber != null) {
        spans.add(_buildCitationWidgetSpan(segment.citationNumber!));
      } else {
        spans.add(TextSpan(
          text: segment.text,
          style: style ?? const TextStyle(fontSize: 16, fontFamily: 'Hanken Grotesk'),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  WidgetSpan _buildCitationWidgetSpan(int citationNumber) {
    final isValid = sources != null && citationNumber > 0 && citationNumber <= sources!.length;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return WidgetSpan(
      child: GestureDetector(
        onTap: isValid ? () => onCitationTap?.call(citationNumber) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isValid 
              ? primaryColor.withValues(alpha: 0.1) 
              : onSurfaceColor.withValues(alpha: 0.1),
            border: Border.all(
              color: isValid 
                ? primaryColor.withValues(alpha: 0.3) 
                : onSurfaceColor.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            citationNumber.toString(),
            style: TextStyle(
              color: isValid ? primaryColor : onSurfaceColor,
              fontSize: (style?.fontSize ?? 16) * 0.85,
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}