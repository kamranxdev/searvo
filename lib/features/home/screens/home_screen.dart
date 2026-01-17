import 'package:flutter/material.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/search/presentation/widgets/search_box.dart'
    show SearchBox;
import 'package:searvo/features/search/domain/entities/search_mode.dart';
import 'package:searvo/features/search/data/datasources/intelligent_search_data_source.dart';
import 'package:searvo/features/settings/services/settings_service.dart';
import 'package:searvo/common/widgets/attachment_input_widget.dart';
import 'package:searvo/core/di/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

// Home screen content widget
class SearvoHomeContent extends StatefulWidget {
  const SearvoHomeContent({super.key});

  @override
  State<SearvoHomeContent> createState() => _SearvoHomeContentState();
}

class _SearvoHomeContentState extends State<SearvoHomeContent> {
  final TextEditingController _searchController = TextEditingController();
  final List<AttachmentData> _attachments = [];
  final SettingsService _settingsService = SettingsService();
  final IntelligentSearchDataSource _intelligentSearchDataSource =
      sl<IntelligentSearchDataSource>();

  bool _isLoading = false;
  SearchMode _currentSearchMode = SearchMode.search;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _intelligentSearchDataSource.initialize();
    } catch (e) {
      print('Failed to initialize search service: $e');
    }
  }

  void _onSearchSubmit() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Check for @mention syntax
    if (query.startsWith('@')) {
      await _handleWebsiteMention(query);
      return;
    }

    // Check if any provider is configured
    if (!_intelligentSearchDataSource.isConfigured) {
      _showConfigurationDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to search results using AppRouter to preserve sidebar
      if (mounted) {
        AppRouter.goToSearchResults(
          context,
          query,
          searchMode: _currentSearchMode,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppThemeConfig.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWebsiteMention(String query) async {
    // Parse @mention (e.g., "@youtube search term" -> key: "youtube", searchTerm: "search term")
    final parts = query.substring(1).split(' ');
    final key = parts[0].toLowerCase();
    final searchTerm = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final websiteMappings = _settingsService.getWebsiteMappings();
    final mapping = websiteMappings[key];

    if (mapping == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unknown website "@$key". Add it in Settings > Website Mappings.',
            ),
            backgroundColor: AppThemeConfig.errorColor,
          ),
        );
      }
      return;
    }

    final baseUrl = mapping['url'] ?? '';
    final searchUrlTemplate = mapping['searchUrl'];

    String urlToOpen;
    if (searchTerm.isNotEmpty &&
        searchUrlTemplate != null &&
        searchUrlTemplate.isNotEmpty) {
      // Use search URL with query
      urlToOpen = searchUrlTemplate.replaceAll(
        '{query}',
        Uri.encodeComponent(searchTerm),
      );
    } else {
      // Use base URL
      urlToOpen = baseUrl;
    }

    if (urlToOpen.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid website configuration.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(urlToOpen);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open website.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening website: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Required'),
        content: const Text(
          'Please configure at least one AI provider in the settings before performing a search.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to settings (you'll need to implement this navigation)
              _navigateToSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    // Navigate to settings screen
    Navigator.of(context).pushNamed('/settings');
  }

  void _onAttachmentsChanged(List<AttachmentData> attachments) {
    setState(() {
      _attachments.clear();
      _attachments.addAll(attachments);
    });
    print('Attachments changed: ${attachments.length} files');
  }

  void _onAttachmentAdded(AttachmentData attachment) {
    print('Attachment added: ${attachment.name} (${attachment.formattedSize})');
  }

  void _onAttachmentError(String error) {
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppThemeConfig.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Define breakpoint for mobile devices
        const double mobileBreakpoint = 768;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;

        if (isMobile) {
          // Mobile Layout: Title centered, Search box at bottom
          return Stack(
            children: [
              // Title centered vertically and horizontally
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Searvo A!',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontFamily: 'Goldman',
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // Search Box at bottom
              Positioned(
                bottom: 75,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 16,
                  ),
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppThemeConfig.primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Searching...',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SearchBox(
                          controller: _searchController,
                          onSend: _onSearchSubmit,
                          onAttachmentsChanged: _onAttachmentsChanged,
                          onAttachmentAdded: _onAttachmentAdded,
                          onAttachmentError: _onAttachmentError,
                          onSearchModeChanged: (mode) {
                            setState(() {
                              _currentSearchMode = mode;
                            });
                          },
                        ),
                ),
              ),
            ],
          );
        } else {
          // Desktop/Web Layout: Original positioning
          return Stack(
            children: [
              // Title positioned at specific location
              Positioned(
                top: screenSize.height * 0.35, // 35% from top
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Searvo A!',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontFamily: 'Goldman',
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // Search Box positioned below title
              Positioned(
                top: screenSize.height * 0.5, // 50% from top
                left: 32,
                right: 32,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: _isLoading
                        ? Column(
                            children: [
                              const CircularProgressIndicator(
                                color: AppThemeConfig.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Searching...',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : SearchBox(
                            controller: _searchController,
                            onSend: _onSearchSubmit,
                            onAttachmentsChanged: _onAttachmentsChanged,
                            onAttachmentAdded: _onAttachmentAdded,
                            onAttachmentError: _onAttachmentError,
                            onSearchModeChanged: (mode) {
                              setState(() {
                                _currentSearchMode = mode;
                              });
                            },
                          ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
