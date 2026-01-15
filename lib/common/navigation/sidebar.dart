import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/common/widgets/app_logo.dart';
import 'package:searvo/common/widgets/install_modal.dart';
import 'package:searvo/common/navigation/navigation_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR MAPPER FOR SVG ICONS
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsColorMapper extends ColorMapper {
  final Color targetColor;
  const _SettingsColorMapper(this.targetColor);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (color == const Color(0xFFFFFFFF)) {
      return targetColor;
    }
    return color;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDITORIAL SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════════

/// A refined, editorial-style sidebar navigation with smooth animations
/// and premium visual design inspired by magazine aesthetics.
class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  int _hoveredIndex = -1;
  bool _isLogoHovered = false;
  
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: NavigationTheme.expandDuration,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  int get _currentIndex {
    final location = GoRouterState.of(context).uri.path;
    if (location == AppRouter.home || location.startsWith('/search')) {
      return AppRouter.homeIndex;
    } else if (location == AppRouter.discover) {
      return AppRouter.discoverIndex;
    } else if (location == AppRouter.conversationHistory) {
      return AppRouter.historyIndex;
    } else if (location == AppRouter.settings) {
      return AppRouter.settingsIndex;
    }
    return AppRouter.homeIndex;
  }

  void _toggleSidebar() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _navigateToIndex(int index) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
    }
    AppRouter.goToIndex(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavigationTheme.colors(context);
    
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final width = NavigationTheme.sidebarCollapsedWidth +
            (_expandAnimation.value *
                (NavigationTheme.sidebarExpandedWidth -
                    NavigationTheme.sidebarCollapsedWidth));
        
        return Container(
          width: width,
          height: double.infinity,
          decoration: NavigationTheme.sidebarDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(colors),
              const SizedBox(height: 32),
              _buildNavigationSection(colors),
              const Spacer(),
              _buildFooterSection(colors),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HEADER SECTION
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(NavigationColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NavigationTheme.horizontalPadding,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isLogoHovered = true),
        onExit: (_) => setState(() => _isLogoHovered = false),
        child: GestureDetector(
          onTap: _toggleSidebar,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                // Logo with hover effect
                AnimatedContainer(
                  duration: NavigationTheme.hoverDuration,
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()
                    ..scale(_isLogoHovered ? 1.05 : 1.0),
                  transformAlignment: Alignment.center,
                  child: _buildLogo(colors),
                ),
                
                // Brand text (fades in when expanded)
                if (_expandAnimation.value > 0.1) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Searvo',
                              style: NavigationTheme.brandText(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          _buildCollapseButton(colors),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(NavigationColors colors) {
    if (!_isExpanded && _isLogoHovered) {
      return Container(
        width: NavigationTheme.logoSize,
        height: NavigationTheme.logoSize,
        decoration: BoxDecoration(
          color: colors.hoverBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 20,
          color: colors.activeIcon,
        ),
      );
    }
    return const AppLogo(size: NavigationTheme.logoSize);
  }

  Widget _buildCollapseButton(NavigationColors colors) {
    return AnimatedOpacity(
      opacity: _isLogoHovered ? 1.0 : 0.5,
      duration: NavigationTheme.hoverDuration,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _isLogoHovered ? colors.hoverBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.chevron_left_rounded,
          size: 20,
          color: colors.inactiveIcon,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NAVIGATION SECTION
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildNavigationSection(NavigationColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section label
        if (_expandAnimation.value > 0.5)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(
                left: NavigationTheme.horizontalPadding + 4,
                bottom: 12,
              ),
              child: Text(
                'NAVIGATE',
                style: NavigationTheme.sectionLabel(context),
              ),
            ),
          ),
        
        // Navigation items
        _buildNavItem(
          index: AppRouter.homeIndex,
          icon: Icons.add_rounded,
          label: 'New Search',
          colors: colors,
        ),
        _buildNavItem(
          index: AppRouter.discoverIndex,
          icon: Icons.explore_outlined,
          label: 'Discover',
          colors: colors,
        ),
        _buildNavItem(
          index: AppRouter.historyIndex,
          icon: Icons.history_rounded,
          label: 'History',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required NavigationColors colors,
  }) {
    final isActive = _currentIndex == index;
    final isHovered = _hoveredIndex == index;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: NavigationTheme.horizontalPadding,
        vertical: NavigationTheme.itemSpacing / 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: GestureDetector(
          onTap: () => _navigateToIndex(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: NavigationTheme.hoverDuration,
            curve: Curves.easeOut,
            height: NavigationTheme.navItemHeight,
            decoration: _isExpanded && isHovered
                ? NavigationTheme.hoverItemDecoration(context)
                : null,
            child: _isExpanded
                ? _buildExpandedNavItem(icon, label, isActive, isHovered, colors)
              : _buildCollapsedNavItem(index, icon, label, isActive, isHovered, colors),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedNavItem(
    IconData icon,
    String label,
    bool isActive,
    bool isHovered,
    NavigationColors colors,
  ) {
    return Row(
      children: [
        const SizedBox(width: 14),
        const SizedBox(width: 3), // Spacer to align with footer items
        const SizedBox(width: 12),
        
        // Icon
        AnimatedContainer(
          duration: NavigationTheme.hoverDuration,
          child: Icon(
            icon,
            size: NavigationTheme.iconSize,
            color: isHovered
                ? colors.hoverText
                : colors.inactiveIcon,
          ),
        ),
        
        const SizedBox(width: 14),
        
        // Label
        Flexible(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              label,
              style: NavigationTheme.navItemText(context).copyWith(
                color: isHovered
                    ? colors.hoverText
                    : colors.inactiveText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedNavItem(
    int index,
    IconData icon,
    String label,
    bool isActive,
    bool isHovered,
    NavigationColors colors,
  ) {
    return IconButton(
      icon: Icon(
        icon,
        size: NavigationTheme.iconSize,
        color: isHovered ? colors.hoverText : colors.inactiveIcon,
      ),
      onPressed: () => _navigateToIndex(index),
      tooltip: label,
      style: ButtonStyle(
        backgroundColor: isActive ? WidgetStateProperty.all(colors.activeIndicator.withOpacity(0.2)) : null,
        shape: WidgetStateProperty.all(CircleBorder()),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FOOTER SECTION
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildFooterSection(NavigationColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: NavigationTheme.horizontalPadding,
            vertical: 8,
          ),
          child: Container(
            height: 1,
            color: colors.divider,
          ),
        ),
        
        // Section label
        if (_expandAnimation.value > 0.5)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(
                left: NavigationTheme.horizontalPadding + 4,
                bottom: 12,
                top: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MORE',
                  style: NavigationTheme.sectionLabel(context),
                ),
              ),
            ),
          ),
        
        // Install button
        _buildInstallItem(colors),
        
        // Settings
        _buildSettingsItem(colors),
      ],
    );
  }

  Widget _buildInstallItem(NavigationColors colors) {
    const index = -2; // Special index for install
    final isHovered = _hoveredIndex == index;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: NavigationTheme.horizontalPadding,
        vertical: NavigationTheme.itemSpacing / 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            showDialog(
              context: context,
              builder: (context) => const InstallModal(),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: NavigationTheme.hoverDuration,
            curve: Curves.easeOut,
            height: NavigationTheme.navItemHeight,
            decoration: isHovered ? NavigationTheme.hoverItemDecoration(context) : null,
            child: _isExpanded
                ? _buildExpandedFooterItem(
                    Icons.download_rounded,
                    'Install App',
                    isHovered,
                    colors,
                  )
                : _buildCollapsedFooterItem(
                    Icons.download_rounded,
                    'Install App',
                    isHovered,
                    colors,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(NavigationColors colors) {
    final isActive = _currentIndex == AppRouter.settingsIndex;
    const index = AppRouter.settingsIndex;
    final isHovered = _hoveredIndex == index;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: NavigationTheme.horizontalPadding,
        vertical: NavigationTheme.itemSpacing / 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: GestureDetector(
          onTap: () => _navigateToIndex(AppRouter.settingsIndex),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: NavigationTheme.hoverDuration,
            curve: Curves.easeOut,
            height: NavigationTheme.navItemHeight,
            decoration: _isExpanded && isHovered
                ? NavigationTheme.hoverItemDecoration(context)
                : null,
            child: _isExpanded
                ? _buildExpandedSettingsItem(isActive, isHovered, colors)
                : _buildCollapsedSettingsItem(index, isActive, isHovered, colors),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedFooterItem(
    IconData icon,
    String label,
    bool isHovered,
    NavigationColors colors,
  ) {
    return Row(
      children: [
        const SizedBox(width: 14),
        const SizedBox(width: 3), // Spacer to align with nav items
        const SizedBox(width: 12),
        Icon(
          icon,
          size: NavigationTheme.iconSize,
          color: isHovered ? colors.hoverText : colors.inactiveIcon,
        ),
        const SizedBox(width: 14),
        Flexible(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              label,
              style: NavigationTheme.navItemText(context).copyWith(
                color: isHovered ? colors.hoverText : colors.inactiveText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedFooterItem(
    IconData icon,
    String label,
    bool isHovered,
    NavigationColors colors,
  ) {
    return Tooltip(
      message: label,
      textStyle: NavigationTheme.tooltipText(context),
      decoration: BoxDecoration(
        color: colors.mobileNavBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.shadowPrimary,
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: NavigationTheme.iconSize,
          color: isHovered ? colors.hoverText : colors.inactiveIcon,
        ),
      ),
    );
  }

  Widget _buildExpandedSettingsItem(
    bool isActive,
    bool isHovered,
    NavigationColors colors,
  ) {
    final iconColor = isHovered
        ? colors.hoverText
        : colors.inactiveIcon;
    
    return Row(
      children: [
        const SizedBox(width: 14),
        const SizedBox(width: 3), // Spacer to align with nav items
        const SizedBox(width: 12),
        
        SvgPicture.asset(
          'assets/icons/Settings_Future.svg',
          colorMapper: _SettingsColorMapper(iconColor),
          width: NavigationTheme.iconSize,
          height: NavigationTheme.iconSize,
        ),
        
        const SizedBox(width: 14),
        
        Flexible(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Settings',
              style: NavigationTheme.navItemText(context).copyWith(
                color: isHovered
                    ? colors.hoverText
                    : colors.inactiveText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedSettingsItem(
    int index,
    bool isActive,
    bool isHovered,
    NavigationColors colors,
  ) {
    final iconColor = isHovered
        ? colors.hoverText
        : colors.inactiveIcon;
    
    return IconButton(
      icon: SvgPicture.asset(
        'assets/icons/Settings.svg',
        colorMapper: _SettingsColorMapper(iconColor),
        width: NavigationTheme.iconSize,
        height: NavigationTheme.iconSize,
      ),
      onPressed: () => _navigateToIndex(index),
      tooltip: 'Settings',
      style: ButtonStyle(
        backgroundColor: isActive ? WidgetStateProperty.all(colors.activeIndicator.withOpacity(0.2)) : null,
        shape: WidgetStateProperty.all(CircleBorder()),
      ),
    );
  }
}