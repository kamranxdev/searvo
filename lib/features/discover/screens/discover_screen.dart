import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/core/di/injection_container.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:searvo/features/discover/presentation/cubit/discover_state.dart';
import 'package:searvo/features/discover/theme/discover_theme.dart';
import 'package:searvo/features/discover/widgets/editorial_hero_card.dart';
import 'package:searvo/features/discover/widgets/editorial_article_card.dart';
import 'package:searvo/features/discover/widgets/editorial_compact_card.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DiscoverCubit>()..loadArticles(DiscoverTopic.tech),
      child: const _DiscoverScreenContent(),
    );
  }
}

class _DiscoverScreenContent extends StatefulWidget {
  const _DiscoverScreenContent({Key? key}) : super(key: key);

  @override
  State<_DiscoverScreenContent> createState() => _DiscoverScreenContentState();
}

class _DiscoverScreenContentState extends State<_DiscoverScreenContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShowElevation = _scrollController.offset > 10;
    if (shouldShowElevation != _isScrolled) {
      setState(() => _isScrolled = shouldShowElevation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<DiscoverCubit, DiscoverState>(
          builder: (context, state) {
            return state.when(
              initial: () => _buildLoading(DiscoverTopic.tech),
              loading: () => _buildLoading(DiscoverTopic.tech),
              error: (failure) => _buildError(failure.message),
              loaded: (articles, currentTopic) {
                if (articles.isEmpty) {
                  return _buildEmpty(currentTopic);
                }
                return _buildContent(articles, currentTopic);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading(DiscoverTopic topic) {
    final colors = DiscoverTheme.colors(context);
    return Column(
      children: [
        _EditorialMasthead(
          currentTopic: topic,
          isScrolled: _isScrolled,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colors.accent),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CURATING STORIES',
                  style: DiscoverTheme.caption(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    final colors = DiscoverTheme.colors(context);
    return Column(
      children: [
        _EditorialMasthead(
          currentTopic: DiscoverTopic.tech,
          isScrolled: _isScrolled,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: colors.caption,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unable to Load Stories',
                    style: DiscoverTheme.sectionHeadline(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: DiscoverTheme.bodyText(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _RetryButton(
                    onPressed: () {
                      context.read<DiscoverCubit>().refreshArticles();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(DiscoverTopic topic) {
    final colors = DiscoverTheme.colors(context);
    return Column(
      children: [
        _EditorialMasthead(
          currentTopic: topic,
          isScrolled: _isScrolled,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 48,
                  color: colors.caption,
                ),
                const SizedBox(height: 20),
                Text(
                  'No Stories Available',
                  style: DiscoverTheme.sectionHeadline(context),
                ),
                const SizedBox(height: 12),
                Text(
                  'Check back later for new content',
                  style: DiscoverTheme.bodyText(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<Article> articles, DiscoverTopic currentTopic) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 1024;
        final isMediumScreen = constraints.maxWidth >= 600;

        if (isWideScreen) {
          return _buildDesktopLayout(articles, currentTopic);
        } else if (isMediumScreen) {
          return _buildTabletLayout(articles, currentTopic);
        } else {
          return _buildMobileLayout(articles, currentTopic);
        }
      },
    );
  }

  Widget _buildDesktopLayout(List<Article> articles, DiscoverTopic currentTopic) {
    final colors = DiscoverTheme.colors(context);

    return RefreshIndicator(
      onRefresh: () => context.read<DiscoverCubit>().refreshArticles(),
      color: colors.accent,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _EditorialMasthead(
              currentTopic: currentTopic,
              isScrolled: _isScrolled,
            ),
          ),
          // Hero Section
          if (articles.isNotEmpty)
            SliverToBoxAdapter(
              child: _HeroSection(article: articles.first),
            ),
          // Editorial Divider
          SliverToBoxAdapter(child: _EditorialDivider()),
          // Section Title
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Latest Stories'),
          ),
          // Featured Articles Grid
          SliverToBoxAdapter(
            child: _FeaturedGrid(
              articles: articles.skip(1).take(3).toList(),
            ),
          ),
          // More Stories
          if (articles.length > 4) ...[
            SliverToBoxAdapter(child: _EditorialDivider()),
            SliverToBoxAdapter(
              child: _SectionTitle(title: 'More to Explore'),
            ),
            SliverToBoxAdapter(
              child: _CompactStoriesSection(
                articles: articles.skip(4).toList(),
              ),
            ),
          ],
          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(List<Article> articles, DiscoverTopic currentTopic) {
    final colors = DiscoverTheme.colors(context);

    return RefreshIndicator(
      onRefresh: () => context.read<DiscoverCubit>().refreshArticles(),
      color: colors.accent,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _EditorialMasthead(
              currentTopic: currentTopic,
              isScrolled: _isScrolled,
            ),
          ),
          // Hero Section
          if (articles.isNotEmpty)
            SliverToBoxAdapter(
              child: _HeroSection(article: articles.first, isCompact: true),
            ),
          // Editorial Divider
          SliverToBoxAdapter(child: _EditorialDivider()),
          // Articles Grid
          if (articles.length > 1)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 32,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final articleIndex = index + 1;
                    if (articleIndex >= articles.length) return const SizedBox.shrink();
                    return EditorialArticleCard(article: articles[articleIndex]);
                  },
                  childCount: articles.length - 1,
                ),
              ),
            ),
          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<Article> articles, DiscoverTopic currentTopic) {
    final colors = DiscoverTheme.colors(context);

    return RefreshIndicator(
      onRefresh: () => context.read<DiscoverCubit>().refreshArticles(),
      color: colors.accent,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _EditorialMasthead(
              currentTopic: currentTopic,
              isScrolled: _isScrolled,
              isMobile: true,
            ),
          ),
          // Hero Card
          if (articles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: EditorialHeroCard(article: articles.first),
              ),
            ),
          // Section Divider
          SliverToBoxAdapter(
            child: _EditorialDivider(horizontalPadding: 16),
          ),
          // Article List
          if (articles.length > 1)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final articleIndex = index + 1;
                    if (articleIndex >= articles.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: EditorialCompactCard(article: articles[articleIndex]),
                    );
                  },
                  childCount: articles.length - 1,
                ),
              ),
            ),
          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// EDITORIAL MASTHEAD
// ===========================================================================

class _EditorialMasthead extends StatelessWidget {
  final DiscoverTopic currentTopic;
  final bool isScrolled;
  final bool isMobile;

  const _EditorialMasthead({
    required this.currentTopic,
    this.isScrolled = false,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isScrolled ? colors.divider : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: isMobile ? 20 : 28,
          ),
          child: Column(
            children: [
              // Masthead Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo & Title
                  Row(
                    children: [
                      _MastheadLogo(colors: colors),
                      SizedBox(width: isMobile ? 12 : 16),
                      Text(
                        'Discover',
                        style: isMobile
                            ? DiscoverTheme.sectionHeadline(context)
                            : DiscoverTheme.mastheadTitle(context),
                      ),
                    ],
                  ),
                  // Refresh Button
                  _RefreshButton(
                    onPressed: () {
                      context.read<DiscoverCubit>().refreshArticles();
                    },
                    colors: colors,
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 24),
              // Topic Navigation
              _TopicNavigation(
                currentTopic: currentTopic,
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MastheadLogo extends StatelessWidget {
  final DiscoverColors colors;

  const _MastheadLogo({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: colors.accent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'D',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.accent,
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatefulWidget {
  final VoidCallback onPressed;
  final DiscoverColors? colors;

  const _RefreshButton({required this.onPressed, this.colors});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? DiscoverTheme.colors(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered ? colors.accent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.refresh_rounded,
            size: 22,
            color: _isHovered ? colors.accent : colors.caption,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// TOPIC NAVIGATION
// ===========================================================================

class _TopicNavigation extends StatelessWidget {
  final DiscoverTopic currentTopic;
  final bool isMobile;

  const _TopicNavigation({
    required this.currentTopic,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DiscoverTopic.values.map((topic) {
          final isActive = currentTopic == topic;
          return Padding(
            padding: EdgeInsets.only(right: isMobile ? 20 : 32),
            child: _TopicChip(
              topic: topic,
              isActive: isActive,
              onTap: () {
                context.read<DiscoverCubit>().loadArticles(topic);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopicChip extends StatefulWidget {
  final DiscoverTopic topic;
  final bool isActive;
  final VoidCallback onTap;

  const _TopicChip({
    required this.topic,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TopicChip> createState() => _TopicChipState();
}

class _TopicChipState extends State<_TopicChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? colors.accent
                    : (_isHovered ? colors.caption : Colors.transparent),
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.topic.displayName.toUpperCase(),
            style: DiscoverTheme.navItem(context, isActive: widget.isActive),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// HERO SECTION
// ===========================================================================

class _HeroSection extends StatelessWidget {
  final Article article;
  final bool isCompact;

  const _HeroSection({
    required this.article,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: EditorialHeroCard(
          article: article,
          isCompact: isCompact,
        ),
      ),
    );
  }
}

// ===========================================================================
// SECTION TITLE
// ===========================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: DiscoverTheme.categoryLabel(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// FEATURED GRID
// ===========================================================================

class _FeaturedGrid extends StatelessWidget {
  final List<Article> articles;

  const _FeaturedGrid({required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 64) / 3; // 32px gap * 2
            return Wrap(
              spacing: 32,
              runSpacing: 32,
              children: [
                for (final article in articles)
                  SizedBox(
                    width: itemWidth,
                    child: EditorialArticleCard(article: article),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ===========================================================================
// COMPACT STORIES SECTION
// ===========================================================================

class _CompactStoriesSection extends StatelessWidget {
  final List<Article> articles;

  const _CompactStoriesSection({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < articles.length; i++) ...[
              if (i > 0) _CompactDivider(),
              EditorialCompactCard(article: articles[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 1,
      color: colors.divider.withOpacity(0.5),
    );
  }
}

// ===========================================================================
// EDITORIAL DIVIDER
// ===========================================================================

class _EditorialDivider extends StatelessWidget {
  final double horizontalPadding;

  const _EditorialDivider({this.horizontalPadding = 32});

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        margin: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 32,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      colors.divider,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                Icons.diamond_outlined,
                size: 12,
                color: colors.accent,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.divider,
                      Colors.transparent,
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
}

// ===========================================================================
// RETRY BUTTON
// ===========================================================================

class _RetryButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _RetryButton({required this.onPressed});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? colors.accent : Colors.transparent,
            border: Border.all(color: colors.accent, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'TRY AGAIN',
            style: DiscoverTheme.navItem(context, isActive: true).copyWith(
              color: _isHovered ? Colors.white : colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
