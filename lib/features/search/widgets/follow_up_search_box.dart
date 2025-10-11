import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/voice/widgets/voice_input_widget.dart';
import 'package:searvo/shared/widgets/attachment_input_widget.dart';

class FollowUpSearchBox extends StatefulWidget {
  final TextEditingController controller;
  final Function(List<AttachmentData>?)? onSend;
  final Function(String)? onVoiceTextReceived;
  final Function(String)? onVoiceError;
  final bool enabled;

  const FollowUpSearchBox({
    super.key,
    required this.controller,
    this.onSend,
    this.onVoiceTextReceived,
    this.onVoiceError,
    this.enabled = true,
  });

  @override
  State<FollowUpSearchBox> createState() => _FollowUpSearchBoxState();
}

class _FollowUpSearchBoxState extends State<FollowUpSearchBox> {
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  List<AttachmentData> _attachments = [];
  final GlobalKey<AttachmentInputWidgetState> _attachmentWidgetKey = GlobalKey();

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleAttachmentsChanged(List<AttachmentData> attachments) {
    setState(() {
      _attachments = attachments;
    });
  }

  void _removeAttachment(AttachmentData attachment) {
    _attachmentWidgetKey.currentState?.removeAttachment(attachment);
  }

  void _handleSend() {
    if (widget.enabled && widget.controller.text.trim().isNotEmpty) {
      final attachmentsCopy = List<AttachmentData>.from(_attachments);
      widget.onSend?.call(attachmentsCopy.isNotEmpty ? attachmentsCopy : null);
      
      // Clear attachments after sending
      _attachmentWidgetKey.currentState?.clearAttachments();
    }
  }

  Widget _buildAttachmentPill(AttachmentData attachment) {
    final colorScheme = context.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.icon,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            attachment.formattedSize,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeAttachment(attachment),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                size: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachments.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  children: _attachments.map((attachment) => 
                    _buildAttachmentPill(attachment)).toList(),
                ),
              ),
            
            Padding(
              padding: EdgeInsets.fromLTRB(
                16, 
                _attachments.isNotEmpty ? 8 : 16, 
                16, 
                8
              ),
              child: RawKeyboardListener(
                focusNode: _keyboardFocusNode,
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !event.isShiftPressed &&
                      !event.isControlPressed &&
                      !event.isAltPressed &&
                      !event.isMetaPressed) {
                    _handleSend();
                  }
                },
                child: TextField(
                  controller: widget.controller,
                  focusNode: _textFieldFocusNode,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    hintText: 'Ask a follow-up...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  onSubmitted: (_) => _handleSend(),
                  maxLines: null,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  const Spacer(),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AttachmentInputWidget(
                        key: _attachmentWidgetKey,
                        onAttachmentsChanged: _handleAttachmentsChanged,
                        activeColor: colorScheme.primary,
                        inactiveColor: widget.enabled ? colorScheme.onSurfaceVariant.withOpacity(0.6) : colorScheme.onSurfaceVariant.withOpacity(0.3),
                        iconSize: 20,
                        maxFileSize: 50 * 1024 * 1024,
                        maxFiles: 5,
                        allowMultiple: true,
                      ),
                      const SizedBox(width: 16),
                      
                      VoiceInputWidget(
                        onTextReceived: (text) {
                          if (widget.controller.text.isEmpty) {
                            widget.controller.text = text;
                          } else {
                            widget.controller.text += ' $text';
                          }
                          widget.controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: widget.controller.text.length),
                          );
                          widget.onVoiceTextReceived?.call(text);
                        },
                        onError: widget.onVoiceError,
                        activeColor: colorScheme.primary,
                        inactiveColor: widget.enabled ? colorScheme.onSurfaceVariant.withOpacity(0.6) : colorScheme.onSurfaceVariant.withOpacity(0.3),
                        iconSize: 20,
                      ),
                      const SizedBox(width: 16),
                      
                      GestureDetector(
                        onTap: widget.enabled ? _handleSend : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.enabled 
                                ? colorScheme.primary 
                                : colorScheme.primary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.graphic_eq,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}