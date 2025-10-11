# Web Scraping

Searvo includes powerful web scraping capabilities to extract full content from web pages, enabling comprehensive AI analysis of search results.

## Overview

Traditional search engines show only snippets. Searvo scrapes full page content to provide the AI with complete context for better answers.

## How It Works

### Scraping Pipeline

```
Search Result URL
     ↓
HTTP Request
     ↓
HTML Parsing
     ↓
Content Extraction
     ↓
Text Cleaning
     ↓
RAG Context
```

### Content Extraction

For each search result, Searvo extracts:

- **Main Content** - Article text, documentation, etc.
- **Metadata** - Title, author, date, description
- **Links** - Related pages and references
- **Images** - Relevant media (when applicable)
- **Code Blocks** - Syntax-highlighted code
- **Tables** - Structured data

## Features

### Smart Extraction

Intelligently identifies main content:
- Filters ads and navigation
- Removes boilerplate
- Preserves article structure
- Maintains code formatting
- Handles dynamic content

### Multi-Format Support

Handles various content types:

| Format | Support | Notes |
|--------|---------|-------|
| HTML | ✅ Full | Complete parsing |
| Markdown | ✅ Full | Native support |
| PDF | ✅ Partial | Text extraction |
| JSON | ✅ Full | API responses |
| XML | ✅ Full | Data parsing |
| DOCX | ✅ Partial | Text extraction |

### Rate Limiting

Respectful scraping:
- Delays between requests
- Respects robots.txt
- User-agent identification
- Configurable request rate
- Automatic backoff

## Configuration

### Scraper Settings

Configure in Settings → Advanced → Web Scraping:

```yaml
Max Pages Per Search: 5
Request Timeout: 10s
Respect robots.txt: true
User Agent: Searvo/1.0
Rate Limit: 1 request/second
Max Content Size: 1MB
```

### Content Filters

Control what gets scraped:

**Include:**
- Main article content
- Documentation
- Code examples
- Tables and lists

**Exclude:**
- Advertisements
- Navigation menus
- Footers
- Sidebars
- Comment sections (optional)

## Use Cases

### Technical Documentation

Scrape full documentation:
```
"How to implement OAuth in Flutter"
→ Scrapes: Official docs, tutorials, examples
```

### Research Articles

Extract academic content:
```
"Latest quantum computing research"
→ Scrapes: Papers, abstracts, methodologies
```

### News & Blogs

Get complete articles:
```
"Tech industry news this week"
→ Scrapes: Full articles, not just headlines
```

### Code Examples

Extract working code:
```
"Flutter state management examples"
→ Scrapes: Complete code with context
```

## Advanced Features

### Dynamic Content

Handle JavaScript-rendered content:
- Waits for page load
- Executes JavaScript
- Captures dynamic elements
- Handles single-page apps (SPAs)

### Authentication (Planned)

Future support for authenticated scraping:
- Cookie management
- Session handling
- OAuth support
- API key integration

### Selective Scraping

Target specific page sections:

```dart
// Example configuration
{
  "selector": "article.main-content",
  "exclude": [".ads", ".comments"],
  "extract": ["p", "pre", "code", "h1", "h2", "h3"]
}
```

## Performance

### Caching

Scraped content is cached:
- **Duration**: 24 hours default
- **Storage**: Local SQLite database
- **Size Limit**: Configurable (default 100MB)
- **Cleanup**: Automatic old content removal

### Parallel Scraping

Multiple pages simultaneously:
- Configurable concurrent requests
- Default: 3 concurrent scrapers
- Maximum: 5 concurrent (to be respectful)

### Compression

Reduce storage requirements:
- Content compressed in cache
- Typical ratio: 70-80% reduction
- Transparent decompression

## Error Handling

### Retry Logic

Automatic retries for failures:
- Max retries: 3
- Exponential backoff
- Timeout handling
- Fallback to snippet

### Failure Modes

Graceful degradation:
- **403/401**: Use search snippet
- **404**: Skip result
- **Timeout**: Use cached/snippet
- **Parse Error**: Extract visible text

## Privacy & Ethics

### Ethical Scraping

Searvo follows best practices:

✅ **We Do:**
- Respect robots.txt
- Use reasonable delays
- Identify ourselves (User-Agent)
- Cache to minimize requests
- Honor opt-out requests

❌ **We Don't:**
- Overwhelm servers
- Ignore robots.txt
- Scrape personal data
- Bypass paywalls (without permission)
- Store copyrighted content permanently

### Data Handling

- Content used only for user's query
- Not shared with third parties
- Cached temporarily
- User can clear cache anytime

### Legal Compliance

- Respects copyright
- Fair use for search/research
- No redistribution
- Personal use focused

## Troubleshooting

### Scraping Failures

**Problem**: Can't scrape certain websites

**Possible Causes:**
- Site blocks bots
- Requires JavaScript
- Behind paywall
- Requires authentication

**Solutions:**
- Check robots.txt
- Enable JavaScript rendering
- Use authenticated session (when supported)
- Fallback to snippet

### Incomplete Content

**Problem**: Missing parts of page

**Solutions:**
- Increase timeout
- Enable JavaScript execution
- Adjust content selectors
- Check for dynamic loading

### Slow Scraping

**Problem**: Takes too long

**Solutions:**
- Reduce max pages
- Increase timeout
- Check network connection
- Enable more parallelism

## Customization

### Custom Selectors

For specific sites, add custom extraction rules:

```json
{
  "domain": "example.com",
  "selectors": {
    "title": "h1.article-title",
    "content": "div.article-body",
    "author": "span.author-name",
    "date": "time.published"
  }
}
```

### Site-Specific Rules

Override defaults per domain:

```json
{
  "github.com": {
    "rate_limit": 0.5,
    "timeout": 15,
    "javascript": true
  },
  "stackoverflow.com": {
    "exclude_selectors": [".sidebar", ".ads"]
  }
}
```

## API Integration

### Future API Support

Planned features:
- Custom scraper plugins
- API endpoint scraping
- GraphQL support
- WebSocket content
- Stream processing

## Metrics

Monitor scraping performance:

```
Scraping Statistics:
- Pages scraped: 1,234
- Success rate: 95%
- Average time: 2.3s
- Cache hits: 456
- Total data: 45MB
```

View in Settings → Advanced → Statistics

## Best Practices

1. **Be Respectful** - Don't overwhelm servers
2. **Cache Aggressively** - Reuse content when possible
3. **Handle Errors** - Always have fallbacks
4. **Monitor Performance** - Watch for slow sites
5. **Clear Cache** - Regularly for fresh content

## Limitations

Current limitations:

- No paywall bypass
- Limited JavaScript support
- No CAPTCHA solving
- No authentication (yet)
- Rate limited by design

## Next Steps

- [AI Search](ai-search.md) - Use scraped content in searches
- [Multi-Provider Support](multi-provider-support.md) - Configure AI analysis
- [Architecture](../architecture/services.md) - Technical implementation details
