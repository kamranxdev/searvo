import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/search/domain/entities/message_branch_manager.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';

import 'package:searvo/features/voice/services/voice_service.dart';
import 'package:searvo/common/widgets/streaming_text_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:searvo/common/widgets/link_preview.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import 'package:searvo/features/search/presentation/widgets/reasoning_widget.dart';
import 'package:searvo/features/search/presentation/widgets/tools/weather_widget.dart';
import 'package:searvo/features/search/presentation/widgets/tools/stock_widget.dart';
import 'package:searvo/features/search/presentation/widgets/tools/map_widget.dart';
import 'package:searvo/features/search/presentation/widgets/tools/crypto_widget.dart';
import 'package:searvo/features/search/presentation/widgets/tools/dictionary_widget.dart';
import 'package:searvo/features/search/domain/entities/tool_widget_data.dart';

class MessageBox extends StatefulWidget {
  final MessageBranchManager branchManager;
  final Function(String)? onRelatedQuestionTap;
  final bool isFirstMessage;
  final VoidCallback? onRewrite;
  final Function(String)? onEditQuery;
  final VoidCallback? onBranchChanged;
  final String? externalUrl;

  const MessageBox({
    super.key,
    required this.branchManager,
    this.onRelatedQuestionTap,
    this.isFirstMessage = true,
    this.onRewrite,
    this.onEditQuery,
    this.onBranchChanged,
    this.externalUrl,
  });

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox> with TickerProviderStateMixin {
  bool _isEditingQuery = false;
  final TextEditingController _queryEditController = TextEditingController();
  final FocusNode _queryEditFocusNode = FocusNode();
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _queryEditController.text = widget.branchManager.currentMessage.query;
    _voiceService.addListener(_onVoiceStateChanged);
    _voiceService.initializeTts();
  }

  MessageData get _currentMessage => widget.branchManager.currentMessage;

