import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import 'package:intl/intl.dart';

/// Widget for displaying a single conversation in the history list
class ConversationListItem extends StatelessWidget {
  final ConversationModel conversation;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onRename;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onPin,
    required this.onRename,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withAlpha(25)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary.withAlpha(100)
              : colorScheme.outline.withAlpha(20),
          width: 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: colorScheme.primary.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          splashColor: colorScheme.primary.withAlpha(30),
          highlightColor: colorScheme.primary.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection checkbox or distinct icon
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4),
                    child: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: colorScheme.outline,
                          width: 1.5,
                        ),
                        onChanged: (value) => onTap(),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 2),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          80,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        conversation.isPinned
                            ? Icons.push_pin
                            : Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: conversation.isPinned
                            ? colorScheme.primary
                            : colorScheme.primary.withAlpha(180),
                      ),
                    ),
                  ),

                // Conversation content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title
                          Expanded(
                            child: Text(
                              conversation.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time
                          Text(
                            _formatDate(conversation.updatedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Preview
                      Text(
                        conversation.preview,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant.withAlpha(200),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Message count and tags
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.message_outlined,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${conversation.messageCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (conversation.tags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label_outline,
                                    size: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    conversation.tags.first,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (conversation.tags.length > 1)
                                    Text(
                                      ' +${conversation.tags.length - 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions menu
                if (!isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: colorScheme.surfaceContainer,
                      onSelected: (value) {
                        switch (value) {
                          case 'pin':
                            onPin();
                            break;
                          case 'rename':
                            onRename();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(
                                conversation.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                conversation.isPinned ? 'Unpin' : 'Pin',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: colorScheme.onSurface,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Rename',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
