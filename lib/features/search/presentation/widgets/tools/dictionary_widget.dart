import 'package:flutter/material.dart';
import 'package:searvo/features/search/theme/search_theme.dart';

class DictionaryWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const DictionaryWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);
    final word = data['word'] ?? '';
    final phonetic = data['phonetic'] ?? '';
    final meanings = data['meanings'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: searchColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: searchColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                word,
                style: TextStyle(
                  color: searchColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                phonetic,
                style: TextStyle(
                  color: searchColors.onSurfaceVariant,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...meanings.map((m) {
            final partOfSpeech = m['partOfSpeech'];
            final definitions = m['definitions'] as List<dynamic>;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: searchColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      partOfSpeech,
                      style: TextStyle(
                        color: searchColors.primary,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...definitions
                      .take(2)
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 4.0,
                            left: 8.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: searchColors.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  d['definition'],
                                  style: TextStyle(
                                    color: searchColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
