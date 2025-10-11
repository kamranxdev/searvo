import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/features/home/screens/home_screen.dart';
import 'package:searvo/features/history/screens/conversation_history_screen.dart';
import 'package:searvo/features/search/providers/search_provider.dart';
import 'package:searvo/features/search/screens/search_results_screen.dart';
import 'package:searvo/features/search/widgets/search_box.dart';
import 'package:searvo/features/settings/screens/settings_screen.dart';
import 'package:searvo/shared/navigation/sidebar.dart';

class SettingsNormalMapper extends ColorMapper {
  const SettingsNormalMapper();

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == const Color(0xFFFFFFFF)) {
      return Colors.grey.shade400;
    }
    return color;
  }
}

class SettingsActiveMapper extends ColorMapper {
  final ColorScheme colorScheme;
  const SettingsActiveMapper(this.colorScheme);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == const Color(0xFFFFFFFF)) {
      return colorScheme.primary;
    }
    return color;
  }
}

class RootNavigationScreen extends StatefulWidget {
  final int currentIndex;
  final String? initialQuery;
  final SearchMode searchMode;
  final String? conversationId;
  
  const RootNavigationScreen({
    super.key,
    required this.currentIndex,
    this.initialQuery,
    this.searchMode = SearchMode.search,
    this.conversationId,
  });

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  void _onNavigationTap(int index) {
    if (index != widget.currentIndex) {
      // Clear conversation when navigating to home for a fresh start
      if (index == AppRouter.homeIndex) {
        final searchProvider = context.read<SearchProvider>();
        searchProvider.clearMessages();
      }
      AppRouter.goToIndex(context, index);
    }
  }

  Widget _getCurrentScreen() {
    // Show search results if query is provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      return SearchResultsContent(
        query: widget.initialQuery!,
        searchMode: widget.searchMode,
        conversationId: widget.conversationId,
      );
    }
    
    // Show screen based on current index
    switch (widget.currentIndex) {
      case AppRouter.homeIndex:
        return const SearvoHomeContent();
      case AppRouter.historyIndex:
        return const ConversationHistoryScreen();
      case AppRouter.settingsIndex:
        return const SettingsScreen();
      default:
        return const SearvoHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define breakpoint for responsive design
        const double mobileBreakpoint = 768;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;

        if (isMobile) {
          // Mobile Layout with Bottom Navigation
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: _getCurrentScreen(),
            bottomNavigationBar: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: BottomNavigationBar(
                  currentIndex: widget.currentIndex,
                  onTap: _onNavigationTap,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: colorScheme.surface,
                  selectedItemColor: colorScheme.primary,
                  unselectedItemColor: Colors.grey.shade400,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  elevation: 0,
                  items: [
                    _buildNavItem(
                      icon: CupertinoIcons.search,
                      label: 'Home',
                      index: AppRouter.homeIndex,
                      colorScheme: colorScheme,
                    ),
                    _buildNavItem(
                      icon: Icons.history,
                      label: 'History',
                      index: AppRouter.historyIndex,
                      colorScheme: colorScheme,
                    ),
                    BottomNavigationBarItem(
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 40,
                            width: 0,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/icons/Settings.svg',
                              colorMapper: const SettingsNormalMapper(),
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      ),
                      activeIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/icons/Settings_Future.svg',
                              colorMapper: SettingsActiveMapper(colorScheme),
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      ),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
            ),
          );
        } else {
          // Desktop Layout with Sidebar
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Row(
              children: [
                // Left Sidebar
                const Sidebar(),
                
                // Vertical Divider
                Container(
                  width: 1,
                  height: double.infinity,
                  color: colorScheme.outline,
                ),
                
                // Main Content Area
                Expanded(
                  child: _getCurrentScreen(),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    String? assetIcon,
    required ColorScheme colorScheme,
  }) {
    final bool isSelected = widget.currentIndex == index;
    
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: assetIcon != null
                ? Image.asset(
                    assetIcon,
                    width: 24,
                    height: 24,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                  )
                : Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                  ),
          ),
        ],
      ),
      label: label,
      activeIcon: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: assetIcon != null
                ? Image.asset(
                    assetIcon,
                    width: 24,
                    height: 24,
                    color: colorScheme.primary,
                  )
                : Icon(
                    icon,
                    size: 24,
                    color: colorScheme.primary,
                  ),
          ),
        ],
      ),
    );
  }
}