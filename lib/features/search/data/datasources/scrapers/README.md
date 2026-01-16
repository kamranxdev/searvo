# Scraper System

A maintainable, modular web scraping system for extracting data from various websites including YouTube, TikTok, and Google Play Store.

## 📁 Architecture

```
scrapers/
├── base/                           # Base classes and interfaces
│   ├── base_scraper.dart          # Abstract base scraper class
│   └── scraper_models.dart        # Data models for all scrapers
├── sites/                          # Site-specific scrapers
│   ├── youtube/
│   │   └── youtube_scraper.dart   # YouTube video scraper
│   ├── tiktok/
│   │   └── tiktok_scraper.dart    # TikTok video scraper
│   └── playstore/
│       └── playstore_scraper.dart # Play Store app scraper
├── utils/
│   └── scraper_utils.dart         # Utility functions
├── scraper_manager.dart           # Central scraper orchestrator
└── README.md                       # This file
```

## 🎯 Features

### Base Features (All Scrapers)
- ✅ **Automatic retry logic** with exponential backoff
- ✅ **Built-in caching** with configurable TTL
- ✅ **Rate limiting** for batch operations
- ✅ **Concurrent scraping** with configurable limits
- ✅ **Error handling** with detailed error messages
- ✅ **Progress tracking** for batch operations

### Supported Sites

#### 1. YouTube (`youtube_scraper.dart`)
- Video metadata (title, description, channel)
- Statistics (views, likes, comments count)
- Video duration and publish date
- Tags and categories
- Thumbnail URLs
- Optional transcript extraction

**Supported Domains:**
- `youtube.com`
- `www.youtube.com`
- `m.youtube.com`
- `youtu.be`

#### 2. TikTok (`tiktok_scraper.dart`)
- Video description and hashtags
- User information (username, display name)
- Engagement metrics (likes, comments, shares, views)
- Music information
- Video and thumbnail URLs
- Create timestamp

**Supported Domains:**
- `tiktok.com`
- `www.tiktok.com`
- `vm.tiktok.com`

#### 3. Google Play Store (`playstore_scraper.dart`)
- App name and description
- Developer information
- Rating and reviews count
- Download count and category
- Price and in-app purchases
- Screenshots and icon
- Version and release date

**Supported Domains:**
- `play.google.com`

## 🚀 Usage

### Basic Usage

```dart
import 'package:searvo/features/search/scrapers/scraper_manager.dart';

// Initialize the manager
final scraperManager = ScraperManager();

// Scrape a single URL
final result = await scraperManager.scrape('https://www.youtube.com/watch?v=dQw4w9WgXcQ');

if (result != null && result.success) {
  print('✅ ${result.getSummary()}');
} else {
  print('❌ Scraping failed: ${result?.errorMessage}');
}
```

### Type-Safe Scraping

```dart
// YouTube
final youtubeResult = await scraperManager.scrapeYouTube(youtubeUrl);
if (youtubeResult != null) {
  print('Title: ${youtubeResult.title}');
  print('Views: ${youtubeResult.viewCount}');
  print('Channel: ${youtubeResult.channelName}');
}
```

### Batch Scraping

```dart
final urls = [
  'https://www.youtube.com/watch?v=VIDEO1',
  'https://www.tiktok.com/@user/video/...',
  'https://play.google.com/store/apps/details?id=...',
];

final results = await scraperManager.scrapeMultiple(
  urls,
  onProgress: (completed, total) {
    print('Progress: $completed/$total');
  },
);

// Process results
for (final result in results) {
  if (result.success) {
    if (result.isYouTube()) {
      final yt = result.asYouTube()!;
      print('YouTube: ${yt.title}');
    }
    // ... handle other types
  }
}
```

### Custom Configuration

```dart
import 'package:searvo/features/search/scrapers/base/scraper_models.dart';

final config = ScraperConfig(
  timeout: 30,                              // Request timeout in seconds
  maxRetries: 3,                            // Number of retry attempts
  useCache: true,                           // Enable caching
  cacheDuration: Duration(hours: 1),        // Cache TTL
  maxConcurrent: 5,                         // Max concurrent requests
  includeComments: true,                    // Include comments/reviews
  maxComments: 10,                          // Max comments to fetch
);

final manager = ScraperManager(defaultConfig: config);
```

## 🔧 Adding a New Scraper

### Step 1: Create Model in `scraper_models.dart`

```dart
class MyNewSiteResult extends ScraperResult {
  final String? title;
  final String? description;
  // Add your fields...

  MyNewSiteResult({
    required super.url,
    required super.success,
    super.errorMessage,
    this.title,
    this.description,
  });

  @override
  Map<String, dynamic> toJson() => {
    'url': url,
    'success': success,
    'title': title,
    'description': description,
  };

  @override
  String getSummary() => 'MyNewSite: $title';
}
```

