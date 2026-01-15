import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:docx_to_text/docx_to_text.dart';

/// Service for processing various file attachments
class AttachmentProcessor {
  static final AttachmentProcessor _instance = AttachmentProcessor._internal();
  factory AttachmentProcessor() => _instance;
  AttachmentProcessor._internal();

  /// Process attachment and extract text/content
  Future<AttachmentProcessResult> processAttachment(
    String filePath,
    String fileName,
  ) async {
    try {
      final extension = fileName.split('.').last.toLowerCase();
      
      print('📎 Processing attachment: $fileName ($extension)');
      
      switch (extension) {
        case 'pdf':
          return await _processPDF(filePath);
        
        case 'doc':
        case 'docx':
          return await _processWord(filePath);
        
        case 'txt':
          return await _processText(filePath);
        
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
        case 'webp':
          return await _processImage(filePath);
        
        case 'ppt':
        case 'pptx':
          return await _processPowerPoint(filePath);
        
        default:
          return AttachmentProcessResult(
            success: false,
            errorMessage: 'Unsupported file type: $extension',
          );
      }
    } catch (e) {
      print('❌ Error processing attachment: $e');
      return AttachmentProcessResult(
        success: false,
        errorMessage: 'Failed to process file: $e',
      );
    }
  }

  /// Process PDF file
  Future<AttachmentProcessResult> _processPDF(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Note: You'll need to add pdf_text package for actual text extraction
      // For now, returning a placeholder
      // In production, use: https://pub.dev/packages/pdf_text
      
      return AttachmentProcessResult(
        success: true,
        extractedText: '[PDF content extraction requires pdf_text package]',
        metadata: {
          'type': 'pdf',
          'size': bytes.length,
          'pages': 'unknown',
        },
      );
    } catch (e) {
      return AttachmentProcessResult(
        success: false,
        errorMessage: 'Failed to process PDF: $e',
      );
    }
  }

  /// Process Word document
  Future<AttachmentProcessResult> _processWord(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Extract text from DOCX
      final text = docxToText(bytes);
      
      return AttachmentProcessResult(
        success: true,
        extractedText: text,
        metadata: {
          'type': 'word',
          'size': bytes.length,
          'characters': text.length,
        },
      );
    } catch (e) {
      return AttachmentProcessResult(
        success: false,
        errorMessage: 'Failed to process Word document: $e',
      );
    }
  }

  /// Process text file
  Future<AttachmentProcessResult> _processText(String filePath) async {
    try {
      final file = File(filePath);
      final text = await file.readAsString();
      
      return AttachmentProcessResult(
        success: true,
        extractedText: text,
        metadata: {
          'type': 'text',
          'lines': text.split('\n').length,
          'characters': text.length,
        },
      );
    } catch (e) {
      return AttachmentProcessResult(
        success: false,
        errorMessage: 'Failed to process text file: $e',
      );
    }
  }

  /// Process image file
  Future<AttachmentProcessResult> _processImage(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return AttachmentProcessResult(
          success: false,
          errorMessage: 'Failed to decode image',
        );
      }
      
      // For images, we return metadata and a description
      return AttachmentProcessResult(
        success: true,
        extractedText: '[Image: ${image.width}x${image.height} pixels]',
        metadata: {
          'type': 'image',
          'width': image.width,
          'height': image.height,
          'size': bytes.length,
        },
        imageData: bytes,
      );
    } catch (e) {
      return AttachmentProcessResult(
        success: false,
        errorMessage: 'Failed to process image: $e',
      );
    }
  }

  /// Process PowerPoint file
  Future<AttachmentProcessResult> _processPowerPoint(String filePath) async {
    try {
      // PowerPoint processing requires additional packages
      // For now, return placeholder
      return AttachmentProcessResult(
        success: true,
        extractedText: '[PowerPoint content extraction not yet implemented]',
        metadata: {
          'type': 'powerpoint',
        },
      );
    } catch (e) {
      return AttachmentProcessResult(
        success: false,
        errorMessage: 'Failed to process PowerPoint: $e',
      );
    }
  }

  /// Create context string for LLM from attachments
  String createAttachmentContext(List<AttachmentProcessResult> results) {
    if (results.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('# ATTACHED FILES CONTENT\n');
    
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      if (!result.success || result.extractedText == null) continue;
      
      buffer.writeln('## Attachment ${i + 1}');
      if (result.metadata != null) {
        buffer.writeln('Type: ${result.metadata!['type'] ?? 'unknown'}');
      }
      buffer.writeln('\nContent:');
      buffer.writeln(result.extractedText);
      buffer.writeln('\n---\n');
    }
    
    return buffer.toString();
  }

  /// Validate file before processing
  bool validateFile(String filePath, int maxSizeBytes) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      
      final size = file.lengthSync();
      return size <= maxSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// Get supported file extensions
  List<String> get supportedExtensions => [
    'pdf', 'doc', 'docx', 'txt', 
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp',
    'ppt', 'pptx',
  ];
}

/// Result of attachment processing
class AttachmentProcessResult {
  final bool success;
  final String? extractedText;
  final Map<String, dynamic>? metadata;
  final Uint8List? imageData;
  final String? errorMessage;

  AttachmentProcessResult({
    required this.success,
    this.extractedText,
    this.metadata,
    this.imageData,
    this.errorMessage,
  });

  bool get hasText => extractedText != null && extractedText!.isNotEmpty;
  bool get hasImage => imageData != null;
}