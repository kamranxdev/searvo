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
import 'package:searvo/features/settings/widgets/settings_tab_chip.dart';
import 'package:searvo/features/settings/widgets/settings_tab_item.dart';
import 'package:searvo/features/settings/widgets/toggle_card.dart';
import 'package:searvo/features/settings/widgets/website_mappings_panel.dart';
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
    final colorScheme = context.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1024;
    
    return Column(
      children: [
        // Header with better styling
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 32 : 20,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: isLargeScreen ? 26 : 22,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 768;
              
              if (isTablet) {
                return _buildTabletLayout(context);
              } else {
                return _buildMobileLayout(context.isDark);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar with original background box styling
          Container(
            width: 256,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline,
              ),
            ),
            child: Column(
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isActive = _selectedTabIndex == index;
                
                return SettingsTabItem(
                  id: tab.id,
                  label: tab.label,
                  icon: tab.icon,
                  isActive: isActive,
                  onTap: () {
                    _tabController!.animateTo(index);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 24),
          // Content with original background box styling
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        tabs[_selectedTabIndex].icon,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tabs[_selectedTabIndex].label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildTabContent(context.isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return Column(
      children: [
        // Mobile tab chips with better spacing
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isActive = _selectedTabIndex == index;
              
              return SettingsTabChip(
                id: tab.id,
                label: tab.label,
                icon: tab.icon,
                isActive: isActive,
                onTap: () {
                  _tabController!.animateTo(index);
                },
              );
            }).toList(),
          ),
        ),
        // Content with original background box styling
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      tabs[_selectedTabIndex].icon,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tabs[_selectedTabIndex].label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildTabContent(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
        // Profile Section
        const UserProfileWidget(),
        const SizedBox(height: 24),

        // Data Management Section
        _buildSectionTitle('Data Management', colorScheme),
        const SizedBox(height: 16),
        
        // Clear History
        _buildActionCard(
          context: context,
          icon: Icons.delete_sweep_outlined,
          title: 'Clear History',
          description: 'Clear all local search history and cached data',
          buttonText: 'Clear',
          buttonColor: Colors.orange.shade400,
          onPressed: () {
            _showClearHistoryDialog(context);
          },
        ),
        
        const SizedBox(height: 12),
        
        // Cloud Sync
        if (isAuthenticated) ...[
          Consumer<ConversationHistoryProvider>(
            builder: (context, historyProvider, child) {
              final syncService = ConversationSyncService();
              return ToggleCard(
                margin: EdgeInsets.zero,
                icon: Icons.cloud_sync_outlined,
                title: 'Cloud Sync',
                description: 'Sync your conversation history across devices',
                value: syncService.isCloudSyncEnabled,
                onChanged: (bool value) async {
                  if (!syncService.isAuthenticated) return;

                  try {
                    await syncService.setCloudSyncEnabled(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? 'Cloud sync enabled' : 'Cloud sync disabled'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update cloud sync: $error'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ] else ...[
          _buildInfoCard(
            context: context,
            icon: Icons.cloud_off_outlined,
            title: 'Cloud Sync Unavailable',
            description: 'Sign in to sync your data across devices',
            color: colorScheme.primaryContainer,
          ),
        ],

        // Account Management - Only for authenticated users
        if (isAuthenticated) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Account Management', colorScheme),
          const SizedBox(height: 16),
          
          _buildActionCard(
            context: context,
            icon: Icons.logout_outlined,
            title: 'Sign Out',
            description: 'Sign out of your account',
            buttonText: 'Sign Out',
            buttonColor: colorScheme.error,
            onPressed: () {
              _showSignOutDialog(context, authService);
            },
          ),
        ],
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
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    final colorScheme = context.colorScheme;
    return Container(
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
              color: buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: buttonColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // Helper method for info cards
  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        _buildSectionTitle('App Permissions', context.colorScheme),
        const SizedBox(height: 12),
        Text(
          'Manage the permissions granted to the app',
          style: TextStyle(
            fontSize: 14,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ToggleCard(
          margin: const EdgeInsets.only(bottom: 12),
          icon: Icons.mic_outlined,
          title: 'Microphone',
          description: 'Enable voice input for search queries',
          value: microphoneEnabled,
          onChanged: (value) {
            setState(() {
              microphoneEnabled = value;
            });
          },
        ),
        ToggleCard(
          margin: const EdgeInsets.only(bottom: 12),
          icon: Icons.contacts_outlined,
          title: 'Contacts',
          description: 'Access contacts for personalized features',
          value: contactsEnabled,
          onChanged: (value) {
            setState(() {
              contactsEnabled = value;
            });
          },
        ),
        ToggleCard(
          margin: const EdgeInsets.only(bottom: 12),
          icon: Icons.calendar_today_outlined,
          title: 'Calendar',
          description: 'Assist with your schedule and events',
          value: calendarEnabled,
          onChanged: (value) {
            setState(() {
              calendarEnabled = value;
            });
          },
        ),
        ToggleCard(
          margin: const EdgeInsets.only(bottom: 12),
          icon: Icons.phone_outlined,
          title: 'Phone',
          description: 'Enable phone call capabilities',
          value: phoneEnabled,
          onChanged: (value) {
            setState(() {
              phoneEnabled = value;
            });
          },
        ),
        ToggleCard(
          margin: EdgeInsets.zero,
          icon: Icons.location_on_outlined,
          title: 'Location',
          description: 'Provide location-based search results',
          value: locationEnabled,
          onChanged: (value) {
            setState(() {
              locationEnabled = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMoreTab(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Legal & Policies', colorScheme),
        const SizedBox(height: 16),
        
        _buildLinkCard(
          context: context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          description: 'Learn how we protect your data',
          onTap: () {
            AppRouter.goTo(context, AppRouter.privacyPolicy);
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildLinkCard(
          context: context,
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          description: 'Review our terms and conditions',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening Terms of Service...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHelpCenterTab(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Getting Started', colorScheme),
        const SizedBox(height: 16),
        
        _buildLinkCard(
          context: context,
          icon: Icons.rocket_launch_outlined,
          title: 'Get Started',
          description: 'Quick guide to help you get started',
          isPrimary: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening Get Started guide...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Support & Resources', colorScheme),
        const SizedBox(height: 16),
        
        _buildLinkCard(
          context: context,
          icon: Icons.help_outline,
          title: 'Help & FAQ',
          description: 'Find answers to common questions',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening Help & FAQ...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper method for link cards
  Widget _buildLinkCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary 
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPrimary
                    ? colorScheme.primaryContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isPrimary
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
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