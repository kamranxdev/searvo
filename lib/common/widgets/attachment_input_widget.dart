import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// Supported attachment types
enum AttachmentType {
  document,
  image,
  audio,
  video,
  other,
}

/// Attachment data model
class AttachmentData {
  final String name;
  final String path;
  final AttachmentType type;
  final int size;
  final DateTime uploadedAt;

  AttachmentData({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  /// Get file extension
  String get extension => name.split('.').last.toLowerCase();

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Determine attachment type from file extension
  static AttachmentType getTypeFromExtension(String extension) {
    final ext = extension.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return AttachmentType.image;
    } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].contains(ext)) {
      return AttachmentType.audio;
    } else if (['mp4', 'avi', 'mov', 'wmv', 'mkv', 'webm'].contains(ext)) {
      return AttachmentType.video;
    } else if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) {
      return AttachmentType.document;
    } else {
      return AttachmentType.other;
    }
  }

  /// Get appropriate icon for attachment type
  IconData get icon {
    switch (type) {
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.audio:
        return Icons.audiotrack;
      case AttachmentType.video:
        return Icons.videocam;
      case AttachmentType.other:
        return Icons.insert_drive_file;
    }
  }
}

/// Reusable attachment input widget that can be integrated into various UI components
class AttachmentInputWidget extends StatefulWidget {
  final Function(List<AttachmentData>)? onAttachmentsChanged;
  final Function(AttachmentData)? onAttachmentAdded;
  final Function(AttachmentData)? onAttachmentRemoved;
  final Function(String)? onError;
  final Widget? customIcon;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? iconSize;
  final List<String>? allowedExtensions;
  final int? maxFileSize; // in bytes
  final int? maxFiles;
  final bool showAttachmentList;
  final bool allowMultiple;

  const AttachmentInputWidget({
    super.key,
    this.onAttachmentsChanged,
    this.onAttachmentAdded,
    this.onAttachmentRemoved,
    this.onError,
    this.customIcon,
    this.activeColor,
    this.inactiveColor,
    this.iconSize,
    this.allowedExtensions,
    this.maxFileSize, // Default 10MB if not specified
    this.maxFiles, // No limit if not specified
    this.showAttachmentList = false,
    this.allowMultiple = true,
  });

  @override
  State<AttachmentInputWidget> createState() => AttachmentInputWidgetState();
}

class AttachmentInputWidgetState extends State<AttachmentInputWidget> {
  final List<AttachmentData> _attachments = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attachment button
        GestureDetector(
          onTap: _isLoading ? null : _pickFiles,
          child: Container(
            decoration: _isLoading ? BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.withOpacity(0.1),
            ) : null,
            child: _isLoading 
                ? SizedBox(
                    width: widget.iconSize ?? 20,
                    height: widget.iconSize ?? 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.activeColor ?? Theme.of(context).primaryColor,
                    ),
                  )
                : widget.customIcon ?? Icon(
                    Icons.attachment,
                    color: _attachments.isNotEmpty 
                        ? (widget.activeColor ?? Theme.of(context).primaryColor)
                        : (widget.inactiveColor ?? Colors.grey),
                    size: widget.iconSize ?? 20,
                  ),
          ),
        ),
        
        // Attachment list (if enabled and has attachments)
        if (widget.showAttachmentList && _attachments.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _attachments.map((attachment) => _buildAttachmentItem(attachment)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentItem(AttachmentData attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.icon,
            size: 16,
            color: widget.activeColor ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.formattedSize,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeAttachment(attachment),
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: widget.allowMultiple,
        allowedExtensions: widget.allowedExtensions,
        type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          if (file.path != null) {
            // Check file size limit
            final fileSize = file.size;
            final maxSize = widget.maxFileSize ?? (10 * 1024 * 1024); // Default 10MB
            
            if (fileSize > maxSize) {
              widget.onError?.call('File "${file.name}" is too large. Maximum size is ${_formatBytes(maxSize)}.');
              continue;
            }

            // Check max files limit
            if (widget.maxFiles != null && _attachments.length >= widget.maxFiles!) {
              widget.onError?.call('Maximum ${widget.maxFiles} files allowed.');
              break;
            }

            // Create attachment data
            final attachment = AttachmentData(
              name: file.name,
              path: file.path!,
              type: AttachmentData.getTypeFromExtension(file.extension ?? ''),
              size: fileSize,
              uploadedAt: DateTime.now(),
            );

            // Add to list
            setState(() {
              _attachments.add(attachment);
            });

            // Notify callbacks
            widget.onAttachmentAdded?.call(attachment);
            widget.onAttachmentsChanged?.call(List.from(_attachments));
          }
        }
      }
    } catch (e) {
      widget.onError?.call('Error picking files: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeAttachment(AttachmentData attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
    
    widget.onAttachmentRemoved?.call(attachment);
    widget.onAttachmentsChanged?.call(List.from(_attachments));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Public method to get current attachments
  List<AttachmentData> get attachments => List.from(_attachments);

  /// Public method to clear all attachments
  void clearAttachments() {
    final removedAttachments = List.from(_attachments);
    setState(() {
      _attachments.clear();
    });
    
    for (var attachment in removedAttachments) {
      widget.onAttachmentRemoved?.call(attachment);
    }
    widget.onAttachmentsChanged?.call([]);
  }

  /// Public method to add attachment programmatically
  void addAttachment(AttachmentData attachment) {
    if (widget.maxFiles != null && _attachments.length >= widget.maxFiles!) {
      widget.onError?.call('Maximum ${widget.maxFiles} files allowed.');
      return;
    }

    setState(() {
      _attachments.add(attachment);
    });
    
    widget.onAttachmentAdded?.call(attachment);
    widget.onAttachmentsChanged?.call(List.from(_attachments));
  }

  /// Public method to remove attachment programmatically
  void removeAttachment(AttachmentData attachment) {
    _removeAttachment(attachment);
  }
}