import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'file_parser.dart';
import 'parsing_result.dart';

class PdfParser implements FileParser {
  @override
  List<String> get supportedExtensions => ['pdf'];

  @override
  Future<ParsingResult> parse(File file) async {
    try {
      final List<int> bytes = await file.readAsBytes();

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      try {
        // Extract text from the document
        // PdfTextExtractor provides more options if needed,
        // but simple extraction is accessed via PdfTextExtractor(document).extractText()
        String text = PdfTextExtractor(document).extractText();

        // Basic cleanup
        text = text.trim();

        return ParsingResult.success(
          text: text,
          metadata: {
            'type': 'pdf',
            'pageCount': document.pages.count,
            'characters': text.length,
          },
        );
      } finally {
        // Dispose the document
        document.dispose();
      }
    } catch (e) {
      return ParsingResult.failure('Failed to parse PDF: $e');
    }
  }
}
