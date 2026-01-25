/// Result of a parsing operation
class ParsingResult {
  final bool success;
  final String text;
  final Map<String, dynamic> metadata;
  final String? errorMessage;

  ParsingResult({
    required this.success,
    required this.text,
    this.metadata = const {},
    this.errorMessage,
  });

  factory ParsingResult.success({
    required String text,
    Map<String, dynamic> metadata = const {},
  }) {
    return ParsingResult(success: true, text: text, metadata: metadata);
  }

  factory ParsingResult.failure(String errorMessage) {
    return ParsingResult(success: false, text: '', errorMessage: errorMessage);
  }
}
