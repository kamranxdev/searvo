import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart';
import 'file_parser.dart';
import 'parsing_result.dart';

class DocxParser implements FileParser {
  @override
  List<String> get supportedExtensions => ['docx', 'doc'];

  @override
  Future<ParsingResult> parse(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes);

      return ParsingResult.success(
        text: text,
        metadata: {'type': 'word', 'characters': text.length},
      );
    } catch (e) {
      return ParsingResult.failure('Failed to parse Word document: $e');
    }
  }
}
