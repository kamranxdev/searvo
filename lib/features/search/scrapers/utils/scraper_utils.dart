/// Utility functions for scrapers

/// Parse duration from various formats (ISO 8601, human-readable, etc.)
Duration? parseDuration(String? durationStr) {
  if (durationStr == null || durationStr.isEmpty) return null;

  try {
    // ISO 8601 duration format (e.g., "PT1H30M45S")
    if (durationStr.startsWith('PT')) {
      return _parseIso8601Duration(durationStr);
    }

    // Human-readable format (e.g., "1:30:45", "45:23")
    if (durationStr.contains(':')) {
      return _parseColonDuration(durationStr);
    }

    // Seconds only
    final seconds = int.tryParse(durationStr);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
  } catch (e) {
    print('⚠️ Failed to parse duration: $durationStr - $e');
  }

  return null;
}

Duration _parseIso8601Duration(String duration) {
  final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
  final match = regex.firstMatch(duration);

  if (match == null) throw FormatException('Invalid ISO 8601 duration: $duration');

  final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
  final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

Duration _parseColonDuration(String duration) {
  final parts = duration.split(':').map(int.parse).toList();

  if (parts.length == 2) {
    // MM:SS
    return Duration(minutes: parts[0], seconds: parts[1]);
  } else if (parts.length == 3) {
    // HH:MM:SS
    return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
  }

  throw FormatException('Invalid colon-separated duration: $duration');
}

/// Format duration to human-readable string
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds}s';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

/// Parse view count with abbreviations (1M, 100K, etc.)
int? parseViewCount(String? countStr) {
  if (countStr == null || countStr.isEmpty) return null;

  try {
    // Remove non-numeric characters except K, M, B
    String normalized = countStr.replaceAll(RegExp(r'[^\dKMB.]'), '').toUpperCase();

    if (normalized.isEmpty) return null;

    double multiplier = 1;
    if (normalized.endsWith('B')) {
      multiplier = 1000000000;
      normalized = normalized.substring(0, normalized.length - 1);
    } else if (normalized.endsWith('M')) {
      multiplier = 1000000;
      normalized = normalized.substring(0, normalized.length - 1);
    } else if (normalized.endsWith('K')) {
      multiplier = 1000;
      normalized = normalized.substring(0, normalized.length - 1);
    }

    final number = double.tryParse(normalized);
    if (number == null) return null;

    return (number * multiplier).toInt();
  } catch (e) {
    print('⚠️ Failed to parse view count: $countStr - $e');
    return null;
  }
}

/// Format view count with abbreviations
String formatViewCount(int count) {
  if (count >= 1000000000) {
    return '${(count / 1000000000).toStringAsFixed(1)}B';
  } else if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}

/// Clean HTML text (remove extra whitespace, newlines, etc.)
String cleanText(String text) {
  return text
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .trim();
}

/// Extract domain from URL
String? extractDomain(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host.toLowerCase();
  } catch (e) {
    return null;
  }
}

/// Check if URL is valid
bool isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  } catch (e) {
    return false;
  }
}

/// Normalize URL (remove tracking parameters, etc.)
String normalizeUrl(String url) {
  try {
    final uri = Uri.parse(url);
    
    // Remove common tracking parameters
    final trackingParams = [
      'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
      'fbclid', 'gclid', 'msclkid', 'mc_cid', 'mc_eid',
    ];
    
    final cleanParams = Map<String, String>.from(uri.queryParameters);
    for (final param in trackingParams) {
      cleanParams.remove(param);
    }
    
    return uri.replace(queryParameters: cleanParams.isEmpty ? null : cleanParams).toString();
  } catch (e) {
    return url;
  }
}

/// Parse date from various formats
DateTime? parseDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;

  try {
    // Try ISO 8601 first
    return DateTime.parse(dateStr);
  } catch (e) {
    // Try common formats
    final formats = [
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'), // YYYY-MM-DD
      RegExp(r'(\d{2})/(\d{2})/(\d{4})'), // MM/DD/YYYY
      RegExp(r'(\d{2})-(\d{2})-(\d{4})'), // DD-MM-YYYY
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          return DateTime.parse('${match.group(1)}-${match.group(2)}-${match.group(3)}');
        } catch (e) {
          continue;
        }
      }
    }
  }

  return null;
}

/// Extract JSON from HTML script tag
Map<String, dynamic>? extractJsonFromScript(String html, String scriptId) {
  try {
    final regex = RegExp(
      '<script[^>]*id="$scriptId"[^>]*>(.+?)</script>',
      dotAll: true,
    );
    final match = regex.firstMatch(html);

    if (match != null) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        return _parseJson(jsonStr);
      }
    }
  } catch (e) {
    print('⚠️ Failed to extract JSON from script tag: $e');
  }
  return null;
}

dynamic _parseJson(String jsonStr) {
  try {
    // Try to parse as-is
    return _parseJsonString(jsonStr);
  } catch (e) {
    // Try to clean up common issues
    final cleaned = jsonStr
        .replaceAll(RegExp(r'[\r\n\t]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return _parseJsonString(cleaned);
  }
}

dynamic _parseJsonString(String jsonStr) {
  // This is a placeholder - in real implementation you'd use dart:convert
  // or a more robust JSON parser
  return null;
}
