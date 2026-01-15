import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/theme/discover_theme.dart';

/// Editorial-style compact card for horizontal layouts and lists
/// Features a horizontal layout with thumbnail, headline, and excerpt
class EditorialCompactCard extends StatefulWidget {
  final Article article;

  const EditorialCompactCard({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  State<EditorialCompactCard> createState() => _EditorialCompactCardState();
}

class _EditorialCompactCardState extends State<EditorialCompactCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openArticle(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? colors.cardBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? colors.divider : Colors.transparent,
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              
              if (isNarrow) {
                return _buildVerticalLayout(context, colors);
              }
              return _buildHorizontalLayout(context, colors);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, DiscoverColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        _CompactThumbnail(
          imageUrl: _cleanThumbnailUrl(widget.article.thumbnail),
          isHovered: _isHovered,
        ),
        const SizedBox(width: 24),
        // Content
        Expanded(
          child: _CompactContent(
            article: widget.article,
            isHovered: _isHovered,
          ),
        ),
        // Arrow indicator on desktop
        _ArrowIndicator(isHovered: _isHovered),
      ],
    );
  }

  Widget _buildVerticalLayout(BuildContext context, DiscoverColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thumbnail (full width for mobile)
        _MobileThumbnail(
          imageUrl: _cleanThumbnailUrl(widget.article.thumbnail),
          isHovered: _isHovered,
        ),
        const SizedBox(height: 16),
        // Content
        _CompactContent(
          article: widget.article,
          isHovered: _isHovered,
          showReadMore: true,
        ),
      ],
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
// COMPACT THUMBNAIL
// ===========================================================================

class _CompactThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isHovered;

  const _CompactThumbnail({
    required this.imageUrl,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isHovered ? 0.12 : 0.06),
            blurRadius: isHovered ? 12 : 6,
            offset: Offset(0, isHovered ? 4 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isHovered ? 1.05 : 1.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colors.divider,
                ),
                errorWidget: (context, url, error) => Container(
                  color: colors.divider,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 24,
                    color: colors.caption,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// MOBILE THUMBNAIL
// ===========================================================================

class _MobileThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isHovered;

  const _MobileThumbnail({
    required this.imageUrl,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: colors.divider,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.caption),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: colors.divider,
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 32,
              color: colors.caption,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// COMPACT CONTENT
// ===========================================================================

class _CompactContent extends StatelessWidget {
  final Article article;
  final bool isHovered;
  final bool showReadMore;

  const _CompactContent({
    required this.article,
    required this.isHovered,
    this.showReadMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: DiscoverTheme.cardHeadline(context).copyWith(
            color: isHovered ? colors.accent : colors.headline,
          ),
          child: Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        // Excerpt
        Text(
          article.content,
          style: DiscoverTheme.bodyText(context).copyWith(
            fontSize: 14,
            height: 1.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (showReadMore) ...[
          const SizedBox(height: 12),
          _ReadMoreLink(isHovered: isHovered),
        ],
      ],
    );
  }
}

// ===========================================================================
// ARROW INDICATOR
// ===========================================================================

class _ArrowIndicator extends StatelessWidget {
  final bool isHovered;

  const _ArrowIndicator({required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isHovered ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(isHovered ? 0 : -8, 0, 0),
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 20,
          color: colors.accent,
        ),
      ),
    );
  }
}

// ===========================================================================
// READ MORE LINK
// ===========================================================================

class _ReadMoreLink extends StatelessWidget {
  final bool isHovered;

  const _ReadMoreLink({required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return Row(
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: DiscoverTheme.caption(context).copyWith(
            color: isHovered ? colors.accent : colors.caption,
            fontWeight: FontWeight.w600,
          ),
          child: const Text('READ MORE'),
        ),
        const SizedBox(width: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(isHovered ? 4 : 0, 0, 0),
          child: Icon(
            Icons.arrow_forward,
            size: 12,
            color: isHovered ? colors.accent : colors.caption,
          ),
        ),
      ],
    );
  }
}
