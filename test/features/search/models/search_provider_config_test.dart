import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/search/models/search_provider_config.dart';

void main() {
  group('SearchProviderConfig Tests', () {
    test('should create SearchProviderConfig with required fields', () {
      const config = SearchProviderConfig(
        name: 'Test Provider',
        baseUrl: 'https://api.test.com',
      );

      expect(config.name, 'Test Provider');
      expect(config.baseUrl, 'https://api.test.com');
      expect(config.headers, isEmpty);
      expect(config.timeout, 30);
      expect(config.enabled, true);
    });

    test('should create SearchProviderConfig with all fields', () {
      const config = SearchProviderConfig(
        name: 'Full Provider',
        baseUrl: 'https://api.full.com',
        headers: {'Authorization': 'Bearer token'},
        timeout: 60,
        enabled: false,
      );

      expect(config.name, 'Full Provider');
      expect(config.baseUrl, 'https://api.full.com');
      expect(config.headers, {'Authorization': 'Bearer token'});
      expect(config.timeout, 60);
      expect(config.enabled, false);
    });

    group('factory searxng', () {
      test('should create SearXNG config with defaults', () {
        final config = SearchProviderConfig.searxng(
          baseUrl: 'http://localhost:4000',
        );

        expect(config.name, 'SearXNG');
        expect(config.baseUrl, 'http://localhost:4000');
        expect(config.headers['Accept'], 'application/json');
        expect(config.headers['User-Agent'], 'Searvo/1.0');
        expect(config.timeout, 30);
        expect(config.enabled, true);
      });

      test('should create SearXNG config with custom timeout', () {
        final config = SearchProviderConfig.searxng(
          baseUrl: 'http://localhost:4000',
          timeout: 45,
        );

        expect(config.timeout, 45);
      });

      test('should create SearXNG config with enabled false', () {
        final config = SearchProviderConfig.searxng(
          baseUrl: 'http://localhost:4000',
          enabled: false,
        );

        expect(config.enabled, false);
      });
    });

    group('toMap', () {
      test('should convert to map correctly', () {
        const config = SearchProviderConfig(
          name: 'Test',
          baseUrl: 'https://test.com',
          headers: {'Key': 'Value'},
          timeout: 20,
          enabled: true,
        );

        final map = config.toMap();

        expect(map['name'], 'Test');
        expect(map['baseUrl'], 'https://test.com');
        expect(map['headers'], {'Key': 'Value'});
        expect(map['timeout'], 20);
        expect(map['enabled'], true);
      });
    });

    group('fromMap', () {
      test('should create from map correctly', () {
        final map = {
          'name': 'From Map',
          'baseUrl': 'https://frommap.com',
          'headers': {'Header': 'Value'},
          'timeout': 40,
          'enabled': false,
        };

        final config = SearchProviderConfig.fromMap(map);

        expect(config.name, 'From Map');
        expect(config.baseUrl, 'https://frommap.com');
        expect(config.headers, {'Header': 'Value'});
        expect(config.timeout, 40);
        expect(config.enabled, false);
      });

      test('should handle missing fields with defaults', () {
        final map = <String, dynamic>{};

        final config = SearchProviderConfig.fromMap(map);

        expect(config.name, '');
        expect(config.baseUrl, '');
        expect(config.headers, isEmpty);
        expect(config.timeout, 30);
        expect(config.enabled, true);
      });
    });

    group('copyWith', () {
      const originalConfig = SearchProviderConfig(
        name: 'Original',
        baseUrl: 'https://original.com',
        headers: {'Original': 'Header'},
        timeout: 30,
        enabled: true,
      );

      test('should return new config with updated name', () {
        final updated = originalConfig.copyWith(name: 'Updated');
        expect(updated.name, 'Updated');
        expect(updated.baseUrl, originalConfig.baseUrl);
      });

      test('should return new config with updated baseUrl', () {
        final updated = originalConfig.copyWith(baseUrl: 'https://updated.com');
        expect(updated.baseUrl, 'https://updated.com');
      });

      test('should return new config with updated headers', () {
        final updated = originalConfig.copyWith(headers: {'New': 'Header'});
        expect(updated.headers, {'New': 'Header'});
      });

      test('should return new config with updated timeout', () {
        final updated = originalConfig.copyWith(timeout: 60);
        expect(updated.timeout, 60);
      });

      test('should return new config with updated enabled', () {
        final updated = originalConfig.copyWith(enabled: false);
        expect(updated.enabled, false);
      });

      test('should keep original values when no updates', () {
        final updated = originalConfig.copyWith();
        expect(updated.name, originalConfig.name);
        expect(updated.baseUrl, originalConfig.baseUrl);
        expect(updated.timeout, originalConfig.timeout);
        expect(updated.enabled, originalConfig.enabled);
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        const config = SearchProviderConfig(
          name: 'Test',
          baseUrl: 'https://test.com',
          timeout: 30,
          enabled: true,
        );

        final str = config.toString();
        expect(str, contains('Test'));
        expect(str, contains('https://test.com'));
        expect(str, contains('30'));
        expect(str, contains('true'));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        const config1 = SearchProviderConfig(
          name: 'Test',
          baseUrl: 'https://test.com',
          timeout: 30,
          enabled: true,
        );
        const config2 = SearchProviderConfig(
          name: 'Test',
          baseUrl: 'https://test.com',
          timeout: 30,
          enabled: true,
        );

        expect(config1 == config2, isTrue);
      });

      test('should not be equal when name differs', () {
        const config1 = SearchProviderConfig(name: 'A', baseUrl: 'url');
        const config2 = SearchProviderConfig(name: 'B', baseUrl: 'url');

        expect(config1 == config2, isFalse);
      });

      test('should not be equal when baseUrl differs', () {
        const config1 = SearchProviderConfig(name: 'Test', baseUrl: 'url1');
        const config2 = SearchProviderConfig(name: 'Test', baseUrl: 'url2');

        expect(config1 == config2, isFalse);
      });
    });

    group('hashCode', () {
      test('should be same for equal configs', () {
        const config1 = SearchProviderConfig(
          name: 'Test',
          baseUrl: 'https://test.com',
        );
        const config2 = SearchProviderConfig(
          name: 'Test',
          baseUrl: 'https://test.com',
        );

        expect(config1.hashCode, config2.hashCode);
      });
    });
  });

  group('SearchResult Tests', () {
    test('should create SearchResult with required fields', () {
      const result = SearchResult(
        title: 'Test Title',
        url: 'https://example.com/page',
        snippet: 'This is a test snippet',
      );

      expect(result.title, 'Test Title');
      expect(result.url, 'https://example.com/page');
      expect(result.snippet, 'This is a test snippet');
      expect(result.thumbnail, isNull);
      expect(result.publishedDate, isNull);
      expect(result.source, isNull);
    });

    test('should create SearchResult with all fields', () {
      final publishedDate = DateTime(2024, 1, 15);
      final result = SearchResult(
        title: 'Full Result',
        url: 'https://example.com',
        snippet: 'Full snippet',
        thumbnail: 'https://thumb.jpg',
        publishedDate: publishedDate,
        source: 'google',
        imgSrc: 'https://image.jpg',
        thumbnailSrc: 'https://small-thumb.jpg',
        resolution: '1920x1080',
        imgFormat: 'jpeg',
        filesize: 102400,
        iframeSrc: 'https://iframe.url',
        length: '10:30',
        author: 'Author Name',
        views: '1000',
      );

      expect(result.thumbnail, 'https://thumb.jpg');
      expect(result.publishedDate, publishedDate);
      expect(result.source, 'google');
      expect(result.imgSrc, 'https://image.jpg');
      expect(result.resolution, '1920x1080');
      expect(result.filesize, 102400);
      expect(result.length, '10:30');
      expect(result.author, 'Author Name');
      expect(result.views, '1000');
    });

    group('fromSearXNG', () {
      test('should create from SearXNG JSON', () {
        final json = {
          'title': 'SearXNG Result',
          'url': 'https://searxng.example.com',
          'content': 'Result content snippet',
          'engine': 'google',
          'publishedDate': '2024-01-15T10:30:00Z',
        };

        final result = SearchResult.fromSearXNG(json);

        expect(result.title, 'SearXNG Result');
        expect(result.url, 'https://searxng.example.com');
        expect(result.snippet, 'Result content snippet');
        expect(result.source, 'google');
      });

      test('should handle missing fields', () {
        final json = <String, dynamic>{};

        final result = SearchResult.fromSearXNG(json);

        expect(result.title, '');
        expect(result.url, '');
        expect(result.snippet, '');
      });

      test('should handle image-specific fields', () {
        final json = {
          'title': 'Image Result',
          'url': 'https://example.com/image.jpg',
          'content': '',
          'img_src': 'https://full-image.jpg',
          'thumbnail_src': 'https://thumb.jpg',
          'resolution': '800x600',
          'img_format': 'png',
          'filesize': 51200,
        };

        final result = SearchResult.fromSearXNG(json);

        expect(result.imgSrc, 'https://full-image.jpg');
        expect(result.thumbnailSrc, 'https://thumb.jpg');
        expect(result.resolution, '800x600');
        expect(result.imgFormat, 'png');
        expect(result.filesize, 51200);
      });

      test('should handle video-specific fields', () {
        final json = {
          'title': 'Video Result',
          'url': 'https://youtube.com/watch?v=123',
          'content': 'Video description',
          'iframe_src': 'https://youtube.com/embed/123',
          'length': '5:30',
          'author': 'Channel Name',
          'views': 1500,
        };

        final result = SearchResult.fromSearXNG(json);

        expect(result.iframeSrc, 'https://youtube.com/embed/123');
        expect(result.length, '5:30');
        expect(result.author, 'Channel Name');
        expect(result.views, '1500');
      });

      test('should handle views as string', () {
        final json = {
          'title': 'Video',
          'url': 'https://example.com',
          'content': '',
          'views': '2000',
        };

        final result = SearchResult.fromSearXNG(json);
        expect(result.views, '2000');
      });
    });

    group('toMap', () {
      test('should convert to map correctly', () {
        const result = SearchResult(
          title: 'Test',
          url: 'https://test.com',
          snippet: 'Snippet',
          source: 'bing',
        );

        final map = result.toMap();

        expect(map['title'], 'Test');
        expect(map['url'], 'https://test.com');
        expect(map['snippet'], 'Snippet');
        expect(map['source'], 'bing');
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        const result = SearchResult(
          title: 'Test Title',
          url: 'https://test.com',
          snippet: 'Snippet',
          source: 'google',
        );

        final str = result.toString();
        expect(str, contains('Test Title'));
        expect(str, contains('https://test.com'));
        expect(str, contains('google'));
      });
    });
  });
}
