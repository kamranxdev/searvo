import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/services/search_provider_settings_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_card.dart';

class SearchProviderSettingsPanel extends StatefulWidget {
  const SearchProviderSettingsPanel({Key? key}) : super(key: key);

  @override
  State<SearchProviderSettingsPanel> createState() => _SearchProviderSettingsPanelState();
}

class _SearchProviderSettingsPanelState extends State<SearchProviderSettingsPanel> {
  final SearchProviderSettingsService _searchSettings = SearchProviderSettingsService();
  bool _testingConnection = false;
  String? _testResult;
  late TextEditingController _endpointController;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController(text: _searchSettings.getSearXNGEndpoint());
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

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
          subtitle: 'Configure your SearXNG search engine endpoint',
        ),
        const SizedBox(height: 24),
        _buildSearXNGSettings(colorScheme, isConfigured),
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
        _buildTextFieldWithController(colorScheme, 'SearXNG Endpoint URL', 'http://localhost:4000', 'URL of your SearXNG instance. Find public instances at https://searx.space/ (recommended to use self-hosted)', _endpointController, (value) {
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
  Widget _buildTextFieldWithController(ColorScheme colorScheme, String label, String hint, String description, TextEditingController controller, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint, border: OutlineInputBorder()),
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.url,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        _buildDescription(description, colorScheme),
      ],
    );
  }

  Widget _buildDescription(String text, ColorScheme colorScheme) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);

    if (match != null) {
      final url = match.group(0)!;
      final before = text.substring(0, match.start);
      final after = text.substring(match.end);

      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          children: [
            if (before.isNotEmpty) TextSpan(text: before),
            TextSpan(
              text: url,
              style: TextStyle(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  try {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      // Fallback for desktop platforms
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    }
                  } catch (e) {
                    // If URL launching fails, show a snackbar with the URL
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unable to open URL. Please visit: $url'),
                          action: SnackBarAction(
                            label: 'Copy',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: url));
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
            ),
            if (after.isNotEmpty) TextSpan(text: after),
          ],
        ),
      );
    } else {
      return Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      );
    }
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
