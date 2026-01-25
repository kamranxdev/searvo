import 'dart:io';
import 'file_parser.dart';
import 'parsing_result.dart';

class TextParser implements FileParser {
  @override
  List<String> get supportedExtensions => [
    'txt',
    'md',
    'json',
    'csv',
    'yaml',
    'xml',
    'log',
  ];

  @override
  Future<ParsingResult> parse(File file) async {
    try {
      final text = await file.readAsString();
      return ParsingResult.success(
        text: text,
        metadata: {
          'type': 'text',
          'lines': text.split('\n').length,
          'characters': text.length,
        },
      );
    } catch (e) {
      return ParsingResult.failure('Failed to read text file: $e');
    }
  }
}
