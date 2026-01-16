import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/settings/services/settings_service.dart';
import 'package:searvo/features/voice/widgets/voice_input_widget.dart';
import 'package:searvo/common/widgets/rich_text_editing_controller.dart';
import 'package:searvo/common/widgets/attachment_input_widget.dart';
import 'package:searvo/core/di/injection_container.dart';
import 'package:searvo/features/search/domain/usecases/get_autocomplete_suggestions_usecase.dart';
import 'package:searvo/features/search/domain/entities/autocomplete_entities.dart';
import 'package:searvo/features/search/domain/entities/search_mode.dart';
import 'dart:ui';
import 'search_box_mode_tooltip.dart';

class SearchBox extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final Function(String)? onVoiceTextReceived;
  final Function(String)? onVoiceError;
  final Function(String)? onSuggestionTap;
  final Function(List<AttachmentData>)? onAttachmentsChanged;
  final Function(AttachmentData)? onAttachmentAdded;
  final Function(String)? onAttachmentError;
  final Function(SearchMode)? onSearchModeChanged;

  const SearchBox({
    super.key,
    required this.controller,
    this.onSend,
    this.onVoiceTextReceived,
    this.onVoiceError,
    this.onSuggestionTap,
    this.onAttachmentsChanged,
    this.onAttachmentAdded,
    this.onAttachmentError,
    this.onSearchModeChanged,
  });

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> with TickerProviderStateMixin {
  SearchMode _selectedMode = SearchMode.search;
  TooltipData? _currentTooltip;
  bool _tooltipVisible = false;
  bool _isTextFieldFocused = false;
  int _selectedSuggestionIndex = -1;
  FocusNode _textFieldFocusNode = FocusNode();
  List<AttachmentData> _attachments = [];
  bool _isSettingTextProgrammatically = false;
  // Stores the original text typed by the user while navigating suggestions
  String? _navigatingOriginalText;

  final SettingsService _settingsService = SettingsService();
  Map<String, Map<String, String>> _websiteMappings = {};
  late RichTextEditingController _mentionController;

  // Autocomplete use case
  late GetAutocompleteSuggestionsUseCase _autocompleteUseCase;
  List<AutocompleteSuggestion> _dynamicSuggestions = [];
  bool _isLoadingSuggestions = false;

  String get _effectiveQuery =>
      _navigatingOriginalText ?? widget.controller.text;

  // Animation controllers
  late AnimationController _suggestionsAnimationController;
  late Animation<double> _suggestionsHeightAnimation;
  late Animation<double> _suggestionsOpacityAnimation;
  late Animation<double> _containerElevationAnimation;

  // Use GlobalKey to access AttachmentInputWidget
  final GlobalKey<AttachmentInputWidgetState> _attachmentWidgetKey =
      GlobalKey<AttachmentInputWidgetState>();

  SearchMode get selectedMode => _selectedMode;

  set selectedMode(SearchMode mode) {
    setState(() {
      _selectedMode = mode;
    });
    widget.onSearchModeChanged?.call(mode);
  }

  DetectedType _getCurrentInputType() {
    final text = _effectiveQuery;
    if (text.isEmpty) return DetectedType.plainText;

    if (text.startsWith('@')) {
      return DetectedType.mention;
    } else if (text.startsWith('http://') || text.startsWith('https://')) {
      return DetectedType.url;
    }
    return DetectedType.plainText;
  }

  List<String> get _filteredSuggestions {
    final text = _effectiveQuery;
    final inputType = _getCurrentInputType();

    switch (inputType) {
      case DetectedType.mention:
        final mentionQuery = text.substring(1).toLowerCase();

        if (mentionQuery.isEmpty) {
          // Show all available @mentions
          return _websiteMappings.keys.map((key) => '@$key').toList();
        } else {
          // Filter @mentions based on query
          return _websiteMappings.keys
              .where((key) => key.toLowerCase().contains(mentionQuery))
              .map((key) => '@$key')
              .toList();
        }

      case DetectedType.url:
        // Don't show suggestions for URLs
        return [];

      case DetectedType.plainText:
        // Return dynamic suggestions from autocomplete service
        return _dynamicSuggestions.map((s) => s.text).toList();
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize website mappings
    _websiteMappings = _settingsService.getWebsiteMappings();

    // Initialize autocomplete use case
    _autocompleteUseCase = sl<GetAutocompleteSuggestionsUseCase>();

    // Fetch trending suggestions for empty state
    _fetchTrendingSuggestions();

    // Initialize mention controller with valid mentions
    _mentionController = RichTextEditingController(
      validMentions: _websiteMappings.keys.toSet(),
    );

    // Sync with the provided controller
    _mentionController.text = widget.controller.text;
    _mentionController.addListener(() {
      if (_mentionController.text != widget.controller.text) {
        widget.controller.text = _mentionController.text;
        widget.controller.selection = _mentionController.selection;
      }
    });

    widget.controller.addListener(() {
      if (widget.controller.text != _mentionController.text) {
        _mentionController.text = widget.controller.text;
        _mentionController.selection = widget.controller.selection;
      }
    });

    // Initialize animation controller
    _suggestionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _suggestionsHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _suggestionsAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _suggestionsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _suggestionsAnimationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _containerElevationAnimation = Tween<double>(begin: 8.0, end: 16.0).animate(
      CurvedAnimation(
        parent: _suggestionsAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _textFieldFocusNode.addListener(() {
      final hasFocus = _textFieldFocusNode.hasFocus;
      final shouldShowSuggestions = hasFocus && _filteredSuggestions.isNotEmpty;

      setState(() {
        _isTextFieldFocused = hasFocus;
        if (!_isTextFieldFocused) {
          _selectedSuggestionIndex = -1;
        }
      });

      // Animate suggestions appearance/disappearance
      if (shouldShowSuggestions &&
          !_suggestionsAnimationController.isCompleted) {
        _suggestionsAnimationController.forward();
      } else if (!shouldShowSuggestions &&
          !_suggestionsAnimationController.isDismissed) {
        _suggestionsAnimationController.reverse();
      }
    });

    // Listen to text changes to update filtered suggestions
    _mentionController.addListener(() {
      if (_isTextFieldFocused && !_isSettingTextProgrammatically) {
        setState(() {
          _selectedSuggestionIndex = -1;
        });

        // Fetch autocomplete suggestions for plain text
        final inputType = _getCurrentInputType();
        if (inputType == DetectedType.plainText) {
          final query = widget.controller.text;
          if (query.isEmpty) {
            // Fetch trending suggestions when empty
            _fetchTrendingSuggestions();
          } else {
            // Fetch query-based suggestions
            _fetchAutocompleteSuggestions(query);
          }
        }

        // Update animation based on filtered suggestions
        final shouldShowSuggestions =
            _isTextFieldFocused && _filteredSuggestions.isNotEmpty;
        if (shouldShowSuggestions &&
            !_suggestionsAnimationController.isCompleted) {
          _suggestionsAnimationController.forward();
        } else if (!shouldShowSuggestions &&
            !_suggestionsAnimationController.isDismissed) {
          _suggestionsAnimationController.reverse();
        }
      }
    });
  }

  void _updateControllerText(String text) {
    _isSettingTextProgrammatically = true;
    widget.controller.text = text;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _isSettingTextProgrammatically = false;
  }

  /// Fetch trending suggestions from SearxNG
  void _fetchTrendingSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    // TODO: Implement trending suggestions in use case
    if (mounted) {
      setState(() {
        _dynamicSuggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  /// Fetch autocomplete suggestions with debouncing
  void _fetchAutocompleteSuggestions(String query) {
    if (query.trim().length < 2) {
      setState(() {
        _dynamicSuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    // Use debounced method to avoid excessive API calls
    _autocompleteUseCase.callDebounced(query, (suggestions) {
      if (mounted) {
        setState(() {
          _dynamicSuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _suggestionsAnimationController.dispose();
    _textFieldFocusNode.dispose();
    _mentionController.dispose();
    _autocompleteUseCase.cancelPendingRequests();
    super.dispose();
  }

  // Define tooltip data for left side search mode buttons only
  final Map<String, TooltipData> _tooltipData = {
    'search': const TooltipData(
      title: 'Search',
      subtitle: 'Fast answers to everyday questions',
      description:
          'Get quick, concise answers to your questions with our AI-powered search mode.',
    ),
    'research': const TooltipData(
      title: 'Research',
      subtitle: 'Deep research on any topic',
      description:
          'In-depth research capabilities to help you explore complex topics thoroughly.',
    ),
    'study': const TooltipData(
      title: 'Study',
      subtitle: 'Step-by-step explanations and learning',
      description:
          'Interactive learning and study tools that guide you toward deeper understanding beyond quick answers.',
      badge: 'New',
    ),
  };

  void _showTooltip(String key) {
    setState(() {
      _currentTooltip = _tooltipData[key];
      _tooltipVisible = true;
    });
  }

  void _hideTooltip() {
    setState(() {
      _tooltipVisible = false;
    });
  }

  void _handleAttachmentsChanged(List<AttachmentData> attachments) {
    setState(() {
      _attachments = attachments;
    });
    widget.onAttachmentsChanged?.call(attachments);
  }

  void _removeAttachment(AttachmentData attachment) {
    _attachmentWidgetKey.currentState?.removeAttachment(attachment);
  }

  void _handleAttachmentRemoved(AttachmentData attachment) {
    // This will be called when attachment is removed from AttachmentInputWidget
  }

  Widget _buildAttachmentPill(AttachmentData attachment) {
    final searchColors = SearchTheme.colors(context);

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: searchColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(attachment.icon, size: 14, color: searchColors.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              style: TextStyle(
                color: searchColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            attachment.formattedSize,
            style: TextStyle(color: searchColors.caption, fontSize: 10),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeAttachment(attachment),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: searchColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close, size: 10, color: searchColors.caption),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_isTextFieldFocused) return;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_selectedSuggestionIndex >= 0 &&
            _selectedSuggestionIndex < _filteredSuggestions.length) {
          final selectedSuggestion =
              _filteredSuggestions[_selectedSuggestionIndex];

          // Clear navigation state as we are making a selection
          _navigatingOriginalText = null;

          _updateControllerText(selectedSuggestion);
          widget.onSuggestionTap?.call(selectedSuggestion);
          _textFieldFocusNode.unfocus();
          setState(() {
            _selectedSuggestionIndex = -1;
          });
        } else {
          if (widget.controller.text.trim().isNotEmpty) {
            _textFieldFocusNode.unfocus();
            setState(() {
              _selectedSuggestionIndex = -1;
              _navigatingOriginalText = null;
            });
            widget.onSend?.call();
          }
        }
      } else if (_filteredSuggestions.isNotEmpty) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            // Start navigation if not already navigating
            if (_selectedSuggestionIndex == -1) {
              _navigatingOriginalText = widget.controller.text;
              _selectedSuggestionIndex = 0;
            } else {
              _selectedSuggestionIndex =
                  (_selectedSuggestionIndex + 1) % _filteredSuggestions.length;
            }

            // Update text box with selected suggestion
            final suggestion = _filteredSuggestions[_selectedSuggestionIndex];
            _updateControllerText(suggestion);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            // Start navigation if not already navigating
            if (_selectedSuggestionIndex == -1) {
              _navigatingOriginalText = widget.controller.text;
              _selectedSuggestionIndex = _filteredSuggestions.length - 1;
            } else {
              _selectedSuggestionIndex = _selectedSuggestionIndex <= 0
                  ? _filteredSuggestions.length - 1
                  : _selectedSuggestionIndex - 1;
            }

            // Update text box with selected suggestion
            final suggestion = _filteredSuggestions[_selectedSuggestionIndex];
            _updateControllerText(suggestion);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          // Restore original text if we were navigating
          if (_navigatingOriginalText != null) {
            _updateControllerText(_navigatingOriginalText!);
            _navigatingOriginalText = null;
          }

          _textFieldFocusNode.unfocus();
          setState(() {
            _selectedSuggestionIndex = -1;
          });
        }
      }
    }
  }

  Widget _buildSuggestionItem(String suggestion, int index) {
    final isSelected = index == _selectedSuggestionIndex;
    final searchColors = SearchTheme.colors(context);
    final isMention = suggestion.startsWith('@');

    String displayText = suggestion;
    String? subtitle;
    IconData icon = Icons.search;
    Color iconColor = searchColors.caption;

    if (isMention) {
      final key = suggestion.substring(1);
      final mapping = _websiteMappings[key];
      if (mapping != null) {
        displayText = '@$key';
        subtitle = mapping['name'] ?? key;
        icon = Icons.link;
        iconColor = isSelected
            ? searchColors.accent
            : searchColors.accent.withValues(alpha: 0.7);
      }
    } else {
      // For regular suggestions, use trending_up icon
      icon = Icons.trending_up;
      iconColor = isSelected
          ? searchColors.caption
          : searchColors.caption.withValues(alpha: 0.7);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _selectedSuggestionIndex = index;
          });
        },
        onExit: (_) {},
        child: GestureDetector(
          onTap: () {
            _isSettingTextProgrammatically = true;
            widget.controller.text = suggestion;
            _isSettingTextProgrammatically = false;

            widget.onSuggestionTap?.call(suggestion);
            setState(() {
              _selectedSuggestionIndex = -1;
            });
            _textFieldFocusNode.unfocus();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? searchColors.surface.withValues(alpha: 0.8)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(
                      color: isMention
                          ? searchColors.accent.withValues(alpha: 0.3)
                          : searchColors.border,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    color: isSelected ? iconColor : searchColors.caption,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: isSelected
                              ? searchColors.text
                              : searchColors.caption,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        child: Text(displayText),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: searchColors.caption.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    isMention ? Icons.open_in_new : Icons.trending_up,
                    color: isSelected
                        ? iconColor
                        : iconColor.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _suggestionsAnimationController,
          builder: (context, child) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: searchColors.inputBackground.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: searchColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: Offset(0, _containerElevationAnimation.value),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 40,
                      offset: Offset(
                        0,
                        _containerElevationAnimation.value + 12,
                      ),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_attachments.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              children: _attachments
                                  .map(
                                    (attachment) =>
                                        _buildAttachmentPill(attachment),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                    Focus(
                      onKeyEvent: (node, event) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                            event.logicalKey == LogicalKeyboardKey.arrowUp ||
                            event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.escape) {
                          _handleKeyEvent(event);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          _attachments.isNotEmpty ? 8 : 16,
                          16,
                          8,
                        ),
                        child: TextField(
                          controller: _mentionController,
                          focusNode: _textFieldFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Ask anything or @mention a website',
                            hintStyle: SearchTheme.searchPlaceholder(context),
                            filled: false,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: SearchTheme.searchInput(context),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              widget.onSend?.call();
                            }
                          },
                          maxLines: null,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Tooltip(
                            message: '',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MouseRegion(
                                  onEnter: (_) => _showTooltip('search'),
                                  onExit: (_) => _hideTooltip(),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedMode = SearchMode.search;
                                      });
                                    },
                                    child: Icon(
                                      Icons.search,
                                      color: selectedMode == SearchMode.search
                                          ? searchColors.accent
                                          : searchColors.caption.withOpacity(
                                              0.6,
                                            ),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                MouseRegion(
                                  onEnter: (_) => _showTooltip('research'),
                                  onExit: (_) => _hideTooltip(),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedMode = SearchMode.research;
                                      });
                                    },
                                    child: Icon(
                                      Icons.casino_outlined,
                                      color: selectedMode == SearchMode.research
                                          ? searchColors.accent
                                          : searchColors.caption.withOpacity(
                                              0.6,
                                            ),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                MouseRegion(
                                  onEnter: (_) => _showTooltip('study'),
                                  onExit: (_) => _hideTooltip(),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedMode = SearchMode.study;
                                      });
                                    },
                                    child: Icon(
                                      Icons.explore,
                                      color: selectedMode == SearchMode.study
                                          ? searchColors.accent
                                          : searchColors.caption.withOpacity(
                                              0.6,
                                            ),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AttachmentInputWidget(
                                key: _attachmentWidgetKey,
                                onAttachmentsChanged: _handleAttachmentsChanged,
                                onAttachmentAdded: widget.onAttachmentAdded,
                                onAttachmentRemoved: _handleAttachmentRemoved,
                                onError: widget.onAttachmentError,
                                activeColor: searchColors.accent,
                                inactiveColor: searchColors.caption.withOpacity(
                                  0.6,
                                ),
                                iconSize: 20,
                                maxFileSize: 50 * 1024 * 1024,
                                maxFiles: 5,
                                allowMultiple: true,
                              ),
                              const SizedBox(width: 16),

                              VoiceInputWidget(
                                onTextReceived: (text) {
                                  _isSettingTextProgrammatically = true;
                                  widget.controller.text = text;
                                  widget.controller.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(
                                          offset: widget.controller.text.length,
                                        ),
                                      );
                                  _isSettingTextProgrammatically = false;
                                  widget.onVoiceTextReceived?.call(text);
                                },
                                onError: widget.onVoiceError,
                                activeColor: searchColors.accent,
                                inactiveColor: searchColors.caption.withOpacity(
                                  0.6,
                                ),
                                iconSize: 20,
                              ),
                              const SizedBox(width: 16),

                              GestureDetector(
                                onTap: widget.onSend,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: searchColors.accent,
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

                    AnimatedBuilder(
                      animation: _suggestionsAnimationController,
                      builder: (context, child) {
                        final shouldShow =
                            _isTextFieldFocused &&
                            _filteredSuggestions.isNotEmpty;

                        return SizeTransition(
                          sizeFactor: _suggestionsHeightAnimation,
                          axisAlignment: -1.0,
                          child: FadeTransition(
                            opacity: _suggestionsOpacityAnimation,
                            child: shouldShow
                                ? Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Divider(
                                          color: searchColors.divider,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 16),
                                        if (_isLoadingSuggestions) ...[
                                          Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(searchColors.accent),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          ..._filteredSuggestions
                                              .asMap()
                                              .entries
                                              .map(
                                                (entry) => _buildSuggestionItem(
                                                  entry.value,
                                                  entry.key,
                                                ),
                                              ),
                                        ],
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_tooltipVisible)
          Positioned(
            left: 0,
            top: _attachments.isNotEmpty ? 140 : 115,
            child: SearchBoxModeTooltip(
              data: _currentTooltip,
              isVisible: _tooltipVisible,
            ),
          ),
      ],
    );
  }
}
