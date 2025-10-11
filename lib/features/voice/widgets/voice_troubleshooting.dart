import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/voice/screens/voice_diagnostics_screen.dart';
import 'package:searvo/features/voice/services/voice_service.dart';
import 'package:searvo/features/voice/widgets/voice_input_widget.dart';

/// Quick voice troubleshooting widget that can be added to any screen
class VoiceTroubleshootingWidget extends StatefulWidget {
  const VoiceTroubleshootingWidget({super.key});

  @override
  State<VoiceTroubleshootingWidget> createState() => _VoiceTroubleshootingWidgetState();
}

class _VoiceTroubleshootingWidgetState extends State<VoiceTroubleshootingWidget> {
  final VoiceService _voiceService = VoiceService();
  String? _status;
  String? _lastInput;
  bool _isLoading = false;

  Future<void> _quickTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing...';
      _lastInput = null;
    });

    try {
      // Test initialization
      final success = await _voiceService.initialize();
      
      if (!success) {
        setState(() {
          _status = 'Initialization failed: ${_voiceService.errorMessage}';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'Ready! Tap mic button to test voice input.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _quickTest();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.troubleshoot,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voice Input Troubleshooting',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceDiagnosticsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Full Diagnostics',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quick test section
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _quickTest,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Quick Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                VoiceInputButton(
                  size: 40,
                  onTextReceived: (text) {
                    setState(() {
                      _lastInput = text;
                      _status = 'Voice input successful!';
                    });
                  },
                  onError: (error) {
                    setState(() {
                      _status = 'Voice input failed: $error';
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status display
            if (_status != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status!.contains('successful') 
                      ? Colors.green.withOpacity(0.1)
                      : _status!.contains('failed') || _status!.contains('Error')
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status!.contains('successful') 
                        ? Colors.green.withOpacity(0.3)
                        : _status!.contains('failed') || _status!.contains('Error')
                            ? Colors.red.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _status!,
                  style: TextStyle(
                    color: _status!.contains('successful') 
                        ? Colors.green
                        : _status!.contains('failed') || _status!.contains('Error')
                            ? Colors.red
                            : Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
              
              if (_lastInput != null) ...[
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
                        'Voice Input Result:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastInput!,
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
            
            const SizedBox(height: 12),
            
            // Common solutions
            Text(
              'Common Solutions:',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Grant microphone permission in device settings\n'
              '• Ensure internet connection is stable\n'
              '• Try restarting the app\n'
              '• Check if other voice apps work\n'
              '• Update your device system',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}