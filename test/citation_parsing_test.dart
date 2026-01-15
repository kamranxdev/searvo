import 'package:flutter_test/flutter_test.dart';

// Copy of the logic from StreamingTextWidget.dart for testing purposes
String cleanText(String text) {
  // 1. Remove space between citation and punctuation
  var cleaned = text.replaceAllMapped(
    RegExp(r'(\[\d+\])\s+([.,;:?])'),
    (match) => '${match.group(1)}${match.group(2)}',
  );

  // 2. Normalize and merge consecutive citations: [1] [2] -> [1, 2]
  //First, remove spaces between citations: [1] [2] -> [1][2]
  var prev = '';
  do {
    prev = cleaned;
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\[\d+\])\s+(\[\d+\])'),
      (match) => '${match.group(1)}${match.group(2)}',
    );
  } while (prev != cleaned);

  // Then merge them: [1][2][3] -> [1, 2, 3]

  bool changed = true;
  while (changed) {
    changed = false;
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\[[\d,\s]+\])(\[[\d,\s]+\])'),
      (match) {
        changed = true;
        // group 1: [1, 2], group 2: [3]
        final first = match.group(1)!.replaceAll('[', '').replaceAll(']', '');
        final second = match.group(2)!.replaceAll('[', '').replaceAll(']', '');
        return '[$first, $second]';
      },
    );
  }

  return cleaned;
}

void main() {
  group('Citation Parsing Logic', () {
    test('removes space before punctuation', () {
      expect(cleanText('This is a fact [1] .'), 'This is a fact [1].');
      expect(cleanText('Fact [2] , however'), 'Fact [2], however');
    });

    test('merges simple consecutive citations', () {
      expect(cleanText('Fact [1][2]'), 'Fact [1, 2]');
      expect(cleanText('Fact [1] [2]'), 'Fact [1, 2]');
    });

    test('merges multiple citations', () {
      expect(cleanText('Fact [1][2][3]'), 'Fact [1, 2, 3]');
      expect(cleanText('Fact [1] [2] [3]'), 'Fact [1, 2, 3]');
    });

    test('handles already grouped citations being extended', () {
      expect(cleanText('Fact [1, 2][3]'), 'Fact [1, 2, 3]');
      expect(cleanText('Fact [1][2, 3]'), 'Fact [1, 2, 3]');
    });

    test('does not merge separated citations', () {
      expect(cleanText('Fact [1] and [2]'), 'Fact [1] and [2]');
    });

    test('handles complex case', () {
      expect(
        cleanText('Claims [1] [2]. Another [3][4][5].'),
        'Claims [1, 2]. Another [3, 4, 5].',
      );
    });
  });
}
