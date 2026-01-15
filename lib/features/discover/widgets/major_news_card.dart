import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme_extensions.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';

class MajorNewsCard extends StatefulWidget {
  final Article article;
  final bool isLeft;

  const MajorNewsCard({
    Key? key,
    required this.article,
    this.isLeft = true,
  }) : super(key: key);

  @override
  State<MajorNewsCard> createState() => _MajorNewsCardState();
}

class _MajorNewsCardState extends State<MajorNewsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => _openArticle(context),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isHovered
                ? context.colorScheme.surfaceContainerHighest
                : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: widget.isLeft
                ? [
                    _buildImage(context),
                    const SizedBox(width: 32),
                    Expanded(child: _buildContent(context, isDark)),
                  ]
                : [
                    Expanded(child: _buildContent(context, isDark)),
                    const SizedBox(width: 32),
                    _buildImage(context),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 340,
        height: 240,
        child: Image.network(
          _cleanThumbnailUrl(widget.article.thumbnail),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, size: 50),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.article.title,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w300,
              height: 1.2,
              fontFamily: 'PP Editorial',
              letterSpacing: -0.5,
              color: context.colorScheme.onSurface,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            widget.article.content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              letterSpacing: 0.2,
              color: context.colorScheme.onSurfaceVariant,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
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

  Future<void> _openArticle(BuildContext context) async {
    // Create a search query with the article URL for summary
    final searchQuery = 'Summary: ${widget.article.url}';
    
    // Navigate to home screen with search query
    Navigator.pushNamed(
      context,
      '/',
      arguments: {'query': searchQuery},
    );
  }
}
