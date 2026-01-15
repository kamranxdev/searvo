import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Install Modal Widget
/// Shows download options for mobile (iPhone/Android) and desktop (macOS/Windows)
/// Follows the design from the provided UI mockup
class InstallModal extends StatefulWidget {
  const InstallModal({super.key});

  @override
  State<InstallModal> createState() => _InstallModalState();
}

class _InstallModalState extends State<InstallModal> {
  // Track hover states for buttons
  bool _iPhoneHovered = false;
  bool _androidHovered = false;
  bool _macOSHovered = false;
  bool _windowsHovered = false;
  bool _webHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 900;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isSmallScreen ? screenSize.width * 0.9 : 900,
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: screenSize.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    splashRadius: 20,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                child: isSmallScreen
                    ? _buildMobileLayout(colorScheme)
                    : _buildDesktopLayout(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 64),
        // First row - Mobile section (image right, info left)
        _buildSplitView(
          colorScheme: colorScheme,
          mockup: _buildPhoneMockup(colorScheme),
          title: 'Searvo A! for Mobile',
          description: 'Stay curious on the go and start new threads from anywhere. Ask questions with voice mode and follow up with queries from desktop.',
          buttons: _buildMobileButtons(),
          imageOnLeft: false,
        ),
        const SizedBox(height: 64),
        // Second row - Desktop section (image left, info right - reversed)
        _buildSplitView(
          colorScheme: colorScheme,
          mockup: _buildDesktopMockup(colorScheme),
          title: 'Searvo A! for Desktop',
          description: 'Get instant answers and explore topics in depth with our native desktop experience. Built for productivity and deep research.',
          buttons: _buildDesktopButtons(),
          imageOnLeft: true,
        ),
        const SizedBox(height: 64),
        // Third row - Web section (image right, info left)
        _buildSplitView(
          colorScheme: colorScheme,
          mockup: _buildWebMockup(colorScheme),
          title: 'Searvo A! for Web',
          description: 'Access Searvo A! from any web browser. No installation required - just open and start exploring.',
          buttons: _buildWebButtons(),
          imageOnLeft: false,
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildSplitView(
          colorScheme: colorScheme,
          mockup: _buildPhoneMockup(colorScheme),
          title: 'Searvo A! for Mobile',
          description: 'Stay curious on the go and start new threads from anywhere. Ask questions with voice mode and follow up with queries from desktop.',
          buttons: _buildMobileButtons(),
          imageOnLeft: true,
        ),
        const SizedBox(height: 48),
        _buildSplitView(
          colorScheme: colorScheme,
          mockup: _buildDesktopMockup(colorScheme),
          title: 'Searvo A! for Desktop',
          description: 'Get instant answers and explore topics in depth with our native desktop experience. Built for productivity and deep research.',
          buttons: _buildDesktopButtons(),
          imageOnLeft: true,
        ),
        const SizedBox(height: 48),
        _buildSplitView(
          colorScheme: colorScheme,
          mockup: _buildWebMockup(colorScheme),
          title: 'Searvo A! for Web',
          description: 'Access Searvo A! from any web browser. No installation required - just open and start exploring.',
          buttons: _buildWebButtons(),
          imageOnLeft: true,
        ),
      ],
    );
  }

  // Split view component with consistent width layout
  Widget _buildSplitView({
    required ColorScheme colorScheme,
    required Widget mockup,
    required String title,
    required String description,
    required Widget buttons,
    required bool imageOnLeft,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 900;

    // Fixed width for image section to maintain consistency
    final imageSection = SizedBox(
      width: isSmallScreen ? double.infinity : 360,
      child: Center(child: mockup),
    );
    
    // Flexible width for info section that takes remaining space
    final infoSection = Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 0 : 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            buttons,
          ],
        ),
      ),
    );

    // Mobile layout: always stack with image on top
    if (isSmallScreen) {
      return Column(
        children: [
          imageSection,
          const SizedBox(height: 32),
          infoSection,
        ],
      );
    }

    // Desktop layout: side by side with consistent widths
    // First row: image left, info right
    // Second row: info left, image right (reversed)
    if (imageOnLeft) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            imageSection,
            infoSection,
          ],
        ),
      );
    } else {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            infoSection,
            imageSection,
          ],
        ),
      );
    }
  }

  // Phone mockup widget
  Widget _buildPhoneMockup(ColorScheme colorScheme) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status bar area
            Container(
              height: 40,
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '9:41',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_4_bar, size: 14, color: colorScheme.onSurface),
                        const SizedBox(width: 4),
                        Icon(Icons.wifi, size: 14, color: colorScheme.onSurface),
                        const SizedBox(width: 4),
                        Icon(Icons.battery_full, size: 14, color: colorScheme.onSurface),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // App header
            Container(
              height: 44,
              color: colorScheme.surface,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    child: Icon(Icons.person, size: 16, color: colorScheme.primary),
                  ),
                  const Expanded(child: SizedBox()),
                  Text(
                    'Searvo A!',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Icon(Icons.ios_share, size: 18, color: colorScheme.onSurface),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Where\nknowledge\nbegins',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop mockup widget
  Widget _buildDesktopMockup(ColorScheme colorScheme) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Window controls
            Container(
              height: 32,
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // App content
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: Row(
                  children: [
                    // Sidebar
                    Container(
                      width: 80,
                      color: colorScheme.surfaceContainerHigh,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Searvo A!',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New Thread',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSidebarItem(colorScheme, Icons.home, 'Home'),
                          const SizedBox(height: 6),
                          _buildSidebarItem(colorScheme, Icons.explore, 'Discover'),
                        ],
                      ),
                    ),
                    // Main content
                    Expanded(
                      child: Container(
                        color: colorScheme.surface,
                        child: Center(
                          child: Icon(
                            Icons.search,
                            size: 32,
                            color: colorScheme.onSurface.withOpacity(0.2),
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

  // Web mockup widget
  Widget _buildWebMockup(ColorScheme colorScheme) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Browser toolbar
            Container(
              height: 40,
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, size: 12, color: colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            'searvo.ai',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    Icon(Icons.refresh, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
            // App content
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: Center(
                  child: Icon(
                    Icons.search,
                    size: 32,
                    color: colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile download buttons
  Widget _buildMobileButtons() {
    final colorScheme = context.colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildDownloadButton(
            colorScheme: colorScheme,
            icon: Icons.apple,
            label: 'iPhone',
            isHovered: _iPhoneHovered,
            onHover: (value) => setState(() => _iPhoneHovered = value),
            onTap: () {
              // TODO: Add iPhone download link
              debugPrint('Download for iPhone');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDownloadButton(
            colorScheme: colorScheme,
            icon: Icons.android,
            label: 'Android',
            isHovered: _androidHovered,
            onHover: (value) => setState(() => _androidHovered = value),
            onTap: () {
              // TODO: Add Android download link
              debugPrint('Download for Android');
            },
          ),
        ),
      ],
    );
  }

  // Desktop download buttons
  Widget _buildDesktopButtons() {
    final colorScheme = context.colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildDownloadButton(
            colorScheme: colorScheme,
            icon: Icons.apple,
            label: 'macOS',
            isHovered: _macOSHovered,
            onHover: (value) => setState(() => _macOSHovered = value),
            onTap: () {
              // TODO: Add macOS download link
              debugPrint('Download for macOS');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDownloadButton(
            colorScheme: colorScheme,
            icon: Icons.window,
            label: 'Windows',
            isHovered: _windowsHovered,
            onHover: (value) => setState(() => _windowsHovered = value),
            onTap: () {
              // TODO: Add Windows download link
              debugPrint('Download for Windows');
            },
          ),
        ),
      ],
    );
  }

  // Web download buttons
  Widget _buildWebButtons() {
    final colorScheme = context.colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildDownloadButton(
            colorScheme: colorScheme,
            icon: Icons.web,
            label: 'Web',
            isHovered: _webHovered,
            onHover: (value) => setState(() => _webHovered = value),
            onTap: () {
              // TODO: Add web app link
              debugPrint('Open Web App');
            },
          ),
        ),
      ],
    );
  }

  // Sidebar item for desktop mockup
  Widget _buildSidebarItem(ColorScheme colorScheme, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 10, color: colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable download button
  Widget _buildDownloadButton({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required bool isHovered,
    required Function(bool) onHover,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isHovered
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? colorScheme.primary.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isHovered ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isHovered ? colorScheme.primary : colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
