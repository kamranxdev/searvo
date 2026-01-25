import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/voice/widgets/voice_input_widget.dart';
import 'package:searvo/common/widgets/attachment_input_widget.dart';

class FollowUpSearchBox extends StatefulWidget {
  final TextEditingController controller;
  final Function(List<AttachmentData>?)? onSend;
  final Function(String)? onVoiceTextReceived;
  final Function(String)? onVoiceError;
  final Function(String)? onAttachmentError;
  final bool enabled;

  const FollowUpSearchBox({
    super.key,
    required this.controller,
    this.onSend,
    this.onVoiceTextReceived,
    this.onVoiceError,
    this.onAttachmentError,
    this.enabled = true,
  });

  @override
  State<FollowUpSearchBox> createState() => _FollowUpSearchBoxState();
}

class _FollowUpSearchBoxState extends State<FollowUpSearchBox> {
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  List<AttachmentData> _attachments = [];
  final GlobalKey<AttachmentInputWidgetState> _attachmentWidgetKey =
      GlobalKey();

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
    print('🔔 FollowUpSearchBox._handleSend called');
    print(
      '   enabled: ${widget.enabled}, text: "${widget.controller.text.trim()}"',
    );
    if (widget.enabled && widget.controller.text.trim().isNotEmpty) {
      final attachmentsCopy = List<AttachmentData>.from(_attachments);
      print('   Calling onSend with ${attachmentsCopy.length} attachments');
      widget.onSend?.call(attachmentsCopy.isNotEmpty ? attachmentsCopy : null);

      // Clear attachments after sending
      _attachmentWidgetKey.currentState?.clearAttachments();
    } else {
      print(
        '   ⚠️ Send blocked: enabled=${widget.enabled}, hasText=${widget.controller.text.trim().isNotEmpty}',
      );
    }
  }

  Widget _buildAttachmentPill(AttachmentData attachment) {
    final searchColors = SearchTheme.colors(context);

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: searchColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: searchColors.outline, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(attachment.icon, size: 14, color: searchColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              style: TextStyle(
                color: searchColors.onSurface,
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
              color: searchColors.onSurfaceVariant,
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
                color: searchColors.surfaceContainerHighest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                size: 10,
                color: searchColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: searchColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: searchColors.outline, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachments.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  children: _attachments
                      .map((attachment) => _buildAttachmentPill(attachment))
                      .toList(),
                ),
              ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                _attachments.isNotEmpty ? 8 : 16,
                16,
                8,
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
                      color: searchColors.onSurfaceVariant.withOpacity(0.6),
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
                  style: TextStyle(color: searchColors.onSurface, fontSize: 16),
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
                        onError: widget.onAttachmentError,
                        activeColor: searchColors.primary,
                        inactiveColor: widget.enabled
                            ? searchColors.onSurfaceVariant.withOpacity(0.6)
                            : searchColors.onSurfaceVariant.withOpacity(0.3),
                        iconSize: 20,
                        maxFileSize: 50 * 1024 * 1024,
                        maxFiles: 5,
                        allowMultiple: true,
                      ),
                      const SizedBox(width: 16),

                      VoiceInputWidget(
                        onTextReceived: (text) {
                          widget.controller.text = text;
                          widget
                              .controller
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: widget.controller.text.length),
                          );
                          widget.onVoiceTextReceived?.call(text);
                        },
                        onError: widget.onVoiceError,
                        activeColor: searchColors.primary,
                        inactiveColor: widget.enabled
                            ? searchColors.onSurfaceVariant.withOpacity(0.6)
                            : searchColors.onSurfaceVariant.withOpacity(0.3),
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
                                ? searchColors.primary
                                : searchColors.primary.withOpacity(0.5),
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
