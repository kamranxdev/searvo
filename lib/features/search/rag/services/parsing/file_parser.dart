import 'dart:io';
import 'parsing_result.dart';

/// Interface for file parsers
abstract class FileParser {
  /// Parse a file and return the result
  Future<ParsingResult> parse(File file);

  /// Get the list of supported file extensions (without dot)
  List<String> get supportedExtensions;
}
