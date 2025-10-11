// kIsWeb was previously used to gate the Install button. The Install button is
// now available on all platforms, so the import is no longer required.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/shared/widgets/app_logo.dart';
import 'package:searvo/shared/widgets/install_modal.dart';
import '../../core/theme/theme.dart';

// Color Mappers - Extracted to separate section for clarity
class SettingsColorMapper extends ColorMapper {
  final bool isActive;
  final ColorScheme colorScheme;
  const SettingsColorMapper({required this.isActive, required this.colorScheme});

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (color == const Color(0xFFFFFFFF)) {
      return isActive ? colorScheme.primary : Colors.grey.shade400;
    }
    return color;
  }
}

// Main Sidebar Widget
class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // State variables grouped together
  bool _isExpanded = false;
  bool _isLogoHovered = false;
  bool _isSettingsHovered = false;
  bool _isInstallHovered = false;

  // Constants
  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 64;
  static const int _animationDuration = 250;
  static const double _horizontalPadding = 12;
  static const double _iconSize = 40;

  // Computed properties
  int get _currentIndex {
    final location = GoRouterState.of(context).uri.path;
    if (location == AppRouter.home || location.startsWith('/search')) {
      return AppRouter.homeIndex;
    } else if (location == AppRouter.settings) {
      return AppRouter.settingsIndex;
    }
    return AppRouter.homeIndex;
  }

  // Navigation methods
  void _navigateToIndex(int index) => AppRouter.goToIndex(context, index);

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: _animationDuration),
      curve: Curves.easeInOut,
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      height: double.infinity,
      color: colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildHeader(colorScheme),
          const SizedBox(height: 24),
          _buildNavigationSection(),
          const Spacer(),
          // Always show Install button above Settings so users can open the
          // InstallModal on any platform. Previously it was gated to web only.
          _buildInstallSection(colorScheme),
          const SizedBox(height: 8),
          _buildSettingsSection(colorScheme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Header with logo and close button
  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: SizedBox(
        height: _iconSize,
        child: Row(
          children: [
            Expanded(child: _buildLogoSection(colorScheme)),
            if (_isExpanded) _buildCloseButton(colorScheme),
          ],
        ),
      ),
    );
  }

  // Logo section with brand name
  Widget _buildLogoSection(ColorScheme colorScheme) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isLogoHovered = true),
      onExit: (_) => setState(() => _isLogoHovered = false),
      child: GestureDetector(
        onTap: _toggleSidebar,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedLogo(),
            if (_isExpanded) ...[
              const SizedBox(width: 12),
              _buildBrandText(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  // Animated logo with conditional open icon
  Widget _buildAnimatedLogo() {
    if (!_isExpanded && _isLogoHovered) {
      return Center(
        child: SvgPicture.asset(
          'assets/icons/Bar_Left.svg',
          width: 24,
          height: 24,
        ),
      );
    }
    return const AppLogo(size: _iconSize);
  }

  // Brand text with opacity animation
  Widget _buildBrandText(ColorScheme colorScheme) {
    return Expanded(
      child: AnimatedOpacity(
        opacity: _isExpanded ? 1.0 : 0.0,
        duration: const Duration(milliseconds: _animationDuration),
        child: Text(
          'Searvo',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  // Close button
  Widget _buildCloseButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _toggleSidebar,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.arrow_back_ios,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }

  // Navigation icons section
  Widget _buildNavigationSection() {
    return Column(
      children: [
        _buildNavItem(Icons.add, AppRouter.homeIndex, "New Search"),
        const SizedBox(height: 8),
        _buildNavItem(Icons.history, AppRouter.historyIndex, "History"),
      ],
    );
  }

  // Individual navigation item
  Widget _buildNavItem(IconData icon, int index, String label) {
    final colorScheme = context.colorScheme;
    final isSelected = _currentIndex == index;

    final child = GestureDetector(
      onTap: () => _navigateToIndex(index),
      child: Container(
        width: _isExpanded ? double.infinity : _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isExpanded
            ? _buildExpandedNavItem(icon, label, isSelected, colorScheme)
            : _buildCollapsedNavItem(icon, isSelected, colorScheme),
      ),
    );

    // Wrap with padding or tooltip based on expansion state
    return _isExpanded
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: child,
          )
        : Tooltip(message: label, child: child);
  }

  // Expanded navigation item with icon and text
  Widget _buildExpandedNavItem(
    IconData icon,
    String label,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return ClipRect(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(width: 12),
          Icon(
            icon,
            color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: AnimatedOpacity(
              opacity: _isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: _animationDuration),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Collapsed navigation item with icon only
  Widget _buildCollapsedNavItem(
    IconData icon,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Icon(
        icon,
        color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  // Install section (web only)
  Widget _buildInstallSection(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isInstallHovered = true),
        onExit: (_) => setState(() => _isInstallHovered = false),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const InstallModal(),
            );
          },
          child: Container(
            width: _isExpanded ? double.infinity : _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(
              color: _isInstallHovered ? colorScheme.surfaceContainerHighest : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isExpanded
                ? _buildExpandedInstall(colorScheme)
                : _buildCollapsedInstall(colorScheme),
          ),
        ),
      ),
    );
  }

  // Expanded install with icon and text
  Widget _buildExpandedInstall(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 12),
        Icon(
          Icons.download,
          color: _isInstallHovered ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: AnimatedOpacity(
            opacity: _isExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: _animationDuration),
            child: Text(
              'Install',
              style: TextStyle(
                color: _isInstallHovered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // Collapsed install with icon only
  Widget _buildCollapsedInstall(ColorScheme colorScheme) {
    return Tooltip(
      message: 'Install',
      child: Center(
        child: Icon(
          Icons.download,
          color: _isInstallHovered ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }

  // Settings section at bottom
  Widget _buildSettingsSection(ColorScheme colorScheme) {
    final isActive = _currentIndex == AppRouter.settingsIndex || _isSettingsHovered;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isSettingsHovered = true),
        onExit: (_) => setState(() => _isSettingsHovered = false),
        child: GestureDetector(
          onTap: () => _navigateToIndex(AppRouter.settingsIndex),
          child: Container(
            width: _isExpanded ? double.infinity : _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(
              color: _currentIndex == AppRouter.settingsIndex
                  ? colorScheme.surfaceContainerHighest
                  : (_isSettingsHovered ? colorScheme.surfaceContainerHighest : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isExpanded
                ? _buildExpandedSettings(isActive, colorScheme)
                : _buildCollapsedSettings(isActive, colorScheme),
          ),
        ),
      ),
    );
  }

  // Expanded settings with icon and text
  Widget _buildExpandedSettings(bool isActive, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 12),
        SvgPicture.asset(
          'assets/icons/Settings_Future.svg',
          colorMapper: SettingsColorMapper(isActive: isActive, colorScheme: colorScheme),
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: AnimatedOpacity(
            opacity: _isExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: _animationDuration),
            child: Text(
              'Settings',
              style: TextStyle(
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // Collapsed settings with icon only
  Widget _buildCollapsedSettings(bool isActive, ColorScheme colorScheme) {
    return Center(
      child: SvgPicture.asset(
        'assets/icons/Settings.svg',
        colorMapper: SettingsColorMapper(isActive: isActive, colorScheme: colorScheme),
        width: 24,
        height: 24,
      ),
    );
  }
}