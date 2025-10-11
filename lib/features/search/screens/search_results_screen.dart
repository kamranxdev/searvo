import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/search/widgets/follow_up_search_box.dart';
import 'package:searvo/features/search/widgets/message_box.dart';
import 'package:searvo/features/search/widgets/search_box.dart';
import 'package:searvo/features/history/utils/conversation_auto_saver.dart';
import 'package:searvo/shared/widgets/attachment_input_widget.dart';
import 'dart:async';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message_branch_model.dart';
import '../providers/search_provider.dart';

class SearchResultsContent extends StatefulWidget {
  final String query;
  final SearchMode searchMode;
  final List<dynamic>? initialAttachments;
  final String? conversationId;
  
  const SearchResultsContent({
    super.key,
    required this.query,
    this.searchMode = SearchMode.search,
    this.initialAttachments,
    this.conversationId,
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
      _setupAutoSave();
    });
  }

  void _setupAutoSave() {
    final searchProvider = context.read<SearchProvider>();
    searchProvider.onConversationUpdate = () {
      ConversationAutoSaver.autoSave(context);
    };
  }

  Future<void> _initializeAndSearch() async {
    final searchProvider = context.read<SearchProvider>();
    try {
      await searchProvider.initialize();
      
      if (widget.conversationId != null && searchProvider.currentConversationId == widget.conversationId) {
        // Conversation already loaded
      } else {
        // New search or different conversation
        searchProvider.clearMessages();
        await searchProvider.performInitialSearch(
          widget.query,
          widget.searchMode,
          widget.initialAttachments,
        );
      }
    } catch (e) {
      print('Failed to initialize: $e');
      _showErrorMessage('Failed to perform search: $e');
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
    final searchProvider = context.read<SearchProvider>();
    try {
      await searchProvider.addNewMessage(query, attachments);
      _scrollToBottom();
    } catch (e) {
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
    if (_followUpController.text.trim().isNotEmpty) {
      final query = _followUpController.text.trim();
      _addNewMessage(query, attachments);
      _followUpController.clear();
    }
  }

  void _onRewriteMessage(int index, MessageBranchManager branchManager) async {
    final searchProvider = context.read<SearchProvider>();
    try {
      await searchProvider.rewriteMessage(index);
    } catch (e) {
      _showErrorMessage('Failed to rewrite message: $e');
    }
  }

  void _onEditQuery(int index, MessageBranchManager branchManager, String newQuery) async {
    final searchProvider = context.read<SearchProvider>();
    try {
      await searchProvider.editQuery(index, newQuery);
    } catch (e) {
      _showErrorMessage('Failed to edit query: $e');
    }
  }

  Future<void> _exportConversation(String format) async {
    final searchProvider = context.read<SearchProvider>();
    final messageBranches = searchProvider.messageBranches;
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
          return [
            pw.Text(content),
          ];
        },
      ),
    );
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/conversation.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Conversation');
  }

  Future<void> _shareConversation() async {
    final searchProvider = context.read<SearchProvider>();
    final messageBranches = searchProvider.messageBranches;
    String content = '';

    for (var branch in messageBranches) {
      final message = branch.currentMessage;
      content += '${message.query}\n\n${message.answer}\n\n';
    }

    await Share.share(content, subject: 'Shared Conversation');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        final messageBranches = searchProvider.messageBranches;
        final isProcessing = searchProvider.isProcessing;

        final colorScheme = context.colorScheme;
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1024;
        final searchBoxHeight = 120.0; // Approximate height for the search box area
        
        return Stack(
          children: [
            // Scrollable content area - full screen
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      width: isLargeScreen ? 896 : double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 0 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...messageBranches.asMap().entries.map((entry) {
                            final index = entry.key;
                            final branchManager = entry.value;
                            
                            return Column(
                              children: [
                                if (index > 0) ...[
                                  const SizedBox(height: 24),
                                  Container(
                                    height: 1,
                                    color: colorScheme.outline,
                                    margin: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                MessageBox(
                                  branchManager: branchManager,
                                  isFirstMessage: index == 0,
                                  onRelatedQuestionTap: (question) {
                                    _followUpController.text = question;
                                    _scrollToBottom();
                                  },
                                  onRewrite: () => _onRewriteMessage(index, branchManager),
                                  onEditQuery: (newQuery) => _onEditQuery(index, branchManager, newQuery),
                                  onBranchChanged: () {
                                    setState(() {});
                                  },
                                ),
                                if (index == messageBranches.length - 1)
                                  SizedBox(height: searchBoxHeight + 40),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
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
                      colorScheme.surface.withOpacity(0.0),
                      colorScheme.surface.withOpacity(0.95),
                      colorScheme.surface,
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
                  color: colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share button
                    IconButton(
                      onPressed: () => _shareConversation(),
                      icon: Icon(
                        Icons.share,
                        color: colorScheme.onSurface,
                      ),
                      tooltip: 'Share Conversation',
                    ),
                    // Export button with menu
                    PopupMenuButton<String>(
                      onSelected: _exportConversation,
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'MD', child: Text('Export as MD')),
                        PopupMenuItem(value: 'PDF', child: Text('Export as PDF')),
                        PopupMenuItem(value: 'TXT', child: Text('Export as TXT')),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.file_download_outlined,
                          color: colorScheme.onSurface,
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

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<dynamic>? initialAttachments;
  final String? conversationId;
  
  const SearchResultsScreen({
    super.key,
    required this.query,
    this.initialAttachments,
    this.conversationId,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SearchResultsContent(
        query: widget.query,
        initialAttachments: widget.initialAttachments,
        conversationId: widget.conversationId,
      ),
    );
  }
}