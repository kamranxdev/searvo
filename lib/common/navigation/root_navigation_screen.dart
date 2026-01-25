import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/features/discover/screens/discover_screen.dart';
import 'package:searvo/features/home/screens/home_screen.dart';
import 'package:searvo/features/history/screens/conversation_history_screen.dart';
import 'package:searvo/features/search/presentation/bloc/search_bloc.dart';
import 'package:searvo/features/search/presentation/bloc/search_event.dart';
import 'package:searvo/features/search/presentation/pages/search_results_page.dart';

import 'package:searvo/features/settings/screens/settings_screen.dart';
import 'package:searvo/common/navigation/sidebar.dart';
import 'package:searvo/common/navigation/navigation_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR MAPPERS FOR SVG ICONS
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsIconMapper extends ColorMapper {
  final Color targetColor;
  const _SettingsIconMapper(this.targetColor);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == const Color(0xFFFFFFFF)) {
      return targetColor;
    }
    return color;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROOT NAVIGATION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

/// The root navigation screen that provides responsive layout with:
/// - Desktop: Editorial sidebar navigation
/// - Mobile: Swipeable pages with floating pill navigation
class RootNavigationScreen extends StatefulWidget {
  final int currentIndex;
  final String? initialQuery;

  final String? conversationId;
  final String? externalUrl;

  const RootNavigationScreen({
    super.key,
    required this.currentIndex,
    this.initialQuery,
    this.conversationId,
    this.externalUrl,
  });

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _navBarController;
  late Animation<double> _navBarAnimation;

  // Track hover states for each nav item
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);

    _navBarController = AnimationController(
      vsync: this,
      duration: NavigationTheme.transitionDuration,
    );

    _navBarAnimation = CurvedAnimation(
      parent: _navBarController,
      curve: Curves.easeOutCubic,
    );

    _navBarController.value = 1.0; // Start visible
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navBarController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    if (index != widget.currentIndex) {
      HapticFeedback.selectionClick();

      // Clear conversation when navigating to home
      if (index == AppRouter.homeIndex) {
        final searchBloc = context.read<SearchBloc>();
        searchBloc.add(const SearchEvent.clearMessages());
      }

      // Animate page transition
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    if (index != widget.currentIndex) {
      if (index == AppRouter.homeIndex) {
        final searchBloc = context.read<SearchBloc>();
        searchBloc.add(const SearchEvent.clearMessages());
      }
      AppRouter.goToIndex(context, index);
    }
  }

  Widget _getCurrentScreen() {
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      return SearchResultsContent(
        query: widget.initialQuery!,
        conversationId: widget.conversationId,
        externalUrl: widget.externalUrl,
      );
    }

    switch (widget.currentIndex) {
      case AppRouter.homeIndex:
        return const SearvoHomeContent();
      case AppRouter.discoverIndex:
        return const DiscoverScreen();
      case AppRouter.historyIndex:
        return const ConversationHistoryScreen();
      case AppRouter.settingsIndex:
        return const SettingsScreen();
      default:
        return const SearvoHomeContent();
    }
  }

  List<Widget> _getScreens() {
    return const [
      SearvoHomeContent(),
      DiscoverScreen(),
      ConversationHistoryScreen(),
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavigationTheme.colors(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double mobileBreakpoint = 768;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;

        if (isMobile) {
          return _buildMobileLayout(colors);
        } else {
          return _buildDesktopLayout(colors);
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(NavigationColors colors) {
    return Scaffold(
      backgroundColor: colors.sidebarBackground,
      body: Stack(
        children: [
          // Page view with swipe navigation
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _getScreens(),
          ),

          // Floating navigation pill
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _navBarAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - _navBarAnimation.value)),
                  child: Opacity(opacity: _navBarAnimation.value, child: child),
                );
              },
              child: Center(child: _buildMobileNavPill(colors)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavPill(NavigationColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: NavigationTheme.mobileNavDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMobileNavItem(
            index: AppRouter.homeIndex,
            icon: Icons.add_rounded,
            label: 'Search',
            colors: colors,
          ),
          const SizedBox(width: 4),
          _buildMobileNavItem(
            index: AppRouter.discoverIndex,
            icon: Icons.explore_outlined,
            label: 'Discover',
            colors: colors,
          ),
          const SizedBox(width: 4),
          _buildMobileNavItem(
            index: AppRouter.historyIndex,
            icon: Icons.history_rounded,
            label: 'History',
            colors: colors,
          ),
          const SizedBox(width: 4),
          _buildMobileSettingsItem(
            index: AppRouter.settingsIndex,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem({
    required int index,
    required IconData icon,
    required String label,
    required NavigationColors colors,
  }) {
    final isActive = widget.currentIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _onNavigationTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: NavigationTheme.hoverDuration,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? colors.activeBackground
                : isHovered
                ? colors.hoverBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active indicator dot
              if (isActive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.activeIndicator,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Icon
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? colors.activeIcon
                    : isHovered
                    ? colors.hoverText
                    : colors.inactiveIcon,
              ),

              // Label (only shown when active)
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: NavigationTheme.navItemText(context, isActive: true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSettingsItem({
    required int index,
    required NavigationColors colors,
  }) {
    final isActive = widget.currentIndex == index;
    final isHovered = _hoveredIndex == index;

    final iconColor = isActive
        ? colors.activeIcon
        : isHovered
        ? colors.hoverText
        : colors.inactiveIcon;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _onNavigationTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: NavigationTheme.hoverDuration,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? colors.activeBackground
                : isHovered
                ? colors.hoverBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active indicator dot
              if (isActive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.activeIndicator,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Settings icon
              SvgPicture.asset(
                isActive
                    ? 'assets/icons/Settings_Future.svg'
                    : 'assets/icons/Settings.svg',
                colorMapper: _SettingsIconMapper(iconColor),
                width: 20,
                height: 20,
              ),

              // Label (only shown when active)
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: NavigationTheme.navItemText(context, isActive: true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(NavigationColors colors) {
    return Scaffold(
      backgroundColor: colors.sidebarBackground,
      body: Row(
        children: [
          // Editorial sidebar
          const Sidebar(),

          // Main content area
          Expanded(child: _getCurrentScreen()),
        ],
      ),
    );
  }
}
