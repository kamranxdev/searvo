import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/search/presentation/widgets/follow_up_search_box.dart';
import 'package:searvo/features/search/presentation/widgets/message_box.dart';

import 'package:searvo/features/history/services/conversation_database_service.dart';
import 'package:searvo/common/widgets/attachment_input_widget.dart';
import 'dart:async';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:searvo/features/search/domain/entities/message_branch_manager.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class SearchResultsContent extends StatefulWidget {
  final String query;

  final List<dynamic>? initialAttachments;
  final String? conversationId;
  final String? externalUrl;

  const SearchResultsContent({
    super.key,
    required this.query,
    this.initialAttachments,
    this.conversationId,
    this.externalUrl,
  });

  @override
  State<SearchResultsContent> createState() => _SearchResultsContentState();
}

class _SearchResultsContentState extends State<SearchResultsContent> {
  final TextEditingController _followUpController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndSearch();
    });
  }

  Future<void> _initializeAndSearch() async {
    final searchBloc = context.read<SearchBloc>();
    try {
      searchBloc.add(const SearchEvent.initialize());

      if (widget.conversationId != null) {
        // Check if conversation is already loaded in memory
        final currentState = searchBloc.state;
        if (currentState.conversationId == widget.conversationId &&
            currentState.hasActiveConversation) {
          // Conversation already loaded in memory
          print('📌 Conversation already loaded: ${widget.conversationId}');
        } else {
          // Load conversation from database (local or cloud)
          await _loadConversationFromDatabase();
        }
      } else {
        // New search - no conversation ID provided
        searchBloc.add(const SearchEvent.clearMessages());
        searchBloc.add(
          SearchEvent.performInitialSearch(
            query: widget.query,
            attachments: widget.initialAttachments,
          ),
        );
      }
    } catch (e) {
      print('Failed to initialize: $e');
      _showErrorMessage('Failed to perform search: $e');
    }
  }

  Future<void> _loadConversationFromDatabase() async {
    final searchBloc = context.read<SearchBloc>();
    final databaseService = ConversationDatabaseService();

    try {
      print('📥 Loading conversation from database: ${widget.conversationId}');

      // Get the conversation from database by exact UUID match
      final conversation = await databaseService
          .getConversationByConversationId(widget.conversationId!);

      if (conversation != null) {
        // Convert stored messages back to branches
        final branches = databaseService.convertMessagesToBranches(
          conversation.messages,
        );

        // Load conversation into SearchBloc
        searchBloc.add(
          SearchEvent.loadConversation(
            conversationId: conversation.conversationId,
            title: conversation.title,
            branches: branches,
          ),
        );

        print('✅ Conversation loaded successfully: ${conversation.title}');
      } else {
        // Conversation not found in database
        // This could happen if conversation was deleted or never saved
        // Perform a new search with the UUID from URL
        print(
          '⚠️ Conversation not found in database, performing new search with UUID',
        );
        searchBloc.add(const SearchEvent.clearMessages());
        searchBloc.add(
          SearchEvent.performInitialSearch(
            query: widget.query,
            attachments: widget.initialAttachments,
            conversationId: widget.conversationId, // Use UUID from URL
          ),
        );
      }
    } catch (e) {
      print('❌ Failed to load conversation from database: $e');
      // Fall back to new search with UUID from URL
      searchBloc.add(const SearchEvent.clearMessages());
      searchBloc.add(
        SearchEvent.performInitialSearch(
          query: widget.query,
          attachments: widget.initialAttachments,
          conversationId: widget.conversationId, // Use UUID from URL
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppThemeConfig.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _followUpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewMessage(String query, List<AttachmentData>? attachments) async {
    print('🔔 SearchResultsPage._addNewMessage called');
    print('   query: "$query", attachments: ${attachments?.length ?? 0}');
    final searchBloc = context.read<SearchBloc>();
    try {
      print('   Dispatching SearchEvent.addNewMessage...');
      searchBloc.add(
        SearchEvent.addNewMessage(query: query, attachments: attachments),
      );
      print('   ✅ Event dispatched');
      _scrollToBottom();
    } catch (e) {
      print('   ❌ Error dispatching event: $e');
      _showErrorMessage('Failed to send message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onFollowUpSubmit(List<AttachmentData>? attachments) {
    print('🔔 SearchResultsPage._onFollowUpSubmit called');
    print(
      '   text: "${_followUpController.text.trim()}", attachments: ${attachments?.length ?? 0}',
    );
    if (_followUpController.text.trim().isNotEmpty) {
      final query = _followUpController.text.trim();
      print('   Calling _addNewMessage with query: "$query"');
      _addNewMessage(query, attachments);
      _followUpController.clear();
    } else {
      print('   ⚠️ Submit blocked: empty text');
    }
  }

  void _onRewriteMessage(int index, MessageBranchManager branchManager) async {
    final searchBloc = context.read<SearchBloc>();
    try {
      searchBloc.add(SearchEvent.rewriteMessage(index: index));
    } catch (e) {
      _showErrorMessage('Failed to rewrite message: $e');
    }
  }

  void _onEditQuery(
    int index,
    MessageBranchManager branchManager,
    String newQuery,
  ) async {
    final searchBloc = context.read<SearchBloc>();
    try {
      searchBloc.add(SearchEvent.editQuery(index: index, newQuery: newQuery));
    } catch (e) {
      _showErrorMessage('Failed to edit query: $e');
    }
  }

  Future<void> _exportConversation(String format) async {
    final searchBloc = context.read<SearchBloc>();
    final messageBranches = searchBloc.state.messageBranches;
    String content = '';

    for (var branch in messageBranches) {
      final message = branch.currentMessage;
      content += '## ${message.query}\n\n${message.answer}\n\n';
    }

    if (format == 'MD') {
      await _shareText(content, 'conversation.md');
    } else if (format == 'TXT') {
      await _shareText(content, 'conversation.txt');
    } else if (format == 'PDF') {
      await _exportAsPdf(content);
    }
  }

  Future<void> _shareText(String text, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(text);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Conversation');
  }

  Future<void> _exportAsPdf(String content) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [pw.Text(content)];
        },
      ),
    );
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/conversation.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Conversation');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final messageBranches = state.messageBranches;
        final isProcessing = state.isProcessing;

        final searchColors = SearchTheme.colors(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1024;
        final searchBoxHeight =
            120.0; // Approximate height for the search box area

        return Stack(
          children: [
            // Scrollable content area - full screen
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverList.builder(
                  itemCount: messageBranches.length + 1,
                  itemBuilder: (context, index) {
                    if (index == messageBranches.length) {
                      return SizedBox(height: searchBoxHeight + 40);
                    }

                    final branchManager = messageBranches[index];

                    return Center(
                      child: Container(
                        width: isLargeScreen ? 896 : double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 0 : 0,
                        ),
                        child: Column(
                          children: [
                            if (index > 0) ...[
                              const SizedBox(height: 24),
                              Container(
                                height: 1,
                                color: searchColors.divider,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            MessageBox(
                              branchManager: branchManager,
                              isFirstMessage: index == 0,
                              externalUrl: index == 0
                                  ? widget.externalUrl
                                  : null,
                              onRelatedQuestionTap: (question) {
                                _followUpController.text = question;
                                _scrollToBottom();
                              },
                              onRewrite: () =>
                                  _onRewriteMessage(index, branchManager),
                              onEditQuery: (newQuery) =>
                                  _onEditQuery(index, branchManager, newQuery),
                              onBranchChanged: () {
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Floating follow-up search box at bottom (overlay)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isLargeScreen ? (screenWidth - 896) / 2 + 20 : 20,
                  24,
                  isLargeScreen ? (screenWidth - 896) / 2 + 20 : 20,
                  MediaQuery.of(context).padding.bottom + 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      searchColors.background.withOpacity(0.0),
                      searchColors.background.withOpacity(0.95),
                      searchColors.background,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: isLargeScreen ? 896 : double.infinity,
                    child: FollowUpSearchBox(
                      controller: _followUpController,
                      onSend: (attachments) => _onFollowUpSubmit(attachments),
                      onAttachmentError: (error) =>
                          print('Attachment Error: $error'),
                      enabled: !isProcessing,
                    ),
                  ),
                ),
              ),
            ),

            // Export and Share buttons at top right
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: searchColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: searchColors.text.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Export button with menu
                    PopupMenuButton<String>(
                      onSelected: _exportConversation,
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'MD', child: Text('Export as MD')),
                        PopupMenuItem(
                          value: 'PDF',
                          child: Text('Export as PDF'),
                        ),
                        PopupMenuItem(
                          value: 'TXT',
                          child: Text('Export as TXT'),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.file_download_outlined,
                          color: searchColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SearchResultsPage extends StatefulWidget {
  final String query;
  final List<dynamic>? initialAttachments;
  final String? conversationId;
  final String? externalUrl;

  const SearchResultsPage({
    super.key,
    required this.query,
    this.initialAttachments,
    this.conversationId,
    this.externalUrl,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);

    return Scaffold(
      backgroundColor: searchColors.background,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8), // Slightly higher center
                radius: 1.5,
                colors: [
                  AppThemeConfig.primaryColor.withValues(alpha: 0.03),
                  searchColors.background,
                ],
              ),
            ),
          ),
          SearchResultsContent(
            query: widget.query,
            initialAttachments: widget.initialAttachments,
            conversationId: widget.conversationId,
            externalUrl: widget.externalUrl,
          ),
        ],
      ),
    );
  }
}
