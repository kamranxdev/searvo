/// Metadata for attached files
class AttachmentMetadata {
  final String id;
  final String name;
  final String path;
  final String type;
  final int size;
  final DateTime uploadedAt;
  final String? extractedText;
  final Map<String, dynamic>? metadata;

  AttachmentMetadata({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.uploadedAt,
    this.extractedText,
    this.metadata,
  });

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Check if attachment has been processed
  bool get isProcessed => extractedText != null;

  /// Create from AttachmentData
  factory AttachmentMetadata.fromAttachmentData(
    dynamic attachmentData,
    String? extractedText,
  ) {
    return AttachmentMetadata(
      id: attachmentData.path.hashCode.toString(),
      name: attachmentData.name,
      path: attachmentData.path,
      type: attachmentData.type.toString(),
      size: attachmentData.size,
      uploadedAt: attachmentData.uploadedAt,
      extractedText: extractedText,
    );
  }

  AttachmentMetadata copyWith({
    String? extractedText,
    Map<String, dynamic>? metadata,
  }) {
    return AttachmentMetadata(
      id: id,
      name: name,
      path: path,
      type: type,
      size: size,
      uploadedAt: uploadedAt,
      extractedText: extractedText ?? this.extractedText,
      metadata: metadata ?? this.metadata,
    );
  }
}
