import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../base/base_scraper.dart';
import '../../base/scraper_models.dart';

/// Scholar scraper for academic papers and research articles
/// Supports Google Scholar, arXiv, PubMed, IEEE Xplore, ACM Digital Library, etc.
class ScholarScraper extends BaseScraper<ScholarScraperResult> {
  ScholarScraper({
    super.dio,
    super.config,
  });

  @override
  String get name => 'Scholar';

  @override
  List<String> get supportedDomains => [
        'scholar.google.com',
        'arxiv.org',
        'pubmed.ncbi.nlm.nih.gov',
        'ieeexplore.ieee.org',
        'dl.acm.org',
        'academic.oup.com',
        'nature.com',
        'science.org',
        'sciencedirect.com',
        'springer.com',
        'researchgate.net',
        'semanticscholar.org',
      ];

  @override
  Future<ScholarScraperResult> scrape(String url) async {
    // Check cache
    final cached = getFromCache(url);
    if (cached != null) return cached;

    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    ScholarScraperResult result;

    try {
      if (host.contains('arxiv.org')) {
        result = await _scrapeArXiv(url);
      } else if (host.contains('pubmed.ncbi.nlm.nih.gov')) {
        result = await _scrapePubMed(url);
      } else if (host.contains('scholar.google.com')) {
        result = await _scrapeGoogleScholar(url);
      } else if (host.contains('semanticscholar.org')) {
        result = await _scrapeSemanticScholar(url);
      } else {
        // Fallback to generic academic scraping
        result = await _scrapeGenericAcademic(url);
      }

      storeInCache(url, result);
      return result;
    } catch (e) {
      print('❌ [$name] Failed to scrape $url: $e');
      return createFailedResult(url, e.toString());
    }
  }

  @override
  ScholarScraperResult createFailedResult(String url, String error) {
    return ScholarScraperResult(
      url: url,
      success: false,
      errorMessage: error,
    );
  }

  /// Scrape arXiv paper
  Future<ScholarScraperResult> _scrapeArXiv(String url) async {
    print('📚 [$name] Scraping arXiv: $url');

    final response = await fetchWithTimeout(url);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final document = html_parser.parse(response.data.toString());

    // Extract metadata
    final title = document.querySelector('h1.title')?.text.replaceAll('Title:', '').trim();
    final authors = _extractArXivAuthors(document);
    final abstract = document.querySelector('.abstract')?.text.replaceAll('Abstract:', '').trim();
    
    // Extract arXiv ID and construct PDF URL
    final arxivIdMatch = RegExp(r'arxiv\.org/abs/(\d+\.\d+)').firstMatch(url);
    final arxivId = arxivIdMatch?.group(1);
    final pdfUrl = arxivId != null ? 'https://arxiv.org/pdf/$arxivId.pdf' : null;

    // Extract date
    final submittedText = document.querySelector('.dateline')?.text ?? '';
    final dateMatch = RegExp(r'\[Submitted.*?(\d{1,2}\s+\w+\s+\d{4})').firstMatch(submittedText);
    DateTime? publishedDate;
    if (dateMatch != null) {
      try {
        publishedDate = DateTime.parse(dateMatch.group(1)!);
      } catch (e) {
        // Parse manually if needed
      }
    }

    // Extract subjects/keywords
    final subjects = document.querySelector('.subjects')?.text.replaceAll('Subjects:', '').trim().split(';').map((s) => s.trim()).toList();

    return ScholarScraperResult(
      url: url,
      success: true,
      title: title,
      authors: authors,
      abstract: abstract,
      publishedDate: publishedDate,
      pdfUrl: pdfUrl,
      keywords: subjects,
      metadata: {
        'source': 'arXiv',
        'arxivId': arxivId,
      },
    );
  }

  List<String> _extractArXivAuthors(dom.Document document) {
    final authors = <String>[];
    document.querySelectorAll('.authors a').forEach((element) {
      authors.add(element.text.trim());
    });
    return authors;
  }

