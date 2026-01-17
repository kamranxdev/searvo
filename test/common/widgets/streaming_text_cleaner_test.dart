import 'package:flutter_test/flutter_test.dart';

// Copying the logic to verify it in isolation without needing widget test scaffolding for now
String cleanText(String text) {
  var cleaned = text;

  // 1. Normalize and merge consecutive citations: [1] [2] -> [1][2]
  var prev = '';
  do {
    prev = cleaned;
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\[\d+\])\s+(\[\d+\])'),
      (match) => '${match.group(1)}${match.group(2)}',
    );
  } while (prev != cleaned);

  // 2. Bind punctuation to citations
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'((?:\[[\d]+\])+)\s*([.,;:?])'),
    (match) => '${match.group(1)}\u2060${match.group(2)}',
  );

  // 3. Bind citations to preceding text
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

    test('retains [1][2] separation but removes space', () {
      expect(cleanText('Sources [1] [2]'), 'Sources\u00A0[1][2]');
    });

    test('handles merged citations [1][2] with punctuation', () {
      expect(cleanText('End [1][2].'), 'End\u00A0[1][2]\u2060.');
    });

    test('handles standard space removal before citation', () {
      expect(cleanText('Word [1]'), 'Word\u00A0[1]');
    });
  });
}
