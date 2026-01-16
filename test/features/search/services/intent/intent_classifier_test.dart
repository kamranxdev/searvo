import 'package:test/test.dart';
import 'package:searvo/features/search/domain/services/intent_classifier.dart';
import 'package:searvo/features/search/domain/entities/search_intent.dart';

void main() {
  group('IntentClassifier', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    test('classifies general queries correctly', () async {
      expect(
        await classifier.classify('hello world'),
        equals(SearchIntent.general),
      );
      expect(
        await classifier.classify('why is sky blue'),
        equals(SearchIntent.general),
      );
    });

    test('classifies coding queries correctly', () async {
      expect(
        await classifier.classify('python sort list'),
        equals(SearchIntent.coding),
      );
      expect(
        await classifier.classify('how to implement quicksort in dart'),
        equals(SearchIntent.coding),
      );
      expect(
        await classifier.classify('github copilot api'),
        equals(SearchIntent.coding),
      );
      expect(
        await classifier.classify('flutter widget test'),
        equals(SearchIntent.coding),
      );
    });

    test('classifies visual queries correctly', () async {
      expect(
        await classifier.classify('image of a cat'),
        equals(SearchIntent.visual),
      );
      expect(
        await classifier.classify('photos of mountains'),
        equals(SearchIntent.visual),
      );
      expect(
        await classifier.classify('logo design ideas'),
        equals(SearchIntent.visual),
      );
    });

    test('classifies video queries correctly', () async {
      expect(
        await classifier.classify('youtube tutorial flutter'),
        equals(SearchIntent.visual),
      );
      expect(
        await classifier.classify('video of space launch'),
        equals(SearchIntent.visual),
      );
      expect(
        await classifier.classify('watch movie online'),
        equals(SearchIntent.visual),
      );
    });

    test('classifies shopping queries correctly', () async {
      expect(
        await classifier.classify('buy iphone 15'),
        equals(SearchIntent.shopping),
      );
      expect(
        await classifier.classify('price of ps5'),
        equals(SearchIntent.shopping),
      );
      expect(
        await classifier.classify('cheap laptops'),
        equals(SearchIntent.shopping),
      );
      expect(
        await classifier.classify('amazon gift card'),
        equals(SearchIntent.shopping),
      );
    });

    test('classifies academic queries correctly', () async {
      expect(
        await classifier.classify('research paper on transformers'),
        equals(SearchIntent.academic),
      );
      expect(
        await classifier.classify('arxiv paper llm'),
        equals(SearchIntent.academic),
      );
      expect(
        await classifier.classify('study of quantum mechanics'),
        equals(SearchIntent.academic),
      );
    });

    test('classifies map/local queries correctly', () async {
      expect(
        await classifier.classify('restaurants near me'),
        equals(SearchIntent.map),
      );
      expect(
        await classifier.classify('weather in london'),
        equals(SearchIntent.map),
      ); // Might be map or news/general depending on logic
      expect(
        await classifier.classify('directions to airport'),
        equals(SearchIntent.map),
      );
    });
  });
}
