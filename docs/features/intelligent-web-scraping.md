# RAG System Enhancement: Intelligent Web Scraping

## Overview
The RAG (Retrieval-Augmented Generation) system has been enhanced with intelligent web scraping capabilities. Instead of using a generic web scraper for all URLs, the system now automatically detects the URL type and routes it to the appropriate specialized scraper, with a fallback to a generic scraper for unsupported sites.

## Architecture Changes

### Before
```
RAG System → WebScraperService (generic scraping only)
```

### After
```
RAG System → RAGScraperAdapter → ScraperManager → [Specialized Scrapers + Generic Fallback]
                                                    ├── YouTubeScraper
                                                    ├── TikTokScraper
                                                    ├── PlayStoreScraper
                                                    ├── ScholarScraper
                                                    └── GenericWebScraper (fallback)
```

## Components

### 1. ScraperManager (`lib/features/search/scrapers/scraper_manager.dart`)
**Enhanced with:**
- Automatic URL detection and routing
- Generic web scraper as fallback for unsupported URLs
- Always returns a scraper (no null checks needed)

### 2. GenericWebScraper (`lib/features/search/scrapers/sites/generic/generic_web_scraper.dart`)
**New component** - Replaces the old `WebScraperService`
- Implements `BaseScraper` interface for consistency
- Handles any HTTP/HTTPS URL that doesn't have a specialized scraper
- Provides same functionality as old `WebScraperService`:
  - Content extraction using readability algorithm
  - Metadata extraction (title, author, date, etc.)
  - Image and link extraction
  - Readability scoring
  - Caching support

### 3. RAGScraperAdapter (`lib/features/search/rag/services/data_ingestion/rag_scraper_adapter.dart`)
**New bridge component**
- Converts `ScraperResult` objects to RAG `Document` format
- Handles different scraper result types:
  - `GenericScraperResult` → Generic web content
  - `YouTubeScraperResult` → YouTube videos with transcripts
  - `TikTokScraperResult` → TikTok videos
  - `PlayStoreScraperResult` → Play Store apps
- Maintains document cache for performance
- Provides consistent interface for RAG system

### 4. ScraperConfig (`lib/features/search/scrapers/base/scraper_models.dart`)
**Enhanced with:**
- `includeImages`: Control image extraction
- `includeLinks`: Control link extraction
- Consistent configuration across all scrapers

## Benefits

### 1. Specialized Content Extraction
- **YouTube**: Extracts video metadata, transcripts, comments
- **TikTok**: Extracts video info, hashtags, engagement metrics
- **Play Store**: Extracts app details, ratings, reviews
- **Scholar**: Extracts academic papers, citations, abstracts, DOIs
- **Generic**: Handles all other websites with clean content extraction

### 2. Intelligent Routing
```dart
// Automatic detection and routing
final result = await scraperManager.scrape('https://youtube.com/watch?v=...');
// → Routes to YouTubeScraper

final result = await scraperManager.scrape('https://arxiv.org/abs/2301.12345');
// → Routes to ScholarScraper

final result = await scraperManager.scrape('https://example.com/article');
// → Routes to GenericWebScraper
```

### 3. Rich Metadata
Each scraper provides domain-specific metadata:
```dart
// YouTube
metadata: {
  'scraperType': 'youtube',
  'videoId': '...',
  'viewCount': 123456,
  'hasTranscript': true,
}

// Scholar
metadata: {
  'scraperType': 'scholar',
  'authors': ['John Doe', 'Jane Smith'],
  'citationCount': 42,
  'doi': '10.1234/example',
  'pdfUrl': 'https://arxiv.org/pdf/...',
}

// Generic
metadata: {
  'scraperType': 'generic',
  'wordCount': 1500,
  'readabilityScore': '75.3',
  'author': 'John Doe',
}
```

### 4. Consistent RAG Integration
All scraper results are converted to uniform `Document` objects:
```dart
final documents = await scraperAdapter.scrapeMultiple(urls);
// All documents have consistent structure regardless of source
```

## Usage Examples

### RAG Orchestrator (Automatic)
```dart
// Automatically uses intelligent scraping
final response = await ragOrchestrator.generateRAGResponse(
  'Explain this YouTube video',
  // URLs from search results are automatically routed
);
```

