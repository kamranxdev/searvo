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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox or icon
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onTap(),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 24,
                    color: Colors.grey,
                  ),
                ),

              // Conversation content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Pin indicator
                        if (conversation.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),

                        // Title
                        Expanded(
                          child: Text(
                            conversation.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Time
                        Text(
                          _formatDate(conversation.updatedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Preview
                    Text(
                      conversation.preview,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Message count and tags
                    Row(
                      children: [
                        const Icon(
                          Icons.message,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${conversation.messageCount} message${conversation.messageCount != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (conversation.tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.label,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conversation.tags.first,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (conversation.tags.length > 1)
                            Text(
                              ' +${conversation.tags.length - 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
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
                          ),
                          const SizedBox(width: 8),
                          Text(conversation.isPinned ? 'Unpin' : 'Pin'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
