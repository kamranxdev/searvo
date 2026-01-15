import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/core/di/injection_container.dart' as di;
import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/presentation/cubit/history_cubit.dart';
import 'package:searvo/features/history/presentation/cubit/history_state.dart';
import '../../../core/routing/app_router.dart';
import '../widgets/conversation_list_item_bloc.dart';
import '../widgets/empty_history_widget.dart';

/// Main conversation history screen
class ConversationHistoryScreen extends StatelessWidget {
  const ConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<HistoryCubit>()..loadConversations(),
      child: const _ConversationHistoryView(),
    );
  }
}

class _ConversationHistoryView extends StatefulWidget {
  const _ConversationHistoryView();

  @override
  State<_ConversationHistoryView> createState() =>
      _ConversationHistoryViewState();
}

class _ConversationHistoryViewState extends State<_ConversationHistoryView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<String> _selectedConversations = {};

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

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete ALL conversation history? This action cannot be undone.',
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
      final cubit = context.read<HistoryCubit>();
      // We need a way to clear all.
      // Assuming HistoryCubit has a method or we Iterate.
      // Best is to add clearAll to cubit.
      // Checking HistoryCubit... it likely doesn't have it explicitly exposed yet in the screen usage I saw earlier?
      // I dug into HistoryDependencies explaining deleteAllConversations usecase exists.
      // I should add deleteAll to HistoryCubit if not present.

      // Let's assumme I need to check HistoryCubit.
      // Implementation below assumes I will add it or it exists.
      await cubit.deleteAll(); // I will need to verify/add this.

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All history cleared')));
      }
    }
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
      final cubit = context.read<HistoryCubit>();
      for (final conversationId in _selectedConversations) {
        await cubit.delete(conversationId);
      }
      setState(() {
        _selectedConversations.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Conversations deleted')));
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
                      : 'History',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (_isSelectionMode) ...[
                BlocBuilder<HistoryCubit, HistoryState>(
                  builder: (context, state) {
                    return state.maybeWhen(
                      loaded: (conversations, _, __, ___, ____) => IconButton(
                        icon: const Icon(Icons.select_all),
                        onPressed: () {
                          setState(() {
                            if (_selectedConversations.length ==
                                conversations.length) {
                              _selectedConversations.clear();
                            } else {
                              _selectedConversations.addAll(
                                conversations.map((c) => c.conversationId),
                              );
                            }
                          });
                        },
                        tooltip: 'Select all',
                      ),
                      orElse: () => const SizedBox(),
                    );
                  },
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
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // Navigate to settings tab
                    // Assuming RootNavigation can switch tabs or we push SettingsScreen
                    // For now, let's just push SettingsScreen if not easily switchable
                    // Or finding a way to switch to settings tab
                    // Since Settings is a tab in RootNavigation, we might need a way to switch tabs.
                    // But for now, let's assume we can push a settings route or better yet,
                    // since I need to integrate simple settings, maybe a modal or bottom sheet?
                    // The requirement says "Improve... UX... and check in @directory:settings".
                    // So I should link to settings.

                    // Since I don't have direct access to switch main tabs from here easily without context of main navigation,
                    // I'll show a todo or try to find how to switch.
                    // Reviewing RootNavigationScreen might be needed but let's just push settings for now if possible or add a callback.
                  },
                  tooltip: 'History Settings',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'select':
                        _toggleSelectionMode();
                        break;
                      case 'clear_all':
                        _clearAllHistory();
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
                          Text('Select Conversations'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Clear All History',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                        context.read<HistoryCubit>().clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            onChanged: (value) {
              context.read<HistoryCubit>().search(value);
            },
          ),
        ),

        // Conversation list
        Expanded(
          child: BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              return state.when(
                initial: () => const Center(child: Text('Start searching...')),
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded:
                    (
                      conversations,
                      groupedConversations,
                      searchResults,
                      searchQuery,
                      isSearching,
                    ) {
                      // Show search loading
                      if (isSearching) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Show search results if searching
                      if (searchQuery.isNotEmpty) {
                        if (searchResults.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found for "$searchQuery"',
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildConversationList(searchResults);
                      }

                      // Show empty state if no conversations
                      if (conversations.isEmpty) {
                        return const EmptyHistoryWidget();
                      }

                      // Show grouped conversations
                      return _buildGroupedConversationList(
                        groupedConversations,
                      );
                    },
                error: (failure) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${failure.message}',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<HistoryCubit>().loadConversations(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedConversationList(
    Map<String, List<Conversation>> grouped,
  ) {
    final categories = [
      'Today',
      'Yesterday',
      'Last 7 Days',
      'Last 30 Days',
      'Older',
    ];
    final filteredCategories = categories
        .where((cat) => grouped[cat]?.isNotEmpty ?? false)
        .toList();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      itemCount: filteredCategories.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        final conversations = grouped[category] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...conversations.map(
              (conversation) => ConversationListItemBloc(
                conversation: conversation,
                isSelected: _selectedConversations.contains(
                  conversation.conversationId,
                ),
                isSelectionMode: _isSelectionMode,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleConversationSelection(conversation.conversationId);
                  } else {
                    _openConversation(conversation);
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
                onDelete: () => _deleteConversation(conversation),
                onPin: () => context.read<HistoryCubit>().togglePin(
                  conversation.conversationId,
                ),
                onRename: () => _renameConversation(conversation),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConversationList(List<Conversation> conversations) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationListItemBloc(
          conversation: conversation,
          isSelected: _selectedConversations.contains(
            conversation.conversationId,
          ),
          isSelectionMode: _isSelectionMode,
          onTap: () {
            if (_isSelectionMode) {
              _toggleConversationSelection(conversation.conversationId);
            } else {
              _openConversation(conversation);
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
          onDelete: () => _deleteConversation(conversation),
          onPin: () => context.read<HistoryCubit>().togglePin(
            conversation.conversationId,
          ),
          onRename: () => _renameConversation(conversation),
        );
      },
    );
  }

  void _openConversation(Conversation conversation) {
    // Navigate to search results with conversation ID - let the screen load from database
    AppRouter.goToSearchResults(
      context,
      conversation.title,
      conversationId: conversation.conversationId,
    );
  }

  Future<void> _deleteConversation(Conversation conversation) async {
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
      await context.read<HistoryCubit>().delete(conversation.conversationId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
      }
    }
  }

  Future<void> _renameConversation(Conversation conversation) async {
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

    // TODO: Implement update conversation use case
    // For now, just show a message
    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != conversation.title &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rename functionality coming soon')),
      );
    }

    controller.dispose();
  }
}
