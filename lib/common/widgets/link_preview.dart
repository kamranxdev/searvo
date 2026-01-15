import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPreview extends StatefulWidget {
  final Widget child;
  final String url;
  final String? imageSrc;
  final bool isStatic;
  final double width;
  final double height;
  final TextStyle? style;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const LinkPreview({
    super.key,
    required this.child,
    required this.url,
    this.imageSrc,
    this.isStatic = false,
    this.width = 200,
    this.height = 125,
    this.style,
    this.padding,
    this.onTap,
  });

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Parallax effect
  final ValueNotifier<double> _xOffset = ValueNotifier(0.0);

  bool _isHovering = false;

  // To handle entrance/exit delays
  Future<void>? _closeFuture;

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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _xOffset.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent event) {
    _isHovering = true;
    _updatePosition(event);
    // Cancel any pending close
    if (_closeFuture != null) {
      // We rely on the _isHovering check inside the future callback.
    }
    _overlayController.show();
    _animationController.forward();
  }

  void _onExit(PointerEvent event) {
    _isHovering = false;
    // Add a small delay before closing
    _closeFuture = Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isHovering && mounted) {
        // Only reverse if we are still not hovering after the delay
        _animationController.reverse().then((_) {
          if (mounted && !_isHovering) {
            _overlayController.hide();
          }
        });
      }
    });
  }

  void _onHover(PointerEvent event) {
    if (!_isHovering) return;
    _updatePosition(event);
  }

  void _updatePosition(PointerEvent event) {
    // Center the preview horizontally on the cursor
    final localDx = event.localPosition.dx;
    // We want the center of the preview (widget.width / 2) to be at localDx
    // Since we anchor to the top-left of the target, the x-offset should be:
    final targetX = localDx - (widget.width / 2);
    _xOffset.value = targetX;
  }

  String _getPreviewUrl() {
    if (widget.isStatic && widget.imageSrc != null) {
      return widget.imageSrc!;
    }

    // Construct Microlink API URL
    // React params: url, screenshot=true, meta=false, embed=screenshot.url,
    // colorScheme=dark, viewport.isMobile=true, viewport.deviceScaleFactor=1
    // viewport.width=width*3, viewport.height=height*3

    final targetUrl = Uri.encodeComponent(widget.url);
    final width = (widget.width * 3).toInt();
    final height = (widget.height * 3).toInt();

    return 'https://api.microlink.io/?url=$targetUrl&screenshot=true&meta=false&embed=screenshot.url&colorScheme=dark&viewport.isMobile=true&viewport.deviceScaleFactor=1&viewport.width=$width&viewport.height=$height';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      onHover: _onHover,
      cursor: SystemMouseCursors.click,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (BuildContext context) {
            return Positioned(
              width: widget.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                // Position above the text.
                // We use offset based on _xOffset for X.
                // For Y, we want it above the target.
                offset: Offset(0, -16),

                // Align Bottom-Left of preview to Top-Left of target.
                // Then we translate X using Transform.translate based on cursor position.
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,

                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: ValueListenableBuilder<double>(
                    valueListenable: _xOffset,
                    builder: (context, xOffset, child) {
                      return Transform.translate(
                        offset: Offset(xOffset, 0),
                        child: _buildPreviewCard(context),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              if (widget.onTap != null) {
                widget.onTap!();
              } else {
                launchUrl(Uri.parse(widget.url));
              }
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    // Determine if it's a network image or asset
    final previewUrl = _getPreviewUrl();
    final isAsset = widget.isStatic && !previewUrl.startsWith('http');

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: isAsset
          ? Image.asset(
              previewUrl,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
            )
          : CachedNetworkImage(
              imageUrl: previewUrl,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildErrorPlaceholder(),
            ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}
