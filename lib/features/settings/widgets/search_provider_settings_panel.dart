import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/services/search_provider_settings_service.dart';
import 'section_header.dart';
import 'setting_item.dart';

class SearchProviderSettingsPanel extends StatefulWidget {
  const SearchProviderSettingsPanel({Key? key}) : super(key: key);

  @override
  State<SearchProviderSettingsPanel> createState() => _SearchProviderSettingsPanelState();
}

class _SearchProviderSettingsPanelState extends State<SearchProviderSettingsPanel> {
  final SearchProviderSettingsService _searchSettings = SearchProviderSettingsService();
  bool _testingConnection = false;
  String? _testResult;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final status = _searchSettings.getStatus();
    final isConfigured = status['isConfigured'] as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Search Engine Settings',
          description: 'Configure your SearXNG search engine endpoint',
        ),
        const SizedBox(height: 24),
        _buildSearXNGSettings(colorScheme, isConfigured),
        const SizedBox(height: 32),
        _buildGeneralSettings(colorScheme),
      ],
    );
  }

  Widget _buildSearXNGSettings(ColorScheme colorScheme, bool isConfigured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: 8),
            Text('SearXNG Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(colorScheme, 'SearXNG Endpoint URL', 'http://localhost:4000', 'URL of your SearXNG instance', _searchSettings.getSearXNGEndpoint(), (value) {
          _searchSettings.setSearXNGEndpoint(value);
          setState(() { _testResult = null; });
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _searchSettings.getSearXNGEndpoint().isNotEmpty && !_testingConnection ? _testConnection : null,
              icon: _testingConnection ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSurface)) : Icon(Icons.wifi_protected_setup, size: 16),
              label: Text(_testingConnection ? 'Testing...' : 'Test Connection'),
            ),
            if (_testResult != null) ...[
              const SizedBox(width: 12),
              Icon(_testResult == 'success' ? Icons.check_circle : Icons.error, color: _testResult == 'success' ? Colors.green : Colors.red),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('General Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SettingItem(
          isDark: Theme.of(context).brightness == Brightness.dark,
          label: 'Request Timeout',
          description: 'Maximum time to wait for search results (seconds)',
          child: SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(text: _searchSettings.getSearchTimeout().toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final timeout = int.tryParse(value);
                if (timeout != null && timeout > 0) { _searchSettings.setSearchTimeout(timeout); }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(ColorScheme colorScheme, String label, String hint, String description, String currentValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(controller: TextEditingController(text: currentValue), decoration: InputDecoration(hintText: hint, border: OutlineInputBorder()), onChanged: onChanged),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _testConnection() async {
    setState(() { _testingConnection = true; _testResult = null; });
    try {
      final success = await _searchSettings.testSearXNGConnection();
      setState(() { _testingConnection = false; _testResult = success ? 'success' : 'failed'; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Successfully connected!' : 'Failed to connect.'), backgroundColor: success ? Colors.green : Colors.red));
      }
    } catch (e) {
      setState(() { _testingConnection = false; _testResult = 'failed'; });
    }
  }
}
