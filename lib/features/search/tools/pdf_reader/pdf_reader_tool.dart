import '../../agent/models/agent_tool.dart';
import '../../../search/rag/services/data_ingestion/pdf_extractor_service.dart';

class PdfReaderTool extends AgentTool {
  final PDFExtractorService _pdfExtractor;

  PdfReaderTool({PDFExtractorService? pdfExtractor})
    : _pdfExtractor = pdfExtractor ?? PDFExtractorService(),
      super(
        id: 'pdf_reader',
        name: 'PDF Reader',
        description: 'Extracts text from a PDF file or URL for analysis.',
      );

  @override
  Future<bool> get isAvailable async => true; // Always available if package compiled

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'url': {
        'type': 'string',
        'description': 'The URL or local path of the PDF to read',
      },
    },
    'required': ['url'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final url = input['url'] as String;

    try {
      final content = await _pdfExtractor.extractFromUrl(url);
      return {
        'text': content.text,
        'pageCount': content.pageCount,
        'metadata': content.metadata,
      };
    } catch (e) {
      return {'error': 'Failed to read PDF: $e'};
    }
  }
}
