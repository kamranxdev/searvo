import 'dart:io';
import 'package:searvo/common/widgets/attachment_input_widget.dart';
import '../parsing/parsing_registry.dart';
import 'rag_ingestion_service.dart';

/// Service to handle the ingestion of file attachments
class AttachmentIngestionService {
  final ParsingRegistry _parsingRegistry;
  final RAGIngestionService _ragIngestionService;

  AttachmentIngestionService({
    required ParsingRegistry parsingRegistry,
    required RAGIngestionService ragIngestionService,
  }) : _parsingRegistry = parsingRegistry,
       _ragIngestionService = ragIngestionService;

  /// Ingest an attachment
  /// Returns a map of details including success status and ingestion IDs
  Future<Map<String, dynamic>> ingestAttachment(
    AttachmentData attachment,
  ) async {
    final file = File(attachment.path);
    if (!await file.exists()) {
      return {'success': false, 'error': 'File not found: ${attachment.path}'};
    }

    // 1. Find appropriate parser
    final parser = _parsingRegistry.getParserForExtension(attachment.extension);
    if (parser == null) {
      return {
        'success': false,
        'error': 'No parser found for extension: ${attachment.extension}',
      };
    }

    // 2. Parse content
    try {
      final result = await parser.parse(file);

      if (!result.success) {
        return {
          'success': false,
          'error': result.errorMessage ?? 'Unknown parsing error',
        };
      }

      // 3. Ingest content
      final metadata = {
        'source': 'attachment',
        'filename': attachment.name,
        'fileType': attachment.extension,
        'originalSize': attachment.size,
        'uploadedAt': attachment.uploadedAt.toIso8601String(),
        ...result.metadata,
      };

      final outputIds = await _ragIngestionService.ingestText(
        text: result.text,
        metadata: metadata,
      );

      return {
        'success': true,
        'chunkIds': outputIds,
        'extractedTextLength': result.text.length,
      };
    } catch (e) {
      return {'success': false, 'error': 'Ingestion failed: $e'};
    }
  }
}
