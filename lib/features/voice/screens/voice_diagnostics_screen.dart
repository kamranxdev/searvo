import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/voice/services/voice_service.dart';
import 'package:searvo/features/voice/widgets/voice_input_widget.dart';

/// Diagnostic screen to troubleshoot voice input issues
class VoiceDiagnosticsScreen extends StatefulWidget {
  const VoiceDiagnosticsScreen({super.key});

  @override
  State<VoiceDiagnosticsScreen> createState() => _VoiceDiagnosticsScreenState();
}

class _VoiceDiagnosticsScreenState extends State<VoiceDiagnosticsScreen> {
  final VoiceService _voiceService = VoiceService();
  Map<String, dynamic>? _diagnostics;
  bool _isLoading = false;
  String? _testResult;
  String? _lastVoiceInput;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diagnostics = await _voiceService.runDiagnostics();
      setState(() {
        _diagnostics = diagnostics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _diagnostics = {'error': 'Failed to run diagnostics: $e'};
        _isLoading = false;
      });
    }
  }

  Future<void> _testVoiceInput() async {
    setState(() {
      _testResult = 'Testing voice input...';
      _lastVoiceInput = null;
    });

    try {
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _lastVoiceInput = text;
            _testResult = 'Voice input successful!';
          });
        },
        onError: (error) {
          setState(() {
            _testResult = 'Voice input failed: $error';
          });
        },
      );

      // Auto-stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _voiceService.isListening) {
          _voiceService.stopListening();
          if (_lastVoiceInput == null) {
            setState(() {
              _testResult = 'No voice input detected. Please check microphone.';
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _testResult = 'Failed to start voice input test: $e';
      });
    }
  }

  Future<void> _copyDiagnostics() async {
    if (_diagnostics == null) return;

    final diagnosticsText = _diagnostics!.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');

    await Clipboard.setData(ClipboardData(text: diagnosticsText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Diagnostics copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Color _getStatusColor(String key, dynamic value) {
    switch (key) {
      case 'permissionGranted':
      case 'isAvailable':
      case 'initializationSuccess':
      case 'speechRecognitionAvailable':
        return value == true ? Colors.green : Colors.red;
      case 'lastError':
        return value?.toString().isNotEmpty == true ? Colors.red : Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String key, dynamic value) {
    switch (key) {
      case 'permissionGranted':
      case 'isAvailable':
      case 'initializationSuccess':
      case 'speechRecognitionAvailable':
        return value == true ? Icons.check_circle : Icons.error;
      case 'lastError':
        return value?.toString().isNotEmpty == true ? Icons.error : Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  List<Widget> _getRecommendations() {
    if (_diagnostics == null) return [];

    final recommendations = <Widget>[];

    // Permission issues
    if (_diagnostics!['permissionGranted'] != true) {
      recommendations.add(_buildRecommendation(
        'Permission Issue',
        'Microphone permission is not granted. Try the following:',
        [
          '1. Tap "Test Voice Input" to request permission again',
          '2. Go to device Settings > Apps > Your App > Permissions > Microphone',
          '3. Enable microphone permission manually',
          '4. Restart the app after granting permission',
        ],
        Icons.mic_off,
        Colors.red,
      ));
    }

    // Speech recognition not available
    if (_diagnostics!['speechRecognitionAvailable'] != true) {
      recommendations.add(_buildRecommendation(
        'Speech Recognition Issue',
        'Speech recognition is not available on this device:',
        [
          '1. Check if your device supports speech-to-text',
          '2. Ensure you have an internet connection (required for some devices)',
          '3. Try updating Google app (Android) or iOS (iPhone)',
          '4. Check if language/region settings support speech recognition',
        ],
        Icons.record_voice_over,
        Colors.orange,
      ));
    }

    // Initialization failed
    if (_diagnostics!['initializationSuccess'] != true) {
      recommendations.add(_buildRecommendation(
        'Initialization Issue',
        'Voice service failed to initialize:',
        [
          '1. Restart the app',
          '2. Check device storage (low storage can cause issues)',
          '3. Ensure device has working microphone hardware',
          '4. Try using another voice app to test microphone',
        ],
        Icons.settings_voice,
        Colors.orange,
      ));
    }

    // No locales available
    if ((_diagnostics!['availableLocales'] as int?) == 0) {
      recommendations.add(_buildRecommendation(
        'Language Support Issue',
        'No speech recognition languages available:',
        [
          '1. Check device language settings',
          '2. Ensure internet connection for downloading language packs',
          '3. Try changing device language to English temporarily',
          '4. Update system language packs',
        ],
        Icons.language,
        Colors.orange,
      ));
    }

    // If no specific issues found but still not working
    if (recommendations.isEmpty && _testResult?.contains('failed') == true) {
      recommendations.add(_buildRecommendation(
        'General Troubleshooting',
        'Try these general solutions:',
        [
          '1. Close and restart the app completely',
          '2. Restart your device',
          '3. Check for app updates',
          '4. Test microphone with another app (voice recorder, calls)',
          '5. Check if battery optimization is disabled for this app',
        ],
        Icons.troubleshoot,
        Colors.blue,
      ));
    }

    return recommendations;
  }

  Widget _buildRecommendation(
    String title,
    String description,
    List<String> steps,
    IconData icon,
    Color color,
  ) {
    return Builder(
      builder: (context) {
        final colorScheme = context.colorScheme;
        return Card(
          color: colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    step,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        title: Text(
          'Voice Input Diagnostics',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            onPressed: _runDiagnostics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Diagnostics',
          ),
          if (_diagnostics != null)
            IconButton(
              onPressed: _copyDiagnostics,
              icon: const Icon(Icons.copy),
              tooltip: 'Copy Diagnostics',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Test Voice Input Section
                  Card(
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Input Test',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _testVoiceInput,
                                  icon: const Icon(Icons.mic),
                                  label: const Text('Test Voice Input'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              VoiceInputButton(
                                size: 48,
                                onTextReceived: (text) {
                                  setState(() {
                                    _lastVoiceInput = text;
                                    _testResult = 'Voice widget test successful!';
                                  });
                                },
                                onError: (error) {
                                  setState(() {
                                    _testResult = 'Voice widget test failed: $error';
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_testResult != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _testResult!.contains('successful') 
                                    ? Colors.green.withOpacity(0.1)
                                    : _testResult!.contains('failed')
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _testResult!.contains('successful') 
                                      ? Colors.green.withOpacity(0.3)
                                      : _testResult!.contains('failed')
                                          ? Colors.red.withOpacity(0.3)
                                          : Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _testResult!,
                                style: TextStyle(
                                  color: _testResult!.contains('successful') 
                                      ? Colors.green
                                      : _testResult!.contains('failed')
                                          ? Colors.red
                                          : Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_lastVoiceInput != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outline,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Last Voice Input:',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _lastVoiceInput!,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Diagnostics Section
                  if (_diagnostics != null) ...[
                    Card(
                      color: colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Diagnostics',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._diagnostics!.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _getStatusIcon(entry.key, entry.value),
                                      color: _getStatusColor(entry.key, entry.value),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${entry.key}: ${entry.value}',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recommendations Section
                    ..._getRecommendations(),
                  ],
                ],
              ),
            ),
    );
  }
}