  /// Scrape PubMed article
  Future<ScholarScraperResult> _scrapePubMed(String url) async {
    print('📚 [$name] Scraping PubMed: $url');

    final response = await fetchWithTimeout(url);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final document = html_parser.parse(response.data.toString());

    final title = document.querySelector('h1.heading-title')?.text.trim();
    final authors = _extractPubMedAuthors(document);
    final abstract = document.querySelector('#enc-abstract')?.text.trim();
    
    // Extract journal
    final journal = document.querySelector('.journal-actions-trigger')?.text.trim();
    
    // Extract DOI
    final doiElement = document.querySelector('.id-link[data-ga-action="DOI"]');
    final doi = doiElement?.text.trim();

    // Extract publication date
    final dateText = document.querySelector('.cit')?.text ?? '';
    final dateMatch = RegExp(r'(\d{4})\s+(\w+)(?:\s+(\d{1,2}))?').firstMatch(dateText);
    DateTime? publishedDate;
    if (dateMatch != null) {
      try {
        final year = int.parse(dateMatch.group(1)!);
        final month = _monthNameToNumber(dateMatch.group(2)!);
        final day = dateMatch.group(3) != null ? int.parse(dateMatch.group(3)!) : 1;
        publishedDate = DateTime(year, month, day);
      } catch (e) {
        // Failed to parse date
      }
    }

    // Extract keywords
    final keywords = <String>[];
    document.querySelectorAll('.keywords-list a').forEach((element) {
      keywords.add(element.text.trim());
    });

    return ScholarScraperResult(
      url: url,
      success: true,
      title: title,
      authors: authors,
      abstract: abstract,
      journal: journal,
      doi: doi,
      publishedDate: publishedDate,
      keywords: keywords.isNotEmpty ? keywords : null,
      metadata: {
        'source': 'PubMed',
      },
    );
  }

  List<String> _extractPubMedAuthors(dom.Document document) {
    final authors = <String>[];
    document.querySelectorAll('.authors-list .authors-list-item a').forEach((element) {
      authors.add(element.text.trim());
    });
    return authors;
  }

  /// Scrape Google Scholar (limited due to bot protection)
  Future<ScholarScraperResult> _scrapeGoogleScholar(String url) async {
    print('📚 [$name] Scraping Google Scholar: $url');

    try {
      final response = await fetchWithTimeout(url);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final document = html_parser.parse(response.data.toString());

      final title = document.querySelector('#gsc_oci_title')?.text.trim();
      final authors = _extractGoogleScholarAuthors(document);
      
      // Extract metadata from table
      final metadata = <String, String>{};
      document.querySelectorAll('.gs_scl').forEach((row) {
        final label = row.querySelector('.gsc_oci_field')?.text.trim();
        final value = row.querySelector('.gsc_oci_value')?.text.trim();
        if (label != null && value != null) {
          metadata[label] = value;
        }
      });

      final abstract = document.querySelector('#gsc_oci_descr')?.text.trim();
      final citationCountText = document.querySelector('#gsc_oci_cites a')?.text;
      final citationCount = citationCountText != null ? int.tryParse(RegExp(r'\d+').firstMatch(citationCountText)?.group(0) ?? '0') : null;

      return ScholarScraperResult(
        url: url,
        success: true,
        title: title,
        authors: authors,
        abstract: abstract,
        journal: metadata['Publication'],
        citationCount: citationCount,
        year: metadata['Publication date'] != null ? int.tryParse(metadata['Publication date']!) : null,
        metadata: {
          'source': 'Google Scholar',
          ...metadata,
        },
      );
    } catch (e) {
      // Google Scholar often blocks scrapers, return basic info
      return ScholarScraperResult(
        url: url,
        success: false,
        errorMessage: 'Google Scholar scraping limited due to bot protection. Consider using their API or alternative sources.',
      );
    }
  }

