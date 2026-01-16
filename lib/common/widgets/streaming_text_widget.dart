import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/search/widgets/citation_chip.dart';
import 'package:searvo/common/widgets/code_block_view.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';

class StreamingTextWidget extends StatefulWidget {
  final Stream<String>? textStream;
  final String? staticText;
  final TextStyle? style;
  final VoidCallback? onComplete;
  final Function(int)? onCitationTap;
  final List<SourceItem>? sources;

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
  bool _hasStartedStreaming = false;
  bool _isStreamingComplete = false;

  // Custom blink controller for the cursor
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Start blinking immediately
    _cursorController.repeat(reverse: true);

    if (widget.textStream != null) {
      _listenToStream();
    } else if (widget.staticText != null && widget.staticText!.isNotEmpty) {
      _currentText = widget.staticText!;
      _isStreamingComplete = true;
    }
  }

  @override
  void didUpdateWidget(StreamingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final streamChanged = widget.textStream != oldWidget.textStream;
    final staticTextChanged = widget.staticText != oldWidget.staticText;

    if (streamChanged) {
      _subscription?.cancel();
      _subscription = null;
      setState(() {
        _currentText = '';
        _hasStartedStreaming = false;
        _isStreamingComplete = false;
      });
      if (widget.textStream != null) {
        _listenToStream();
      }
    } else if (staticTextChanged && widget.textStream == null) {
      setState(() {
        _currentText = widget.staticText ?? '';
        _isStreamingComplete = true;
      });
    }
  }

  void _listenToStream() {
    if (widget.textStream == null) return;

    _subscription = widget.textStream!.listen(
      (chunk) {
        if (mounted) {
          setState(() {
            _hasStartedStreaming = true;
            _currentText += chunk;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isStreamingComplete = true;
          });
          widget.onComplete?.call();
        }
      },
      onError: (error) {
        print('Streaming error: $error');
        if (mounted) {
          setState(() {
            _isStreamingComplete = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  String _cleanText(String text) {
    var cleaned = text;

    // 1. Normalize and merge consecutive citations: [1] [2] -> [1, 2]
    // First, remove spaces between citations: [1] [2] -> [1][2]
    var prev = '';
    do {
      prev = cleaned;
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'(\[\d+\])\s+(\[\d+\])'),
        (match) => '${match.group(1)}${match.group(2)}',
      );
    } while (prev != cleaned);

    // Then merge them: [1][2][3] -> [1, 2, 3]
    bool changed = true;
    while (changed) {
      changed = false;
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'(\[[\d,\s]+\])(\[[\d,\s]+\])'),
        (match) {
          changed = true;
          final first = match.group(1)!.replaceAll('[', '').replaceAll(']', '');
          final second = match
              .group(2)!
              .replaceAll('[', '')
              .replaceAll(']', '');
          return '[$first, $second]';
        },
      );
    }

    // 2. Bind punctuation to citations (prevent [1] . from splitting)
    // We use a Word Joiner (\u2060) to keep them together if needed,
    // or just remove the space entirely.
    // Also updated regex to handle merged citations like [1, 2]
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\[[\d,\s]+\])\s*([.,;:?])'),
      (match) => '${match.group(1)}\u2060${match.group(2)}',
    );

    // 3. Bind citations to preceding text (prevent "text [1]" split)
    // Replace standard space with Non-Breaking Space (\u00A0)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([^\s\n])\s+(\[[\d,\s]+\])'),
      (match) => '${match.group(1)}\u00A0${match.group(2)}',
    );

    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    var textToDisplay = _currentText;
    final searchColors = SearchTheme.colors(context);
    final userStyle =
        widget.style ??
        TextStyle(fontSize: 16, height: 1.6, color: searchColors.onSurface);

    // If waiting for stream to start and no static text, show generic loading
    if (widget.staticText == null &&
        !_hasStartedStreaming &&
        _currentText.isEmpty &&
        widget.textStream != null) {
      return _buildLoadingWave(userStyle);
    }

    if (textToDisplay.isEmpty && widget.staticText != null) {
      textToDisplay = widget.staticText!;
    }

    // Clean citation spacing and merge
    textToDisplay = _cleanText(textToDisplay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: textToDisplay,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: userStyle,
            h1: userStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
            h2: userStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            h3: userStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            code: TextStyle(
              backgroundColor: searchColors.surfaceContainerHighest,
              color: searchColors.onSurface,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
            codeblockPadding: EdgeInsets.zero,
            codeblockDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            blockquote: userStyle.copyWith(
              color: searchColors.onSurfaceVariant,
            ),
            blockquoteDecoration: BoxDecoration(
              color: searchColors.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border(
                left: BorderSide(color: searchColors.primary, width: 4),
              ),
            ),
          ),
          extensionSet: md.ExtensionSet(
            [...md.ExtensionSet.gitHubFlavored.blockSyntaxes],
            [
              md.EmojiSyntax(),
              _CitationSyntax(),
              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            ],
          ),
          builders: {
            'citation': _CitationElementBuilder(
              onCitationTap: widget.onCitationTap,
              searchColors: searchColors,
              sources: widget.sources,
            ),
            'code': _CodeElementBuilder(),
          },
        ),

        // The pulsing cursor at the end of content while streaming
        if (!_isStreamingComplete)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FadeTransition(
              opacity: _cursorController,
              child: Container(
                width: 8,
                height: 16,
                color: searchColors.primary,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
      ],
    );
  }

  Widget _buildLoadingWave(TextStyle style) {
    // Simple 3-dot shimmer/wave
    return Row(
      children: [0, 1, 2].map((i) {
        return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.color?.withValues(alpha: 0.5) ?? Colors.grey,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(end: 1.5, duration: 600.ms, delay: (200 * i).ms)
            .fadeIn(duration: 600.ms);
      }).toList(),
    );
  }
}

