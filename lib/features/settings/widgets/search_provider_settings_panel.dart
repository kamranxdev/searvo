import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';
import 'package:searvo/features/settings/services/search_provider_settings_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_card.dart';

class SearchProviderSettingsPanel extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;

  const SearchProviderSettingsPanel({
    super.key,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<SearchProviderSettingsPanel> createState() =>
      _SearchProviderSettingsPanelState();
}

class _SearchProviderSettingsPanelState
    extends State<SearchProviderSettingsPanel> {
  final SearchProviderSettingsService _searchSettings =
      SearchProviderSettingsService();
  bool _testingConnection = false;
  String? _testResult;
  late TextEditingController _endpointController;
  late TextEditingController _regionController;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController(
      text: _searchSettings.getSearXNGEndpoint(),
    );
    _regionController = TextEditingController(
      text: _searchSettings.getRegion(),
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        _buildSearXNGSettings(isConfigured),
      ],
    );
  }

  Widget _buildSearXNGSettings(bool isConfigured) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, size: 20, color: settingsColors.text),
            const SizedBox(width: 8),
            Text(
              'SearXNG Configuration',
              style: SettingsTheme.settingTitle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithController(
          'SearXNG Endpoint URL',
          'http://localhost:4000',
          'URL of your SearXNG instance. Find public instances at https://searx.space/ (recommended to use self-hosted)',
          _endpointController,
          (value) {
            _searchSettings.setSearXNGEndpoint(value);
            setState(() {
              _testResult = null;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed:
                  _searchSettings.getSearXNGEndpoint().isNotEmpty &&
                      !_testingConnection
                  ? _testConnection
                  : null,
              icon: _testingConnection
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: settingsColors.inverseText,
                      ),
                    )
                  : Icon(Icons.wifi_protected_setup, size: 16),
              label: Text(
                _testingConnection ? 'Testing...' : 'Test Connection',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: settingsColors.accent,
                foregroundColor: settingsColors.inverseText,
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(width: 12),
              Icon(
                _testResult == 'success' ? Icons.check_circle : Icons.error,
                color: _testResult == 'success'
                    ? settingsColors.success
                    : settingsColors.error,
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildSafeSearchDropdown(),
        const SizedBox(height: 16),
        _buildRegionField(),
        const SizedBox(height: 16),
        _buildMaxSearchTimeSlider(),
      ],
    );
  }

  Widget _buildSafeSearchDropdown() {
    final settingsColors = SettingsTheme.colors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SafeSearch', style: SettingsTheme.inputLabel(context)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: settingsColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: settingsColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _searchSettings.getSafeSearch(),
              isExpanded: true,
              dropdownColor: settingsColors.cardBackground,
              style: SettingsTheme.inputText(context),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Off')),
                DropdownMenuItem(value: 1, child: Text('Moderate')),
                DropdownMenuItem(value: 2, child: Text('Strict')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  await _searchSettings.setSafeSearch(value);
                  setState(() {});
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        _buildDescription('Filter explicit content from search results.'),
      ],
    );
  }

  Widget _buildRegionField() {
    return _buildTextFieldWithController(
      'Search Region',
      'wt-wt', // Default 'world-wide'
      'Region code (e.g. us-en, de-de) for localized results. Leave empty for auto.',
      _regionController,
      (value) {
        _searchSettings.setRegion(value);
      },
    );
  }

  Widget _buildMaxSearchTimeSlider() {
    final settingsColors = SettingsTheme.colors(context);
    final currentTimeout = _searchSettings.getMaxSearchTime();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Max Search Time', style: SettingsTheme.inputLabel(context)),
            Text(
              '${currentTimeout.toStringAsFixed(1)}s',
              style: TextStyle(
                color: settingsColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: currentTimeout,
          min: 1.0,
          max: 10.0,
          divisions: 18,
          activeColor: settingsColors.accent,
          inactiveColor: settingsColors.border,
          onChanged: (value) async {
            await _searchSettings.setMaxSearchTime(value);
            setState(() {});
          },
        ),
        _buildDescription(
          'Limit how long to wait for results. Lower is faster but may miss some engines.',
        ),
      ],
    );
  }

  Widget _buildTextFieldWithController(
    String label,
    String hint,
    String description,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    final settingsColors = SettingsTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SettingsTheme.inputLabel(context)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: settingsColors.subtitle.withOpacity(0.5),
              fontSize: 14,
            ),
            filled: true,
            fillColor: settingsColors.inputBackground,
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
              borderSide: BorderSide(color: settingsColors.accent, width: 2),
            ),
          ),
          style: SettingsTheme.inputText(context),
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.url,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        _buildDescription(description),
      ],
    );
  }

  Widget _buildDescription(String text) {
    final settingsColors = SettingsTheme.colors(context);
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
            color: settingsColors.subtitle.withOpacity(0.6),
          ),
          children: [
            if (before.isNotEmpty) TextSpan(text: before),
            TextSpan(
              text: url,
              style: TextStyle(
                color: settingsColors.accent,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  try {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      // Fallback for desktop platforms
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    }
                  } catch (e) {
                    // If URL launching fails, show a snackbar with the URL
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Unable to open URL. Please visit: $url',
                          ),
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
          color: settingsColors.subtitle.withOpacity(0.6),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });
    try {
      final success = await _searchSettings.testSearXNGConnection();
      setState(() {
        _testingConnection = false;
        _testResult = success ? 'success' : 'failed';
      });
      if (mounted) {
        final settingsColors = SettingsTheme.colors(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Successfully connected!' : 'Failed to connect.',
            ),
            backgroundColor: success
                ? settingsColors.success
                : settingsColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _testingConnection = false;
        _testResult = 'failed';
      });
    }
  }
}
