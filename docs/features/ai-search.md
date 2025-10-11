# AI-Powered Search

Searvo's AI search combines traditional web search with advanced language models to provide comprehensive, contextual answers to your questions.

## How It Works

### RAG (Retrieval-Augmented Generation) Pipeline

Searvo uses a sophisticated RAG pipeline to generate accurate responses:

```
Your Question
     ↓
Query Analysis (LLM)
     ↓
Web Search (SearXNG)
     ↓
Content Extraction (Web Scraping)
     ↓
Context Building (RAG)
     ↓
Answer Generation (LLM)
     ↓
Formatted Response with Sources
```

### Step-by-Step Process

#### 1. Query Understanding
The LLM analyzes your question to:
- Identify key entities and concepts
- Understand search intent
- Generate optimal search queries

#### 2. Multi-Source Search
Searvo searches multiple sources:
- General web search via SearXNG
- Site-specific searches (using @mentions)
- Cached knowledge from previous searches

#### 3. Content Extraction
For each search result:
- Full webpage content is scraped
- Text is extracted and cleaned
- Relevant sections are identified

#### 4. Context Building
- Combines content from multiple sources
- Ranks by relevance to your question
- Builds a comprehensive context window

#### 5. AI Synthesis
The LLM:
- Analyzes all gathered content
- Synthesizes information coherently
- Cites sources for claims
- Formats response for readability

## Search Features

### Basic Search

Simply type your question and press enter:

```
"What is quantum entanglement?"
```

Searvo will:
1. Search the web
2. Analyze top results
3. Generate a comprehensive answer
4. Provide source links

### Conversational Search

Searvo maintains context throughout your conversation:

```
You: "What is TypeScript?"
Searvo: [Explains TypeScript]

You: "What are its advantages over JavaScript?"
Searvo: [Understands context, compares to JavaScript]

You: "Show me code examples"
Searvo: [Provides TypeScript examples]
```

### Site-Specific Search with @Mentions

Target specific websites using @mentions:

```
@github best flutter packages for state management
@youtube flutter tutorial for beginners
@stackoverflow how to debug flutter app
@reddit best practices for flutter development
@wiki history of computer programming
```

#### Default Site Mappings

| Mention | Website |
|---------|---------|
| @youtube | YouTube.com |
| @github | GitHub.com |
| @stackoverflow | StackOverflow.com |
| @reddit | Reddit.com |
| @wiki | Wikipedia.org |
| @twitter | Twitter.com |
| @linkedin | LinkedIn.com |
| @medium | Medium.com |

#### Custom Mappings

Add your own mappings in Settings → Advanced → Website Mappings:

```json
{
  "name": "Hacker News",
  "mention": "@hn",
  "url": "https://news.ycombinator.com"
}
```

### Multi-Query Search

Combine multiple queries in one request:

```
"Compare @github flutter packages with @medium articles about state management"
```

### Follow-Up Questions

Ask follow-ups without repeating context:

```
You: "Explain neural networks"
Searvo: [Detailed explanation]

You: "How are they different from traditional algorithms?"
You: "What are common applications?"
You: "Can you show a simple example?"
```

## Search Modes

### Quick Search
- Fast, concise answers
- Uses fewer web sources
- Lower LLM token usage
- Best for simple questions

### Deep Search
- Comprehensive analysis
- Multiple source checking
- Detailed synthesis
- Best for research topics

### Research Mode
- Maximum depth
- Extended context window
- Multiple LLM passes
- Best for academic/professional research

## Advanced Features

### Search Filters

Apply filters to refine results:

```
[Time Filter]
"Latest AI developments" (past week)
"Historical events in 1990s" (specific time period)

[Content Type]
"Videos about Flutter" → Prioritizes video content
"Research papers on ML" → Prioritizes academic sources

[Domain Filter]
site:github.com flutter packages
site:stackoverflow.com flutter errors
```

### Source Quality

Searvo ranks sources by:
- **Relevance** - How well content matches your query
- **Authority** - Domain reputation and credibility
- **Recency** - Publication/update date
- **Completeness** - Depth of information

### Context Window

Manage how much context the LLM sees:

- **Small** (2K tokens) - Quick answers, lower cost
- **Medium** (4K tokens) - Balanced approach
- **Large** (8K tokens) - Deep analysis
- **XLarge** (16K+ tokens) - Maximum context (supported models only)

## Search Tips

### Effective Queries

✅ **Good Queries:**
```
"What are the benefits of TypeScript over JavaScript?"
"How to deploy a Flutter app to production?"
"Compare React, Vue, and Angular for enterprise apps"
```

❌ **Less Effective:**
```
"TypeScript" (too vague)
"help" (no context)
"stuff about programming" (unclear intent)
```

### Using Context

Build on previous responses:
```
1. "Explain Docker"
2. "How does it differ from virtual machines?"
3. "What are best practices for Docker in production?"
```

### Combining Features

Use multiple features together:
```
@github @youtube "best resources for learning Rust programming"
```

## Response Format

### Standard Response

```
[AI Analysis]
Your comprehensive answer here, synthesized from multiple sources...

[Sources]
1. Article Title - domain.com
2. Documentation - docs.example.com
3. Tutorial - tutorial.site

[Related Topics]
- Topic A
- Topic B
```

### Code Examples

When relevant, Searvo provides code:

````markdown
Here's a TypeScript example:

```typescript
interface User {
  name: string;
  age: number;
}

const user: User = {
  name: "John",
  age: 30
};
```
````

### Visual Formatting

- **Bold** for emphasis
- *Italics* for technical terms
- `Code` for inline code
- Lists for organization
- Tables for comparisons

## Performance Optimization

## Search History

### Search Again

Quickly rerun previous searches to get updated information.

### Export Results

Export search results in multiple formats:
- **PDF** - Professional documents
- **Markdown** - Text with formatting
- **Text** - Plain text
- **JSON** - Structured data

### Share Searches

Share your findings:
- Copy response text
- Share via system share sheet
- Export and send files

## Performance Optimization

### Caching

Searvo caches:
- Recent search results (1 hour)
- Scraped web content (24 hours)
- LLM responses (session)

Clear cache in Settings → Advanced → Clear Cache

### Token Usage

Monitor and optimize token consumption:
- View token count per search
- Set maximum token limits
- Choose appropriate models

### Rate Limiting

Respect API rate limits:
- Auto-retry with backoff
- Queue requests during limits
- Display clear error messages

## Troubleshooting

### No Results

**Problem**: Search returns no results

**Solutions:**
- Check internet connection
- Verify SearXNG is accessible
- Try different search terms
- Check search provider settings

### Incomplete Answers

**Problem**: Response seems cut off

**Solutions:**
- Increase context window size
- Use a model with larger context
- Break question into smaller parts

### Slow Responses

**Problem**: Search takes too long

**Solutions:**
- Use smaller context window
- Enable quick search mode
- Check network speed
- Try faster LLM model

### Inaccurate Information

**Problem**: Response contains errors

**Solutions:**
- Check source links yourself
- Try rephrasing question
- Use deep search mode
- Cross-reference with traditional search

## Best Practices

1. **Be Specific** - Detailed questions get better answers
2. **Use Context** - Build on previous responses
3. **Verify Critical Info** - Always check sources for important decisions
4. **Experiment** - Try different phrasings and approaches
5. **Combine Features** - Use @mentions, follow-ups, and filters together

## Next Steps

- [Voice Interaction](voice-interaction.md) - Use voice for hands-free search
- [Web Scraping](web-scraping.md) - Understand content extraction
- [Multi-Provider Support](multi-provider-support.md) - Configure LLM providers
