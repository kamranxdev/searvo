import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';

/// Perplexity-style citation popup that appears when user taps a citation [1]
class CitationPopup extends StatelessWidget {
  final SourceItem source;
  final int citationNumber;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenSource;

  const CitationPopup({
    super.key,
    required this.source,
    required this.citationNumber,
    required this.onDismiss,
    this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SearchTheme.colors(context);

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss when tapping popup
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with citation number and close button
                  _buildHeader(colors),

                  // Source preview
                  _buildSourcePreview(colors),

                  // Source info
                  _buildSourceInfo(colors),

                  // Snippet/description
                  if (source.description.isNotEmpty) _buildSnippet(colors),

                  // Action buttons
                  _buildActions(colors, context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SearchColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          // Citation badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemeConfig.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '[$citationNumber]',
              style: TextStyle(
                color: AppThemeConfig.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Source',
              style: TextStyle(
                color: colors.caption,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          // Close button
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, size: 20, color: colors.caption),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePreview(SearchColors colors) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: _getScreenshotUrl(source.url),
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Container(
          color: colors.inputBackground,
          child: Center(
            child: Icon(Icons.public, color: colors.caption, size: 32),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: colors.inputBackground,
          child: Center(
            child: Icon(Icons.public, color: colors.caption, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceInfo(SearchColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            source.title,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Domain row
          Row(
            children: [
              // Favicon
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl:
                      source.favicon ??
                      'https://www.google.com/s2/favicons?domain=${source.domain}&sz=32',
                  width: 16,
                  height: 16,
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.public, size: 16, color: colors.caption),
                ),
              ),
              const SizedBox(width: 8),
              // Domain
              Expanded(
                child: Text(
                  source.domain,
                  style: TextStyle(
                    color: colors.caption,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Date if available
              if (source.publishedDate != null) ...[
                const SizedBox(width: 8),
                Text(
                  _formatDate(source.publishedDate!),
                  style: TextStyle(
                    color: colors.caption.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnippet(SearchColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.background.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withOpacity(0.3)),
        ),
        child: Text(
          source.description,
          style: TextStyle(
            color: colors.text.withOpacity(0.85),
            fontSize: 13,
            height: 1.5,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActions(SearchColors colors, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Open source button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                onOpenSource?.call();
                _launchUrl(source.url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text(
                'Open Source',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Copy URL button
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () {
                // Copy URL to clipboard
                // Clipboard.setData(ClipboardData(text: source.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(Icons.copy, size: 20, color: colors.caption),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  String _getScreenshotUrl(String url) {
    final encodedUrl = Uri.encodeComponent(url);
    return 'https://api.microlink.io/?url=$encodedUrl&screenshot=true&meta=false&embed=screenshot.url';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Show citation popup as an overlay
void showCitationPopup(
  BuildContext context,
  SourceItem source,
  int citationNumber,
) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => CitationPopup(
      source: source,
      citationNumber: citationNumber,
      onDismiss: () => entry.remove(),
      onOpenSource: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}
