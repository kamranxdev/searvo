import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/theme/discover_theme.dart';

/// Editorial-style article card with vertical layout
/// Features image, category, headline, and excerpt with elegant hover effects
class EditorialArticleCard extends StatefulWidget {
  final Article article;

  const EditorialArticleCard({Key? key, required this.article})
    : super(key: key);

  @override
  State<EditorialArticleCard> createState() => _EditorialArticleCardState();
}

class _EditorialArticleCardState extends State<EditorialArticleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      // Tap handling is now done by the parent widget for proper routing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Container
          _ArticleImage(
            imageUrl: _cleanThumbnailUrl(widget.article.thumbnail),
            isHovered: _isHovered,
          ),
          const SizedBox(height: 20),
          // Category
          _ArticleCategory(),
          const SizedBox(height: 12),
          // Title
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: DiscoverTheme.sectionHeadline(
              context,
            ).copyWith(color: _isHovered ? colors.accent : colors.headline),
            child: Text(
              widget.article.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          // Excerpt
          Text(
            widget.article.content,
            style: DiscoverTheme.bodyText(context),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Read More Link
          _ReadMoreLink(isHovered: _isHovered),
        ],
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
}

// ===========================================================================
// ARTICLE IMAGE
// ===========================================================================

class _ArticleImage extends StatelessWidget {
  final String imageUrl;
  final bool isHovered;

  const _ArticleImage({required this.imageUrl, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
            blurRadius: isHovered ? 20 : 12,
            offset: Offset(0, isHovered ? 8 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: isHovered ? 1.05 : 1.0,
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
              // Subtle overlay on hover
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: isHovered
                    ? colors.accent.withOpacity(0.1)
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ARTICLE CATEGORY
// ===========================================================================

class _ArticleCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 2,
          color: DiscoverTheme.colors(context).accent,
        ),
        const SizedBox(width: 12),
        Text('STORY', style: DiscoverTheme.categoryLabel(context)),
      ],
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
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(isHovered ? 4 : 0, 0, 0),
          child: Icon(
            Icons.arrow_forward,
            size: 14,
            color: isHovered ? colors.accent : colors.caption,
          ),
        ),
      ],
    );
  }
}
