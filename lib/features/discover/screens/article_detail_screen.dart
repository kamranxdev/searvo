import 'package:flutter/material.dart';

import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/theme/discover_theme.dart';
import 'package:searvo/features/discover/widgets/article_responsive_layout.dart';
import 'package:searvo/features/discover/widgets/editorial_divider.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({Key? key, required this.article})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ArticleDetailContent(article: article);
  }
}

class _ArticleDetailContent extends StatelessWidget {
  final Article article;

  const _ArticleDetailContent({Key? key, required this.article})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Use the same standard MaxWidth 1400 logic for the outer shell on large screens
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: ArticleResponsiveLayout(
              mobile: _MobileLayout(article: article),
              tablet: _TabletLayout(article: article),
              desktop: _DesktopLayout(article: article),
            ),
          ),
        ),
      ),
    );
  }
}

// ... Mobile Layout similar to before but refined ...
class _MobileLayout extends StatelessWidget {
  final Article article;

  const _MobileLayout({required this.article});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return CustomScrollView(
      slivers: [
        ArticleAppBar(article: article),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: DiscoverTheme.heroHeadline(
                    context,
                  ).copyWith(fontSize: 32),
                ),
                const SizedBox(height: 24),
                ArticleMeta(colors: colors),
                const SizedBox(height: 32),
                const EditorialDivider(horizontalPadding: 0),
                const SizedBox(height: 32),
                ArticleBody(content: article.content),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ... Tablet Layout ...
class _TabletLayout extends StatelessWidget {
  final Article article;

  const _TabletLayout({required this.article});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return Column(
      children: [
        _DetailSimpleHeader(colors: colors),
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40.0,
                        horizontal: 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                article.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: colors.cardBackground),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            article.title,
                            style: DiscoverTheme.heroHeadline(
                              context,
                            ).copyWith(fontSize: 42),
                          ),
                          const SizedBox(height: 24),
                          ArticleMeta(colors: colors),
                          const SizedBox(height: 32),
                          const EditorialDivider(horizontalPadding: 0),
                          const SizedBox(height: 40),
                          ArticleBody(content: article.content, fontSize: 20),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ... Desktop Layout ...
class _DesktopLayout extends StatelessWidget {
  final Article article;

  const _DesktopLayout({required this.article});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return Column(
      children: [
        _DetailSimpleHeader(colors: colors),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content Column
              Flexible(
                flex: 2,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 60.0,
                            horizontal: 48.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 21 / 9,
                                  child: Image.network(
                                    article.thumbnail,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: colors.cardBackground),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 60),
                              Text(
                                article.title,
                                style: DiscoverTheme.heroHeadline(
                                  context,
                                ).copyWith(fontSize: 52),
                              ),
                              const SizedBox(height: 32),
                              ArticleMeta(colors: colors),
                              const SizedBox(height: 40),
                              const EditorialDivider(horizontalPadding: 0),
                              const SizedBox(height: 40),
                              ArticleBody(
                                content: article.content,
                                fontSize: 21,
                              ),
                              const SizedBox(height: 150),
                            ],
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
      ],
    );
  }
}

class _DetailSimpleHeader extends StatelessWidget {
  final DiscoverColors colors;
  const _DetailSimpleHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: colors.divider.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.headline),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.share_outlined, color: colors.caption),
            onPressed: () {},
            tooltip: 'Share',
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border, color: colors.caption),
            onPressed: () {},
            tooltip: 'Save',
          ),
        ],
      ),
    );
  }
}

// ... ArticleComponents (AppBar, Meta, AIInsights, Body) ...
// (Reusing the previous classes but refining them if needed)

class ArticleAppBar extends StatelessWidget {
  final Article article;
  const ArticleAppBar({required this.article});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.headline),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              article.thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: colors.cardBackground),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleMeta extends StatelessWidget {
  final DiscoverColors colors;
  const ArticleMeta({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colors.caption.withOpacity(0.2),
          child: Icon(Icons.person_outline, size: 16, color: colors.caption),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Searvo Editorial",
              style: TextStyle(
                color: colors.headline,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              "Oct 24, 2023 · 5 min read",
              style: TextStyle(color: colors.caption, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class ArticleBody extends StatelessWidget {
  final String content;
  final double fontSize;

  const ArticleBody({required this.content, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: DiscoverTheme.bodyText(context).copyWith(fontSize: fontSize),
    );
  }
}
