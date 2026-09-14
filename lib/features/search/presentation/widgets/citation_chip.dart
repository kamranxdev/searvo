import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class CitationChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (citationNumbers.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: citationNumbers.map((citNumber) {
        SourceItem? matchingSource;
        if (sources != null && sources!.isNotEmpty) {
          if (citNumber - 1 >= 0 && citNumber - 1 < sources!.length) {
            matchingSource = sources![citNumber - 1];
          }
        }
        return _SingleCitationBadge(
          number: citNumber,
          source: matchingSource,
          onTap: onTap,
          searchColors: searchColors,
        );
      }).toList(),
    );
  }
}

class _SingleCitationBadge extends StatefulWidget {
  final int number;
  final SourceItem? source;
  final Function(int)? onTap;
  final SearchColors searchColors;

  const _SingleCitationBadge({
    required this.number,
    this.source,
    this.onTap,
    required this.searchColors,
  });

  @override
  State<_SingleCitationBadge> createState() => _SingleCitationBadgeState();
}

class _SingleCitationBadgeState extends State<_SingleCitationBadge>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovering = false;

  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (widget.source != null) {
      _overlayController.show();
      _animationController.forward();
    }
  }

  void _hideOverlay() {
    _animationController.reverse().then((_) {
      if (mounted) _overlayController.hide();
    });
  }

  void _onEnter(PointerEvent event) {
    if (widget.source != null) {
      _isHovering = true;
      setState(() {});
      _showOverlay();
    }
  }

  void _onExit(PointerEvent? event) {
    _isHovering = false;
    if (mounted) setState(() {});
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted && !_isHovering) {
        _hideOverlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          return CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -6),
            child: MouseRegion(
              onEnter: (_) {
                _isHovering = true;
                if (mounted) setState(() {});
              },
              onExit: (_) => _onExit(null),
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
              if (widget.source != null) {
                launchUrl(Uri.parse(widget.source!.url));
              } else if (widget.onTap != null) {
                widget.onTap!(widget.number);
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 1, bottom: 2),
              child: AnimatedScale(
                scale: _isPressed ? 0.9 : (_isHovering ? 1.05 : 1.0),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _isHovering
                        ? widget.searchColors.primary.withValues(alpha: 0.16)
                        : widget.searchColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isHovering
                          ? widget.searchColors.primary.withValues(alpha: 0.4)
                          : widget.searchColors.primary.withValues(alpha: 0.18),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    '${widget.number}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      color: widget.searchColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
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
    final source = widget.source;
    if (source == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(source.url)),
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.transparent,
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.searchColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.searchColors.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: [Citation #] + Favicon + Domain + External Icon
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.searchColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.number}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.searchColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (source.favicon != null && source.favicon!.isNotEmpty) ...[
                    CachedNetworkImage(
                      imageUrl: source.favicon!,
                      width: 14,
                      height: 14,
                      errorWidget: (context, error, stackTrace) =>
                          Icon(Icons.public, size: 14, color: widget.searchColors.caption),
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    CachedNetworkImage(
                      imageUrl:
                          'https://www.google.com/s2/favicons?domain=${source.domain}&sz=64',
                      width: 14,
                      height: 14,
                      errorWidget: (context, error, stackTrace) =>
                          Icon(Icons.public, size: 14, color: widget.searchColors.caption),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      source.domain,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.searchColors.caption,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 13,
                    color: widget.searchColors.caption,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Source Title
              Text(
                source.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.searchColors.text,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (source.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  source.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: widget.searchColors.text.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Visit source',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: widget.searchColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 11,
                    color: widget.searchColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
