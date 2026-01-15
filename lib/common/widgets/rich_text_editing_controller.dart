import 'package:flutter/material.dart';

enum DetectedType {
  mention, // By Default texts starting with @sign
  url, // By default texts starting with http://xxx.yyy or https://aaa.bbb
  plainText // Any other type falls into this.
}

// Custom TextEditingController that supports @mention and URL highlighting
class RichTextEditingController extends TextEditingController {
  final Set<String> validMentions;
  final Color mentionColor;
  final Color urlColor;
  final Color backgroundColor;

  RichTextEditingController({
    required this.validMentions,
    this.mentionColor = const Color(0xFF00B4A6), // Teal color equivalent to old primary
    this.urlColor = const Color(0xFF00B4A6), // Same teal color for URLs
    this.backgroundColor = const Color(0xFF1A1A1A), // Dark background
  });

  DetectedType _detectType(String text) {
    if (text.startsWith('@')) {
      return DetectedType.mention;
    } else if (text.startsWith('http://') || text.startsWith('https://')) {
      return DetectedType.url;
    }
    return DetectedType.plainText;
  }

  /// Extract all URLs from the current text
  List<String> extractUrls() {
    final text = this.text;
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    
    return urlPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Check if the text contains any URLs
  bool containsUrls() {
    return extractUrls().isNotEmpty;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> spans = [];
    final text = this.text;
    
    // Combined pattern for mentions and URLs
    final pattern = RegExp(
      r'@\w+|https?://[^\s]+',
      caseSensitive: false,
    );
    
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add text before the special element
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      final matchedText = match.group(0)!;
      final detectedType = _detectType(matchedText);
      
      TextStyle? specialStyle;
      
      switch (detectedType) {
        case DetectedType.mention:
          final mentionKey = matchedText.substring(1); // Remove @ symbol
          final isValid = validMentions.contains(mentionKey);
          specialStyle = style?.copyWith(
            color: isValid ? mentionColor : style.color,
            fontWeight: isValid ? FontWeight.w600 : style.fontWeight,
          );
          break;
          
        case DetectedType.url:
          specialStyle = style?.copyWith(
            color: urlColor,
            fontWeight: FontWeight.w600, // Same bold weight as mentions
          );
          break;
          
        case DetectedType.plainText:
          specialStyle = style;
          break;
      }

      spans.add(TextSpan(
        text: matchedText,
        style: specialStyle,
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style,
      ));
    }

    return TextSpan(
      style: style,
      children: spans.isEmpty ? [TextSpan(text: text, style: style)] : spans,
    );
  }
}
