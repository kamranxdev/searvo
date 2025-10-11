import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/app_router.dart';
import '../providers/conversation_history_provider.dart';
import '../models/conversation_model.dart';
import '../widgets/conversation_list_item.dart';
import '../widgets/empty_history_widget.dart';
import '../../search/providers/search_provider.dart';

/// Main conversation history screen
class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({super.key});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<String> _selectedConversations = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationHistoryProvider>().loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedConversations.clear();
      }
    });
  }

  void _toggleConversationSelection(String conversationId) {
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
      } else {
        _selectedConversations.add(conversationId);
      }
    });
  }

  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversations.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversations'),
        content: Text(
          'Are you sure you want to delete ${_selectedConversations.length} conversation(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ConversationHistoryProvider>();
      await provider.deleteConversations(_selectedConversations.toList());
      setState(() {
        _selectedConversations.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversations deleted')),
        );
      }
    }
  }

  Future<void> _deleteAllConversations() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Conversations'),
        content: const Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ConversationHistoryProvider>().deleteAllConversations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All conversations deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1024;
    
    return Column(
      children: [
        // Header section
        Container(
          padding: EdgeInsets.fromLTRB(
            isLargeScreen ? 32 : 16,
            16,
            isLargeScreen ? 32 : 16,
            16,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isSelectionMode
                      ? '${_selectedConversations.length} selected'
                      : 'Conversation History',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    final provider = context.read<ConversationHistoryProvider>();
                    setState(() {
                      if (_selectedConversations.length ==
                          provider.conversations.length) {
                        _selectedConversations.clear();
                      } else {
                        _selectedConversations.addAll(
                          provider.conversations.map((c) => c.conversationId),
                        );
                      }
                    });
                  },
                  tooltip: 'Select all',
                ),
                if (_selectedConversations.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelectedConversations,
                    tooltip: 'Delete selected',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'Cancel selection',
                ),
              ] else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'select':
                        _toggleSelectionMode();
                        break;
                      case 'delete_all':
                        _deleteAllConversations();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist),
                          SizedBox(width: 8),
                          Text('Select'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete All', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        // Search bar
        Padding(
          padding: EdgeInsets.fromLTRB(
            isLargeScreen ? 32 : 16,
            16,
            isLargeScreen ? 32 : 16,
            8,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<ConversationHistoryProvider>()
                            .clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              context
                  .read<ConversationHistoryProvider>()
                  .searchConversations(value);
            },
          ),
        ),

        // Conversation list
        Expanded(
            child: Consumer<ConversationHistoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadConversations(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Show search results if searching
                if (provider.searchQuery.isNotEmpty) {
                  if (provider.searchResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No results found for "${provider.searchQuery}"',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildConversationList(
                    provider.searchResults,
                    provider,
                  );
                }

                // Show empty state if no conversations
                if (!provider.hasConversations) {
                  return const EmptyHistoryWidget();
                }

                // Show grouped conversations
                return _buildGroupedConversationList(
                  provider.groupedConversations,
                  provider,
                );
              },
            ),
          ),
        ],
      );
  }

  Widget _buildGroupedConversationList(
    Map<String, List<ConversationModel>> grouped,
    ConversationHistoryProvider provider,
  ) {
    final categories = ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'Older'];
    final filteredCategories = categories.where((cat) => grouped[cat]?.isNotEmpty ?? false).toList();

    return ListView.builder(
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        final conversations = grouped[category] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...conversations.map((conversation) => ConversationListItem(
                  conversation: conversation,
                  isSelected: _selectedConversations.contains(conversation.conversationId),
                  isSelectionMode: _isSelectionMode,
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleConversationSelection(conversation.conversationId);
                    } else {
                      _openConversation(conversation, provider);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedConversations.add(conversation.conversationId);
                      });
                    }
                  },
                  onDelete: () => _deleteConversation(conversation, provider),
                  onPin: () => provider.togglePin(conversation.conversationId),
                  onRename: () => _renameConversation(conversation, provider),
                )),
          ],
        );
      },
    );
  }

  Widget _buildConversationList(
    List<ConversationModel> conversations,
    ConversationHistoryProvider provider,
  ) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationListItem(
          conversation: conversation,
          isSelected: _selectedConversations.contains(conversation.conversationId),
          isSelectionMode: _isSelectionMode,
          onTap: () {
            if (_isSelectionMode) {
              _toggleConversationSelection(conversation.conversationId);
            } else {
              _openConversation(conversation, provider);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedConversations.add(conversation.conversationId);
              });
            }
          },
          onDelete: () => _deleteConversation(conversation, provider),
          onPin: () => provider.togglePin(conversation.conversationId),
          onRename: () => _renameConversation(conversation, provider),
        );
      },
    );
  }

  void _openConversation(
    ConversationModel conversation,
    ConversationHistoryProvider provider,
  ) {
    // Convert stored messages back to branches
    final branches = provider.convertToBranches(conversation.messages);

    // Load conversation into SearchProvider first
    final searchProvider = context.read<SearchProvider>();
    searchProvider.loadConversation(
      conversationId: conversation.conversationId,
      title: conversation.title,
      branches: branches,
    );

    // Navigate to search route with conversation query
    // This way it won't be cleared when going to home
    AppRouter.goToSearchResults(
      context,
      conversation.title,
      conversationId: conversation.conversationId,
    );
  }

  Future<void> _deleteConversation(
    ConversationModel conversation,
    ConversationHistoryProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Delete "${conversation.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteConversation(conversation.conversationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      }
    }
  }

  Future<void> _renameConversation(
    ConversationModel conversation,
    ConversationHistoryProvider provider,
  ) async {
    final controller = TextEditingController(text: conversation.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != conversation.title) {
      await provider.updateConversation(
        conversationId: conversation.conversationId,
        title: newTitle,
      );
    }

    controller.dispose();
  }
}