class _CitationSyntax extends md.InlineSyntax {
  // Capture [1] or [1, 2] or [1, 2, 3]
  _CitationSyntax() : super(r'\[([\d,\s]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final citationContent = match.group(1);
    final element = md.Element.empty('citation');
    element.attributes['numbers'] = citationContent!;
    parser.addNode(element);
    return true;
  }
}

class _CitationElementBuilder extends MarkdownElementBuilder {
  final Function(int)? onCitationTap;
  final SearchColors searchColors;
  final List<SourceItem>? sources;

  _CitationElementBuilder({
    this.onCitationTap,
    required this.searchColors,
    this.sources,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final numbersStr = element.attributes['numbers'];
    if (numbersStr == null) return null;

    // Parse comma separated numbers
    final numbers = numbersStr
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    if (numbers.isEmpty) return null;

    // Resolve valid sources
    // Source index is 1-based, list is 0-based
    final sourceList = <SourceItem>[];
    if (sources != null && sources!.isNotEmpty) {
      for (final idx in numbers) {
        if (idx - 1 >= 0 && idx - 1 < sources!.length) {
          sourceList.add(sources![idx - 1]);
        }
      }
    }

    return CitationChip(
      citationNumbers: numbers,
      sources: sourceList,
      onTap: onCitationTap != null ? (idx) => onCitationTap!(idx) : null,
      searchColors: searchColors,
    );
  }
}

class _CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    // Check if it's a code block based on language class or standard multiline detection
    final languageClass = element.attributes['class'];
    final bool isBlock =
        languageClass != null && languageClass.startsWith('language-');
    final bool hasNewlines = text.contains('\n');

    // Treat as block if explicitly marked with language or contains newlines (and is not just a long inline string)
    // Note: flutter_markdown often passes the whole block content to 'code' builder
    if (isBlock || hasNewlines) {
      var language = '';
      if (languageClass != null) {
        language = languageClass.replaceAll('language-', '');
      } else {
        // Try to auto-detect or default to empty (plaintext)
        language = '';
      }

      return CodeBlockView(
        code: text
            .trimRight(), // Trim trailing newline which markdown parsers often add
        language: language,
      );
    }

    // Inline code
    return _InlineCodeView(text: text, style: preferredStyle);
  }
}

class _InlineCodeView extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _InlineCodeView({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: searchColors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: searchColors.outline.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          textStyle: style,
          fontSize: (style?.fontSize ?? 14) - 1,
          color: searchColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
