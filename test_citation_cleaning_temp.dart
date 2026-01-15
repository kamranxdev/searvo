void main() {
  String _cleanText(String text) {
    var cleaned = text;

    // 1. Normalize and merge consecutive citations: [1] [2] -> [1, 2]
    // First, remove spaces between citations: [1] [2] -> [1][2]
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
          final first = match.group(1)!.replaceAll('[', '').replaceAll(']', '');
          final second = match
              .group(2)!
              .replaceAll('[', '')
              .replaceAll(']', '');
          return '[$first, $second]';
        },
      );
    }

    // 2. Bind punctuation to citations (prevent [1] . from splitting)
    // We use a Word Joiner (\u2060) to keep them together if needed,
    // or just remove the space entirely.
    // Also updated regex to handle merged citations like [1, 2]
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\[[\d,\s]+\])\s*([.,;:?])'),
      (match) => '${match.group(1)}\u2060${match.group(2)}',
    );

    // 3. Bind citations to preceding text (prevent "text [1]" split)
    // Replace standard space with Non-Breaking Space (\u00A0)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([^\s\n])\s+(\[[\d,\s]+\])'),
      (match) => '${match.group(1)}\u00A0${match.group(2)}',
    );

    return cleaned;
  }

  void test(String input, String expected) {
    final result = _cleanText(input);
    if (result == expected) {
      print('PASS: "$input" -> "$result"');
    } else {
      print('FAIL: "$input"');
      print('  Expected: "$expected"');
      print('  Actual:   "$result"');
      print(
        '  Escaped Exp: "${expected.replaceAll('\u00A0', '\\u00A0').replaceAll('\u2060', '\\u2060')}"',
      );
      print(
        '  Escaped Act: "${result.replaceAll('\u00A0', '\\u00A0').replaceAll('\u2060', '\\u2060')}"',
      );
    }
  }

  print('Running tests...');

  // auto_run: true
  // Test 1: Binding to previous word
  test('word [1]', 'word\u00A0[1]');

  // Test 2: Binding punctuation
  test('[1] .', '[1]\u2060.');

  // Test 3: Merging
  test('[1] [2]', '[1, 2]');

  // Test 4: Complex Case
  test(
    'End of sentence [1]. Then start.',
    'End of sentence\u00A0[1]\u2060. Then start.',
  );

  // Test 5: Merged + Punctuation
  test('Combined [1] [2] .', 'Combined\u00A0[1, 2]\u2060.');

  print('Done.');
}
