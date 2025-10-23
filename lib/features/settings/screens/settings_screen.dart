import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/auth/services/auth_service.dart';
import 'package:searvo/features/auth/widgets/user_profile_widget.dart';
import 'package:searvo/features/settings/providers/settings_provider.dart';
import 'package:searvo/features/settings/widgets/embedding_settings_panel.dart';
import 'package:searvo/features/settings/widgets/llm_provider_settings_panel.dart';
import 'package:searvo/features/settings/widgets/search_provider_settings_panel.dart';
import 'package:searvo/features/settings/widgets/website_mappings_panel.dart';
import 'package:searvo/features/settings/widgets/settings_card.dart';
import 'package:searvo/features/history/providers/conversation_history_provider.dart';
import 'package:searvo/features/history/services/conversation_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedTabIndex = 0;
  late final ThemeManager _themeController;
  final ScrollController _scrollController = ScrollController();

  // State variables for toggles
  bool microphoneEnabled = false;
  bool contactsEnabled = false;
  bool calendarEnabled = false;
  bool phoneEnabled = false;
  bool locationEnabled = false;
  String selectedLanguage = 'en';
  bool _isThemeChanging = false;

  final List<TabItem> tabs = [
    TabItem(id: 'account', label: 'Account', icon: Icons.person_outline),
    TabItem(id: 'appearance', label: 'Appearance', icon: Icons.palette_outlined),
    TabItem(id: 'aiProviders', label: 'AI Providers', icon: Icons.psychology_outlined),
    TabItem(id: 'embedding', label: 'Embedding', icon: Icons.memory_outlined),
    TabItem(id: 'searchProviders', label: 'Search', icon: Icons.search),
    TabItem(id: 'websiteMappings', label: 'Mappings', icon: Icons.link),
    TabItem(id: 'permissions', label: 'Permissions', icon: Icons.security_outlined),
    TabItem(id: 'helpCenter', label: 'Help', icon: Icons.help_outline),
    TabItem(id: 'more', label: 'More', icon: Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();
    _themeController = ThemeManager();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController!.index;
      });
    });
    
    // Listen to theme changes
    _themeController.addListener(_onThemeChanged);
  }
  
  /// Handle theme changes from the controller
  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with the new theme
      });
    }
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return ListenableBuilder(
          listenable: _themeController,
          builder: (context, child) {
            return _buildSettingsContent(context, settingsProvider);
          },
        );
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context, SettingsProvider settingsProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        
        if (isTablet) {
          return _buildTabletLayout(context);
        } else {
          return _buildMobileLayout(context.isDark);
        }
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final colorScheme = context.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 32.0 : 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar Navigation
            Container(
              width: isLargeScreen ? 280 : 260,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Divider(height: 1),
                  ),
                  
                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      children: tabs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tab = entry.value;
                        final isActive = _selectedTabIndex == index;
                        
                        return _buildSidebarNavItem(
                          context: context,
                          tab: tab,
                          index: index,
                          isActive: isActive,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: isLargeScreen ? 32 : 24),
            
            // Content Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Content Header
                    Container(
                      padding: EdgeInsets.all(isLargeScreen ? 32.0 : 24.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              tabs[_selectedTabIndex].icon,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tabs[_selectedTabIndex].label,
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 28 : 24,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getTabDescription(tabs[_selectedTabIndex].id),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content Body
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.02, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: SingleChildScrollView(
                            key: ValueKey<int>(_selectedTabIndex),
                            padding: EdgeInsets.all(isLargeScreen ? 32.0 : 24.0),
                            child: _buildTabContent(context.isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebarNavItem({
    required BuildContext context,
    required TabItem tab,
    required int index,
    required bool isActive,
  }) {
    final colorScheme = context.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _tabController!.animateTo(index);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.85),
                      ],
                    )
                  : null,
              color: isActive ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 22,
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getTabDescription(String tabId) {
    switch (tabId) {
      case 'account':
        return 'Manage your profile and account preferences';
      case 'appearance':
        return 'Customize theme and display settings';
      case 'aiProviders':
        return 'Configure AI models and providers';
      case 'embedding':
        return 'Set up embedding models and services';
      case 'searchProviders':
        return 'Configure search engines and sources';
      case 'websiteMappings':
        return 'Manage website and URL mappings';
      case 'permissions':
        return 'Control app permissions and access';
      case 'helpCenter':
        return 'Get help and support resources';
      case 'more':
        return 'Additional settings and information';
      default:
        return '';
    }
  }

  Widget _buildMobileLayout(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern collapsible app bar
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: colorScheme.surface.withOpacity(0.95),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Text(
              tabs[_selectedTabIndex].label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.3),
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Horizontal scrolling category tabs
        SliverToBoxAdapter(
          child: Container(
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: tabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = _selectedTabIndex == index;
                
                return _buildModernTabChip(
                  tab: tab,
                  index: index,
                  isActive: isActive,
                  colorScheme: colorScheme,
                );
              },
            ),
          ),
        ),
        
        // Content area with better spacing
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_selectedTabIndex),
                child: _buildTabContent(isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildModernTabChip({
    required TabItem tab,
    required int index,
    required bool isActive,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _tabController!.animateTo(index);
          // Smooth scroll to top when changing tabs
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isActive ? null : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 18,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    switch (tabs[_selectedTabIndex].id) {
      case 'account':
        return _buildAccountTab(isDark);
      case 'appearance':
        return _buildAppearanceTab(isDark);
      case 'aiProviders':
        return const LLMProviderSettingsPanel();
      case 'embedding':
        return const EmbeddingSettingsPanel();
      case 'searchProviders':
        return const SearchProviderSettingsPanel();
      case 'websiteMappings':
        return const WebsiteMappingsPanel();
      case 'permissions':
        return _buildPermissionsTab(isDark);
      case 'helpCenter':
        return _buildHelpCenterTab(isDark);
      case 'more':
        return _buildMoreTab(isDark);
      default:
        return const SizedBox();
    }
  }


  Widget _buildAccountTab(bool isDark) {
    final colorScheme = context.colorScheme;
    final authService = AuthService();
    final isAuthenticated = authService.currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Section with enhanced card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.surfaceContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: UserProfileWidget(),
          ),
        ),
        
        const SizedBox(height: 8),

        // Data Management Section
        SectionHeader(
          title: 'Data Management',
          subtitle: 'Manage your local and cloud data',
        ),
        
        // Clear History
        ActionCard(
          icon: Icons.delete_sweep_outlined,
          title: 'Clear History',
          description: 'Remove all local search history and cached data',
          buttonText: 'Clear',
          buttonColor: Colors.orange.shade700,
          onPressed: () => _showClearHistoryDialog(context),
        ),
        
        // Cloud Sync
        if (isAuthenticated) ...[
          Consumer<ConversationHistoryProvider>(
            builder: (context, historyProvider, child) {
              final syncService = ConversationSyncService();
              return ToggleCard(
                icon: Icons.cloud_sync_outlined,
                title: 'Cloud Sync',
                description: 'Sync your conversation history across all devices',
                value: syncService.isCloudSyncEnabled,
                onChanged: (bool value) async {
                  if (!syncService.isAuthenticated) return;

                  try {
                    await syncService.setCloudSyncEnabled(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                value ? Icons.cloud_done : Icons.cloud_off,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(value ? 'Cloud sync enabled' : 'Cloud sync disabled'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Failed to update: $error')),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ] else ...[
          SettingsCard(
            icon: Icons.cloud_off_outlined,
            title: 'Cloud Sync Unavailable',
            description: 'Sign in to sync your data across all your devices',
            iconColor: colorScheme.tertiary,
            backgroundColor: colorScheme.tertiaryContainer.withOpacity(0.3),
            showChevron: false,
          ),
        ],

        // Account Management - Only for authenticated users
        if (isAuthenticated) ...[
          SectionHeader(
            title: 'Account',
            subtitle: 'Manage your account settings',
          ),
          
          ActionCard(
            icon: Icons.logout_outlined,
            title: 'Sign Out',
            description: 'Sign out from your current account',
            buttonText: 'Sign Out',
            isDestructive: true,
            onPressed: () => _showSignOutDialog(context, authService),
          ),
        ],
        
        const SizedBox(height: 8),
      ],
    );
  }

  // Helper method for section titles
  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: -0.3,
      ),
    );
  }

  // Helper method for action cards
  // Dialog for clearing history
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all local search history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear history logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local history cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // Dialog for signing out
  void _showSignOutDialog(BuildContext context, AuthService authService) {
    final colorScheme = context.colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? You will need to sign in again to access cloud sync.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // Dialog for about information
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Searvo',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.search, size: 48),
      children: const [
        Text('A powerful search and AI assistant application.'),
        SizedBox(height: 16),
        Text('Built with Flutter and powered by advanced AI models.'),
      ],
    );
  }

  // Dialog for reporting problems
  void _showReportDialog(BuildContext context) {
    final colorScheme = context.colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report_outlined),
            SizedBox(width: 12),
            Text('Report a Problem'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help us improve by reporting any issues you encounter.'),
            const SizedBox(height: 16),
            Text(
              'You can report issues through:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text('• GitHub Issues', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            Text('• Email Support', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            Text('• In-app Feedback', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.open_in_new, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Opening issue tracker...'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text('Report on GitHub'),
          ),
        ],
      ),
    );
  }


  Widget _buildAppearanceTab(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme Section
        _buildSectionTitle('Theme Mode', colorScheme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.brightness_6_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose between light, dark, or system theme',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _themeController.themeModeString,
                  underline: const SizedBox(),
                  isDense: true,
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    DropdownMenuItem(value: 'system', child: Text('System')),
                  ],
                  onChanged: (value) async {
                    if (value != null && !_isThemeChanging) {
                      setState(() {
                        _isThemeChanging = true;
                      });
                      
                      try {
                        await _themeController.setThemeModeFromString(value);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Theme changed to $value'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to change theme'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isThemeChanging = false;
                          });
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Language Section
        _buildSectionTitle('Language', colorScheme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language_outlined,
                  color: colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interface Language',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your preferred language',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  underline: const SizedBox(),
                  isDense: true,
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value!;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to $value'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildPermissionsTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'App Permissions',
          subtitle: 'Control what the app can access on your device',
        ),
        
        ToggleCard(
          icon: Icons.mic_outlined,
          title: 'Microphone',
          description: 'Enable voice input for search queries and commands',
          value: microphoneEnabled,
          iconColor: Colors.red.shade400,
          onChanged: (value) {
            setState(() {
              microphoneEnabled = value;
            });
          },
        ),
        
        ToggleCard(
          icon: Icons.contacts_outlined,
          title: 'Contacts',
          description: 'Access contacts for personalized search features',
          value: contactsEnabled,
          iconColor: Colors.blue.shade400,
          onChanged: (value) {
            setState(() {
              contactsEnabled = value;
            });
          },
        ),
        
        ToggleCard(
          icon: Icons.calendar_today_outlined,
          title: 'Calendar',
          description: 'Integrate with your schedule and upcoming events',
          value: calendarEnabled,
          iconColor: Colors.green.shade400,
          onChanged: (value) {
            setState(() {
              calendarEnabled = value;
            });
          },
        ),
        
        ToggleCard(
          icon: Icons.phone_outlined,
          title: 'Phone',
          description: 'Enable phone call related capabilities',
          value: phoneEnabled,
          iconColor: Colors.orange.shade400,
          onChanged: (value) {
            setState(() {
              phoneEnabled = value;
            });
          },
        ),
        
        ToggleCard(
          icon: Icons.location_on_outlined,
          title: 'Location',
          description: 'Provide location-based and nearby search results',
          value: locationEnabled,
          iconColor: Colors.purple.shade400,
          onChanged: (value) {
            setState(() {
              locationEnabled = value;
            });
          },
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMoreTab(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Legal & Policies',
          subtitle: 'Privacy, terms, and legal information',
        ),
        
        SettingsCard(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          description: 'Learn how we protect and handle your data',
          iconColor: Colors.blue.shade600,
          onTap: () {
            AppRouter.goTo(context, AppRouter.privacyPolicy);
          },
        ),
        
        SettingsCard(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          description: 'Review our terms and conditions of use',
          iconColor: colorScheme.secondary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.open_in_new, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Opening Terms of Service...'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
        
        SettingsCard(
          icon: Icons.info_outlined,
          title: 'About',
          description: 'App version, credits, and information',
          iconColor: colorScheme.tertiary,
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHelpCenterTab(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Getting Started',
          subtitle: 'Learn the basics and get up to speed',
        ),
        
        SettingsCard(
          icon: Icons.rocket_launch_outlined,
          title: 'Quick Start Guide',
          description: 'Essential steps to begin using the app effectively',
          iconColor: Colors.orange.shade600,
          backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Opening Quick Start Guide...'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
        
        SectionHeader(
          title: 'Support & Resources',
          subtitle: 'Get help and find answers',
        ),
        
        SettingsCard(
          icon: Icons.help_outline,
          title: 'Help & FAQ',
          description: 'Find answers to frequently asked questions',
          iconColor: Colors.green.shade600,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.question_answer, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Opening Help & FAQ...'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
        
        SettingsCard(
          icon: Icons.bug_report_outlined,
          title: 'Report a Problem',
          description: 'Let us know about any issues you encounter',
          iconColor: Colors.red.shade600,
          onTap: () {
            _showReportDialog(context);
          },
        ),
        
        SettingsCard(
          icon: Icons.star_outline,
          title: 'Rate the App',
          description: 'Share your experience and help us improve',
          iconColor: Colors.amber.shade600,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Opening app store...'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }
}

class TabItem {
  final String id;
  final String label;
  final IconData icon;

  TabItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
