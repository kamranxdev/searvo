# URL Scraping Feature

## Overview

The URL scraping feature automatically detects URLs in search queries and scrapes their content to provide better context for AI responses. This enhancement integrates seamlessly with the existing RAG (Retrieval-Augmented Generation) pipeline.

## How It Works

### 1. URL Detection

When a user enters a query containing URLs (e.g., "https://example.com"), the system:

- **RichTextEditingController**: Highlights URLs in blue with underline styling
- **SearchService**: Extracts all URLs using regex pattern `https?://[^\s]+`
- **RAGOrchestrator**: Detects URLs and prepares them for scraping

### 2. URL Scraping Process

The scraping happens automatically during the RAG pipeline:

```dart
// Step 0.1: Detect and scrape URLs in query
final urlsInQuery = _extractUrls(query);
List<Document> scrapedUrlDocuments = [];

if (urlsInQuery.isNotEmpty) {
  for (final url in urlsInQuery) {
    final scrapedDoc = await _scraperAdapter.scrape(url);
    scrapedUrlDocuments.add(scrapedDoc);
  }
}
```

### 3. Content Integration

Scraped content is integrated with highest priority:

- **Positioned First**: Scraped documents are added to the beginning of `allRawDocuments`
- **Ranked**: Documents go through the same ranking process as search results
- **Fused**: Content is merged into the context used for AI response generation

## Features

### Automatic URL Detection

- Detects URLs starting with `http://` or `https://`
- Highlights URLs in the search box with teal color and bold font (same as @mentions)
- Extracts multiple URLs from a single query

### Intelligent Scraping

- Uses the **ScraperManager** to select appropriate scrapers:
  - YouTube videos → YouTubeScraper
  - TikTok videos → TikTokScraper
  - Google Play Store → PlayStoreScraper
  - Google Scholar → ScholarScraper
  - Generic websites → GenericWebScraper

### Error Handling

- Failed scrapes are logged but don't break the pipeline
- Continues with search results if scraping fails
- Shows progress for each URL scraped

## Usage Examples

### Example 1: Single URL Query

```
User: "https://en.wikipedia.org/wiki/Artificial_intelligence explain this"
```

**System behavior:**
1. Detects URL in query
2. Scrapes Wikipedia article content
3. Uses scraped content + search results to generate answer
4. Response includes context from the Wikipedia page

### Example 2: Multiple URLs

```
User: "Compare https://site1.com and https://site2.com"
```

**System behavior:**
1. Detects both URLs
2. Scrapes both websites in parallel
3. Adds both documents to context
4. Generates comparative analysis using both sources

### Example 3: URL with Follow-up

```
User: "https://example.com/article"
User: "What are the main points?"
```

**System behavior:**
1. First query: Scrapes the article
2. Follow-up: Uses conversation history + original scraped content
3. Extracts main points from the previously scraped content

## Technical Details

### Modified Files

1. **`rich_text_editing_controller.dart`**
   - Added `extractUrls()` method
   - Added `containsUrls()` method
   - Enhanced URL detection pattern

2. **`search_service.dart`**
   - Added `_extractUrls()` helper method
   - Logs detected URLs in console
   - Passes URLs to RAG orchestrator

3. **`rag_orchestrator.dart`**
   - Added `_extractUrls()` helper method
   - Scrapes URLs before performing searches
   - Integrates scraped documents with highest priority
   - Updated both `generateRAGResponse()` and `generateRAGResponseWithHistory()`

### Performance Considerations

- **Parallel Scraping**: URLs are scraped sequentially but could be parallelized
- **Caching**: Scraped content is not cached between queries (could be added)
- **Timeout**: Uses default scraper timeout settings
- **Context Window**: Scraped content competes with search results for context space

### Console Output

Example log output:

```
🔗 Detected 2 URL(s) in query:
   - https://example.com/page1
   - https://example.com/page2
   🌐 Scraping: https://example.com/page1
   ✅ Scraped: Example Page Title (2458 chars)
   🌐 Scraping: https://example.com/page2
   ✅ Scraped: Another Page (1823 chars)
✅ Successfully scraped 2/2 URLs
📌 Added 2 scraped URL document(s) to context
```

## Future Enhancements

### Planned Features

1. **URL Caching**: Cache scraped content to avoid re-scraping the same URL
2. **Parallel Scraping**: Scrape multiple URLs concurrently
3. **URL Preview**: Show URL preview cards before scraping
4. **Scrape Options**: Let users disable automatic scraping
5. **PDF Support**: Auto-detect and extract PDF URLs
6. **Rate Limiting**: Respect website rate limits and robots.txt

### Configuration Options

Future settings that could be added:

```dart
class URLScrapingConfig {
  final bool autoScrape;           // Auto-scrape detected URLs
  final int maxUrlsPerQuery;       // Limit URLs to scrape
  final int scrapingTimeout;       // Timeout per URL
  final bool cacheContent;         // Cache scraped content
  final bool respectRobotsTxt;     // Check robots.txt
}
```

## Integration with Other Features

### RAG Pipeline

- Scraped URLs are processed as high-priority documents
- Content goes through document ranking
- Integrated with context fusion

### Search Modes

- **Search Mode**: Quick scraping with smaller context
- **Research Mode**: Deep scraping with full content
- **Study Mode**: Scraped content optimized for learning

### Attachments

- URL scraping works alongside file attachments
- Both contribute to the context window
- Prioritization: URLs → Attachments → Search Results

## Troubleshooting

### URLs Not Being Detected

- Ensure URLs start with `http://` or `https://`
- Check for spaces or special characters in URLs
- View console logs for detection status

### Scraping Failures

- Check network connectivity
- Verify URL is accessible
- Some sites may block scrapers
- Check console for error messages

### Context Window Issues

- Too many URLs may consume context space
- Reduce number of URLs or increase context window
- Use Research mode for larger context

## Related Documentation

- [RAG Pipeline Architecture](../architecture/rag-pipeline.md)
- [Scraper System](../../lib/features/search/scrapers/README.md)
- [Search Service](../development/search-service.md)