  List<String> _extractGoogleScholarAuthors(dom.Document document) {
    final authors = <String>[];
    document.querySelectorAll('.gsc_oci_value a').forEach((element) {
      final text = element.text.trim();
      if (text.isNotEmpty && !text.contains('@')) {
        authors.add(text);
      }
    });
    return authors;
  }

  /// Scrape Semantic Scholar
  Future<ScholarScraperResult> _scrapeSemanticScholar(String url) async {
    print('📚 [$name] Scraping Semantic Scholar: $url');

    final response = await fetchWithTimeout(url);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final document = html_parser.parse(response.data.toString());

    // Try to extract from JSON-LD structured data
    final jsonLdScript = document.querySelector('script[type="application/ld+json"]');
    if (jsonLdScript != null) {
      try {
        final data = json.decode(jsonLdScript.text);
        if (data is Map<String, dynamic>) {
          return _parseSemanticScholarJson(data, url);
        }
      } catch (e) {
        // Fall back to HTML parsing
      }
    }

    // Fallback to HTML parsing
    final title = document.querySelector('h1[data-test-id="paper-detail-title"]')?.text.trim();
    final abstract = document.querySelector('[data-test-id="text-truncator-text"]')?.text.trim();
    
    final authors = <String>[];
    document.querySelectorAll('[data-test-id="author-list"] a').forEach((element) {
      authors.add(element.text.trim());
    });

    final citationCountText = document.querySelector('[data-test-id="citation-count"]')?.text;
    final citationCount = citationCountText != null ? int.tryParse(RegExp(r'\d+').firstMatch(citationCountText)?.group(0) ?? '0') : null;

    return ScholarScraperResult(
      url: url,
      success: true,
      title: title,
      authors: authors.isNotEmpty ? authors : null,
      abstract: abstract,
      citationCount: citationCount,
      metadata: {
        'source': 'Semantic Scholar',
      },
    );
  }

  ScholarScraperResult _parseSemanticScholarJson(Map<String, dynamic> data, String url) {
    final authors = <String>[];
    if (data['author'] is List) {
      for (final author in data['author']) {
        if (author is Map && author['name'] != null) {
          authors.add(author['name']);
        }
      }
    }

    DateTime? publishedDate;
    if (data['datePublished'] != null) {
      try {
        publishedDate = DateTime.parse(data['datePublished']);
      } catch (e) {
        // Failed to parse
      }
    }

    return ScholarScraperResult(
      url: url,
      success: true,
      title: data['headline'] ?? data['name'],
      authors: authors.isNotEmpty ? authors : null,
      abstract: data['description'],
      publishedDate: publishedDate,
      doi: data['identifier'],
      metadata: {
        'source': 'Semantic Scholar',
      },
    );
  }

  /// Generic academic paper scraping
  Future<ScholarScraperResult> _scrapeGenericAcademic(String url) async {
    print('📚 [$name] Scraping generic academic site: $url');

    final response = await fetchWithTimeout(url);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final document = html_parser.parse(response.data.toString());

    // Try JSON-LD first
    final jsonLdScript = document.querySelector('script[type="application/ld+json"]');
    if (jsonLdScript != null) {
      try {
        final data = json.decode(jsonLdScript.text);
        if (data is Map<String, dynamic> && data['@type'] == 'ScholarlyArticle') {
          return _parseGenericScholarlyArticleJson(data, url);
        }
      } catch (e) {
        // Fall back to meta tags
      }
    }

    // Extract from meta tags
    final title = _extractMetaContent(document, [
      'meta[name="citation_title"]',
      'meta[property="og:title"]',
      'meta[name="dc.title"]',
    ]) ?? document.querySelector('h1')?.text.trim();

    final authors = _extractAuthorsFromMeta(document);
    
    final abstract = _extractMetaContent(document, [
      'meta[name="citation_abstract"]',
      'meta[name="description"]',
      'meta[property="og:description"]',
      'meta[name="dc.description"]',
    ]);

    final doi = _extractMetaContent(document, [
      'meta[name="citation_doi"]',
      'meta[name="dc.identifier"]',
    ]);

    final journal = _extractMetaContent(document, [
      'meta[name="citation_journal_title"]',
      'meta[name="dc.source"]',
    ]);

    final pdfUrl = _extractMetaContent(document, [
      'meta[name="citation_pdf_url"]',
    ]);

    final keywords = _extractKeywordsFromMeta(document);

    // Extract date
    final dateStr = _extractMetaContent(document, [
      'meta[name="citation_publication_date"]',
      'meta[name="citation_date"]',
      'meta[name="dc.date"]',
    ]);
    DateTime? publishedDate;
    if (dateStr != null) {
      try {
        publishedDate = DateTime.parse(dateStr);
      } catch (e) {
        // Failed to parse
      }
    }

    return ScholarScraperResult(
      url: url,
      success: true,
      title: title,
      authors: authors.isNotEmpty ? authors : null,
      abstract: abstract,
      journal: journal,
      doi: doi,
      pdfUrl: pdfUrl,
      publishedDate: publishedDate,
      keywords: keywords.isNotEmpty ? keywords : null,
      metadata: {
        'source': 'Generic Academic',
      },
    );
  }