### Step 2: Create Scraper Class

Create a new file: `sites/mynewsite/mynewsite_scraper.dart`

```dart
import '../../base/base_scraper.dart';
import '../../base/scraper_models.dart';

class MyNewSiteScraper extends BaseScraper<MyNewSiteResult> {
  MyNewSiteScraper({super.client, super.config});

  @override
  String get name => 'MyNewSite';

  @override
  List<String> get supportedDomains => ['mynewsite.com'];

  @override
  Future<MyNewSiteResult> scrape(String url) async {
    final cached = getFromCache(url);
    if (cached != null) return cached;

    final result = await retryOnFailure(url, () async {
      return await _performScrape(url);
    });

    storeInCache(url, result);
    return result;
  }

  Future<MyNewSiteResult> _performScrape(String url) async {
    // Your scraping logic here
    final response = await fetchWithTimeout(url);
    // Parse and extract data...
    
    return MyNewSiteResult(
      url: url,
      success: true,
      title: 'Extracted title',
      description: 'Extracted description',
    );
  }

  @override
  MyNewSiteResult createFailedResult(String url, String error) {
    return MyNewSiteResult(
      url: url,
      success: false,
      errorMessage: error,
    );
  }
}
```

### Step 3: Register in ScraperManager

Add to `scraper_manager.dart`:

```dart
import '../sites/mynewsite/mynewsite_scraper.dart';

void _initializeScrapers() {
  _scrapers.addAll([
    // ... existing scrapers
    MyNewSiteScraper(config: _defaultConfig),
  ]);
}
```

## 📊 Result Models

### Common Fields (All Results)
- `url`: Original URL that was scraped
- `success`: Whether the scraping succeeded
- `errorMessage`: Error details if failed
- `scrapedAt`: Timestamp of when scraping occurred
- `metadata`: Additional scraper-specific metadata

### Type Checking

```dart
if (result.isYouTube()) {
  // It's a YouTube result
  final yt = result.asYouTube()!;
}
```

## 🛡️ Error Handling

All scrapers implement robust error handling:

1. **Network errors**: Automatic retry with exponential backoff
2. **Parsing errors**: Graceful degradation with partial data
3. **Rate limiting**: Built-in delays between requests
4. **Timeout handling**: Configurable request timeouts

```dart
final result = await scraperManager.scrape(url);

if (!result.success) {
  print('Error: ${result.errorMessage}');
  // Handle error appropriately
}
```

## 🎨 Best Practices

### 1. Use Type-Safe Methods
```dart
// Good
final yt = await manager.scrapeYouTube(url);

// Avoid
final result = await manager.scrape(url);
final yt = result as YouTubeScraperResult; // Can fail at runtime
```

### 2. Handle Null Results
```dart
final result = await manager.scrapeYouTube(url);
if (result == null) {
  print('No scraper available for this URL');
  return;
}

if (!result.success) {
  print('Scraping failed: ${result.errorMessage}');
  return;
}

// Now safely use result
print(result.title);
```

### 3. Batch Operations for Multiple URLs
```dart
// Good - Uses internal batching and rate limiting
final results = await manager.scrapeMultiple(urls);

// Avoid - No rate limiting
for (final url in urls) {
  await manager.scrape(url);
}
```

### 4. Clear Cache When Needed
```dart
// Clear all caches
scraperManager.clearAllCaches();

// Or clear specific scraper cache
final scraper = scraperManager.getScraperForUrl(url);
scraper?.clearCache();
```

## 🔍 Utility Functions

Located in `utils/scraper_utils.dart`:

- `parseDuration()`: Parse various duration formats
- `parseViewCount()`: Parse abbreviated counts (1M, 100K)
- `cleanText()`: Clean HTML text
- `extractDomain()`: Extract domain from URL
- `normalizeUrl()`: Remove tracking parameters
- `parseDate()`: Parse various date formats

## 📝 Notes

### Anti-Scraping Measures
Some sites (especially TikTok) have anti-scraping measures. Consider:
- Using official APIs when available
- Implementing proxy rotation
- Adding delays between requests
- Respecting robots.txt

### Legal Considerations
- Always respect website terms of service
- Consider rate limiting to avoid server load
- Don't scrape personal/private data
- Cache results to minimize requests

### Performance Tips
- Use caching for frequently accessed URLs
- Batch similar requests together
- Configure appropriate timeout values
- Monitor memory usage for large batches

## 🚧 Future Enhancements

Potential additions:
- [ ] Instagram scraper
- [ ] Twitter/X scraper
- [ ] Reddit scraper
- [ ] LinkedIn scraper
- [ ] Amazon product scraper
- [ ] Wikipedia scraper
- [ ] Proxy support
- [ ] User-agent rotation
- [ ] JavaScript rendering (for dynamic sites)
- [ ] OCR for image-based content

## 📄 License

Part of the Searvo project.
