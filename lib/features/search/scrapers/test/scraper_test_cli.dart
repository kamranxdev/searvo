import 'dart:io';
import 'package:searvo/features/search/scrapers/scraper_manager.dart';
import 'package:searvo/features/search/scrapers/base/scraper_models.dart';

/// CLI tool for testing scrapers
/// Usage: dart run lib/features/search/scrapers/test/scraper_test_cli.dart
void main(List<String> args) async {
  print('🧪 Scraper Testing CLI');
  print('=' * 60);
  print('');

  // Test URLs for each scraper
  final testUrls = {
    'YouTube': [
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://youtu.be/jNQXAC9IVRw',
    ],
    'TikTok': [
      'https://www.tiktok.com/@tiktok/video/7106594312292453675',
    ],
    'PlayStore': [
      'https://play.google.com/store/apps/details?id=com.google.android.youtube',
      'https://play.google.com/store/apps/details?id=com.whatsapp',
    ],
    'Scholar': [
      'https://arxiv.org/abs/1706.03762',
      'https://pubmed.ncbi.nlm.nih.gov/12345678/',
      'https://scholar.google.com/scholar?q=machine+learning',
    ],
  };

  if (args.isEmpty) {
    print('📋 Available commands:');
    print('  test-all          - Test all scrapers');
    print('  test-youtube      - Test YouTube scraper');
    print('  test-tiktok       - Test TikTok scraper');
    print('  test-playstore    - Test Play Store scraper');
    print('  test-scholar      - Test Scholar scraper');
    print('  test-url <url>    - Test specific URL');
    print('  list-scrapers     - List all available scrapers');
    print('  benchmark         - Run performance benchmark');
    print('');
    print('Examples:');
    print('  dart run lib/features/search/scrapers/test/scraper_test_cli.dart test-all');
    print('  dart run lib/features/search/scrapers/test/scraper_test_cli.dart test-url "https://youtube.com/..."');
    return;
  }

  final command = args[0];
  final config = ScraperConfig(
    timeout: 30,
    maxRetries: 2,
    useCache: false, // Disable cache for testing
  );
  final manager = ScraperManager(defaultConfig: config);

  switch (command) {
    case 'test-all':
      await _testAll(manager, testUrls);
      break;
    case 'test-youtube':
      await _testScraper(manager, 'YouTube', testUrls['YouTube']!);
      break;
    case 'test-tiktok':
      await _testScraper(manager, 'TikTok', testUrls['TikTok']!);
      break;
    case 'test-playstore':
      await _testScraper(manager, 'PlayStore', testUrls['PlayStore']!);
      break;
    case 'test-scholar':
      await _testScraper(manager, 'Scholar', testUrls['Scholar']!);
      break;
    case 'test-url':
      if (args.length < 2) {
        print('❌ Please provide a URL');
        return;
      }
      await _testUrl(manager, args[1]);
      break;
    case 'list-scrapers':
      _listScrapers(manager);
      break;
    case 'benchmark':
      await _runBenchmark(manager, testUrls);
      break;
    default:
      print('❌ Unknown command: $command');
      print('Use without arguments to see available commands');
  }

  print('');
  print('✅ Testing completed!');
  exit(0);
}

Future<void> _testAll(ScraperManager manager, Map<String, List<String>> testUrls) async {
  print('🧪 Testing all scrapers...');
  print('');

  final stats = <String, Map<String, int>>{};

  for (final entry in testUrls.entries) {
    final scraperName = entry.key;
    final urls = entry.value;

    stats[scraperName] = {'total': urls.length, 'passed': 0, 'failed': 0};

    print('━' * 60);
    print('Testing $scraperName (${urls.length} URLs)');
    print('━' * 60);

    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      print('');
      print('Test ${i + 1}/${urls.length}: $url');
      
      try {
        final result = await manager.scrape(url);
        if (result != null && result.success) {
          stats[scraperName]!['passed'] = stats[scraperName]!['passed']! + 1;
          _printSuccessResult(result);
        } else {
          stats[scraperName]!['failed'] = stats[scraperName]!['failed']! + 1;
          print('❌ Failed: ${result?.errorMessage ?? "No result"}');
        }
      } catch (e) {
        stats[scraperName]!['failed'] = stats[scraperName]!['failed']! + 1;
        print('❌ Exception: $e');
      }

      // Rate limiting
      await Future.delayed(Duration(seconds: 2));
    }
  }

  // Print summary
  print('');
  print('=' * 60);
  print('📊 Test Summary');
  print('=' * 60);
  
  int totalPassed = 0;
  int totalTests = 0;

  for (final entry in stats.entries) {
    final name = entry.key;
    final stat = entry.value;
    final passed = stat['passed']!;
    final total = stat['total']!;
    
    totalPassed += passed;
    totalTests += total;
    
    final passRate = total > 0 ? (passed / total * 100).toStringAsFixed(1) : '0.0';
    final icon = passed == total ? '✅' : (passed > 0 ? '⚠️' : '❌');
    
    print('$icon $name: $passed/$total passed ($passRate%)');
  }

  print('');
  print('Overall: $totalPassed/$totalTests passed (${(totalPassed / totalTests * 100).toStringAsFixed(1)}%)');
}