  String? _extractMetaContent(dom.Document document, List<String> selectors) {
    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'];
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }
    }
    return null;
  }

  List<String> _extractAuthorsFromMeta(dom.Document document) {
    final authors = <String>[];
    document.querySelectorAll('meta[name="citation_author"]').forEach((element) {
      final author = element.attributes['content'];
      if (author != null && author.isNotEmpty) {
        authors.add(author.trim());
      }
    });
    
    // Fallback to dc.creator
    if (authors.isEmpty) {
      document.querySelectorAll('meta[name="dc.creator"]').forEach((element) {
        final author = element.attributes['content'];
        if (author != null && author.isNotEmpty) {
          authors.add(author.trim());
        }
      });
    }
    
    return authors;
  }

  List<String> _extractKeywordsFromMeta(dom.Document document) {
    final keywords = <String>[];
    
    // Try citation_keywords
    final keywordsContent = _extractMetaContent(document, [
      'meta[name="citation_keywords"]',
      'meta[name="keywords"]',
      'meta[name="dc.subject"]',
    ]);
    
    if (keywordsContent != null) {
      keywords.addAll(
        keywordsContent.split(RegExp(r'[;,]')).map((k) => k.trim()).where((k) => k.isNotEmpty)
      );
    }
    
    return keywords;
  }

  ScholarScraperResult _parseGenericScholarlyArticleJson(Map<String, dynamic> data, String url) {
    final authors = <String>[];
    if (data['author'] is List) {
      for (final author in data['author']) {
        if (author is Map && author['name'] != null) {
          authors.add(author['name']);
        } else if (author is String) {
          authors.add(author);
        }
      }
    }

    DateTime? publishedDate;
    if (data['datePublished'] != null) {
      try {
        publishedDate = DateTime.parse(data['datePublished']);
      } catch (e) {
        // Failed to parse
      }
    }

    final keywords = <String>[];
    if (data['keywords'] is String) {
      keywords.addAll(
        (data['keywords'] as String).split(',').map((k) => k.trim()).where((k) => k.isNotEmpty)
      );
    } else if (data['keywords'] is List) {
      keywords.addAll((data['keywords'] as List).map((k) => k.toString()).where((k) => k.isNotEmpty));
    }

    return ScholarScraperResult(
      url: url,
      success: true,
      title: data['headline'] ?? data['name'],
      authors: authors.isNotEmpty ? authors : null,
      abstract: data['description'],
      publishedDate: publishedDate,
      journal: data['publisher'] is Map ? data['publisher']['name'] : data['publisher'],
      doi: data['identifier'],
      keywords: keywords.isNotEmpty ? keywords : null,
      metadata: {
        'source': 'Generic Academic (JSON-LD)',
      },
    );
  }

  int _monthNameToNumber(String monthName) {
    const months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    return months[monthName.toLowerCase()] ?? 1;
  }
}
