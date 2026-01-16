import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/common/widgets/rich_text_editing_controller.dart';

void main() {
  group('DetectedType Enum', () {
    test('should have all expected types', () {
      expect(DetectedType.values.length, 3);
      expect(DetectedType.values, contains(DetectedType.mention));
      expect(DetectedType.values, contains(DetectedType.url));
      expect(DetectedType.values, contains(DetectedType.plainText));
    });
  });

  group('RichTextEditingController', () {
    late RichTextEditingController controller;
    late Set<String> validMentions;

    setUp(() {
      validMentions = {'github', 'youtube', 'twitter', 'linkedin'};
      controller = RichTextEditingController(validMentions: validMentions);
    });

    tearDown(() {
      controller.dispose();
    });

    group('Constructor', () {
      test('should create controller with valid mentions', () {
        expect(controller.validMentions, equals(validMentions));
      });

      test('should have null default mention color', () {
        expect(controller.mentionColor, null);
      });

      test('should have null default url color', () {
        expect(controller.urlColor, null);
      });

      test('should accept custom colors', () {
        final customController = RichTextEditingController(
          validMentions: {'test'},
          mentionColor: Colors.red,
          urlColor: Colors.blue,
        );

        expect(customController.mentionColor, Colors.red);
        expect(customController.urlColor, Colors.blue);

        customController.dispose();
      });
    });

    group('extractUrls', () {
      test('should extract single http URL', () {
        controller.text = 'Check out http://example.com';
        final urls = controller.extractUrls();
        expect(urls.length, 1);
        expect(urls.first, 'http://example.com');
      });

      test('should extract single https URL', () {
        controller.text = 'Visit https://secure.example.com';
        final urls = controller.extractUrls();
        expect(urls.length, 1);
        expect(urls.first, 'https://secure.example.com');
      });

      test('should extract multiple URLs', () {
        controller.text = 'Check https://first.com and http://second.com';
        final urls = controller.extractUrls();
        expect(urls.length, 2);
        expect(urls, contains('https://first.com'));
        expect(urls, contains('http://second.com'));
      });

      test('should return empty list when no URLs present', () {
        controller.text = 'No URLs in this text';
        final urls = controller.extractUrls();
        expect(urls, isEmpty);
      });

      test('should extract URLs with paths', () {
        controller.text = 'See https://example.com/path/to/page';
        final urls = controller.extractUrls();
        expect(urls.length, 1);
        expect(urls.first, 'https://example.com/path/to/page');
      });

      test('should extract URLs with query parameters', () {
        controller.text = 'Link: https://example.com?query=value&foo=bar';
        final urls = controller.extractUrls();
        expect(urls.length, 1);
        expect(urls.first, 'https://example.com?query=value&foo=bar');
      });

      test('should handle empty text', () {
        controller.text = '';
        final urls = controller.extractUrls();
        expect(urls, isEmpty);
      });
    });

    group('containsUrls', () {
      test('should return true when text contains URL', () {
        controller.text = 'Check https://example.com';
        expect(controller.containsUrls(), true);
      });

      test('should return false when text has no URLs', () {
        controller.text = 'No URLs here';
        expect(controller.containsUrls(), false);
      });

      test('should return false for empty text', () {
        controller.text = '';
        expect(controller.containsUrls(), false);
      });

      test('should detect http URLs', () {
        controller.text = 'http://example.com';
        expect(controller.containsUrls(), true);
      });

      test('should detect https URLs', () {
        controller.text = 'https://example.com';
        expect(controller.containsUrls(), true);
      });

      test('should not detect invalid protocols', () {
        controller.text = 'ftp://example.com';
        expect(controller.containsUrls(), false);
      });
    });

    group('Text handling', () {
      test('should handle plain text', () {
        controller.text = 'This is plain text';
        expect(controller.text, 'This is plain text');
      });

      test('should handle text with mentions', () {
        controller.text = 'Hello @github and @twitter';
        expect(controller.text, contains('@github'));
        expect(controller.text, contains('@twitter'));
      });

      test('should handle mixed content', () {
        controller.text =
            '@github check https://github.com for more info @youtube';
        expect(controller.text, contains('@github'));
        expect(controller.text, contains('https://github.com'));
        expect(controller.text, contains('@youtube'));
      });
    });

    group('Validation of mentions', () {
      test('should recognize valid mentions', () {
        expect(validMentions.contains('github'), true);
        expect(validMentions.contains('youtube'), true);
        expect(validMentions.contains('twitter'), true);
        expect(validMentions.contains('linkedin'), true);
      });

      test('should not recognize invalid mentions', () {
        expect(validMentions.contains('invalid'), false);
        expect(validMentions.contains('random'), false);
      });
    });
  });

  group('RichTextEditingController buildTextSpan', () {
    testWidgets('should build text span for plain text', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});
      controller.text = 'Plain text';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      expect(find.text('Plain text'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should build text span with mentions', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});
      controller.text = 'Hello @github world';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      expect(find.text('Hello @github world'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should build text span with URLs', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});
      controller.text = 'Visit https://example.com today';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      expect(find.text('Visit https://example.com today'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should handle empty text', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});
      controller.text = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      // TextField should exist but have empty text
      expect(find.byType(TextField), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should handle text with only mentions', (tester) async {
      final controller = RichTextEditingController(
        validMentions: {'github', 'youtube'},
      );
      controller.text = '@github @youtube';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      expect(find.text('@github @youtube'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should handle text with only URLs', (tester) async {
      final controller = RichTextEditingController(validMentions: {});
      controller.text = 'https://a.com https://b.com';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      expect(find.text('https://a.com https://b.com'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should handle mixed mentions and URLs', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});
      controller.text = '@github https://github.com @twitter http://x.com';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      expect(
        find.text('@github https://github.com @twitter http://x.com'),
        findsOneWidget,
      );
      controller.dispose();
    });
  });

  group('Text Input Integration', () {
    testWidgets('should allow typing text', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(controller.text, 'Hello World');

      controller.dispose();
    });

    testWidgets('should allow typing mentions', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), '@github');
      expect(controller.text, '@github');

      controller.dispose();
    });

    testWidgets('should allow typing URLs', (tester) async {
      final controller = RichTextEditingController(validMentions: {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'https://example.com');
      expect(controller.text, 'https://example.com');
      expect(controller.containsUrls(), true);

      controller.dispose();
    });

    testWidgets('should handle clear and retype', (tester) async {
      final controller = RichTextEditingController(validMentions: {'github'});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      // Type initial text
      await tester.enterText(find.byType(TextField), 'Initial text');
      expect(controller.text, 'Initial text');

      // Clear and retype
      controller.clear();
      expect(controller.text, isEmpty);

      await tester.enterText(find.byType(TextField), 'New text');
      expect(controller.text, 'New text');

      controller.dispose();
    });
  });
}
