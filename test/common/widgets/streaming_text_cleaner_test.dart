import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/common/widgets/streaming_text_widget.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';
import 'package:searvo/features/search/presentation/widgets/citation_chip.dart';

String cleanText(String text) {
  var cleaned = text;

  // 1. Normalize consecutive citations: [1][2] or [1] [2] or [1], [2] -> [1, 2]
  var prev = '';
  do {
    prev = cleaned;
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[(\d+)\]\s*,?\s*\[(\d+)\]'),
      (match) => '[${match.group(1)}, ${match.group(2)}]',
    );
  } while (prev != cleaned);

  // 2. Also handle chained [1, 2][3] -> [1, 2, 3]
  do {
    prev = cleaned;
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([\d,\s]+)\]\s*,?\s*\[(\d+)\]'),
      (match) => '[${match.group(1)}, ${match.group(2)}]',
    );
  } while (prev != cleaned);

  // 3. Bind punctuation to citations
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'((?:\[[\d,\s]+\])+)\s*([.,;:?])'),
    (match) => '${match.group(1)}\u2060${match.group(2)}',
  );

  // 4. Bind citations to preceding text
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([^\s\n])\s+(\[[\d,\s]+\])'),
    (match) => '${match.group(1)}\u00A0${match.group(2)}',
  );

  return cleaned;
}

void main() {
  group('StreamingTextWidget cleanText logic', () {
    test('removes double punctuation', () {
      expect(cleanText('Elon Musk [1].'), 'Elon Musk\u00A0[1]\u2060.');
    });

    test('normalizes [1] [2] and [1][2] to [1, 2]', () {
      expect(cleanText('Sources [1] [2]'), 'Sources\u00A0[1, 2]');
      expect(cleanText('End [1][2].'), 'End\u00A0[1, 2]\u2060.');
    });

    test('normalizes chained [1, 2][3] to [1, 2, 3]', () {
      expect(cleanText('Sources [1, 2][3]'), 'Sources\u00A0[1, 2, 3]');
    });

    test('handles standard space removal before citation', () {
      expect(cleanText('Word [1]'), 'Word\u00A0[1]');
    });
  });

  group('StreamingTextWidget inline citation widget tests', () {
    testWidgets('renders inline CitationChip within Text.rich without wrapping block', (tester) async {
      final sources = [
        SourceItem(
          thumbnail: '',
          title: 'Source 1',
          url: 'https://example.com/1',
          domain: 'example.com',
          description: 'Excerpt 1',
        ),
        SourceItem(
          thumbnail: '',
          title: 'Source 2',
          url: 'https://example.com/2',
          domain: 'example.com',
          description: 'Excerpt 2',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingTextWidget(
              staticText: 'Prime Minister tenure [1, 2].',
              sources: sources,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CitationChip), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('normalizes consecutive citations [4][5] into merged inline CitationChip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingTextWidget(
              staticText: 'Policies during their tenure [4][5].',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final citationChip = tester.widget<CitationChip>(find.byType(CitationChip));
      expect(citationChip.citationNumbers, equals([4, 5]));
      expect(find.byType(Wrap), findsNothing);
    });
  });
}
