/// Example demonstrating how to use the AutocompleteService
/// 
/// This file shows various use cases and best practices for integrating
/// the NLP-enhanced autocomplete into your Flutter application.

import 'package:flutter/material.dart';
import 'package:searvo/features/search/services/autocomplete_service.dart';

void main() {
  runApp(const AutocompleteExample());
}

class AutocompleteExample extends StatelessWidget {
  const AutocompleteExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autocomplete Service Example',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const AutocompleteDemo(),
    );
  }
}

class AutocompleteDemo extends StatefulWidget {
  const AutocompleteDemo({super.key});

  @override
  State<AutocompleteDemo> createState() => _AutocompleteDemoState();
}

class _AutocompleteDemoState extends State<AutocompleteDemo> {
  late AutocompleteService _autocompleteService;
  final TextEditingController _controller = TextEditingController();
  List<AutocompleteSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Initialize the autocomplete service
    // You can customize the baseUrl to point to your SearxNG instance
    _autocompleteService = AutocompleteService(
      baseUrl: 'http://localhost:4000',
    );

    // Listen to text changes and fetch suggestions
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _autocompleteService.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text;

    // Clear suggestions if query is too short
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch suggestions with debouncing
    // The callback is called after the debounce duration
    _autocompleteService.getSuggestionsDebounced(query, (suggestions) {
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
          
          // Show message if no suggestions found
          if (suggestions.isEmpty && query.isNotEmpty) {
            _errorMessage = 'No suggestions found';
          }
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
          _errorMessage = 'Failed to fetch suggestions: $error';
        });
      }
      return <AutocompleteSuggestion>[]; // Return empty list on error
    });
  }

  void _onSuggestionTap(AutocompleteSuggestion suggestion) {
    // Update the text field with the selected suggestion
    _controller.text = suggestion.text;
    
    // Move cursor to the end
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    // Clear suggestions
    setState(() {
      _suggestions = [];
    });

    // Perform search or other action
    _performSearch(suggestion.text);
  }

  void _performSearch(String query) {
    // Implement your search logic here
    print('Searching for: $query');
    
    // Show a snackbar for demonstration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for: $query'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getIconForSuggestionType(SuggestionType type) {
    switch (type) {
      case SuggestionType.question:
        return Icons.help_outline;
      case SuggestionType.trending:
        return Icons.trending_up;
      case SuggestionType.topic:
        return Icons.topic_outlined;
      case SuggestionType.related:
        return Icons.search;
    }
  }

  Color _getColorForSuggestionType(SuggestionType type) {
    switch (type) {
      case SuggestionType.question:
        return Colors.blue;
      case SuggestionType.trending:
        return Colors.red;
      case SuggestionType.topic:
        return Colors.teal;
      case SuggestionType.related:
        return Colors.grey;
    }
  }

  String _getIntentLabel(QueryIntent intent) {
    switch (intent) {
      case QueryIntent.general:
        return 'General';
      case QueryIntent.question:
        return 'Question';
      case QueryIntent.definition:
        return 'Definition';
      case QueryIntent.howTo:
        return 'How-to';
      case QueryIntent.comparison:
        return 'Comparison';
      case QueryIntent.news:
        return 'News';
      case QueryIntent.research:
        return 'Research';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NLP Autocomplete Demo'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type to search...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _suggestions = [];
                                    _errorMessage = null;
                                  });
                                },
                              )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: _performSearch,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Suggestions list
          Expanded(
            child: _suggestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _controller.text.isEmpty
                              ? 'Type something to see suggestions'
                              : _isLoading
                                  ? 'Loading suggestions...'
                                  : 'No suggestions found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _getIconForSuggestionType(suggestion.type),
                            color: _getColorForSuggestionType(suggestion.type),
                          ),
                          title: Text(suggestion.displayTitle),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getColorForSuggestionType(
                                    suggestion.type,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getIntentLabel(suggestion.intent),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getColorForSuggestionType(
                                      suggestion.type,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Score: ${suggestion.relevanceScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.north_west, size: 16),
                          onTap: () => _onSuggestionTap(suggestion),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Example of using AutocompleteService without debouncing
/// Use this when you want immediate results (e.g., on button press)
class ImmediateAutocompleteExample extends StatefulWidget {
  const ImmediateAutocompleteExample({super.key});

  @override
  State<ImmediateAutocompleteExample> createState() =>
      _ImmediateAutocompleteExampleState();
}

class _ImmediateAutocompleteExampleState
    extends State<ImmediateAutocompleteExample> {
  late AutocompleteService _autocompleteService;
  final TextEditingController _controller = TextEditingController();
  List<AutocompleteSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autocompleteService = AutocompleteService();
  }

  @override
  void dispose() {
    _controller.dispose();
    _autocompleteService.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    final query = _controller.text;
    
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get suggestions immediately without debouncing
      final suggestions = await _autocompleteService.getSuggestions(query);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Immediate Autocomplete'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter search query',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchSuggestions,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Get Suggestions'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    title: Text(suggestion.text),
                    subtitle: Text(
                      'Type: ${suggestion.type.name} | Score: ${suggestion.relevanceScore}',
                    ),
                    onTap: () {
                      _controller.text = suggestion.text;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
