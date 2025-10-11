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
import 'package:searvo/features/settings/widgets/section_header.dart';
import 'package:searvo/features/settings/widgets/setting_item.dart';
import 'package:searvo/features/settings/widgets/settings_tab_chip.dart';
import 'package:searvo/features/settings/widgets/settings_tab_item.dart';
import 'package:searvo/features/settings/widgets/toggle_card.dart';
import 'package:searvo/features/settings/widgets/website_mappings_panel.dart';

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

  // State variables for toggles and inputs
  bool microphoneEnabled = false;
  bool contactsEnabled = false;
  bool calendarEnabled = false;
  bool phoneEnabled = false;
  bool locationEnabled = false;
  String selectedLanguage = 'en';
  String introduceYourself = '';
  bool _isThemeChanging = false;

  final List<TabItem> tabs = [
    TabItem(id: 'account', label: 'Account', icon: Icons.account_circle),
    TabItem(id: 'appearance', label: 'Appearance', icon: Icons.palette),
    TabItem(id: 'aiProviders', label: 'AI Providers', icon: Icons.psychology),
    TabItem(id: 'embedding', label: 'Embedding', icon: Icons.memory),
    TabItem(id: 'searchProviders', label: 'Search Providers', icon: Icons.search),
    TabItem(id: 'websiteMappings', label: 'Website Mappings', icon: Icons.link),
    TabItem(id: 'permissions', label: 'Permissions', icon: Icons.security),
    TabItem(id: 'helpCenter', label: 'Help Center', icon: Icons.help_center),
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
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
            color: colorScheme.onSurfaceVariant),
          onPressed: () => AppRouter.goBack(context),
        ),
        title: Row(
          children: [
            Icon(Icons.settings, 
              color: colorScheme.onSurface,
              size: 23),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 768;
          
          if (isTablet) {
            return _buildTabletLayout(context);
          } else {
            return _buildMobileLayout(context.isDark);
          }
        },
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
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
          // Content
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
                  Text(
                    tabs[_selectedTabIndex].label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
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
        // Mobile tab chips
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
        // Content
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
                Text(
                  tabs[_selectedTabIndex].label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
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
    final user = authService.currentUser;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Profile Widget
        const UserProfileWidget(
          showSignOutButton: false,
        ),
        const SizedBox(height: 24),
        
        SectionHeader(
          title: 'Account Information',
          description: 'Your profile details',
        ),
        const SizedBox(height: 16),
        
        SettingItem(
          isDark: isDark,
          label: 'Display Name',
          description: 'Your account display name',
          child: Text(
            user?.displayName ?? 'Not set',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Email',
          description: 'Your account email address',
          child: Text(
            user?.email ?? 'Not set',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'User ID',
          description: 'Your unique user identifier',
          child: Text(
            user?.uid.substring(0, 8) ?? 'Not set',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        SectionHeader(
          title: 'Account Actions',
          description: 'Manage your account data and session',
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Clear History',
          description: 'Clear all search history and cached data',
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text('Are you sure you want to clear all search history? This action cannot be undone.'),
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
                          const SnackBar(content: Text('History cleared')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear History'),
          ),
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Sign Out',
          description: 'Sign out of your account',
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
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
                            const SnackBar(content: Text('Signed out successfully')),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }


  Widget _buildAppearanceTab(bool isDark) {
    final colorScheme = context.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingItem(
          isDark: isDark,
          label: 'Theme',
          description: 'Choose between light and dark theme',
          child: DropdownButton<String>(
            value: _themeController.themeModeString,
            dropdownColor: colorScheme.surfaceContainerHighest,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
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
                  // Update the actual theme - this will instantly change the app theme
                  await _themeController.setThemeModeFromString(value);
                  
                  // Show a brief confirmation
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Theme changed to ${value.toLowerCase()}'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colorScheme.surface,
                      ),
                    );
                  }
                } catch (e) {
                  // Theme change failed, show error
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to change theme'),
                        backgroundColor: colorScheme.surface,
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
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Language',
          description: 'Select your preferred language for the interface',
          child: DropdownButton<String>(
            value: selectedLanguage,
            dropdownColor: colorScheme.surfaceContainerHighest,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English (English)')),
              DropdownMenuItem(value: 'es', child: Text('Español (Spanish)')),
              DropdownMenuItem(value: 'fr', child: Text('Français (French)')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch (German)')),
            ],
            onChanged: (value) {
              setState(() {
                selectedLanguage = value!;
              });
            },
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
          title: 'Allow Permissions',
          description: 'Manage the permissions granted to the app',
        ),
        const SizedBox(height: 16),
        ToggleCard(
          icon: Icons.mic,
          title: 'Microphone',
          description: 'To use the voice feature, please allow access to your microphone.',
          value: microphoneEnabled,
          onChanged: (value) {
            setState(() {
              microphoneEnabled = value;
            });
          },
        ),
        const SizedBox(height: 12),
        ToggleCard(
          icon: Icons.contacts,
          title: 'Contacts',
          description: 'Allow access to your contacts, for example, to send messages or emails.',
          value: contactsEnabled,
          onChanged: (value) {
            setState(() {
              contactsEnabled = value;
            });
          },
        ),
        const SizedBox(height: 12),
        ToggleCard(
          icon: Icons.calendar_today,
          title: 'Calendar',
          description: 'To assist with your schedule, enable calendar access.',
          value: calendarEnabled,
          onChanged: (value) {
            setState(() {
              calendarEnabled = value;
            });
          },
        ),
        const SizedBox(height: 12),
        ToggleCard(
          icon: Icons.phone,
          title: 'Phone',
          description: 'For making phone calls.',
          value: phoneEnabled,
          onChanged: (value) {
            setState(() {
              phoneEnabled = value;
            });
          },
        ),
        const SizedBox(height: 12),
        ToggleCard(
          icon: Icons.location_on,
          title: 'Location',
          description: 'Helpful answers based on your location.',
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
        SectionHeader(
          title: 'Legal & Support',
          description: 'View our policies and manage your account',
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Privacy Policy',
          description: 'Read our privacy policy to understand how we protect your data',
          child: ElevatedButton.icon(
            onPressed: () {
              AppRouter.goTo(context, AppRouter.privacyPolicy);
            },
            icon: const Icon(Icons.privacy_tip),
            label: const Text('View Privacy Policy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Terms of Service',
          description: 'Review the terms and conditions for using our service',
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Open terms of service URL or dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Terms of Service...')),
              );
            },
            icon: const Icon(Icons.description),
            label: const Text('View Terms of Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
        ),
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
          description: 'Learn how to make the most of our app',
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Get Started',
          description: 'Quick guide to help you get started with the app',
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Open get started guide/tutorial
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Get Started guide...')),
              );
            },
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Get Started'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SectionHeader(
          title: 'Support',
          description: 'Find answers to common questions and get help',
        ),
        const SizedBox(height: 16),
        SettingItem(
          isDark: isDark,
          label: 'Help & FAQ',
          description: 'Frequently asked questions and troubleshooting guides',
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Open help center/FAQ page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Help & FAQ...')),
              );
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('Help & FAQ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
        ),
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