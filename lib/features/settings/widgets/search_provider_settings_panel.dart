import 'package:flutter/material.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';
import 'package:searvo/features/settings/services/search_provider_settings_service.dart';
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

  bool _isTestingConnection = false;
  String? _connectionStatus; // 'success' | 'failed' | null
  int _currentTimeout = 30;

  late TextEditingController _serverUrlController;

  static const String _defaultUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(
      text: _searchSettings.getBackendApiUrl(),
    );
    _currentTimeout = _searchSettings.getSearchTimeout();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Search & Intelligence Server',
          subtitle:
              'Configure connection settings, service endpoints, and processing preferences',
        ),
        const SizedBox(height: 24),
        _buildServerConnectionCard(),
        const SizedBox(height: 20),
        _buildRequestPreferencesCard(),
        const SizedBox(height: 20),
        _buildServiceOverviewCard(),
      ],
    );
  }

  Widget _buildServerConnectionCard() {
    final settingsColors = SettingsTheme.colors(context);
    final isCustomUrl = _serverUrlController.text.trim() != _defaultUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: settingsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: settingsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: settingsColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dns_outlined,
                  size: 20,
                  color: settingsColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Endpoint',
                      style: SettingsTheme.settingTitle(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Primary gateway for AI reasoning, web search, and data synthesis',
                      style: SettingsTheme.settingDescription(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Server URL', style: SettingsTheme.inputLabel(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _serverUrlController,
            decoration: InputDecoration(
              hintText: 'https://api.yourserver.com or http://localhost:8000',
              hintStyle: TextStyle(
                color: settingsColors.subtitle.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: settingsColors.inputBackground,
              suffixIcon: isCustomUrl
                  ? IconButton(
                      tooltip: 'Reset to default',
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () {
                        _serverUrlController.text = _defaultUrl;
                        _searchSettings.setBackendApiUrl(_defaultUrl);
                        setState(() {
                          _connectionStatus = null;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: settingsColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: settingsColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: settingsColors.accent, width: 1.5),
              ),
            ),
            style: SettingsTheme.inputText(context),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              _searchSettings.setBackendApiUrl(value.trim());
              if (_connectionStatus != null) {
                setState(() {
                  _connectionStatus = null;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Specify the host and port of your Searvo server. Android emulators should use http://10.0.2.2:8000.',
            style: TextStyle(
              fontSize: 12,
              color: settingsColors.subtitle.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              FilledButton.icon(
                onPressed:
                    _serverUrlController.text.trim().isNotEmpty &&
                            !_isTestingConnection
                        ? _testServerConnection
                        : null,
                icon: _isTestingConnection
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: settingsColors.inverseText,
                        ),
                      )
                    : const Icon(Icons.wifi_find_outlined, size: 18),
                label: Text(
                  _isTestingConnection
                      ? 'Verifying...'
                      : 'Verify Connection',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: settingsColors.accent,
                  foregroundColor: settingsColors.inverseText,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_connectionStatus != null) ...[
                const SizedBox(width: 16),
                _buildStatusBadge(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final settingsColors = SettingsTheme.colors(context);
    final isOnline = _connectionStatus == 'success';
    final badgeColor = isOnline ? settingsColors.success : settingsColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Server Operational' : 'Server Unreachable',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPreferencesCard() {
    final settingsColors = SettingsTheme.colors(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: settingsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: settingsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: settingsColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: settingsColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Preferences',
                      style: SettingsTheme.settingTitle(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure response timeouts and execution thresholds',
                      style: SettingsTheme.settingDescription(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Connection Timeout', style: SettingsTheme.inputLabel(context)),
              Text(
                '$_currentTimeout seconds',
                style: TextStyle(
                  color: settingsColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: settingsColors.accent,
              thumbColor: settingsColors.accent,
              inactiveTrackColor: settingsColors.border,
              trackHeight: 4,
            ),
            child: Slider(
              value: _currentTimeout.toDouble(),
              min: 10,
              max: 90,
              divisions: 16,
              onChanged: (value) {
                final timeout = value.round();
                setState(() {
                  _currentTimeout = timeout;
                });
                _searchSettings.setSearchTimeout(timeout);
              },
            ),
          ),
          Text(
            'Maximum duration allocated for multi-step search synthesis and tool execution.',
            style: TextStyle(
              fontSize: 12,
              color: settingsColors.subtitle.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOverviewCard() {
    final settingsColors = SettingsTheme.colors(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: settingsColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: settingsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: settingsColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Architecture & Privacy Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: settingsColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.hub_outlined,
            title: 'Dedicated Intelligence Engine',
            description:
                'Search queries, tool orchestration, and neural embeddings run securely on your server node.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.stream_outlined,
            title: 'Real-Time Streaming Protocol',
            description:
                'Synthesized responses and reasoning steps stream incrementally to the client for zero latency.',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.shield_outlined,
            title: 'Privacy By Design',
            description:
                'Search queries and personal document indices remain under your control without third-party tracking.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final settingsColors = SettingsTheme.colors(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: settingsColors.subtitle.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: settingsColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: settingsColors.subtitle.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final isHealthy = await _searchSettings.testBackendApiConnection();
      if (!mounted) return;

      setState(() {
        _isTestingConnection = false;
        _connectionStatus = isHealthy ? 'success' : 'failed';
      });

      final settingsColors = SettingsTheme.colors(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHealthy
                ? 'Server connected successfully and ready.'
                : 'Could not connect to server. Please check the URL.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor:
              isHealthy ? settingsColors.success : settingsColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = 'failed';
      });
    }
  }
}