### Direct Scraping
```dart
// Via RAG adapter
final document = await ragScraperAdapter.scrape(
  'https://example.com/article',
  relevanceScore: 0.95,
);

// Via scraper manager
final result = await scraperManager.scrape('https://youtube.com/...');
```

### Batch Scraping
```dart
final urls = [
  'https://youtube.com/watch?v=abc',
  'https://example.com/article',
  'https://play.google.com/store/apps/details?id=...',
];

final documents = await ragScraperAdapter.scrapeMultiple(
  urls,
  onProgress: (completed, total) {
    print('Progress: $completed/$total');
  },
);
```

## Migration Notes

### Removed
- ❌ `lib/features/search/rag/services/data_ingestion/web_scraper_service.dart`
- ❌ `ScrapedContent` class (replaced by `GenericScraperResult`)

### Added
- ✅ `lib/features/search/scrapers/sites/generic/generic_web_scraper.dart`
- ✅ `lib/features/search/scrapers/sites/scholar/scholar_scraper.dart`
- ✅ `lib/features/search/rag/services/data_ingestion/rag_scraper_adapter.dart`
- ✅ `GenericScraperResult` model in `scraper_models.dart`

### Updated
- 🔄 `RAGOrchestrator` - Uses `RAGScraperAdapter` instead of `WebScraperService`
- 🔄 `RAGProvider` - Updated to use new scraper adapter
- 🔄 `ScraperManager` - Enhanced with generic fallback
- 🔄 `ScraperConfig` - Added image/link extraction flags

## Performance Improvements

1. **Specialized Extraction**: Each scraper is optimized for its domain
2. **Caching**: Multi-level caching (scraper + adapter)
3. **Batch Processing**: Efficient parallel scraping with rate limiting
4. **Smart Fallback**: Generic scraper only used when needed

## Console Output

The system now provides detailed scraping information:
```
🌐 Scraping 6 URLs with intelligent routing (mode: search)...
   ✓ [youtube] https://youtube.com/... → 2500 words, 1 images
   ✓ [scholar] https://arxiv.org/abs/... → 3200 words, 0 images
   ✓ [generic] https://example.com/... → 1500 words, 5 images
   ✓ [tiktok] https://tiktok.com/... → 150 words, 1 images
   ✗ https://blocked-site.com/... → using snippet (HTTP 403)
🌐 Scraped content in 3500ms
   ✅ Success: 4/5 URLs
   🖼️  Total images extracted: 7
   🔗 Total links extracted: 25
```

## Future Enhancements

Potential additions to the scraper system:
- Twitter/X scraper
- Reddit scraper
- GitHub scraper
- Medium/Substack scrapers
- News-specific scrapers (BBC, CNN, etc.)
- E-commerce scrapers (Amazon, eBay, etc.)

Each new scraper can be easily added by:
1. Implementing `BaseScraper<YourResultType>`
2. Adding result model to `scraper_models.dart`
3. Registering in `ScraperManager._initializeScrapers()`
4. Adding conversion logic in `RAGScraperAdapter`

## Scholar Scraper Details

The Scholar scraper supports multiple academic platforms:

### Supported Platforms
- **arXiv**: Preprint server for physics, mathematics, CS, etc.
- **PubMed**: Biomedical literature database
- **Google Scholar**: Academic search engine (limited due to bot protection)
- **Semantic Scholar**: AI-powered academic search
- **Generic Academic Sites**: IEEE, ACM, Springer, Nature, Science, etc.

### Extracted Information
- Title, authors, abstract
- Publication venue (journal/conference)
- DOI (Digital Object Identifier)
- Citation count
- Keywords/subjects
- PDF URL (when available)
- Publication date
- References (for some sources)

### Example Usage
```dart
// Scrape an arXiv paper
final result = await scraperManager.scrape('https://arxiv.org/abs/2301.12345');
final scholarResult = result.asScholar();

print('Title: ${scholarResult?.title}');
print('Authors: ${scholarResult?.authors?.join(", ")}');
print('Citations: ${scholarResult?.citationCount}');
print('PDF: ${scholarResult?.pdfUrl}');
```
