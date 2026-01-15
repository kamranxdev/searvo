import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:searvo/features/search/models/message_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class CitationChip extends StatefulWidget {
  final List<int> citationNumbers;
  final List<SourceItem>? sources;
  final Function(int)? onTap;
  final SearchColors searchColors;

  const CitationChip({
    super.key,
    required this.citationNumbers,
    this.sources,
    this.onTap,
    required this.searchColors,
  });

  @override
  State<CitationChip> createState() => _CitationChipState();
}

class _CitationChipState extends State<CitationChip>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovering = false;

  // Overlay controls
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _overlayController.show();
    _animationController.forward();
  }

  void _hideOverlay() {
    _animationController.reverse().then((_) {
      if (mounted) _overlayController.hide();
    });
  }

  void _onEnter(PointerEvent event) {
    if ((widget.sources?.isNotEmpty ?? false)) {
      _isHovering = true;
      _showOverlay();
    }
  }

  void _onExit(PointerEvent event) {
    _isHovering = false;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && !_isHovering) {
        _hideOverlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.citationNumbers.isEmpty) return const SizedBox.shrink();

    final label = widget.citationNumbers.join(', ');

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          return CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -8),
            child: MouseRegion(
              onEnter: (_) => _isHovering = true,
              onExit: (_) {
                _isHovering = false;
                _hideOverlay();
              },
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  );
                },
                child: _buildRichCard(context),
              ),
            ),
          );
        },
        child: MouseRegion(
          onEnter: _onEnter,
          onExit: _onExit,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              if (_overlayController.isShowing) {
                _hideOverlay();
              } else if (widget.sources?.isNotEmpty ?? false) {
                _showOverlay();
              } else if (widget.onTap != null) {
                widget.onTap!(widget.citationNumbers.first);
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.only(left: 2.0, right: 1.0),
              child: Transform.translate(
                offset: const Offset(0, -5), // Superscript visual offset
                child: AnimatedScale(
                  scale: _isPressed ? 0.9 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: widget.searchColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.searchColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        color: widget.searchColors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRichCard(BuildContext context) {
    if (widget.sources == null || widget.sources!.isEmpty)
      return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: widget.searchColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.searchColors.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: widget.searchColors.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sources',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.searchColors.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: widget.searchColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.sources!.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: widget.searchColors.outline.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final source = widget.sources![index];
                  return InkWell(
                    onTap: () => launchUrl(Uri.parse(source.url)),
                    hoverColor: widget.searchColors.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Circular Source Number
                              Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: widget.searchColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${widget.citationNumbers[index]}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: widget.searchColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Favicon
                              if (source.favicon != null)
                                CachedNetworkImage(
                                  imageUrl: source.favicon!,
                                  width: 14,
                                  height: 14,
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox(width: 14),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  source.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: widget.searchColors.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            source.domain,
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.searchColors.caption,
                            ),
                          ),
                          if (source.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              source.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.searchColors.text.withValues(
                                  alpha: 0.8,
                                ),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
