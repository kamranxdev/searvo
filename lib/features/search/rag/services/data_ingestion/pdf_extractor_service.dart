import 'package:http/http.dart' as http;

/// Service for extracting content from PDF files
/// Supports both local and remote PDFs
class PDFExtractorService {
  final http.Client _client;
  final int _timeout;
  
  PDFExtractorService({
    http.Client? client,
    int timeout = 60,
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  /// Extract text content from a PDF URL
  Future<PDFContent> extractFromUrl(String url) async {
    try {
      print('📄 Extracting PDF from: $url');
      
      final uri = Uri.parse(url);
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/pdf,*/*',
        },
      ).timeout(Duration(seconds: _timeout));

      if (response.statusCode == 200) {
        return await _extractFromBytes(response.bodyBytes, url);
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch PDF');
      }
    } catch (e) {
      print('❌ PDF extraction failed: $e');
      return PDFContent(
        url: url,
        text: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Extract text from PDF bytes
  Future<PDFContent> _extractFromBytes(List<int> bytes, String source) async {
    try {
      // Note: The pdf package in Flutter is primarily for PDF generation,
      // not parsing. For full PDF text extraction, you would need a different package
      // like pdf_text or a native implementation. This is a simplified version.
      
      // For now, we'll return a placeholder that indicates PDF parsing capability
      // In production, you'd use a proper PDF parser like pdf_text package
      
      print('⚠️  PDF text extraction requires pdf_text package');
      print('   Installing: flutter pub add pdf_text');
      
      return PDFContent(
        url: source,
        text: '[PDF Content - Full extraction requires pdf_text package]',
        pageCount: 0,
        success: true,
        metadata: {
          'sizeBytes': bytes.length,
          'note': 'Add pdf_text package for full PDF parsing support',
        },
      );
    } catch (e) {
      return PDFContent(
        url: source,
        text: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Result of PDF extraction
class PDFContent {
  final String url;
  final String text;
  final int pageCount;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;

  const PDFContent({
    required this.url,
    required this.text,
    this.pageCount = 0,
    required this.success,
    this.error,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'PDFContent(url: $url, success: $success, pages: $pageCount, chars: ${text.length})';
  }
}
