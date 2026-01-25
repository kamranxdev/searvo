class StringAlgorithms {
  const StringAlgorithms._();

  /// Levenshtein Distance Algorithm
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < v0.length; j++) v0[j] = v1[j];
    }
    return v1[s2.length];
  }

  /// Simple Soundex implementation
  static String calculateSoundex(String s) {
    if (s.isEmpty) return "";
    String normalized = s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (normalized.isEmpty) return "";

    String fst = normalized[0];
    String rest = normalized.substring(1);

    // Mapping
    // B, F, P, V -> 1
    // C, G, J, K, Q, S, X, Z -> 2
    // D, T -> 3
    // L -> 4
    // M, N -> 5
    // R -> 6
    rest = rest.replaceAll(RegExp(r'[BFPV]'), '1');
    rest = rest.replaceAll(RegExp(r'[CGJKQSXZ]'), '2');
    rest = rest.replaceAll(RegExp(r'[DT]'), '3');
    rest = rest.replaceAll(RegExp(r'[L]'), '4');
    rest = rest.replaceAll(RegExp(r'[MN]'), '5');
    rest = rest.replaceAll(RegExp(r'[R]'), '6');
    rest = rest.replaceAll(RegExp(r'[AEIOUHWY]'), ''); // Remove others

    // Remove adjacent duplicates
    String result = fst;
    if (rest.isNotEmpty) {
      String prev = ''; // Start empty
      for (int i = 0; i < rest.length; i++) {
        if (rest[i] != prev) {
          result += rest[i];
          prev = rest[i];
        }
      }
    }

    // Pad or trim
    if (result.length < 4) {
      return result.padRight(4, '0');
    }
    return result.substring(0, 4);
  }

  static Set<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();
  }
}
