import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/search/models/message_branch_model.dart';
import 'package:searvo/features/search/models/message_data.dart';
import 'package:searvo/features/voice/services/voice_service.dart';
import 'package:searvo/shared/widgets/streaming_text_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';


class MessageBox extends StatefulWidget {
  final MessageBranchManager branchManager;
  final Function(String)? onRelatedQuestionTap;
  final bool isFirstMessage;
  final VoidCallback? onRewrite;
  final Function(String)? onEditQuery;
  final VoidCallback? onBranchChanged;

  const MessageBox({
    super.key,
    required this.branchManager,
    this.onRelatedQuestionTap,
    this.isFirstMessage = true,
    this.onRewrite,
    this.onEditQuery,
    this.onBranchChanged,
  });

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditingQuery = false;
  final TextEditingController _queryEditController = TextEditingController();
  final FocusNode _queryEditFocusNode = FocusNode();
  final VoiceService _voiceService = VoiceService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _getTabCount(), 
      vsync: this,
    );
    _queryEditController.text = widget.branchManager.currentMessage.query;
    // Initialize TTS
    _voiceService.initializeTts();
  }

  MessageData get _currentMessage => widget.branchManager.currentMessage;

  int _getTabCount() {
    return _getTabCountForState(_currentMessage.generationState);
  }

  int _getTabCountForState(MessageGenerationState state) {
    switch (state) {
      case MessageGenerationState.searching:
        return 1; // Only Answer tab during searching
      case MessageGenerationState.generating:
      case MessageGenerationState.streaming:
      case MessageGenerationState.completed:
        int count = 1; // Answer tab
        if (_currentMessage.images.isNotEmpty) count++;
        if (_currentMessage.videos.isNotEmpty) count++;
        if (_currentMessage.sources.isNotEmpty) count++;
        return count;
    }
  }

  List<Widget> _getTabs() {
    switch (_currentMessage.generationState) {
      case MessageGenerationState.searching:
        return const [Tab(text: 'Answer')];
      case MessageGenerationState.generating:
      case MessageGenerationState.streaming:
      case MessageGenerationState.completed:
        final tabs = <Widget>[const Tab(text: 'Answer')];
        
        // Conditionally add Images tab
        if (_currentMessage.images.isNotEmpty) {
          tabs.add(Tab(
            key: ValueKey('images_tab_${_currentMessage.images.length}'),
            child: _buildTabWithBadge('Images', _currentMessage.images.length),
          ));
        }
        
        // Conditionally add Videos tab
        if (_currentMessage.videos.isNotEmpty) {
          tabs.add(Tab(
            key: ValueKey('videos_tab_${_currentMessage.videos.length}'),
            child: _buildTabWithBadge('Videos', _currentMessage.videos.length),
          ));
        }
        
        // Conditionally add Sources tab
        if (_currentMessage.sources.isNotEmpty) {
          tabs.add(Tab(
            key: ValueKey('sources_tab_${_currentMessage.sources.length}'),
            child: _buildTabWithBadge('Sources', _currentMessage.sources.length),
          ));
        }
        
        return tabs;
    }
  }

  List<Widget> _getTabViews(ColorScheme colorScheme) {
    switch (_currentMessage.generationState) {
      case MessageGenerationState.searching:
        return [_buildAnswerTab(colorScheme)];
      case MessageGenerationState.generating:
      case MessageGenerationState.streaming:
      case MessageGenerationState.completed:
        final views = <Widget>[_buildAnswerTab(colorScheme)];
        
        if (_currentMessage.images.isNotEmpty) {
          views.add(_buildImagesTab(colorScheme));
        }
        
        if (_currentMessage.videos.isNotEmpty) {
          views.add(_buildVideosTab(colorScheme));
        }
        
        if (_currentMessage.sources.isNotEmpty) {
          views.add(_buildSourcesTab(colorScheme));
        }
        
        return views;
    }
  }

  Widget _buildTabWithBadge(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppThemeConfig.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void didUpdateWidget(MessageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final oldMessage = oldWidget.branchManager.currentMessage;
    final newMessage = _currentMessage;
    
    // Check if this is a different message entirely (branch change or new message)
    final isDifferentMessage = oldMessage.query != newMessage.query ||
                                oldMessage.answer != newMessage.answer;
    
    // Stop TTS if message changed
    if (isDifferentMessage && _voiceService.isSpeaking) {
      _voiceService.stop();
    }
    
    // Check if generation state changed
    final stateChanged = oldMessage.generationState != newMessage.generationState;
    
    // Check if content changed (images, videos)
    final contentChanged = oldMessage.images.length != newMessage.images.length ||
                          oldMessage.videos.length != newMessage.videos.length ||
                          oldMessage.sources.length != newMessage.sources.length;
    
    // Calculate old and new tab counts
    final oldTabCount = _calculateTabCount(oldMessage);
    final newTabCount = _getTabCount();
    
    // Recreate controller if tab count changed, different message, state changed, or content changed
    if (oldTabCount != newTabCount || isDifferentMessage || stateChanged || contentChanged) {
      final currentIndex = _tabController.index.clamp(0, newTabCount - 1);
      _tabController.dispose();
      _tabController = TabController(
        length: newTabCount,
        vsync: this,
        initialIndex: currentIndex,
      );
      if (mounted) setState(() {});
    }
  }
  
  int _calculateTabCount(MessageData message) {
    if (message.generationState == MessageGenerationState.generating) {
      return 1;
    }
    
    int count = 1; // Answer tab
    if (message.images.isNotEmpty) count++;
    if (message.videos.isNotEmpty) count++;
    count++; // Sources tab always present when streaming/completed
    return count;
  }

  @override
  void dispose() {
    _voiceService.stop();
    _tabController.dispose();
    _queryEditController.dispose();
    _queryEditFocusNode.dispose();
    super.dispose();
  }

  void _handleCitationTap(int citationNumber) {
    // Calculate the correct index for the Sources tab
    // Answer tab is always at index 0
    int sourcesTabIndex = 1; // Start after Answer tab
    
    if (_currentMessage.images.isNotEmpty) {
      sourcesTabIndex++; // Images tab exists
    }
    if (_currentMessage.videos.isNotEmpty) {
      sourcesTabIndex++; // Videos tab exists
    }
    
    _tabController.animateTo(sourcesTabIndex);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing source #$citationNumber'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportAsPdf() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _currentMessage.query,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  _currentMessage.answer,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                if (_currentMessage.sources.isNotEmpty) ...[
                  pw.Text(
                    'Sources:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ..._currentMessage.sources.map((source) =>
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          source.title,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(source.domain),
                        pw.Text(source.description),
                        pw.SizedBox(height: 10),
                      ],
                    )
                  ),
                ],
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'searvo_${_currentMessage.query.replaceAll(' ', '_').substring(0, 20)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportAsTxt() async {
    try {
      final content = '''
${_currentMessage.query}

${_currentMessage.answer}

${_currentMessage.sources.isNotEmpty ? 'Sources:' : ''}
${_currentMessage.sources.map((source) => '${source.title}\n${source.domain}\n${source.description}\n').join('\n')}
''';

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'searvo_${_currentMessage.query.replaceAll(' ', '_').substring(0, 20)}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TXT exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export TXT: $e')),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _currentMessage.answer));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  Future<void> _shareContent() async {
    try {
      final content = '''
${_currentMessage.query}

${_currentMessage.answer}

Sources:
${_currentMessage.sources.map((s) => '- ${s.title}: ${s.url}').join('\n')}
''';
      
      await Share.share(content, subject: _currentMessage.query);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  void _showExportMenuDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export as PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportAsPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Export as TXT'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportAsTxt();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startEditingQuery() {
    setState(() {
      _isEditingQuery = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queryEditFocusNode.requestFocus();
      _queryEditController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _queryEditController.text.length,
      );
    });
  }

  void _cancelEditingQuery() {
    setState(() {
      _isEditingQuery = false;
      _queryEditController.text = _currentMessage.query;
    });
  }

  void _saveEditedQuery() {
    final newQuery = _queryEditController.text.trim();
    if (newQuery.isNotEmpty && newQuery != _currentMessage.query) {
      widget.onEditQuery?.call(newQuery);
    }
    setState(() {
      _isEditingQuery = false;
    });
  }

  void _goToPreviousBranch() {
    if (widget.branchManager.hasPreviousBranch) {
      setState(() {
        widget.branchManager.goToPreviousBranch();
        _queryEditController.text = widget.branchManager.currentMessage.query;
      });
      widget.onBranchChanged?.call();
    }
  }

  void _goToNextBranch() {
    if (widget.branchManager.hasNextBranch) {
      setState(() {
        widget.branchManager.goToNextBranch();
        _queryEditController.text = widget.branchManager.currentMessage.query;
      });
      widget.onBranchChanged?.call();
    }
  }

  Future<void> _toggleTextToSpeech() async {
    if (_voiceService.isSpeaking) {
      // Stop speaking
      await _voiceService.stop();
    } else {
      // Start speaking the answer
      final textToSpeak = _currentMessage.answer;
      if (textToSpeak.isNotEmpty) {
        await _voiceService.speak(textToSpeak);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1024;
    
    // Ensure TabController length matches current tab count
    final expectedTabCount = _getTabCount();
    if (_tabController.length != expectedTabCount) {
      // Dispose old controller and create new one
      _tabController.dispose();
      _tabController = TabController(
        length: expectedTabCount,
        vsync: this,
      );
    }
    
    return Container(
      width: double.infinity,
      constraints: isLargeScreen ? const BoxConstraints(maxWidth: 896) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Query header
          Container(
            padding: EdgeInsets.fromLTRB(
              20, 
              widget.isFirstMessage ? 60 : 20,
              20, 
              16
            ),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditingQuery) ...[
                  TextField(
                    controller: _queryEditController,
                    focusNode: _queryEditFocusNode,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: widget.isFirstMessage ? 32 : 24,
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _saveEditedQuery(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _saveEditedQuery,
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _cancelEditingQuery,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentMessage.query,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: widget.isFirstMessage ? 32 : 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_currentMessage.generationState == MessageGenerationState.completed) ...[
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: colorScheme.onSurfaceVariant),
                          onPressed: _startEditingQuery,
                          tooltip: 'Edit query',
                        ),
                      ],
                    ],
                  ),
                ],
                
                if (_currentMessage.hasAttachments) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentMessage.attachments.map((attachment) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              attachment.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // TabBar
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              labelColor: colorScheme.onSurface,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tabs: _getTabs(),
            ),
          ),
          
          // Tab content - each tab sizes itself
          _buildTabContent(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTabContent(ColorScheme colorScheme) {
    final tabViews = _getTabViews(colorScheme);
    
    // Return the current tab's content directly (no TabBarView wrapper)
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final currentIndex = _tabController.index;
        if (currentIndex >= 0 && currentIndex < tabViews.length) {
          return tabViews[currentIndex];
        }
        return tabViews[0];
      },
    );
  }

  Widget _buildAnswerTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show fallback warning if applicable
          if (_currentMessage.isFallback) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Response generated without search context',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Show image and video previews at the top when available
          if ((_currentMessage.generationState == MessageGenerationState.generating ||
               _currentMessage.generationState == MessageGenerationState.streaming ||
               _currentMessage.generationState == MessageGenerationState.completed) &&
              (_currentMessage.images.isNotEmpty || _currentMessage.videos.isNotEmpty)) ...[
            _buildMediaPreviews(colorScheme),
            const SizedBox(height: 24),
          ],
          
          // Show the answer content
          StreamingTextWidget(
            textStream: _currentMessage.generationState == MessageGenerationState.streaming
                ? _currentMessage.answerStream
                : null,
            staticText: _currentMessage.generationState != MessageGenerationState.streaming
                ? _currentMessage.answer
                : null,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              height: 1.6,
            ),
            onComplete: () {},
            onCitationTap: _handleCitationTap,
            sources: _currentMessage.sources,
          ),
          
          const SizedBox(height: 24),
          
          // Show source profiles only when completed and sources available
          if (_currentMessage.generationState == MessageGenerationState.completed &&
              _currentMessage.sources.isNotEmpty) ...[
            Row(
              children: _currentMessage.sources.take(3).map((profile) {
                final index = _currentMessage.sources.indexOf(profile);
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                    child: _buildSourceProfile(
                      colorScheme,
                      profile.thumbnail,
                      profile.domain,
                      profile.title,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          // Show action buttons only when completed
          if (_currentMessage.generationState == MessageGenerationState.completed) ...[
            Row(
              children: [
                // Branch navigation on the left
                if (widget.branchManager.totalBranches > 1) ...[
                  _buildBranchNavigator(colorScheme),
                  const SizedBox(width: 16),
                ],
                
                // Action buttons
                _buildActionButton(
                  colorScheme,
                  Icons.ios_share,
                  'Share',
                  _shareContent,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  colorScheme,
                  Icons.file_download_outlined,
                  'Export',
                  _showExportMenuDialog,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  colorScheme,
                  Icons.edit_outlined,
                  'Rewrite',
                  widget.onRewrite,
                ),
                
                const Spacer(),
                
                // action buttons on the right
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _voiceService,
                      builder: (context, child) {
                        return _buildIconButton(
                          colorScheme,
                          _voiceService.isSpeaking ? Icons.volume_off : Icons.volume_up,
                          _toggleTextToSpeech,
                          isActive: _voiceService.isSpeaking,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(colorScheme, Icons.content_copy_outlined, _copyToClipboard),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
          
          // Show related questions only when completed and available
          if (_currentMessage.generationState == MessageGenerationState.completed &&
              _currentMessage.relatedQuestions.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Related',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Column(
              children: _currentMessage.relatedQuestions
                  .asMap()
                  .entries
                  .expand((entry) {
                final index = entry.key;
                final question = entry.value;
                final widgets = <Widget>[
                  _buildRelatedQuestion(colorScheme, question),
                ];
                
                if (index < _currentMessage.relatedQuestions.length - 1) {
                  widgets.add(
                    Divider(
                      color: colorScheme.outline,
                      thickness: 1,
                      height: 1,
                    ),
                  );
                }
                
                return widgets;
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBranchNavigator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.branchManager.hasPreviousBranch ? _goToPreviousBranch : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left,
                size: 18,
                color: widget.branchManager.hasPreviousBranch 
                    ? colorScheme.onSurface 
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.branchManager.currentBranchNumber}/${widget.branchManager.totalBranches}',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: widget.branchManager.hasNextBranch ? _goToNextBranch : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: widget.branchManager.hasNextBranch 
                    ? colorScheme.onSurface 
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(ColorScheme colorScheme, IconData icon, VoidCallback? onTap, {bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive 
                ? colorScheme.primary.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.3),
          ),
          color: isActive 
              ? colorScheme.primary.withOpacity(0.1)
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildRelatedQuestion(ColorScheme colorScheme, String question) {
    return _RelatedQuestionItem(
      question: question,
      colorScheme: colorScheme,
      onTap: widget.onRelatedQuestionTap,
    );
  }

  Widget _buildImagesTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentMessage.images.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No images available',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine number of columns based on screen width
                final screenWidth = constraints.maxWidth;
                final crossAxisCount = screenWidth > 800 ? 4 : (screenWidth > 500 ? 3 : 2);
                final spacing = 12.0;
                
                // Create columns for masonry layout
                final columns = List.generate(crossAxisCount, (_) => <Widget>[]);
                
                // Distribute images across columns (simulated masonry)
                for (var i = 0; i < _currentMessage.images.length; i++) {
                  final columnIndex = i % crossAxisCount;
                  columns[columnIndex].add(
                    _buildMasonryImageItem(
                      colorScheme,
                      _currentMessage.images[i],
                      i,
                      crossAxisCount,
                    ),
                  );
                }
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns.asMap().entries.map((entry) {
                    final index = entry.key;
                    final columnWidgets = entry.value;
                    
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : spacing / 2,
                          right: index == crossAxisCount - 1 ? 0 : spacing / 2,
                        ),
                        child: Column(
                          children: columnWidgets,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildMasonryImageItem(
    ColorScheme colorScheme,
    String imageUrl,
    int index,
    int totalColumns,
  ) {
    // Create varied heights for masonry effect
    final heights = [180.0, 220.0, 200.0, 240.0, 190.0, 210.0];
    final height = heights[index % heights.length];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          // Open image in browser on tap
          try {
            final uri = Uri.parse(imageUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            print('Failed to launch image URL: $e');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              httpHeaders: const {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
              placeholder: (context, url) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Failed to load',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildVideosTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentMessage.videos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No videos available',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...(_currentMessage.videos.map((video) => _buildVideoItem(colorScheme, video))),
          ],
        ),
      );
  }

  Widget _buildSourcesTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _currentMessage.sources.asMap().entries.map((entry) {
          final index = entry.key;
          final source = entry.value;
          return _buildSourceItem(colorScheme, source, index + 1);
        }).toList(),
      ),
    );
  }

  Widget _buildVideoItem(ColorScheme colorScheme, VideoItem video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: InkWell(
        onTap: () async {
          try {
            final uri = Uri.parse(video.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            print('Failed to launch video URL: $e');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 120,
                    height: 90,
                    color: colorScheme.surface,
                    child: video.thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: video.thumbnail,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surface,
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.play_circle_outline,
                                color: colorScheme.primary,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.play_circle_outline,
                              color: colorScheme.primary,
                              size: 40,
                            ),
                          ),
                  ),
                ),
                // Duration badge if available
                if (video.duration != null && video.duration!.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.duration!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // Play icon overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Video info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.domain,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (video.views != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.formattedViews,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem(ColorScheme colorScheme, SourceItem source, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 40,
                  height: 40,
                  color: colorScheme.surface,
                  child: CachedNetworkImage(
                    imageUrl: source.thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surface,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          source.domain.isNotEmpty 
                              ? source.domain.substring(0, 1).toUpperCase() 
                              : '?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  source.domain,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  try {
                    final uri = Uri.parse(source.url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    print('Failed to launch URL: $e');
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.open_in_new,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            source.title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            source.description,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceProfile(
    ColorScheme colorScheme,
    String imageUrl,
    String domain,
    String title,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 32,
              height: 32,
              color: colorScheme.surface,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colorScheme.surface,
                  child: const Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      domain.isNotEmpty ? domain.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domain,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ColorScheme colorScheme,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 16),
      label: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildMediaPreviews(ColorScheme colorScheme) {
    final allMediaItems = <Widget>[];

    // Create separate lists for images and videos
    final imageWidgets = _currentMessage.images.map((imageUrl) =>
      _buildImagePreview(colorScheme, imageUrl)
    ).toList();

    final videoWidgets = _currentMessage.videos.map((video) =>
      _buildVideoPreview(colorScheme, video)
    ).toList();

    // Combine and shuffle for random mixing
    allMediaItems.addAll(imageWidgets);
    allMediaItems.addAll(videoWidgets);

    // Shuffle the combined list for random order
    allMediaItems.shuffle();

    if (allMediaItems.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive configuration based on available width
        final availableWidth = constraints.maxWidth;
        
        // Determine layout based on screen size
        late final double itemWidth;
        late final double itemHeight;
        late final double spacing;
        
        if (availableWidth >= 800) {
          // Large screens: larger items
          itemWidth = 120;
          itemHeight = 90;
          spacing = 20;
        } else if (availableWidth >= 600) {
          // Medium screens: moderate size
          itemWidth = 110;
          itemHeight = 83;
          spacing = 18;
        } else {
          // Small screens: compact size
          itemWidth = 80;
          itemHeight = 60;
          spacing = 12;
        }

        return _MediaPreviewWithArrows(
          colorScheme: colorScheme,
          mediaItems: allMediaItems,
          itemWidth: itemWidth,
          itemHeight: itemHeight,
          spacing: spacing,
        );
      },
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme, String imageUrl) {
    return InkWell(
      onTap: () async {
        try {
          final uri = Uri.parse(imageUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('Failed to launch image URL: $e');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_not_supported,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ColorScheme colorScheme, VideoItem video) {
    return InkWell(
      onTap: () async {
        try {
          final uri = Uri.parse(video.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('Failed to launch video URL: $e');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: video.thumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: video.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.video_file,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.video_file,
                        color: colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
            ),
            // Play icon overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPreviewWithArrows extends StatefulWidget {
  const _MediaPreviewWithArrows({
    required this.colorScheme,
    required this.mediaItems,
    required this.itemWidth,
    required this.itemHeight,
    required this.spacing,
  });

  final ColorScheme colorScheme;
  final List<Widget> mediaItems;
  final double itemWidth;
  final double itemHeight;
  final double spacing;

  @override
  State<_MediaPreviewWithArrows> createState() => _MediaPreviewWithArrowsState();
}

class _MediaPreviewWithArrowsState extends State<_MediaPreviewWithArrows> {
  late final ScrollController _scrollController;
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateArrowVisibility);
    
    // Check initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrowVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrowVisibility() {
    if (!mounted) return;
    
    final position = _scrollController.position;
    final showLeft = position.pixels > 0;
    final showRight = position.pixels < position.maxScrollExtent;
    
    if (showLeft != _showLeftArrow || showRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = showLeft;
        _showRightArrow = showRight;
      });
    }
  }

  void _scrollLeft() {
    final currentPosition = _scrollController.position.pixels;
    final scrollAmount = widget.itemWidth + widget.spacing;
    final newPosition = (currentPosition - scrollAmount).clamp(0.0, _scrollController.position.maxScrollExtent);
    
    _scrollController.animateTo(
      newPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    final currentPosition = _scrollController.position.pixels;
    final scrollAmount = widget.itemWidth + widget.spacing;
    final newPosition = (currentPosition + scrollAmount).clamp(0.0, _scrollController.position.maxScrollExtent);
    
    _scrollController.animateTo(
      newPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemHeight + 8,
      child: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: widget.mediaItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < widget.mediaItems.length - 1 ? widget.spacing : 0,
                    ),
                    child: SizedBox(
                      width: widget.itemWidth,
                      height: widget.itemHeight,
                      child: item,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Left arrow - only show when can scroll left
          if (_showLeftArrow)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.colorScheme.surface.withOpacity(0.9),
                      widget.colorScheme.surface.withOpacity(0.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: IconButton(
                  onPressed: _scrollLeft,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: widget.colorScheme.onSurface,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          
          // Right arrow - only show when can scroll right
          if (_showRightArrow)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.colorScheme.surface.withOpacity(0.0),
                      widget.colorScheme.surface.withOpacity(0.9),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: IconButton(
                  onPressed: _scrollRight,
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: widget.colorScheme.onSurface,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelatedQuestionItem extends StatefulWidget {
  final String question;
  final ColorScheme colorScheme;
  final Function(String)? onTap;

  const _RelatedQuestionItem({
    required this.question,
    required this.colorScheme,
    this.onTap,
  });

  @override
  State<_RelatedQuestionItem> createState() => _RelatedQuestionItemState();
}

class _RelatedQuestionItemState extends State<_RelatedQuestionItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: InkWell(
        onTap: () => widget.onTap?.call(widget.question),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    color: isHovered ? AppThemeConfig.primaryColor : widget.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.add,
                color: isHovered ? AppThemeConfig.primaryColor : widget.colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}