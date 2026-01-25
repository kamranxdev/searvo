import 'file_parser.dart';

class ParsingRegistry {
  final Map<String, FileParser> _parsers = {};

  ParsingRegistry() {
    // Parsers will be registered here or via registerParser
  }

  void registerParser(FileParser parser) {
    for (final ext in parser.supportedExtensions) {
      _parsers[ext.toLowerCase()] = parser;
    }
  }

  FileParser? getParserForExtension(String extension) {
    return _parsers[extension.toLowerCase().replaceAll('.', '')];
  }

  bool isExtensionSupported(String extension) {
    return _parsers.containsKey(extension.toLowerCase().replaceAll('.', ''));
  }
}