  @override
  void didUpdateWidget(MessageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchManager.currentMessage != _currentMessage) {}
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceStateChanged);
    _voiceService.stop();
    _queryEditController.dispose();
    _queryEditFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI BUILDERS
  // ---------------------------------------------------------------------------

  int _selectedTabIndex = 0; // 0: All, 1: Sources, 2: Images, 3: Videos

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // 1. User Query Header
        _buildUserQueryHeader(searchColors),

        const SizedBox(height: 16),

        // 2. Main Assistant Response Area with Tabs
        _buildAssistantResponse(searchColors),
      ],
    );
  }

  Widget _buildUserQueryHeader(SearchColors colors) {
    // If editing, show text field
    if (_isEditingQuery) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryEditController,
              focusNode: _queryEditFocusNode,
              style: TextStyle(
                color: colors.text,
                fontSize: widget.isFirstMessage ? 24 : 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Edit your question...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: colors.caption),
              ),
              onSubmitted: (_) => _saveEditedQuery(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppThemeConfig.primaryColor),
            onPressed: _saveEditedQuery,
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.caption),
            onPressed: _cancelEditingQuery,
          ),
        ],
      );
    }

    // Normal Display
    Widget header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: RichText(text: _buildClickableTextSpan(colors))),
        const SizedBox(width: 16),
        // Fallback for Website Mappings (Open in [Domain])
        if (widget.externalUrl != null) ...[
          StreamBuilder<bool>(
            stream: Stream.periodic(const Duration(milliseconds: 500))
                .map((_) => widget.branchManager.currentMessage.isGenerating)
                .distinct(),
            builder: (context, snapshot) {
              // Only show if NOT generating (or show always, depends on preference)
              // For now, allow user to leave anytime
              return ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(widget.externalUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  'Open on ${Uri.parse(widget.externalUrl!).host.replaceFirst('www.', '')}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.surface,
                  foregroundColor: colors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: BorderSide(color: colors.primary.withOpacity(0.3)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        // Edit Button (Icon)
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 20, color: colors.caption),
          onPressed: _startEditingQuery,
          tooltip: 'Edit Query',
        ),
      ],
    );

    // Apply Hero animation only for the first message
    if (widget.isFirstMessage) {
      return Hero(
        tag: 'search_box_input',
        child: Material(type: MaterialType.transparency, child: header),
      );
    }

    return header;
  }

  Widget _buildAssistantResponse(SearchColors colors) {
    return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Branch/Header Controls (Optional: Branch switcher)
              if (widget.branchManager.branches.length > 1)
                _buildBranchSwitcher(colors),

              // B. Reasoning Widget (Above Tabs)
              if (_currentMessage.isGenerating ||
                  _currentMessage.steps.isNotEmpty ||
                  _currentMessage.sources.isNotEmpty)
                ReasoningWidget(
                  state: _currentMessage.generationState,
                  sources: _currentMessage.sources,
                  steps: _currentMessage.steps,
                  activeDetail: _currentMessage.steps
                      .where((s) => s.isInProgress)
                      .lastOrNull
                      ?.title,
                  isGenerating: _currentMessage.isGenerating,
                ),

              // Tabs
              _buildTabs(colors),
              Divider(height: 1, color: colors.divider),

              // Content based on selected tab
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_selectedTabIndex),
                  child: _buildTabContent(colors),
                ),
              ),

              // H. Action Footer (Copy, Share, TTS) - Always visible
              _buildActionFooter(colors),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildTabs(SearchColors colors) {
    // Only show tabs that have content
    final hasImages = _currentMessage.images.isNotEmpty;
    final hasVideos = _currentMessage.videos.isNotEmpty;
    final hasSources = _currentMessage.sources.isNotEmpty;

    // Define all possible tabs
    final allTabs = [
      {'id': 0, 'label': 'All', 'icon': Icons.auto_awesome_mosaic_rounded},
      if (hasSources)
        {'id': 1, 'label': 'Sources', 'icon': Icons.source_rounded},
      if (hasImages) {'id': 2, 'label': 'Images', 'icon': Icons.image_rounded},
      if (hasVideos)
        {'id': 3, 'label': 'Videos', 'icon': Icons.smart_display_rounded},
    ];

    // If only "All" tab is available, hide the tab bar
    if (allTabs.length <= 1) {
      return const SizedBox.shrink();
    }

    // Reset selection if current tab disappears
    // Logic: If selected index is not in the new list of tabs, fallback to 0 (All)
    // Note: We used fixed IDs (0-3) which correspond to the original logic
    final availableIds = allTabs.map((t) => t['id'] as int).toSet();
    if (!availableIds.contains(_selectedTabIndex)) {
      // Schedule a microtask to update state safely during build if needed,
      // but since this is rebuild, we should just correct it for rendering
      // and maybe update state for next frame?
      // Ideally, we just render the content for 'All' if selected tab is gone
      // but keeping state synced is better.
      // For now, let's just assume user clicks.
      // A better approach is to check this before build, but here we'll just handle display.
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: allTabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final tab = allTabs[index];
            final tabId = tab['id'] as int;
            final isSelected = _selectedTabIndex == tabId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = tabId;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.text.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20), // Capsule shape
                  border: Border.all(
                    color: isSelected
                        ? colors.primary.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                          tab['icon'] as IconData,
                          size: 16,
                          color: isSelected ? colors.text : colors.caption,
                        )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                        ),
                    const SizedBox(width: 8),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected ? colors.text : colors.caption,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent(SearchColors colors) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAllContent(colors);
      case 1:
        return _buildSourcesTab(colors);
      case 2:
        return _buildImagesTab(colors);
      case 3:
        return _buildVideosTab(colors);
      default:
        return _buildAllContent(colors);
    }
  }

  Widget _buildAllContent(SearchColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // C. Tools & Widgets (e.g. Weather, Stock)
        if (_currentMessage.toolWidgets.isNotEmpty) _buildToolWidgets(colors),

        // D. Main Answer Content
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentMessage.answer.isNotEmpty)
                StreamBuilder<String>(
                  stream: _currentMessage.answerStream,
                  builder: (context, snapshot) {
                    // We use the accumulated answer from _currentMessage usually
                    return MarkdownResponse(
                      text: _currentMessage.answer,
                      isStreaming: _currentMessage.isGenerating,
                      onCitationTap: _handleCitationTap,
                      sources: _currentMessage.sources,
                    );
                  },
                ),
            ],
          ),
        ),

        // E. Visuals (Images/Videos) Grid/Carousel
        if (_currentMessage.images.isNotEmpty ||
            _currentMessage.videos.isNotEmpty)
          _buildMediaSection(colors),

        // F. Sources Section
        if (_currentMessage.sources.isNotEmpty) _buildSourcesSection(colors),

        // G. Related Questions
        if (_currentMessage.relatedQuestions.isNotEmpty)
          _buildRelatedQuestions(colors),
      ],
    );
  }

  Widget _buildSourcesTab(SearchColors colors) {
    if (_currentMessage.sources.isEmpty) {
      if (_currentMessage.isGenerating) {
        return _buildSourcesShimmer(colors, isVertical: true);
      }
      return _buildEmptyState(
        colors,
        icon: Icons.search_off_rounded,
        message: 'No sources found for this query',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _currentMessage.sources.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final source = _currentMessage.sources[index];
        return _buildSourceCard(colors, source, index);
      },
    );
  }

  Widget _buildSourceCard(SearchColors colors, SourceItem source, int index) {
    return LinkPreview(
      url: source.url,
      onTap: () => _handleUrlTap(source.url),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Screenshot Thumbnail
            SizedBox(
              width: 110,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _getScreenshotUrl(source.url),
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: colors.inputBackground),
                    errorWidget: (_, __, ___) => Container(
                      color: colors.inputBackground,
                      child: Icon(Icons.public, color: colors.caption),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colors.border.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      source.title,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildFavicon(colors, source),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            source.domain,
                            style: TextStyle(
                              color: colors.caption,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Action Icon
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: colors.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildFavicon(SearchColors colors, SourceItem source) {
    if (source.favicon != null && source.favicon!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: source.favicon!,
        width: 14,
        height: 14,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) =>
            _buildGoogleFavicon(colors, source.domain),
      );
    }
    return _buildGoogleFavicon(colors, source.domain);
  }

  Widget _buildGoogleFavicon(SearchColors colors, String domain) {
    return CachedNetworkImage(
      imageUrl: 'https://www.google.com/s2/favicons?domain=$domain&sz=64',
      width: 14,
      height: 14,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) =>
          Icon(Icons.public, size: 14, color: colors.caption),
    );
  }

  String _getScreenshotUrl(String url) {
    final encodedUrl = Uri.encodeComponent(url);
    return 'https://api.microlink.io/?url=$encodedUrl&screenshot=true&meta=false&embed=screenshot.url';
  }

  Widget _buildImagesTab(SearchColors colors) {
    if (_currentMessage.images.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.image_not_supported_rounded,
        message: 'No images available',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _currentMessage.images.length,
      itemBuilder: (context, index) {
        final imgUrl = _currentMessage.images[index];
        return GestureDetector(
          onTap: () => _showImageModal(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: colors.inputBackground),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosTab(SearchColors colors) {
    if (_currentMessage.videos.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.ondemand_video_rounded,
        message: 'No videos available',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _currentMessage.videos.length,
      itemBuilder: (context, index) {
        final video = _currentMessage.videos[index];
        return GestureDetector(
          onTap: () => _handleUrlTap(video.url),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (video.thumbnail.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: video.thumbnail,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: Colors.black),
                  )
                else
                  Container(color: Colors.black),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    SearchColors colors, {
    required IconData icon,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.background.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: colors.caption),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: colors.caption,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSwitcher(SearchColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
        color: colors.background.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: widget.branchManager.hasPreviousBranch
                ? _goToPreviousBranch
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.branchManager.currentBranchIndex + 1} / ${widget.branchManager.branches.length}',
            style: TextStyle(color: colors.caption, fontSize: 12),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: widget.branchManager.hasNextBranch
                ? _goToNextBranch
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildToolWidgets(SearchColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Column(
        children: _currentMessage.toolWidgets.map((toolData) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildToolWidget(toolData),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolWidget(ToolWidgetData toolData) {
    switch (toolData.toolId) {
      case 'weather':
        return WeatherWidget(data: toolData.data);
      case 'stock_price':
        return StockWidget(data: toolData.data);
      case 'map':
        return MapWidget(data: toolData.data);
      case 'crypto_price':
        return CryptoWidget(data: toolData.data);
      case 'dictionary':
        return DictionaryWidget(data: toolData.data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMediaSection(SearchColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Visuals',
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount:
                _currentMessage.images.length + _currentMessage.videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < _currentMessage.images.length) {
                final imgUrl = _currentMessage.images[index];
                return GestureDetector(
                  onTap: () => _showImageModal(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      height: 160,
                      width: 240,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: colors.inputBackground),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                );
              } else {
                // Videos
                return Container(
                  width: 240,
                  color: Colors.black, // Placeholder for video thumb
                  child: const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSourcesSection(SearchColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.3),
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        0,
        24,
      ), // Right padding handled by list
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              'Sources',
              style: TextStyle(
                color: colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180, // Increased height for screenshot
            child:
                _currentMessage.sources.isEmpty && _currentMessage.isGenerating
                ? _buildSourcesShimmer(colors, isVertical: false)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 24),
                    itemCount: _currentMessage.sources.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final source = _currentMessage.sources[index];
                      return LinkPreview(
                        url: source.url,
                        width: 240, // Increased width
                        onTap: () => _handleUrlTap(source.url),
                        child: Container(
                          width: 240,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.border.withOpacity(0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Screenshot
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: _getScreenshotUrl(source.url),
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: colors.inputBackground,
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: colors.inputBackground,
                                        child: Icon(
                                          Icons.public,
                                          color: colors.caption,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: colors.border.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Content
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        source.title,
                                        style: TextStyle(
                                          color: colors.text,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          _buildFavicon(colors, source),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              source.domain,
                                              style: TextStyle(
                                                color: colors.caption,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: (index * 50).ms).fadeIn().slideX();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesShimmer(SearchColors colors, {required bool isVertical}) {
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHighest,
      highlightColor: colors.surface,
      child: isVertical
          ? ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => Container(
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 24),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  Widget _buildRelatedQuestions(SearchColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related',
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._currentMessage.relatedQuestions.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => widget.onRelatedQuestionTap?.call(q),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: colors.caption),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(q, style: TextStyle(color: colors.text)),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: colors.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(SearchColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Rewrite',
            onTap: widget.onRewrite,
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: _copyToClipboard,
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: _shareContent,
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _voiceService.isSpeaking
                ? Icons.stop_rounded
                : Icons.volume_up_rounded,
            label: _voiceService.isSpeaking ? 'Stop' : 'Listen',
            onTap: _toggleTextToSpeech,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required SearchColors colors,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: colors.caption),
      label: Text(label, style: TextStyle(color: colors.caption, fontSize: 13)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UTILS & ACTIONS
  // ---------------------------------------------------------------------------

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
      widget.branchManager.goToPreviousBranch();
      _queryEditController.text = widget.branchManager.currentMessage.query;
      widget.onBranchChanged?.call();
      setState(() {});
    }
  }

  void _goToNextBranch() {
    if (widget.branchManager.hasNextBranch) {
      widget.branchManager.goToNextBranch();
      _queryEditController.text = widget.branchManager.currentMessage.query;
      widget.onBranchChanged?.call();
      setState(() {});
    }
  }

  Future<void> _toggleTextToSpeech() async {
    if (_voiceService.isSpeaking) {
      await _voiceService.stop();
    } else {
      final textToSpeak = _currentMessage.answer;
      if (textToSpeak.isNotEmpty) {
        await _voiceService.speak(textToSpeak);
      }
    }
    setState(() {}); // Update icon state
  }

  Future<void> _handleUrlTap(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _handleCitationTap(int citationNumber) {
    // Get the source for this citation
    if (citationNumber > 0 &&
        citationNumber <= _currentMessage.sources.length) {
      final source = _currentMessage.sources[citationNumber - 1];

      // Show Perplexity-style citation popup
      final overlay = Overlay.of(context);
      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (context) => _CitationPopupOverlay(
          source: source,
          citationNumber: citationNumber,
          onDismiss: () => entry.remove(),
          onOpenSource: () {
            entry.remove();
            _handleUrlTap(source.url);
          },
        ),
      );

      overlay.insert(entry);
    } else {
      // Fallback for invalid citation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Citation #$citationNumber not found')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _currentMessage.answer));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _shareContent() async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${_currentMessage.query}\n\n${_currentMessage.answer}',
      ),
    );
  }

  TextSpan _buildClickableTextSpan(SearchColors searchColors) {
    final text = _currentMessage.query;
    final List<InlineSpan> spans = [];
    final pattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(
              color: searchColors.text,
              fontSize: widget.isFirstMessage ? 28 : 20,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        );
      }

      final matchedText = match.group(0)!;
      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(
            color: const Color(0xFF00B4A6),
            fontSize: widget.isFirstMessage ? 28 : 20,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            height: 1.2,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleUrlTap(matchedText),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(
            color: searchColors.text,
            fontSize: widget.isFirstMessage ? 28 : 20,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      );
    }

    return TextSpan(
      style: TextStyle(
        color: searchColors.text,
        fontSize: widget.isFirstMessage ? 28 : 20,
        fontWeight: FontWeight.w600,
      ),
      children: spans.isEmpty ? [TextSpan(text: text)] : spans,
    );
  }

  void _showImageModal(int initialIndex) {
    // TODO: Implement simple image viewer
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(
          imageUrl: _currentMessage.images[initialIndex],
        ),
      ),
    );
  }

  void _onVoiceStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}

// ---------------------------------------------------------------------------
// HELPER FOR MARKDOWN
// ---------------------------------------------------------------------------

class MarkdownResponse extends StatelessWidget {
  final String text;
  final bool isStreaming;
  final Function(int)? onCitationTap;
  final List<SourceItem> sources;

  const MarkdownResponse({
    super.key,
    required this.text,
    this.isStreaming = false,
    this.onCitationTap,
    this.sources = const [],
  });

  @override
  Widget build(BuildContext context) {
    return StreamingTextWidget(
      staticText: text,
      onCitationTap: onCitationTap,
      sources: sources,
      style: TextStyle(
        fontSize: 16,
        height: 1.6,
        color: SearchTheme.colors(context).text.withValues(alpha: 0.9),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CITATION POPUP OVERLAY
// ---------------------------------------------------------------------------

class _CitationPopupOverlay extends StatelessWidget {
  final SourceItem source;
  final int citationNumber;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenSource;

  const _CitationPopupOverlay({
    required this.source,
    required this.citationNumber,
    required this.onDismiss,
    this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SearchTheme.colors(context);

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss when tapping popup
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(colors),
                  // Source preview image
                  _buildPreview(colors),
                  // Source info
                  _buildInfo(colors),
                  // Actions
                  _buildActions(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SearchColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemeConfig.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '[$citationNumber]',
              style: TextStyle(
                color: AppThemeConfig.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Source',
              style: TextStyle(
                color: colors.caption,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, size: 20, color: colors.caption),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(SearchColors colors) {
    final screenshotUrl =
        'https://api.microlink.io/?url=${Uri.encodeComponent(source.url)}&screenshot=true&meta=false&embed=screenshot.url';

    return Container(
      height: 120,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: screenshotUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Container(
          color: colors.inputBackground,
          child: Center(
            child: Icon(Icons.public, color: colors.caption, size: 32),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: colors.inputBackground,
          child: Center(
            child: Icon(Icons.public, color: colors.caption, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(SearchColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            source.title,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Domain row
          Row(
            children: [
              CachedNetworkImage(
                imageUrl:
                    source.favicon ??
                    'https://www.google.com/s2/favicons?domain=${source.domain}&sz=32',
                width: 16,
                height: 16,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.public, size: 16, color: colors.caption),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  source.domain,
                  style: TextStyle(
                    color: colors.caption,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Snippet
          if (source.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border.withOpacity(0.3)),
              ),
              child: Text(
                source.description,
                style: TextStyle(
                  color: colors.text.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(SearchColors colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onOpenSource,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeConfig.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text(
            'Open Source',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
