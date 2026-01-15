import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/theme/discover_theme.dart';

/// Editorial-style hero card for featured articles
/// Features immersive image with gradient overlay and elegant typography
class EditorialHeroCard extends StatefulWidget {
  final Article article;
  final bool isCompact;

  const EditorialHeroCard({
    Key? key,
    required this.article,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<EditorialHeroCard> createState() => _EditorialHeroCardState();
}

class _EditorialHeroCardState extends State<EditorialHeroCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final heroHeight = widget.isCompact ? 320.0 : 480.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openArticle(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          height: heroHeight,
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.005))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 32 : 16,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                _HeroImage(
                  imageUrl: _cleanThumbnailUrl(widget.article.thumbnail),
                  isHovered: _isHovered,
                ),
                // Gradient Overlay
                _GradientOverlay(isHovered: _isHovered),
                // Content
                _HeroContent(
                  article: widget.article,
                  isCompact: widget.isCompact,
                  isHovered: _isHovered,
                ),
                // Hover Indicator
                if (_isHovered) _ReadIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cleanThumbnailUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final id = uri.queryParameters['id'];
      if (id != null) {
        return '${uri.origin}${uri.path}?id=$id';
      }
      return url;
    } catch (e) {
      return url;
    }
  }

  Future<void> _openArticle(BuildContext context) async {
    final searchQuery = 'Summary: ${widget.article.url}';
    Navigator.pushNamed(context, '/', arguments: {'query': searchQuery});
  }
}

// ===========================================================================
// HERO IMAGE
// ===========================================================================

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final bool isHovered;

  const _HeroImage({
    required this.imageUrl,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 500),
      scale: isHovered ? 1.05 : 1.0,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _ImagePlaceholder(),
        errorWidget: (context, url, error) => _ImageError(),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return Container(
      color: colors.divider,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(colors.caption),
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return Container(
      color: colors.divider,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: colors.caption,
        ),
      ),
    );
  }
}

// ===========================================================================
// GRADIENT OVERLAY
// ===========================================================================

class _GradientOverlay extends StatelessWidget {
  final bool isHovered;

  const _GradientOverlay({required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(isHovered ? 0.85 : 0.75),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
    );
  }
}

// ===========================================================================
// HERO CONTENT
// ===========================================================================

class _HeroContent extends StatelessWidget {
  final Article article;
  final bool isCompact;
  final bool isHovered;

  const _HeroContent({
    required this.article,
    required this.isCompact,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isCompact ? 24 : 40,
      right: isCompact ? 24 : 40,
      bottom: isCompact ? 24 : 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Badge
          _CategoryBadge(label: 'FEATURED'),
          SizedBox(height: isCompact ? 12 : 16),
          // Title
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: DiscoverTheme.heroHeadlineLight(context).copyWith(
              fontSize: isCompact ? 28 : 36,
            ),
            child: Text(
              article.title,
              maxLines: isCompact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          // Description
          Text(
            article.content,
            style: DiscoverTheme.bodyTextLight(context),
            maxLines: isCompact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CATEGORY BADGE
// ===========================================================================

class _CategoryBadge extends StatelessWidget {
  final String label;

  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDAA520).withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ===========================================================================
// READ INDICATOR
// ===========================================================================

class _ReadIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'READ STORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
