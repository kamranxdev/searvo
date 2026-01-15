import 'package:flutter/material.dart';
import 'package:searvo/features/settings/services/settings_service.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';
import '../../../core/theme/theme.dart';
import 'settings_card.dart';

class WebsiteMappingsPanel extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;

  const WebsiteMappingsPanel({
    super.key,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<WebsiteMappingsPanel> createState() => _WebsiteMappingsPanelState();
}

class _WebsiteMappingsPanelState extends State<WebsiteMappingsPanel> {
  final SettingsService _settingsService = SettingsService();
  late Map<String, Map<String, String>> _websiteMappings;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedMappings = {};

  @override
  void initState() {
    super.initState();
    _websiteMappings = _settingsService.getWebsiteMappings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMappings.clear();
      }
    });
  }

  void _toggleMappingSelection(String key) {
    setState(() {
      if (_selectedMappings.contains(key)) {
        _selectedMappings.remove(key);
      } else {
        _selectedMappings.add(key);
      }
    });
  }

  Future<void> _deleteSelectedMappings() async {
    if (_selectedMappings.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Website Mappings'),
        content: Text(
          'Are you sure you want to delete ${_selectedMappings.length} mapping(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      for (final key in _selectedMappings) {
        await _settingsService.removeWebsiteMapping(key);
      }
      setState(() {
        _websiteMappings = _settingsService.getWebsiteMappings();
        _selectedMappings.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website mappings deleted')),
        );
      }
    }
  }

  List<MapEntry<String, Map<String, String>>> _getFilteredMappings() {
    if (_searchQuery.isEmpty) {
      return _websiteMappings.entries.toList();
    }

    final query = _searchQuery.toLowerCase();
    return _websiteMappings.entries.where((entry) {
      final key = entry.key.toLowerCase();
      final name = (entry.value['name'] ?? '').toLowerCase();
      final url = (entry.value['url'] ?? '').toLowerCase();
      return key.contains(query) || name.contains(query) || url.contains(query);
    }).toList();
  }

  void _addWebsiteMapping() {
    showDialog(
      context: context,
      builder: (context) => _AddWebsiteDialog(
        onSave: (key, mapping) async {
          await _settingsService.addWebsiteMapping(key, mapping);
          setState(() {
            _websiteMappings = _settingsService.getWebsiteMappings();
          });
        },
      ),
    );
  }

  void _editWebsiteMapping(String key, Map<String, String> mapping) {
    showDialog(
      context: context,
      builder: (context) => _AddWebsiteDialog(
        initialKey: key,
        initialMapping: mapping,
        onSave: (newKey, newMapping) async {
          if (key != newKey) {
            await _settingsService.removeWebsiteMapping(key);
          }
          await _settingsService.addWebsiteMapping(newKey, newMapping);
          setState(() {
            _websiteMappings = _settingsService.getWebsiteMappings();
          });
        },
      ),
    );
  }

  void _removeWebsiteMapping(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Website Mapping'),
        content: Text(
          'Are you sure you want to remove the mapping for "@$key"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.removeWebsiteMapping(key);
      setState(() {
        _websiteMappings = _settingsService.getWebsiteMappings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Website Mappings',
          subtitle:
              'Configure @mention shortcuts for websites. Type "@youtube search term" to search YouTube directly.',
        ),
        const SizedBox(height: 24),

        // Add new mapping button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton.icon(
            onPressed: _addWebsiteMapping,
            icon: Icon(Icons.add, color: settingsColors.text),
            label: Text(
              'Add Website Mapping',
              style: TextStyle(color: settingsColors.text),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: settingsColors.cardBackground,
              foregroundColor: settingsColors.text,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: settingsColors.border),
              ),
              elevation: 0,
            ),
          ),
        ),

        // Website mappings list
        ..._websiteMappings.entries.map((entry) {
          final key = entry.key;
          final mapping = entry.value;
          final name = mapping['name'] ?? key;
          final url = mapping['url'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: settingsColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: settingsColors.border),
            ),
            child: Row(
              children: [
                // Website icon/info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '@$key',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: settingsColors.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: settingsColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                color: settingsColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: TextStyle(
                          fontSize: 14,
                          color: settingsColors.subtitle,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editWebsiteMapping(key, mapping),
                      icon: Icon(Icons.edit, color: settingsColors.icon),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _removeWebsiteMapping(key),
                      icon: Icon(Icons.delete, color: Colors.red.shade400),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // Usage instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: settingsColors.inputBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: settingsColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use @mentions:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: settingsColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Type "@youtube" to open YouTube homepage\n• Type "@youtube flutter tutorial" to search YouTube for "flutter tutorial"\n• Add custom mappings above to create your own shortcuts',
                style: TextStyle(
                  fontSize: 14,
                  color: settingsColors.subtitle,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddWebsiteDialog extends StatefulWidget {
  final String? initialKey;
  final Map<String, String>? initialMapping;
  final Function(String key, Map<String, String> mapping) onSave;

  const _AddWebsiteDialog({
    this.initialKey,
    this.initialMapping,
    required this.onSave,
  });

  @override
  State<_AddWebsiteDialog> createState() => _AddWebsiteDialogState();
}

class _AddWebsiteDialogState extends State<_AddWebsiteDialog> {
  late final TextEditingController _keyController;
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _searchUrlController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialKey ?? '');
    _nameController = TextEditingController(
      text: widget.initialMapping?['name'] ?? '',
    );
    _urlController = TextEditingController(
      text: widget.initialMapping?['url'] ?? '',
    );
    _searchUrlController = TextEditingController(
      text: widget.initialMapping?['searchUrl'] ?? '',
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    _searchUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final key = _keyController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final searchUrl = _searchUrlController.text.trim();

    if (key.isEmpty || name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL must start with http:// or https://'),
        ),
      );
      return;
    }

    final mapping = {
      'name': name,
      'url': url,
      if (searchUrl.isNotEmpty) 'searchUrl': searchUrl,
    };

    widget.onSave(key, mapping);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settingsColors = SettingsTheme.colors(context);

    return Dialog(
      backgroundColor: settingsColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialKey != null
                  ? 'Edit Website Mapping'
                  : 'Add Website Mapping',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: settingsColors.header,
              ),
            ),
            const SizedBox(height: 24),

            // Key field
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: '@mention key (e.g., "youtube")',
                hintText: 'Enter the @mention key',
                labelStyle: TextStyle(color: settingsColors.subtitle),
                hintStyle: TextStyle(
                  color: settingsColors.subtitle.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.accent),
                ),
                filled: true,
                fillColor: settingsColors.inputBackground,
              ),
              style: TextStyle(color: settingsColors.text),
              enabled:
                  widget.initialKey ==
                  null, // Can't edit key if editing existing
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter the website name',
                labelStyle: TextStyle(color: settingsColors.subtitle),
                hintStyle: TextStyle(
                  color: settingsColors.subtitle.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.accent),
                ),
                filled: true,
                fillColor: settingsColors.inputBackground,
              ),
              style: TextStyle(color: settingsColors.text),
            ),
            const SizedBox(height: 16),

            // URL field
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://example.com',
                labelStyle: TextStyle(color: settingsColors.subtitle),
                hintStyle: TextStyle(
                  color: settingsColors.subtitle.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.accent),
                ),
                filled: true,
                fillColor: settingsColors.inputBackground,
              ),
              style: TextStyle(color: settingsColors.text),
            ),
            const SizedBox(height: 16),

            // Search URL field
            TextField(
              controller: _searchUrlController,
              decoration: InputDecoration(
                labelText: 'Search URL (optional)',
                hintText: 'https://example.com/search?q={query}',
                helperText: 'Use {query} as placeholder for search terms',
                helperStyle: TextStyle(color: settingsColors.subtitle),
                labelStyle: TextStyle(color: settingsColors.subtitle),
                hintStyle: TextStyle(
                  color: settingsColors.subtitle.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: settingsColors.accent),
                ),
                filled: true,
                fillColor: settingsColors.inputBackground,
              ),
              style: TextStyle(color: settingsColors.text),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: settingsColors.text),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settingsColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.initialKey != null ? 'Save' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