Future<void> _testScraper(
  ScraperManager manager,
  String scraperName,
  List<String> urls,
) async {
  print('🧪 Testing $scraperName scraper with ${urls.length} URLs...');
  print('');

  for (var i = 0; i < urls.length; i++) {
    final url = urls[i];
    print('━' * 60);
    print('Test ${i + 1}/${urls.length}');
    print('URL: $url');
    print('━' * 60);

    try {
      final result = await manager.scrape(url);
      if (result != null && result.success) {
        _printSuccessResult(result);
      } else {
        print('❌ Failed: ${result?.errorMessage ?? "No result"}');
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
    }

    if (i < urls.length - 1) {
      print('');
      print('⏳ Waiting 2 seconds before next test...');
      await Future.delayed(Duration(seconds: 2));
      print('');
    }
  }
}

Future<void> _testUrl(ScraperManager manager, String url) async {
  print('🧪 Testing URL: $url');
  print('━' * 60);

  // Check if scraper is available
  final scraperInfo = manager.getScraperInfo(url);
  if (scraperInfo == null) {
    print('❌ No scraper available for this URL');
    print('');
    print('Supported domains:');
    for (final domain in manager.getSupportedDomains()) {
      print('  • $domain');
    }
    return;
  }

  print('Using scraper: ${scraperInfo['name']}');
  print('');

  try {
    final result = await manager.scrape(url);
    if (result != null && result.success) {
      _printSuccessResult(result);
    } else {
      print('❌ Failed: ${result?.errorMessage ?? "No result"}');
    }
  } catch (e, stackTrace) {
    print('❌ Exception: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
  }
}

void _printSuccessResult(ScraperResult result) {
  print('✅ Success!');
  print('');
  print('Summary: ${result.getSummary()}');
  print('');

  if (result is YouTubeScraperResult) {
    _printYouTubeResult(result);
  } else if (result is TikTokScraperResult) {
    _printTikTokResult(result);
  } else if (result is PlayStoreScraperResult) {
    _printPlayStoreResult(result);
  } else if (result is ScholarScraperResult) {
    _printScholarResult(result);
  }

  print('');
  print('📄 Metadata:');
  if (result.metadata != null) {
    for (final entry in result.metadata!.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
  }
  print('  Scraped at: ${result.scrapedAt}');
}

void _printYouTubeResult(YouTubeScraperResult result) {
  print('📺 YouTube Video Details:');
  print('  Video ID: ${result.videoId ?? "N/A"}');
  print('  Title: ${result.title ?? "N/A"}');
  print('  Channel: ${result.channelName ?? "N/A"} (${result.channelId ?? "N/A"})');
  print('  Duration: ${result.duration ?? "N/A"}');
  print('  Published: ${result.publishedAt ?? "N/A"}');
  print('');
  print('📊 Statistics:');
  print('  Views: ${_formatNumber(result.viewCount)}');
  print('  Likes: ${_formatNumber(result.likeCount)}');
  print('');
  if (result.description != null && result.description!.isNotEmpty) {
    print('📝 Description:');
    print('  ${_truncate(result.description!, 200)}');
    print('');
  }
  if (result.tags != null && result.tags!.isNotEmpty) {
    print('🏷️ Tags: ${result.tags!.take(5).join(", ")}${result.tags!.length > 5 ? "..." : ""}');
    print('');
  }
  if (result.thumbnailUrl != null) {
    print('🖼️ Thumbnail: ${result.thumbnailUrl}');
  }
}

void _printTikTokResult(TikTokScraperResult result) {
  print('🎵 TikTok Video Details:');
  print('  Video ID: ${result.videoId ?? "N/A"}');
  print('  User: @${result.username ?? "N/A"} (${result.userDisplayName ?? "N/A"})');
  print('  Created: ${result.createTime ?? "N/A"}');
  print('');
  print('📊 Engagement:');
  print('  Views: ${_formatNumber(result.viewCount)}');
  print('  Likes: ${_formatNumber(result.likeCount)}');
  print('  Comments: ${_formatNumber(result.commentCount)}');
  print('  Shares: ${_formatNumber(result.shareCount)}');
  print('');
  if (result.description != null && result.description!.isNotEmpty) {
    print('📝 Description:');
    print('  ${_truncate(result.description!, 200)}');
    print('');
  }
  if (result.hashtags != null && result.hashtags!.isNotEmpty) {
    print('🏷️ Hashtags: #${result.hashtags!.join(" #")}');
    print('');
  }
  if (result.musicName != null) {
    print('🎵 Music: ${result.musicName} by ${result.musicAuthor ?? "Unknown"}');
    print('');
  }
  if (result.thumbnailUrl != null) {
    print('🖼️ Thumbnail: ${result.thumbnailUrl}');
  }
}

void _printPlayStoreResult(PlayStoreScraperResult result) {
  print('📱 Play Store App Details:');
  print('  App ID: ${result.appId ?? "N/A"}');
  print('  Name: ${result.appName ?? "N/A"}');
  print('  Developer: ${result.developer ?? "N/A"}');
  print('  Category: ${result.category ?? "N/A"}');
  print('  Price: ${result.price ?? "N/A"}');
  print('');
  print('⭐ Ratings:');
  print('  Rating: ${result.rating ?? "N/A"} / 5.0');
  print('  Reviews: ${_formatNumber(result.ratingsCount)}');
  print('  Downloads: ${_formatNumber(result.downloadCount)}');
  print('');
  print('ℹ️ Info:');
  print('  Version: ${result.version ?? "N/A"}');
  print('  Size: ${result.size ?? "N/A"}');
  print('  Contains Ads: ${result.containsAds ?? "N/A"}');
  print('  Content Rating: ${result.contentRating ?? "N/A"}');
  print('  Released: ${result.releaseDate ?? "N/A"}');
  print('');
  if (result.shortDescription != null && result.shortDescription!.isNotEmpty) {
    print('📝 Description:');
    print('  ${_truncate(result.shortDescription!, 200)}');
    print('');
  }
  if (result.iconUrl != null) {
    print('🖼️ Icon: ${result.iconUrl}');
  }
  if (result.screenshotUrls != null && result.screenshotUrls!.isNotEmpty) {
    print('📸 Screenshots: ${result.screenshotUrls!.length} available');
  }
}

void _printScholarResult(ScholarScraperResult result) {
  print('📚 Scholar Article Details:');
  print('  Title: ${result.title ?? "N/A"}');
  if (result.authors != null && result.authors!.isNotEmpty) {
    print('  Authors: ${result.authors!.join(", ")}');
  }
  print('  DOI: ${result.doi ?? "N/A"}');
  if (result.publishedDate != null) {
    print('  Published: ${result.publishedDate}');
  }
  if (result.year != null) {
    print('  Year: ${result.year}');
  }
  print('');
  if (result.abstract != null && result.abstract!.isNotEmpty) {
    print('📝 Abstract:');
    print('  ${_truncate(result.abstract!, 300)}');
    print('');
  }
  if (result.keywords != null && result.keywords!.isNotEmpty) {
    print('🏷️ Keywords: ${result.keywords!.join(", ")}');
    print('');
  }
  print('📊 Metrics:');
  print('  Citations: ${result.citationCount ?? "N/A"}');
  print('');
  if (result.pdfUrl != null) {
    print('📄 PDF: ${result.pdfUrl}');
  }
  if (result.journal != null) {
    print('📖 Journal: ${result.journal}');
  }
  if (result.venue != null) {
    print('📍 Venue: ${result.venue}');
  }
  if (result.references != null && result.references!.isNotEmpty) {
    print('📚 References: ${result.references!.length} cited');
  }
}

void _listScrapers(ScraperManager manager) {
  print('📋 Available Scrapers:');
  print('');
  
  final scrapers = manager.getAvailableScrapers();
  for (final scraper in scrapers) {
    print('  ✓ $scraper');
  }

  print('');
  print('🌐 Supported Domains:');
  print('');
  
  final domains = manager.getSupportedDomains();
  for (final domain in domains) {
    print('  • $domain');
  }
}

Future<void> _runBenchmark(
  ScraperManager manager,
  Map<String, List<String>> testUrls,
) async {
  print('⚡ Running performance benchmark...');
  print('');

  final benchmarks = <String, Duration>{};

  for (final entry in testUrls.entries) {
    final scraperName = entry.key;
    final url = entry.value.first;

    print('Testing $scraperName...');
    
    final stopwatch = Stopwatch()..start();
    try {
      await manager.scrape(url);
      stopwatch.stop();
      benchmarks[scraperName] = stopwatch.elapsed;
      print('  ✓ ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      print('  ✗ Failed after ${stopwatch.elapsedMilliseconds}ms');
    }

    await Future.delayed(Duration(seconds: 1));
  }

  print('');
  print('📊 Benchmark Results:');
  print('━' * 60);
  
  final sorted = benchmarks.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));

  for (final entry in sorted) {
    final name = entry.key.padRight(15);
    final ms = entry.value.inMilliseconds;
    print('  $name : ${ms}ms');
  }
}

String _formatNumber(int? number) {
  if (number == null) return 'N/A';
  if (number >= 1000000000) {
    return '${(number / 1000000000).toStringAsFixed(1)}B';
  } else if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}
